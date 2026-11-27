#!/bin/sh
# Polish Keyboard - KPM uninstall hook
# Detaches every layer at the four reserved keyboard keymap targets.
# KPM removes its own unpacked package directory.

set -u

DATA_DIR="/var/local/system/polish-keyboard"
MARKER="$DATA_DIR/.managed-by-polish-keyboard"
DOCS_DIR="/mnt/us/documents"
SCRIPTLET="$DOCS_DIR/Polska klawiatura.sh"

say() {
    printf '%s\n' "Polska klawiatura: $*"
}

fail() {
    say "BLAD: $*" >&2
    exit 1
}

# Count exact mountpoint entries. grep -c prints 0 when there are no matches
# but returns status 1; both 0 and 1 are valid results. Any other status or
# malformed output is an error and must never be interpreted as zero mounts.
mount_count() {
    COUNT_OUTPUT=$(grep -F -c " $1 " /proc/mounts 2>/dev/null)
    GREP_STATUS=$?

    case "$GREP_STATUS" in
        0|1) ;;
        *) return 1 ;;
    esac

    case "$COUNT_OUTPUT" in
        ''|*[!0-9]*) return 1 ;;
    esac

    printf '%s\n' "$COUNT_OUTPUT"
}

restart_kb() {
    STATUS=$(initctl status kb 2>&1 || true)
    case "$STATUS" in
        *start/running*)
            say "Przywracanie oryginalnego ukladu: restart uslugi kb..."
            initctl restart kb >/dev/null 2>&1 || return 1
            ;;
        *)
            say "Uruchamianie uslugi kb z oryginalnym ukladem..."
            initctl start kb >/dev/null 2>&1 || return 1
            ;;
    esac

    STATUS=$(initctl status kb 2>&1 || true)
    say "$STATUS"
    case "$STATUS" in
        *start/running*) return 0 ;;
        *) return 1 ;;
    esac
}

unmount_target() {
    LANG_DIR=$1
    SIZE=$2
    TARGET="/usr/share/keyboard/$LANG_DIR/${LANG_DIR}-${SIZE}.keymap.gz"

    COUNT=$(mount_count "$TARGET") || {
        say "BLAD: nie mozna odczytac liczby montowan dla $TARGET." >&2
        FAILED=1
        return
    }

    while [ "$COUNT" -gt 0 ]; do
        say "Odmontowywanie: $LANG_DIR $SIZE (pozostale warstwy: $COUNT)"

        if ! /bin/umount "$TARGET"; then
            say "BLAD: nie udalo sie odmontowac $TARGET." >&2
            FAILED=1
            return
        fi

        NEW_COUNT=$(mount_count "$TARGET") || {
            say "BLAD: nie mozna zweryfikowac montowan po umount: $TARGET." >&2
            FAILED=1
            return
        }

        if [ "$NEW_COUNT" -ge "$COUNT" ]; then
            say "BLAD: umount nie zmniejszyl liczby montowan dla $TARGET (bylo: $COUNT, jest: $NEW_COUNT)." >&2
            FAILED=1
            return
        fi

        CHANGED=1
        COUNT=$NEW_COUNT
    done
}

[ "$(id -u)" = "0" ] || fail "uninstall.sh musi dzialac jako root."
[ -x /bin/umount ] || fail "Nie znaleziono /bin/umount."
[ -r /proc/mounts ] || fail "Nie mozna odczytac /proc/mounts."
command -v grep >/dev/null 2>&1 || fail "Nie znaleziono polecenia grep."
command -v initctl >/dev/null 2>&1 || fail "Nie znaleziono polecenia initctl."

CHANGED=0
FAILED=0

# All four targets are reserved for this package. Do not depend on DATA_DIR
# or its source files: this hook must also recover orphaned bind mounts.
unmount_target en_GB 1236x1648
unmount_target en_GB 1648x1236
unmount_target en_US 1236x1648
unmount_target en_US 1648x1236

# Reload kb after any successful detach, even if another target failed.
if [ "$CHANGED" -eq 1 ]; then
    restart_kb || {
        say "BLAD: nie udalo sie potwierdzic dzialania uslugi kb po odmontowaniu map." >&2
        FAILED=1
    }
fi

# Final fail-closed verification. A read error is a failure, not zero mounts.
for LANG_DIR in en_GB en_US; do
    for SIZE in 1236x1648 1648x1236; do
        TARGET="/usr/share/keyboard/$LANG_DIR/${LANG_DIR}-${SIZE}.keymap.gz"
        COUNT=$(mount_count "$TARGET") || {
            say "BLAD: nie mozna zweryfikowac punktu montowania $TARGET." >&2
            FAILED=1
            continue
        }
        if [ "$COUNT" -gt 0 ]; then
            say "BLAD: nadal zamontowany jest $TARGET ($COUNT warstw)." >&2
            FAILED=1
        fi
    done
done

if [ "$FAILED" -ne 0 ]; then
    say "Nie usuwam danych ani skryptu bibliotecznego, poniewaz montowania nie zostaly w pelni odlaczone lub kb nie dziala poprawnie."
    exit 1
fi

# During a KPM upgrade, preserve managed data and the library scriptlet.
# KPM itself removes the old package directory and extracts the new version.
if [ "${1:-}" = "upgrade" ]; then
    say "Aktualizacja: zachowano dane i skrypt biblioteczny. Pliki pakietu usunie KPM."
    exit 0
fi

# Remove only the library scriptlet carrying this package's marker.
if [ -f "$SCRIPTLET" ] && [ ! -L "$SCRIPTLET" ]; then
    if grep -q '^# Managed by KPM package: polish-keyboard$' "$SCRIPTLET"; then
        rm -f "$SCRIPTLET" || fail "Nie udalo sie usunac skryptu bibliotecznego. Dane pozostawiono."
        say "Usunieto pozycje 'Polska klawiatura' z biblioteki."
    else
        say "Nie usuwam '$SCRIPTLET': brak znacznika tego pakietu."
    fi
fi

# Remove only the ordinary managed data directory. Never follow a symlink.
if [ -L "$DATA_DIR" ]; then
    say "Pozostawiam $DATA_DIR: sciezka jest dowiazaniem symbolicznym."
elif [ -d "$DATA_DIR" ]; then
    if [ -f "$MARKER" ] && [ ! -L "$MARKER" ]; then
        rm -rf "$DATA_DIR" || fail "Nie udalo sie usunac danych $DATA_DIR."
        [ ! -e "$DATA_DIR" ] || fail "Katalog $DATA_DIR nadal istnieje po probie usuniecia."
        say "Usunieto dane keymap z $DATA_DIR."
    else
        say "Pozostawiam $DATA_DIR: brak zwyklego znacznika tego pakietu."
    fi
elif [ -e "$DATA_DIR" ]; then
    say "Pozostawiam $DATA_DIR: sciezka nie jest zwyklym katalogiem."
fi

say "Polska klawiatura zostala odinstalowana. Oryginalne pliki systemowe nie byly modyfikowane; wszystkie montowania w zarezerwowanych punktach zostaly odlaczone."
exit 0
