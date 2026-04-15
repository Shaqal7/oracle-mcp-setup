# ============================================================
#  Helper: ladowanie zmiennych z pliku .env
#  Uzywane przez test_connection.ps1 i save_connection.ps1
# ============================================================

function Import-DotEnv {
    param(
        [string]$Path = (Join-Path $PSScriptRoot ".env")
    )

    if (-not (Test-Path $Path)) {
        Write-Host ""
        Write-Host "BLAD: Nie znaleziono pliku .env" -ForegroundColor Red
        Write-Host "Skopiuj .env.example do .env i uzupelnij swoje dane:" -ForegroundColor Yellow
        Write-Host "  Copy-Item .env.example .env" -ForegroundColor Cyan
        exit 1
    }

    $vars = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        # Pomijaj komentarze i puste linie
        if ($line -and -not $line.StartsWith('#')) {
            if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
                $key = $matches[1].Trim()
                $val = $matches[2].Trim()
                # Usun otaczajace cudzyslowy jesli sa
                if ($val -match '^"(.*)"$' -or $val -match "^'(.*)'$") {
                    $val = $matches[1]
                }
                $vars[$key] = $val
            }
        }
    }

    # Walidacja wymaganych zmiennych
    $required = @("DB_USER", "DB_PASS", "DB_HOST", "DB_PORT", "DB_SERVICE", "CONN_NAME", "SQLCL_PATH")
    foreach ($key in $required) {
        if (-not $vars.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($vars[$key])) {
            Write-Host "BLAD: Brakujaca lub pusta zmienna w .env: $key" -ForegroundColor Red
            exit 1
        }
    }

    return $vars
}

function Clear-OracleEnvironment {
    # Wyczysc zmienne Oracle - SQLcl uzyje thin JDBC
    $env:ORACLE_HOME       = ""
    $env:TNS_ADMIN         = ""
    $env:NLS_LANG          = ""
    $env:JAVA_TOOL_OPTIONS = ""

    # Usun katalogi Oracle z PATH (wymuszenie thin JDBC zamiast OCI)
    $env:PATH = ($env:PATH -split ';' | Where-Object {
        $_ -notmatch '(?i)(oracle|instantclient|oraclexe)'
    }) -join ';'
}
