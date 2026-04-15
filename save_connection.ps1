# ============================================================
#  Zapisz named connection w SQLcl dla trybu MCP
#  SQLcl MCP wymaga zapisanego polaczenia
#  Dane polaczenia czytane z .env
# ============================================================

. (Join-Path $PSScriptRoot "_load-env.ps1")

$cfg = Import-DotEnv
Clear-OracleEnvironment

if (-not (Test-Path $cfg.SQLCL_PATH)) {
    Write-Host "BLAD: Nie znaleziono SQLcl pod: $($cfg.SQLCL_PATH)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Zapisuje named connection: $($cfg.CONN_NAME)" -ForegroundColor Cyan
Write-Host "Target: $($cfg.DB_USER)@//$($cfg.DB_HOST):$($cfg.DB_PORT)/$($cfg.DB_SERVICE)"
Write-Host "============================================================"

$saveCommand = @"
CONNECT -save $($cfg.CONN_NAME) -savepwd $($cfg.DB_USER)/$($cfg.DB_PASS)@//$($cfg.DB_HOST):$($cfg.DB_PORT)/$($cfg.DB_SERVICE)
SHOW CONNECTION
CONNMGR LIST
exit
"@

$saveCommand | & $cfg.SQLCL_PATH /nolog

Write-Host "============================================================"
Write-Host ""
Write-Host "Polaczenie '$($cfg.CONN_NAME)' zapisane." -ForegroundColor Green
Write-Host "Teraz mozesz uzyc trybu MCP w Claude Code."
Write-Host ""
Read-Host "Nacisnij Enter aby zamknac"
