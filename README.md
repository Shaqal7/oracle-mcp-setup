# Oracle SQLcl MCP for Claude Code

Podpięcie bazy **Oracle** (XE / 18c / 19c / 21c / 23ai) do **Claude Code** przez oficjalny **SQLcl MCP server** na Windows. Działa z bazą lokalną (Docker), zdalną (VPN / sieć firmowa) i cloudową.

Claude Code po podłączeniu potrafi: wykonywać `SELECT`/`INSERT`/`UPDATE`/`DELETE`, opisywać struktury tabel, listować obiekty, pisać i testować zapytania oraz analizować wyniki.

## Co jest w repo

| Plik | Opis |
|------|------|
| `.env.example` | Szablon zmiennych środowiskowych — skopiuj do `.env` i uzupełnij |
| `.env` | **Ignorowany przez git** — Twoje faktyczne creds |
| `_load-env.ps1` | Helper (parser .env + funkcja czyszcząca środowisko) |
| `test_connection.ps1` | Test połączenia z bazą — uruchom najpierw |
| `save_connection.ps1` | Zapisuje named connection w SQLcl (wymagane dla MCP) |
| `sqlcl_mcp_wrapper.bat` | Wrapper, na który wskazuje Claude Code |
| `SETUP_GUIDE.md` | Szczegółowy przewodnik krok po kroku (troubleshooting) |

## Wymagania

- **Windows 10/11** (skrypty pod CMD/PowerShell)
- **Java 17+** — np. [Eclipse Temurin 21 LTS](https://adoptium.net/temurin/releases/?version=21)
- **Oracle SQLcl** — [download](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/), rozpakuj do `C:\tools\sqlcl\`
- **Claude Code** w wersji wspierającej MCP
- Dostęp sieciowy do instancji Oracle (localhost lub zdalna)

## Szybki start

```powershell
# 1. Sklonuj repo i wejdź do folderu
git clone <repo-url>
cd oracle-mcp-setup

# 2. Skopiuj szablon i uzupełnij danymi dostępu
Copy-Item .env.example .env
notepad .env

# 3. Odblokuj wykonywanie PS (tylko dla tej sesji)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 4. Przetestuj połączenie z bazą
.\test_connection.ps1

# 5. Zapisz named connection w SQLcl
.\save_connection.ps1

# 6. Dodaj MCP do Claude Code (ścieżkę dostosuj do swojej lokalizacji repo)
claude mcp add oracle-sqlcl -s user "$(Resolve-Path .\sqlcl_mcp_wrapper.bat)"

# 7. Sprawdź listę MCP i zrestartuj Claude Code
claude mcp list
```

Po restarcie Claude Code wpisz `/mcp` — powinieneś zobaczyć `oracle-sqlcl` na liście. Szczegóły w [SETUP_GUIDE.md](./SETUP_GUIDE.md).

## Konfiguracja (.env)

```env
DB_USER=your_username
DB_PASS=your_password
DB_HOST=10.57.170.83
DB_PORT=1521
DB_SERVICE=XE

CONN_NAME=my_oracle
SQLCL_PATH=C:\tools\sqlcl\bin\sql.exe
```

Dla Oracle XE 18c+ service name to zazwyczaj `XE` lub `XEPDB1` (PDB). Jeśli dostajesz `ORA-12514`, spróbuj `XEPDB1`.

## Dlaczego wrapper, a nie bezpośrednio SQLcl?

Jeśli na maszynie masz zainstalowany Oracle Client / Instant Client, SQLcl **automatycznie wykrywa OCI driver** w PATH i próbuje go użyć — co kończy się błędem `no ocijdbc23 in java.library.path`, jeśli wersje się nie zgadzają (np. lokalny Oracle 18c XE vs. SQLcl 26.1 szukający ocijdbc23). Wrapper:

- Czyści zmienne `ORACLE_HOME`, `TNS_ADMIN`, `NLS_LANG`
- Usuwa wpisy `oracle` / `instantclient` / `oraclexe` z `PATH`
- Odpala SQLcl, który wtedy używa **czystego Java thin JDBC** (brak zależności od natywnych bibliotek)

**Ważne:** wrapper używa `SETLOCAL`, więc zmiany środowiskowe są **izolowane wyłącznie do procesu SQLcl** — nie mają żadnego wpływu na inne działające aplikacje, DBeaver, SSMS ani globalne zmienne systemu. Po zakończeniu SQLcl środowisko rodzica (Claude Code) wraca do stanu sprzed uruchomienia wrappera.

## Bezpieczeństwo

- `.env` jest w `.gitignore` — hasła nigdy nie trafiają do repo
- `.env.example` zawiera tylko szablon bez prawdziwych danych
- SQLcl zapisuje hasło lokalnie w zaszyfrowanym store (`%USERPROFILE%\.dbtools\connections\`)
- Przed pushem do publicznego repo upewnij się, że `.env` jest ignorowany: `git status` nie powinien go pokazywać

## Troubleshooting

| Problem | Rozwiązanie |
|---------|-------------|
| `Dbtools SQLcl Console: This application requires Java 17.0.5` | Zainstaluj [Temurin 21 LTS](https://adoptium.net/temurin/releases/?version=21) |
| `no ocijdbc23 in java.library.path` | Użyj wrappera (czyści PATH) albo odpal `test_connection.ps1` |
| `ORA-12541: No listener` | Sprawdź czy baza działa i port 1521 jest otwarty |
| `ORA-12514: service not found` | Zmień `DB_SERVICE=XEPDB1` w `.env` |
| `ORA-01017: invalid username/password` | Sprawdź dane w `.env` |
| MCP nie pojawia się w `/mcp` | Użyj `claude mcp add` zamiast edytować `settings.json` |
| PowerShell blokuje skrypty | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |

Więcej w [SETUP_GUIDE.md](./SETUP_GUIDE.md).

## License

MIT
