# FIRST DEVICE BRING-UP (Apple TV 3)

Cel: bezpieczne, etapowe pierwsze uruchomienie projektu na Apple TV 3,2 bez zgadywania API i bez ryzykownych zmian na starcie.

Potwierdzony target pierwszego testu:
- model: Apple TV 3,2, A1469
- OS: Apple TV Software 7.9 (8163)
- runtime: iPhone OS 8.4.4 (12H1006)
- architektura binarna: ARM / ARMv7 / MH_MAGIC / EXECUTE / PIE
- host build: Xcode 10.1, iPhoneOS12.1 SDK, minimum iOS 8.0, arch: armv7

Zakres tego dokumentu:
- najpierw tylko diagnostyka runtime,
- dopiero po stabilnym przejsciu etapow uruchomienie diagnostyki JIT,
- brak testow launchera i brak testow YouTube podczas pierwszego przejscia.

## Zasada nadrzedna

Podczas pierwszego testu NIE uruchamiaj launchera ani YouTube. Najpierw zbierz i przeanalizuj raporty diagnostyczne oraz logi stabilnosci procesu.

## Kolejnosc pierwszego uruchomienia

### 1) Jailbreak i potwierdzenie SSH

Wymaganie:
- urzadzenie jest po jailbreaku,
- mozliwe stabilne logowanie SSH na konto root.

Przyklad:
```bash
ssh root@APPLETV_IP
```

Kryterium PASS:
- logowanie SSH dziala i otrzymujesz shell.

Kryterium FAIL:
- brak polaczenia,
- timeout,
- blad uwierzytelnienia bez mozliwosci poprawy.

Checklist:
- [ ] PASS
- [ ] FAIL

### 2) Backup waznych plikow

Wykonaj backup co najmniej:
- pliku dylib tweak-a,
- pliku plist ladowania tweak-a,
- krytycznych plikow konfiguracyjnych, jesli byly modyfikowane.

Przyklad (dostosuj nazwy plikow do instalacji):
```bash
mkdir -p /var/mobile/ATL-backup
cp -a /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib /var/mobile/ATL-backup/
cp -a /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist /var/mobile/ATL-backup/
```

Kryterium PASS:
- backup istnieje i pliki sa czytelne.

Kryterium FAIL:
- nie da sie wykonac kopii,
- brak uprawnien,
- brak miejsca.

Checklist:
- [ ] PASS
- [ ] FAIL

### 3) Sprawdzenie architektury urzadzenia

Potwierdz, ze testy wykonujesz na docelowej architekturze Apple TV 3 (ARMv7).

Przyklad:
```bash
uname -m
```

Kryterium PASS:
- wynik zgodny z oczekiwanym targetem dla Apple TV 3.

Kryterium FAIL:
- wynik niezgodny,
- brak pewnosci co do architektury.

Checklist:
- [ ] PASS
- [ ] FAIL

### 4) Instalacja najprostszej wersji tweak-a

W pierwszym bring-up instaluj minimalny wariant:
- bez nowych funkcji launchera,
- bez aktywacji funkcji YouTube,
- tylko niezbedny kod startowy i diagnostyka.

Na tym etapie uzyj tylko minimalnego targetu `ATLRuntimeProbe`.

Komenda build na Macu:
```bash
make ATL_RUNTIME_ONLY=1 package
```

Jezykowo-sprawdzone zalozenia builda:
- Xcode 10.1
- iPhoneOS12.1 SDK
- `ARCHS=armv7`
- minimum iOS 8.0

Po buildzie powinny powstac artefakty:
- `.theos/obj/armv7/ATLRuntimeProbe.dylib`
- `.theos/_/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib`
- `.theos/_/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist`

Kryterium PASS:
- pakiet instaluje sie poprawnie,
- pliki dylib/plist sa na miejscu.

Kryterium FAIL:
- blad instalacji,
- niespojne pliki,
- brak wymaganych artefaktow.

Checklist:
- [ ] PASS
- [ ] FAIL

### 5) Uruchomienie tylko ATLRuntimeDiagnostics

W pierwszym starcie wlacz wylacznie diagnostyke runtime.

Minimalny entry point ma tylko wywolac:
```objc
[ATLRuntimeDiagnostics runOnceAfterLaunch];
```

Nie podpinaj `LauncherHooks.x`, nie uruchamiaj `ATLLauncherCoordinator` i nie hookuj dodatkowych punktow startowych bez potrzeby.

Kryterium PASS:
- proces AppleTV startuje,
- nie ma natychmiastowego crasha,
- raport runtime zostaje wygenerowany.

Kryterium FAIL:
- crash przy starcie,
- restart procesu,
- brak raportu runtime.

Checklist:
- [ ] PASS
- [ ] FAIL

### 6) Pobranie ATLRuntimeReport.txt

Docelowa sciezka raportu:
- /var/mobile/Library/Logs/ATLRuntimeReport.txt

Przyklad podgladu:
```bash
ssh root@APPLETV_IP 'cat /var/mobile/Library/Logs/ATLRuntimeReport.txt'
```

Przyklad pobrania:
```bash
scp root@APPLETV_IP:/var/mobile/Library/Logs/ATLRuntimeReport.txt ./ATLRuntimeReport.txt
```

Kryterium PASS:
- plik istnieje,
- raport zawiera tresc (nie jest pusty).

Kryterium FAIL:
- brak pliku,
- plik pusty,
- blad odczytu.

Checklist:
- [ ] PASS
- [ ] FAIL

