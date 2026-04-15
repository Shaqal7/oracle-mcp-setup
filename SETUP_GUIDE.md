# Oracle SQLcl MCP — Szczegółowy przewodnik setupu

Ten dokument prowadzi Cię krok po kroku przez podłączenie bazy Oracle do Claude Code przez SQLcl MCP server. Jeśli szukasz szybkiego startu, zobacz [README.md](./README.md).

## Architektura rozwiązania

```
Claude Code
    │
    ▼
sqlcl_mcp_wrapper.bat   ← czyści środowisko (PATH, ORACLE_HOME)
    │
    ▼
Oracle SQLcl (-mcp)      ← oficjalny Oracle MCP server
    │  (thin JDBC)
    ▼
Oracle Database          ← XE / 18c / 19c / 21c / 23ai
```

Wrapper jest kluczowy — bez niego SQLcl wykrywa zainstalowane lokalnie Oracle Client (jeśli są) i próbuje użyć OCI driver, który wymaga zgodnych wersji natywnych DLL.

## Krok 1 — Instalacja Java 17+

SQLcl 25.x+ wymaga **Java 17 lub nowszej**. Zalecana: **Eclipse Temurin 21 LTS** (darmowa, OpenJDK, bez konta Oracle).

1. Sprawdź aktualną wersję w PowerShell:
   ```powershell
   java -version
   ```
2. Jeśli brak lub za stara — pobierz z https://adoptium.net/temurin/releases/?version=21
   - Operating System: **Windows**
   - Architecture: **x64**
   - Package Type: **JDK**
3. Uruchom instalator `.msi` — automatycznie doda Java do `PATH`.
4. **Otwórz nowe okno PowerShell** (stare nie widzi nowej Javy) i zweryfikuj:
   ```powershell
   java -version
   # openjdk version "21.x.x" ...
   ```

## Krok 2 — Instalacja Oracle SQLcl

1. Pobierz z https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/
2. Rozpakuj ZIP do `C:\tools\sqlcl\` (lub innej lokalizacji — zapisz ścieżkę do `.env`).
3. Sprawdź strukturę — powinno być `C:\tools\sqlcl\bin\sql.exe`.
4. Weryfikacja:
   ```powershell
   C:\tools\sqlcl\bin\sql.exe -version
   # SQLcl: Release 25.x / 26.x Production
   ```

## Krok 3 — Przygotuj .env

```powershell
Copy-Item .env.example .env
notepad .env
```

Uzupełnij:

| Zmienna | Opis | Przykład |
|---------|------|----------|
| `DB_USER` | Nazwa użytkownika bazy | `market3_user` |
| `DB_PASS` | Hasło | `tajnehaslo` |
| `DB_HOST` | Host bazy (IP lub nazwa) | `10.57.170.83` albo `localhost` |
| `DB_PORT` | Port (domyślnie 1521) | `1521` |
| `DB_SERVICE` | Service name / SID | `XE` lub `XEPDB1` |
| `CONN_NAME` | Dowolna nazwa dla zapisu w SQLcl | `market3_xe` |
| `SQLCL_PATH` | Absolutna ścieżka do `sql.exe` | `C:\tools\sqlcl\bin\sql.exe` |

> 💡 **Tip:** Dla Oracle XE 18c+ domyślny service name to zazwyczaj `XE` (CDB) albo `XEPDB1` (PDB). Jeśli jeden nie działa, spróbuj drugiego.

## Krok 4 — Test połączenia

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\test_connection.ps1
```

Oczekiwany output:
```
Lacze z: market3_user@//10.57.170.83:1521/XE
============================================================
SQLcl: Release 26.1 Production ...
Connected to: Oracle Database 18c Express Edition ...

STATUS
_________________
Polaczenie OK!

AKTYWNY_USER
_______________
MARKET3_USER

CZAS
______________________
2026-04-14 19:49:50

TABLE_NAME
_____________________________
...
```

Jeśli widzisz wyniki — przejdź do kroku 5. Jeśli nie:

| Błąd | Co zrobić |
|------|-----------|
| `no ocijdbc23 in java.library.path` | Skrypt próbuje już czyścić PATH — jeśli nadal błąd, sprawdź czy nie odpalasz starej wersji skryptu |
| `ORA-12541: No listener` | Baza wyłączona albo zły host/port. Sprawdź kontener Docker: `docker ps` |
| `ORA-12514: service not found` | Zły service name — spróbuj `XEPDB1` |
| `ORA-01017: invalid username/password` | Błędne creds w `.env` |
| Brak outputu w ogóle | Problem z Javą — sprawdź `java -version` |

## Krok 5 — Zapisz named connection

