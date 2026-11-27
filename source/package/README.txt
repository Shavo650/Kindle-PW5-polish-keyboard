POLSKA KLAWIATURA — PAKIET KPM

ID pakietu: polish-keyboard
Platforma: kindlehf (ARMHF)
Wersja: 1.0.0

Co robi instalacja:
- kopiuje cztery przygotowane keymapy do /var/local/system/polish-keyboard;
- dodaje pozycję "Polska klawiatura.sh" do /mnt/us/documents;
- nie modyfikuje plików w /usr ani /etc i nie instaluje autostartu.

Aktywacja:
- otwórz bibliotekę Kindle;
- kliknij "Polska klawiatura";
- skrypt wykrywa en_GB albo en_US;
- montuje oba warianty orientacji (pion/poziom) dla wybranego języka;
- restartuje usługę kb tylko wtedy, gdy jest to potrzebne.

Odinstalowanie:
- uninstall.sh pomija odmontowywanie podczas aktualizacji KPM;
- przy zwykłym odinstalowaniu najpierw sprawdza sumy SHA-256 danych i wszystkich aktywnych map;
- odmontowuje wyłącznie mapy en_GB/en_US zgodne z plikami tego pakietu;
- po odmontowaniu restartuje usługę kb, aby odczytała niezmienione oryginalne pliki;
- dopiero po potwierdzeniu braku mountów usuwa własny scriptlet i katalog danych.
- przy niezgodności albo błędzie zachowuje dane i kończy się błędem zamiast usuwać nieznane montowanie.

Wymagania:
- Kindle ARMHF z KPM;
- aktywny Shell Integration dla plików .sh w documents;
- język klawiatury en_GB lub en_US.
