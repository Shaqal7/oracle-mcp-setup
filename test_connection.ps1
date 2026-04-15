# ============================================================
#  Test polaczenia Oracle przez SQLcl (thin JDBC)
#  Dane polaczenia czytane z .env
# ============================================================

. (Join-Path $PSScriptRoot "_load-env.ps1")

$cfg = Import-DotEnv
Clear-OracleEnvironment

if (-not (Test-Path $cfg.SQLCL_PATH)) {
    Write-Host "BLAD: Nie znaleziono SQLcl pod: $($cfg.SQLCL_PATH)" -ForegroundColor Red
    Write-Host "Popraw SQLCL_PATH w .env lub pobierz SQLcl z Oracle."
    exit 1
}

$conn = "$($cfg.DB_USER)/$($cfg.DB_PASS)@//$($cfg.DB_HOST):$($cfg.DB_PORT)/$($cfg.DB_SERVICE)"

Write-Host ""
Write-Host "Lacze z: $($cfg.DB_USER)@//$($cfg.DB_HOST):$($cfg.DB_PORT)/$($cfg.DB_SERVICE)" -ForegroundColor Cyan
Write-Host "============================================================"

$sql = @"
SET PAGESIZE 50
SET LINESIZE 200
SELECT 'Polaczenie OK!' AS STATUS FROM dual;
SELECT USER AS AKTYWNY_USER FROM dual;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS CZAS FROM dual;
SELECT table_name FROM user_tables WHERE ROWNUM <= 10;
exit
"@

$sql | & $cfg.SQLCL_PATH $conn

Write-Host "============================================================"
Write-Host ""
Write-Host "Jesli widzisz wyniki SELECT powyzej - wszystko dziala!" -ForegroundColor Green
Write-Host ""
Read-Host "Nacisnij Enter aby zamknac"
