@echo off
REM ============================================================
REM  Wrapper dla SQLcl MCP - czysci srodowisko i odpala -mcp
REM  Czyta SQLCL_PATH z pliku .env
REM  Na ten plik wskazuje Claude Code (claude mcp add)
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM Wczytaj SQLCL_PATH z .env
SET "ENV_FILE=%~dp0.env"
IF NOT EXIST "%ENV_FILE%" (
    echo BLAD: Nie znaleziono %ENV_FILE% 1>&2
    echo Skopiuj .env.example do .env i uzupelnij dane. 1>&2
    exit /b 1
)

FOR /F "usebackq tokens=1,* delims==" %%a IN ("%ENV_FILE%") DO (
    IF "%%a"=="SQLCL_PATH" SET "SQLCL_PATH=%%b"
)

IF NOT EXIST "!SQLCL_PATH!" (
    echo BLAD: SQLcl nie znaleziony pod: !SQLCL_PATH! 1>&2
    exit /b 1
)

REM Wyczysc Oracle z srodowiska - wymuszenie thin JDBC
SET "ORACLE_HOME="
SET "NLS_LANG="
SET "TNS_ADMIN="
SET "JAVA_TOOL_OPTIONS="

REM Zbuduj nowy PATH bez Oracle/instantclient/oraclexe
SET "NEW_PATH="
FOR %%p IN ("%PATH:;=";"%") DO (
    SET "item=%%~p"
    echo !item! | findstr /I /C:"oracle" /C:"instantclient" /C:"oraclexe" >nul
    IF ERRORLEVEL 1 (
        IF "!NEW_PATH!"=="" (
            SET "NEW_PATH=!item!"
        ) ELSE (
            SET "NEW_PATH=!NEW_PATH!;!item!"
        )
    )
)
SET "PATH=!NEW_PATH!"

REM Odpal SQLcl w trybie MCP - argumenty przekazywane z Claude Code
"!SQLCL_PATH!" -mcp %*

ENDLOCAL
