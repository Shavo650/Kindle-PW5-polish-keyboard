#!/bin/sh
# Polish Keyboard - KPM install hook
# Installs keymaps and the library scriptlet.
# Activation is performed manually by launching the library scriptlet.

set -eu

PKG_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DATA_DIR="/var/local/system/polish-keyboard"
DOCS_DIR="/mnt/us/documents"
SCRIPTLET="$DOCS_DIR/Polska klawiatura.sh"
MARKER="$DATA_DIR/.managed-by-polish-keyboard"

MAPS="en_GB-1236x1648-PL-clean-safe.keymap.gz en_GB-1648x1236-PL-clean-safe.keymap.gz en_US-1236x1648-PL-clean-safe.keymap.gz en_US-1648x1236-PL-clean-safe.keymap.gz"

say() {
    printf '%s\n' "Polska klawiatura: $*"
}

fail() {
    say "BLAD: $*" >&2
    exit 1
}

# Count mounts at one exact target. grep -c prints 0 and exits with status 1
# when there are no matches; that case is valid. Other grep errors are fatal.
mount_count() {
    MC_TARGET=$1

    if MC_OUTPUT=$(grep -F -c " $MC_TARGET " /proc/mounts 2>/dev/null); then
        :
    else
        MC_STATUS=$?
        [ "$MC_STATUS" -eq 1 ] || return 1
    fi

    case "$MC_OUTPUT" in
        ''|*[!0-9]*) return 1 ;;
    esac

    printf '%s\n' "$MC_OUTPUT"
}

[ "$(id -u)" = "0" ] || fail "install.sh musi dzialac jako root."
[ -d "$DOCS_DIR" ] || fail "Nie znaleziono katalogu $DOCS_DIR."
[ -d "$PKG_DIR/keymaps" ] || fail "Brak katalogu keymaps w paczce."
[ -f "$PKG_DIR/keymaps/SHA256SUMS" ] || fail "Brak keymaps/SHA256SUMS."
[ -f "$PKG_DIR/scriptlets/Polska klawiatura.sh" ] || fail "Brak skryptu bibliotecznego w paczce."
[ -f "$PKG_DIR/activate.sh" ] || fail "Brak activate.sh w paczce."
[ -r /proc/mounts ] || fail "Nie mozna odczytac /proc/mounts."
command -v grep >/dev/null 2>&1 || fail "Nie znaleziono polecenia grep."

say "Sprawdzanie plikow pakietu..."

# Validate all packaged keymaps before changing installed data.
(
    cd "$PKG_DIR/keymaps"
    sha256sum -c SHA256SUMS
    for f in $MAPS; do
        [ -f "$f" ] || exit 1
        gzip -t "$f"
    done
) || fail "Mapy w paczce nie przeszly kontroli SHA256/gzip."

grep -q '^# Managed by KPM package: polish-keyboard$' "$PKG_DIR/scriptlets/Polska klawiatura.sh" \
    || fail "Skrypt biblioteczny w paczce nie ma znacznika tego pakietu."

# Do not overwrite an unrelated library scriptlet.
if [ -e "$SCRIPTLET" ] || [ -L "$SCRIPTLET" ]; then
    [ -f "$SCRIPTLET" ] && [ ! -L "$SCRIPTLET" ] \
        || fail "Plik '$SCRIPTLET' nie jest zwyklym plikiem."
    grep -q '^# Managed by KPM package: polish-keyboard$' "$SCRIPTLET" \
        || fail "Plik '$SCRIPTLET' istnieje, ale nie nalezy do tego pakietu."
fi

# Check all four reserved keyboard targets before creating or changing data.
# A failed /proc/mounts read must never be interpreted as zero mounts.
for spec in \
    "en_GB 1236x1648" \
    "en_GB 1648x1236" \
    "en_US 1236x1648" \
    "en_US 1648x1236"
do
    set -- $spec
    LANG_DIR=$1
    SIZE=$2
    TARGET="/usr/share/keyboard/$LANG_DIR/${LANG_DIR}-${SIZE}.keymap.gz"

    COUNT=$(mount_count "$TARGET") \
        || fail "Nie mozna wiarygodnie sprawdzic montowania $TARGET. Nie zmieniam danych."

    [ "$COUNT" -eq 0 ] \
        || fail "$TARGET nadal jest zamontowany ($COUNT warstw). Najpierw odlacz poprzednie montowanie. Nie zmieniam danych."
done

# Existing data may be changed only when it belongs to this package.
if [ -e "$DATA_DIR" ] || [ -L "$DATA_DIR" ]; then
    [ -d "$DATA_DIR" ] && [ ! -L "$DATA_DIR" ] \
        || fail "$DATA_DIR nie jest zwyklym katalogiem. Niczego nie nadpisuje."
    [ -f "$MARKER" ] \
        || fail "$DATA_DIR istnieje, ale nie ma znacznika tego pakietu. Niczego nie nadpisuje."
else
    mkdir -p "$DATA_DIR" || fail "Nie moge utworzyc $DATA_DIR."
    : > "$MARKER" || fail "Nie moge utworzyc znacznika pakietu."
fi

# Copy the four maps and their checksum manifest into the managed data folder.
for f in $MAPS; do
    cp -f "$PKG_DIR/keymaps/$f" "$DATA_DIR/$f" \
        || fail "Nie udalo sie skopiowac $f do $DATA_DIR."
done

cp -f "$PKG_DIR/keymaps/SHA256SUMS" "$DATA_DIR/SHA256SUMS" \
    || fail "Nie udalo sie skopiowac SHA256SUMS."

# Verify the copied files as well as the packaged originals.
(
    cd "$DATA_DIR"
    sha256sum -c SHA256SUMS
    for f in $MAPS; do
        gzip -t "$f"
    done
) || fail "Skopiowane mapy nie przeszly kontroli SHA256/gzip."

cp -f "$PKG_DIR/scriptlets/Polska klawiatura.sh" "$SCRIPTLET" \
    || fail "Nie udalo sie skopiowac skryptu bibliotecznego."

chmod 755 "$SCRIPTLET" 2>/dev/null || true

say "Instalacja zakonczona poprawnie."
say "Pliki keymap zapisano w: $DATA_DIR"
say "Aby aktywowac uklad, uruchom 'Polska klawiatura' z biblioteki Kindle."
exit 0