### 7) Sprawdzenie crash logow

Po uruchomieniu runtime diagnostics sprawdz logi pod katem:
- crash przy starcie,
- watchdog,
- petle restartow procesu AppleTV.

Kryterium PASS:
- brak nowych crashy krytycznych po wdrozeniu minimalnego tweak-a.

Kryterium FAIL:
- wykryto crash,
- wykryto watchdog,
- wykryto restart procesu.

Checklist:
- [ ] PASS
- [ ] FAIL

### 8) Dopiero potem uruchomienie ATLJITDiagnostics

Warunek wejscia:
- etapy 1-7 zakonczone PASS.

Uruchomienie reczne:
```objc
[ATLJITDiagnostics runDiagnostics];
```

Kryterium PASS:
- uruchomienie kontrolowane,
- brak natychmiastowego crasha procesu.

Kryterium FAIL:
- crash,
- restart procesu,
- objawy niestabilnosci po starcie testu.

Checklist:
- [ ] PASS
- [ ] FAIL

### 9) Pobranie ATLJITReport.txt

Docelowa sciezka raportu:
- /var/mobile/Library/Logs/ATLJITReport.txt

Przyklad podgladu:
```bash
ssh root@APPLETV_IP 'cat /var/mobile/Library/Logs/ATLJITReport.txt'
```

Przyklad pobrania:
```bash
scp root@APPLETV_IP:/var/mobile/Library/Logs/ATLJITReport.txt ./ATLJITReport.txt
```

Kryterium PASS:
- plik istnieje,
- sekcje testow sa wypelnione,
- raport nadaje sie do analizy.

Kryterium FAIL:
- brak pliku,
- plik pusty,
- urwany raport po awarii.

Checklist:
- [ ] PASS
- [ ] FAIL

### 10) Kryteria STOP (natychmiast przerwij test)

Jezeli wystapi ktorykolwiek z ponizszych sygnalow, zatrzymaj test:
- bootloop,
- restart procesu,
- brak SSH,
- watchdog,
- crash przy starcie.

Checklist:
- [ ] PASS (brak sygnalow STOP)
- [ ] FAIL (wystapil co najmniej jeden sygnal STOP)

### 11) Procedura odzyskania

Wykonuj po kolei:
1. wejscie przez SSH,
2. wylaczenie dylib/plist (dezaktywacja ladowania tweak-a),
3. usuniecie pakietu,
4. restart interfejsu.

Szybki wariant dla first-device:
```bash
ssh root@192.168.1.13
mv /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist.disabled
mv /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib.disabled
dpkg -r com.tboifanshop.appletvlauncher || true
killall AppleTV || reboot
```

Kryterium PASS:
- odzyskany dostep SSH,
- AppleTV uruchamia sie bez tweak-a,
- brak petli crashy.

Kryterium FAIL:
- nadal brak SSH,
- nadal bootloop,
- proces nadal crashuje po dezaktywacji.

Checklist:
- [ ] PASS
- [ ] FAIL

### 12) Zakaz uruchamiania launchera i YouTube na pierwszym tescie

W pierwszym bring-up:
- nie uruchamiaj launchera,
- nie testuj funkcji YouTube,
- nie wlaczaj dodatkowych eksperymentalnych hookow.

Kryterium PASS:
- test ograniczony do runtime diagnostics (a potem JIT diagnostics po PASS etapow 1-7).

Kryterium FAIL:
- uruchomiono launcher lub YouTube przed zakonczeniem diagnostyki bazowej.

Checklist:
- [ ] PASS
- [ ] FAIL

### 13) Zbiorcza checklista PASS/FAIL

Oznacz wynik kazdego etapu:

- [ ] Etap 1 PASS / [ ] FAIL
- [ ] Etap 2 PASS / [ ] FAIL
- [ ] Etap 3 PASS / [ ] FAIL
- [ ] Etap 4 PASS / [ ] FAIL
- [ ] Etap 5 PASS / [ ] FAIL
- [ ] Etap 6 PASS / [ ] FAIL
- [ ] Etap 7 PASS / [ ] FAIL
- [ ] Etap 8 PASS / [ ] FAIL
- [ ] Etap 9 PASS / [ ] FAIL
- [ ] Etap 10 PASS / [ ] FAIL
- [ ] Etap 11 PASS / [ ] FAIL
- [ ] Etap 12 PASS / [ ] FAIL

Regula koncowa:
- Jesli jakikolwiek etap ma FAIL, nie przechodz do kolejnych funkcji produktu.
- Wroc do procedury odzyskania i dopiero po stabilizacji powtorz test od Etapu 1.

## Minimalny zestaw plikow do pierwszego testu

Na first-device test wysylasz tylko:
- `ATLRuntimeProbe.dylib`
- `ATLRuntimeProbe.plist`

Nie wysylaj jeszcze:
- `LauncherHooks.x`
- launcher UI
- YouTube hookow
- pakietu rozszerzonego launchera

## Wrzucenie przez SCP

Przyklad po zbudowaniu na Macu:
```bash
scp .theos/_/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib root@192.168.1.13:/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.dylib
scp layout/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist root@192.168.1.13:/Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.plist
```

## Sprawdzenie po instalacji

Na Apple TV po wrzuceniu plikow:
```bash
ssh root@192.168.1.13
ls -l /Library/MobileSubstrate/DynamicLibraries/ATLRuntimeProbe.*
cat /var/mobile/Library/Logs/ATLRuntimeReport.txt
```
