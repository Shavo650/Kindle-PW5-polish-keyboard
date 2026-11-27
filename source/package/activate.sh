#!/bin/sh
set -eu

DATA_DIR="/var/local/system/polish-keyboard"
LAST_LANG_FILE="$DATA_DIR/.last-active-language"

say() {
    printf '%s\n' "$*"
}

fail() {
    say "BLAD: $*"
    exit 1
}

[ "$(id -u)" = "0" ] || fail "Skrypt nie został uruchomiony jako root."
[ -d "$DATA_DIR" ] || fail "Brak danych pakietu: $DATA_DIR. Zainstaluj pakiet ponownie przez KPM."
[ -f "$DATA_DIR/SHA256SUMS" ] || fail "Brak pliku SHA256SUMS."

# Resolve currently selected Kindle keyboard language.
LANG_RAW="$(lipc-get-prop com.lab126.keyboard language 2>/dev/null || true)"
LANG_RAW=$(printf '%s' "$LANG_RAW" | tr -d '\r\n ')
if [ -z "$LANG_RAW" ]; then
    LANG_RAW="$(lipc-get-prop com.lab126.keyboard keyboard_language 2>/dev/null || true)"
    LANG_RAW=$(printf '%s' "$LANG_RAW" | tr -d '\r\n ')
fi

case "$LANG_RAW" in
    en_GB|en-GB) LANG_DIR="en_GB" ;;
    en_US|en-US) LANG_DIR="en_US" ;;
    *) fail "Nieobsługiwany język klawiatury: '$LANG_RAW'. Pakiet obsługuje en_GB i en_US." ;;
esac

# Validate all four installed assets, not just the current language.
(
    cd "$DATA_DIR"
    sha256sum -c SHA256SUMS
) || fail "Kontrola sum SHA-256 nie powiodła się."

NEW_MOUNTS=0
NEED_RESTART=0

# Preflight both orientations before performing either bind mount.
for SIZE in 1236x1648 1648x1236; do
    SRC="$DATA_DIR/${LANG_DIR}-${SIZE}-PL-clean-safe.keymap.gz"
    TARGET="/usr/share/keyboard/${LANG_DIR}/${LANG_DIR}-${SIZE}.keymap.gz"
    [ -f "$SRC" ] || fail "Brak pliku źródłowego: $SRC"
    [ -f "$TARGET" ] || fail "Brak oryginalnego punktu docelowego: $TARGET"
    gzip -t "$SRC" >/dev/null 2>&1 || fail "Uszkodzone archiwum: $SRC"

    SRC_SHA=$(sha256sum "$SRC" | awk '{print $1}')
    if awk -v target="$TARGET" '$2 == target { found=1 } END { exit(found ? 0 : 1) }' /proc/mounts; then
        TARGET_SHA=$(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}')
        [ "$TARGET_SHA" = "$SRC_SHA" ] || fail "Pod $TARGET istnieje inny mount. Nie zmieniam go."
    fi
done

# Bind both portrait and landscape maps for the selected language.
for SIZE in 1236x1648 1648x1236; do
    SRC="$DATA_DIR/${LANG_DIR}-${SIZE}-PL-clean-safe.keymap.gz"
    TARGET="/usr/share/keyboard/${LANG_DIR}/${LANG_DIR}-${SIZE}.keymap.gz"

    if awk -v target="$TARGET" '$2 == target { found=1 } END { exit(found ? 0 : 1) }' /proc/mounts; then
        say "Już zamontowano: ${LANG_DIR} ${SIZE}"
    else
        say "Montowanie: ${LANG_DIR} ${SIZE}"
        /bin/mount --bind "$SRC" "$TARGET" || fail "Nie udało się zamontować $TARGET. Ewentualny wcześniejszy mount pozostaje bez zmian."
        TARGET_SHA=$(sha256sum "$TARGET" 2>/dev/null | awk '{print $1}')
        SRC_SHA=$(sha256sum "$SRC" | awk '{print $1}')
        [ "$TARGET_SHA" = "$SRC_SHA" ] || fail "Weryfikacja bind mount nie powiodła się dla $TARGET."
        NEW_MOUNTS=1
    fi
done

if [ ! -f "$LAST_LANG_FILE" ] || [ "$(cat "$LAST_LANG_FILE" 2>/dev/null || true)" != "$LANG_DIR" ]; then
    NEED_RESTART=1
fi

STATUS="$(initctl status kb 2>&1 || true)"
case "$STATUS" in
    *start/running*)
        if [ "$NEW_MOUNTS" = "1" ] || [ "$NEED_RESTART" = "1" ]; then
            say "Restartowanie klawiatury..."
            initctl restart kb || fail "Nie udało się zrestartować usługi kb. Bind mount pozostaje aktywny; ponowne kliknięcie pozwoli ponowić próbę."
        else
            say "Polski układ dla $LANG_DIR jest już aktywny. Restart nie jest potrzebny."
        fi
        ;;
    *)
        say "Usługa kb nie działa. Uruchamianie..."
        initctl start kb || fail "Nie udało się uruchomić usługi kb. Bind mount pozostaje aktywny."
        ;;
esac

STATUS="$(initctl status kb 2>&1 || true)"
say "$STATUS"
case "$STATUS" in
    *start/running*) ;;
    *) fail "Nie potwierdzono działania usługi kb. Bind mount pozostaje aktywny." ;;
esac

TMP_LAST="${LAST_LANG_FILE}.tmp.$$"
printf '%s\n' "$LANG_DIR" > "$TMP_LAST"
mv -f "$TMP_LAST" "$LAST_LANG_FILE"
say "Polska klawiatura została aktywowana dla $LANG_DIR."
exit 0
