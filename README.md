# Polska klawiatura dla Kindle Paperwhite 5

## Informacja o odpowiedzialności

**Wszelkie opisane modyfikacje wykonujesz na własne ryzyko! Autor projektu zrzeka się odpowiedzialności za ewentualne problemy, uszkodzenia lub nieprawidłowe działanie urządzenia wynikające z instalacji lub użytkowania modyfikacji.**

## Opis

Zmodyfikowana klawiatura dla Kindle, która dodaje obsługę polskich znaków diakrytycznych oraz usuwa znaki niewystępujące w polskim alfabecie.

Modyfikacja nie ingeruje w partycję systemową ani nie nadpisuje oryginalnych plików systemowych.

Podczas instalacji skrypt kopiuje zmodyfikowane pliki `keymap` do katalogu `/var/local`. Następnie, za pomocą mechanizmu **bind mount**, powoduje, że klawiatura korzysta z plików znajdujących się w nowym katalogu zamiast z oryginalnych plików systemowych.

Oryginalne pliki pozostają nienaruszone. Modyfikacja jest tymczasowa i łatwa do wyłączenia — wystarczy ponownie uruchomić urządzenie. Można ją również całkowicie odinstalować, korzystając z instrukcji poniżej.

## Wymagania

- Kindle Paperwhite 5 (11. generacja, 2022) — działanie na innych urządzeniach nie zostało przetestowane.
- Jailbreak.
- KPM (Kindle Package Manager).
- Firmware 5.19.2 — działanie na innych wersjach firmware nie zostało przetestowane.
- Język systemu: `en_US` lub `en_GB`.

---

## Instalacja

### A) Instalacja automatyczna (zalecana)

1. Pobierz plik `instalator-polska-klawiatura.sh`.
2. Podłącz czytnik do komputera za pomocą kabla USB.
3. Skopiuj plik do katalogu `documents` w pamięci Kindle.
4. Upewnij się, że czytnik ma dostęp do Internetu.
5. Odłącz Kindle od komputera.
6. W bibliotece czytnika powinien pojawić się plik instalatora. Uruchom go tak samo jak zwykłą książkę.

Instalator automatycznie wykona następujące czynności:

- Doda adres repozytorium projektu do bazy KPM. Od tego momentu możliwe będzie korzystanie z poleceń KPM bezpośrednio z paska wyszukiwania Kindle.
- Doda do biblioteki skrypt `Polska klawiatura.sh`, służący do aktywacji zmodyfikowanej klawiatury.

### B) Instalacja ręczna (KTerm lub inny terminal na urządzeniu)

1. Otwórz terminal na czytniku i wykonaj polecenie:

   ```sh
   /var/local/kmc/bin/kpm add-repo "https://raw.githubusercontent.com/Shavo650/Kindle-PW5-polish-keyboard/main/manifest.json"
   ```

2. W pasku wyszukiwania Kindle wpisz:

   ```text
   ;kpm update
   ```

3. Następnie wpisz:

   ```text
   ;kpm install polish-keyboard
   ```

---

## Użytkowanie

Po zainstalowaniu pakietu należy ręcznie uruchomić z biblioteki skrypt **Polska klawiatura.sh**.

Zmodyfikowana klawiatura będzie aktywna do momentu ponownego uruchomienia urządzenia.

**Uwaga:** uśpienie czytnika nie wyłącza modyfikacji. Dopiero ponowne uruchomienie Kindle przywraca oryginalny układ klawiatury.

Po każdym restarcie urządzenia, aby ponownie korzystać z polskiej klawiatury, należy uruchomić skrypt **Polska klawiatura.sh** z biblioteki.

## Odinstalowanie

Aby całkowicie usunąć modyfikację:

1. W pasku wyszukiwania Kindle wpisz:

   ```text
   ;kpm uninstall polish-keyboard
   ```

2. KPM uruchomi procedurę odinstalowania, która usunie skrypty oraz pliki wykorzystywane przez polską klawiaturę i przywróci oryginalny układ.

3. Po odinstalowaniu nie ma potrzeby ponownego dodawania repozytorium, jeśli planujesz ponowną instalację.

   Wystarczy wpisać:

   ```text
   ;kpm install polish-keyboard
   ```

---

## Repozytorium projektu

[Kindle-PW5-polish-keyboard – GitHub](https://github.com/Shavo650/Kindle-PW5-polish-keyboard)
