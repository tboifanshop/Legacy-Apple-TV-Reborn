# ATLRuntimeDiagnostics Security Review

Zakres: tylko code review `ATLRuntimeDiagnostics`.

Plik analizowany:
- `Diagnostics/ATLRuntimeDiagnostics.m`

## Podsumowanie

- Znaleziono: 1 ryzyko wysokie.
- Naprawiono: 1 ryzyko wysokie.
- Ryzyka krytyczne po poprawce: brak.

## Findings

### 1) Wysokie: potencjalny wzrost zuzycia pamieci i czasu CPU przez budowanie jednego bardzo duzego raportu

- Poziom: **High**
- Lokalizacja:
  - `Diagnostics/ATLRuntimeDiagnostics.m:30`
  - `Diagnostics/ATLRuntimeDiagnostics.m:135`
  - `Diagnostics/ATLRuntimeDiagnostics.m:185`
  - `Diagnostics/ATLRuntimeDiagnostics.m:235`
  - `Diagnostics/ATLRuntimeDiagnostics.m:269`
  - `Diagnostics/ATLRuntimeDiagnostics.m:369`
  - `Diagnostics/ATLRuntimeDiagnostics.m:403`
- Objaw:
  - raport byl budowany jako jeden `NSMutableString` i mogl rosnac przy duzej liczbie klas/protokolow/obrazow.
  - dlugie iteracje mogly zwiekszac ryzyko watchdog timeout.
- Poprawka:
  - dodano globalny limit rozmiaru raportu `ATLMaxReportCharacters`.
  - dodano bezpieczny guard `_isReportLimitReached:section:` i wczesne przerwanie sekcji z komunikatem `TRUNCATED`.
- Status: **Fixed**
- Linie poprawki:
  - `Diagnostics/ATLRuntimeDiagnostics.m:17`
  - `Diagnostics/ATLRuntimeDiagnostics.m:147`
  - `Diagnostics/ATLRuntimeDiagnostics.m:170`
  - `Diagnostics/ATLRuntimeDiagnostics.m:229`
  - `Diagnostics/ATLRuntimeDiagnostics.m:244`
  - `Diagnostics/ATLRuntimeDiagnostics.m:258`
  - `Diagnostics/ATLRuntimeDiagnostics.m:312`
  - `Diagnostics/ATLRuntimeDiagnostics.m:389`
  - `Diagnostics/ATLRuntimeDiagnostics.m:444`
  - `Diagnostics/ATLRuntimeDiagnostics.m:479`

## Kontrola wymagan bezpieczenstwa

1. `objc_copy*` i `free()`:
- Zwalnianie list potwierdzone dla:
  - `objc_copyProtocolList` (`free(protocolList)`): `Diagnostics/ATLRuntimeDiagnostics.m:224`
  - `protocol_copyProtocolList` (`free(inherited)`): sekcja protokolow
  - `protocol_copyMethodDescriptionList` (`free(methods)`): sekcja grup metod protokolow
  - `objc_copyClassList` (`free(classList)`): `Diagnostics/ATLRuntimeDiagnostics.m:542`
  - `class_copyMethodList` (`free(methods)`): sekcja metod klas
  - `class_copyPropertyList` (`free(properties)`): sekcja properties
  - `class_copyIvarList` (`free(ivars)`): sekcja ivars
  - `class_copyProtocolList` (`free(protocols)`): sekcja protocol names dla klasy

2. NULL safety:
- Sprawdzenia `NULL`/`nil` sa obecne przed dereferencja runtime pointerow i selectorow.

3. Zakres iteracji:
- Petle opieraja sie o liczniki zwrocone przez runtime i nie wychodza poza zakres.

4. Rownoleglosc zapisu raportu:
- Uruchomienie jednorazowe przez `dispatch_once` (`runOnceAfterLaunch`).

5. `dispatch_once`:
- Uzyty poprawnie, scope statyczny procesu.

6. Zgodnosc z Foundation (stare iOS):
- `NSFileManager createDirectoryAtPath` i `NSString writeToFile` sa uzyte defensywnie z obsluga `NSError`.

7. Ochrona przed nadmiernym rozmiarem raportu:
- Dodano globalny limit i `TRUNCATED`.

8. `class_copyMethodList` i watchdog:
- Oprocz istniejacych limitow metod/klas dodano globalne odciecie raportu.

9. Selector checks:
- Nie tworza instancji klas; uzywaja tylko `instancesRespondToSelector:` i `respondsToSelector:` na obiekcie klasy.

10. API runtime i iOS 8.x:
- Uzyte API (`objc/runtime`, `mach-o/dyld`) sa zgodne z epoka iOS 8.x.

## Pozostale uwagi (non-blocking)

- Rozwazenie etapowego zapisu strumieniowego do pliku (zamiast jednego bufora) mogloby dalej ograniczyc peak memory, ale nie jest to blad krytyczny po obecnej poprawce z limitem globalnym.