SQLcl MCP server wymaga zapisanego (named) połączenia z hasłem w wewnętrznym store SQLcl. Połączenie jest szyfrowane i zapisane w `%USERPROFILE%\.dbtools\connections\`.

```powershell
.\save_connection.ps1
```

W outputcie powinno się pojawić Twoje połączenie na liście `CONNMGR LIST`.

## Krok 6 — Dodaj MCP do Claude Code

### Właściwa metoda — przez CLI

```powershell
claude mcp add oracle-sqlcl -s user "$(Resolve-Path .\sqlcl_mcp_wrapper.bat)"
```

Flagi:
- `-s user` — globalnie dla wszystkich projektów
- `-s local` — tylko dla bieżącego projektu (wpis w `.claude/settings.local.json`)

Weryfikacja:
```powershell
claude mcp list
# oracle-sqlcl: ... sqlcl_mcp_wrapper.bat
```

### ⚠️ Czego NIE robić

Nie dodawaj `mcpServers` bezpośrednio do `~/.claude/settings.json` — Claude Code nie czyta MCP z tego pliku. To częsta pomyłka — `settings.json` jest dla konfiguracji Claude Code (model, plugins), a MCP servery są w `~/.claude.json` (zarządzane przez `claude mcp add`).

## Krok 7 — Zrestartuj Claude Code

1. Zamknij Claude Code **całkowicie** (nie wystarczy reload).
2. Otwórz ponownie.
3. Wpisz `/mcp` — powinieneś zobaczyć `oracle-sqlcl` z statusem `connected`.

## Krok 8 — Używanie

W Claude Code możesz teraz bezpośrednio pytać o bazę:

> "Połącz się z moją bazą Oracle i pokaż listę tabel"

Claude Code zapyta najpierw, którego named connection użyć (będzie `market3_xe` lub inna nazwa z `CONN_NAME`), a potem wywoła odpowiednie narzędzia SQLcl MCP:

- `connect` — wybór zapisanego połączenia
- `run-sql` — wykonuje zapytania SQL (SELECT, DML, DDL)
- `run-sqlcl` — wykonuje komendy SQLcl (DESCRIBE, SHOW, itp.)
- `list-connections` — lista zapisanych połączeń
- `disconnect` — rozłączenie

## Wiele połączeń (DEV/PROD/inne bazy)

Możesz zapisać więcej połączeń w SQLcl — każde z inną nazwą:

```powershell
# W .env ustaw np. CONN_NAME=oracle_dev i odpal:
.\save_connection.ps1

# Potem zmień w .env na CONN_NAME=oracle_prod i odpal ponownie:
.\save_connection.ps1
```

Claude Code zobaczy wszystkie i poprosi o wybór podczas `connect`.

## Zmiana hasła / endpointu

1. Zaktualizuj `.env`.
2. Uruchom `.\save_connection.ps1` ponownie — nadpisze istniejący named connection.
3. W Claude Code wywołaj `disconnect` i `connect` ponownie.

## Aktualizacja SQLcl

Gdy wyjdzie nowa wersja SQLcl:
1. Rozpakuj do nowego folderu (np. `C:\tools\sqlcl-26.2\`).
2. Zmień `SQLCL_PATH` w `.env`.
3. Nic więcej — wrapper czyta aktualną ścieżkę z `.env`.

## Usunięcie MCP

```powershell
claude mcp remove oracle-sqlcl
```

## Checklist przed pushem do repo

- [ ] `.env` nie jest widoczny w `git status` (sprawdź `.gitignore`)
- [ ] `.env.example` zawiera placeholdery, nie prawdziwe dane
- [ ] README.md i SETUP_GUIDE.md nie zawierają prawdziwych haseł ani IP produkcyjnych
- [ ] Skrypty działają po fresh clone + `Copy-Item .env.example .env`

## Bezpieczeństwo haseł

SQLcl zapisuje hasła lokalnie w `%USERPROFILE%\.dbtools\connections\` — są zaszyfrowane kluczem lokalnym użytkownika Windows. Znaczy to:

- Hasła nie są w plain text w repo
- Przeniesienie na inną maszynę wymaga ponownego uruchomienia `save_connection.ps1` (creds w `.env`)
- Jeśli komputer zostanie skompromitowany, hasło da się wydobyć — nie używaj tej metody dla środowisk produkcyjnych wysokiego ryzyka

Dla produkcji rozważ:
- Oracle Wallet (zamiast plain password w `.env`)
- Sekrety z keychain Windows / Azure Key Vault
- Kerberos / OS authentication (bez hasła w SQLcl)

## Dalsze kroki

- Dokumentacja SQLcl MCP: https://docs.oracle.com/en/database/oracle/sql-developer-command-line/
- Reference Claude Code MCP: https://code.claude.com/docs/en/mcp
- Issue tracker: (dodaj link do swojego repo)
