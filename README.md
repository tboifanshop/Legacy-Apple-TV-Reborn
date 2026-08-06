# Legacy Apple TV Reborn

Modularny launcher dla Apple TV 3,2 (A1469), Apple TV Software 7.9, ARMv7.

## Status

Aktualnie wdrozony jest fundament Etapow 1-3 (architektura + kod zrodlowy):

- hook Logos inicjalizujacy launcher jako overlay
- modularny root view launchera (tapeta, status bar, widget host, siatka, dock)
- centralny koordynator laczacy modul UI i modul logiki
- wydzielony stan launchera (lista aplikacji, ukrywanie aplikacji, foldery)
- osobne moduly: tapety, odtwarzacz, Drive worker client, menedzer plikow, ustawienia, animacje

## Struktura

- `Launcher/`
- `Hooks/`
- `Resources/`
- `WallpaperManager/`
- `VideoPlayer/`
- `DriveManager/`
- `Settings/`
- `Animations/`
- `Utilities/`
- `FileManager/`
- `Widgets/`

## Moduly i odpowiedzialnosci

- `Launcher/`: warstwa UI i orkiestracja (siatka aplikacji, stan launchera, overlay)
- `Hooks/`: punkt wejscia Logos i przejecie cyklu zycia procesu `AppleTV`
- `WallpaperManager/`: zarzadzanie statyczna i animowana tapeta
- `VideoPlayer/`: playback MP4 (play/pause/seek/loop/mute/volume + pozycja)
- `DriveManager/`: komunikacja z Cloudflare Worker dla operacji Google Drive
- `FileManager/`: operacje kopiowania, przenoszenia, usuwania, tworzenia folderow, zmiany nazwy
- `Settings/`: trwale ustawienia launchera
- `Animations/`: lekkie animacje fokusowania i przejsc
- `Widgets/`: host widokow widgetow

## Wazne zalozenia

- brak zalozen o nowoczesnych API tvOS (SwiftUI, TVUIKit, TVML)
- kazda prywatna klasa lub framework musi byc najpierw potwierdzona runtime lub analiza systemu
- architektura ma byc modularna i rozszerzalna bez przebudowy fundamentu

## Build i wdrozenie

Kompilacja i pakowanie sa celowo odlozone do czasu pracy na docelowym
srodowisku z odpowiednim SDK oraz danymi runtime z urzadzenia.

## Logi Etapu 1

Hook jest potwierdzany przez log jednorazowy:

- `Hook aktywny: UIApplication sendEvent:`

Przy starcie tweak dodatkowo loguje probe obecnosci wybranych klas prywatnych,
bez zakladania ich istnienia.

## Runtime Diagnostics (ATLRuntimeDiagnostics v2)

Raport runtime jest zapisywany do:

- `/var/mobile/Library/Logs/ATLRuntimeReport.txt`

Raport zawiera teraz:

- metadane uruchomienia: timestamp, bundle identifier, executable path, process name, OS version, wersja modulu diagnostycznego
- loaded dyld images z wyroznieniem kluczowych wpisow (UIKit, AVFoundation, FrontBoard, FrontBoardServices, AppleTVServices, ITMLKit, JavaScriptCore, YouTubeATV, QuartzCore, CoreMedia, MediaToolbox)
- loaded bundles i frameworks (`allBundles` / `allFrameworks`) z `bundle path`, `bundle identifier`, `executable path`
- protokoly Objective-C dla prefiksow BR/ATV/RUI/RUIYT/MEYT/YT, wraz z dziedziczeniem i podzialem metod na wymagane/opcjonalne oraz instancyjne/klasowe
- klasy dla prefiksow BR/ATV/RUI/RUIYT/MEYT/YT, wraz z protocols, properties, ivars (typ + offset), methods
- osobna sekcje priority classes z bardziej szczegolowym dumpem
- sekcje krytycznych selectorow (`respondsToSelector:` / `instancesRespondToSelector:`)
- limity rozmiaru i oznaczenia `TRUNCATED` dla zbyt obszernych danych

## Pobranie Raportu po SSH

Przyklad odczytu bezposrednio na urzadzeniu:

```bash
ssh root@APPLETV_IP 'cat /var/mobile/Library/Logs/ATLRuntimeReport.txt'
```

Przyklad skopiowania raportu lokalnie:

```bash
scp root@APPLETV_IP:/var/mobile/Library/Logs/ATLRuntimeReport.txt ./ATLRuntimeReport.txt
```

## Najwazniejsze Sekcje Raportu

a) Szukanie kontrolera glownego menu:

- `[1] Loaded dyld Images`
- `[2] Loaded Bundles and Frameworks`
- `[4] Class Properties, Ivars, Protocols and Methods (Prefixed)`
- `[6] Priority Classes Deep Diagnostics`

b) Przywracanie YouTube:

- `[1] Loaded dyld Images` (szczegolnie `YouTubeATV`, `ITMLKit`, `JavaScriptCore`)
- `[3] Objective-C Protocols (Prefixed)`
- `[4] Class Properties, Ivars, Protocols and Methods (Prefixed)`
- `[6] Priority Classes Deep Diagnostics`

c) Budowa launchera:

- `[0] Required Class Presence`
- `[5] Priority Classes Presence`
- `[6] Priority Classes Deep Diagnostics`
- `[7] Critical Selector Checks (respondsToSelector)`

## Kolejny krok

Uzupelnienie danych aplikacji na podstawie rzeczywistej analizy runtime
na jailbreaku (nazwy klas, zrodlo listy aplikacji, zdarzenia pilota), a nastepnie
podmiana mockowej listy ikon na dane systemowe.
