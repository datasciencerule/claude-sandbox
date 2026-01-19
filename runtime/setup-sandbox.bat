@echo off
REM setup-sandbox.bat - Initialize Claude Code sandbox in a project
REM
REM Usage:
REM   setup-sandbox.bat [TARGET_DIR]    # Setup sandbox in TARGET_DIR (default: parent directory)
REM   setup-sandbox.bat --check         # Verify setup is complete
REM   setup-sandbox.bat --update        # Update existing setup (refresh CLAUDE.md section)
REM   setup-sandbox.bat --uninstall     # Remove sandbox files from project
REM
REM This script:
REM   1. Copies docker-compose.yml to the target directory
REM   2. Copies .env.example to .env (if .env doesn't exist)
REM   3. Copies start-sandbox.bat
REM   4. Updates .gitignore with sandbox files
REM   5. Merges sandbox instructions into project's CLAUDE.md

setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"

REM Marker comments for CLAUDE.md section
set "MARKER_BEGIN=<!-- BEGIN SANDBOX ENVIRONMENT -->"
set "MARKER_END=<!-- END SANDBOX ENVIRONMENT -->"

REM Default values
set "MODE=setup"
set "TARGET_DIR="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto done_parsing

if "%~1"=="--check" (
    set "MODE=check"
    shift
    goto parse_args
)
if "%~1"=="--update" (
    set "MODE=update"
    shift
    goto parse_args
)
if "%~1"=="--uninstall" (
    set "MODE=uninstall"
    shift
    goto parse_args
)
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

REM Assume it's a target directory
set "TARGET_DIR=%~1"
shift
goto parse_args

:show_help
echo Usage: %~nx0 [OPTIONS] [TARGET_DIR]
echo.
echo Initialize Claude Code sandbox in a project directory.
echo.
echo Arguments:
echo   TARGET_DIR          Target directory (default: parent directory)
echo.
echo Options:
echo   --check             Verify setup is complete
echo   --update            Update existing setup (refresh CLAUDE.md section)
echo   --uninstall         Remove sandbox files from project
echo   -h, --help          Show this help message
echo.
echo Examples:
echo   %~nx0                  # Setup in parent directory (typical after unzipping)
echo   %~nx0 .                # Setup in current directory
echo   %~nx0 C:\my\project    # Setup in specific directory
echo   %~nx0 --check          # Check if setup is complete
echo   %~nx0 --update         # Update CLAUDE.md sandbox section
exit /b 0

:done_parsing

REM Default target directory to parent directory (assumes script is in runtime\ subfolder)
if "%TARGET_DIR%"=="" set "TARGET_DIR=%SCRIPT_DIR%.."

REM Convert to absolute path
pushd "%TARGET_DIR%" 2>nul
if errorlevel 1 (
    mkdir "%TARGET_DIR%" 2>nul
    pushd "%TARGET_DIR%"
)
set "TARGET_DIR=%CD%"
popd

REM Execute based on mode
if "%MODE%"=="setup" goto do_setup
if "%MODE%"=="update" goto do_update
if "%MODE%"=="check" goto do_check
if "%MODE%"=="uninstall" goto do_uninstall
goto :eof

:do_setup
call :setup "%TARGET_DIR%" "false"
goto :eof

:do_update
call :setup "%TARGET_DIR%" "true"
goto :eof

:do_check
call :check_setup "%TARGET_DIR%"
goto :eof

:do_uninstall
call :uninstall "%TARGET_DIR%"
goto :eof

REM ============================================================================
REM Setup function
REM ============================================================================
:setup
set "SETUP_DIR=%~1"
set "UPDATE_ONLY=%~2"

echo Setting up Claude Code sandbox in: %SETUP_DIR%
echo.

REM Verify source files exist
if not exist "%SCRIPT_DIR%docker-compose.yml" (
    echo [ERROR] Source files not found. Run this script from the runtime directory.
    exit /b 1
)

REM Create target directory if it doesn't exist
if not exist "%SETUP_DIR%" mkdir "%SETUP_DIR%"

if "%UPDATE_ONLY%"=="true" goto skip_file_copy

REM Copy docker-compose.yml
if not exist "%SETUP_DIR%\docker-compose.yml" (
    copy "%SCRIPT_DIR%docker-compose.yml" "%SETUP_DIR%\" >nul
    echo [OK] Copied docker-compose.yml
) else (
    echo [INFO] docker-compose.yml already exists (skipped)
)

REM Copy .env.example to .env
if not exist "%SETUP_DIR%\.env" (
    if exist "%SCRIPT_DIR%.env.example" (
        copy "%SCRIPT_DIR%.env.example" "%SETUP_DIR%\.env" >nul
        echo [OK] Copied .env.example to .env
    ) else (
        echo [WARN] .env.example not found, skipping
    )
) else (
    echo [WARN] .env already exists (not overwritten - check for updates manually)
)

REM Prompt for Git identity if not configured
call :prompt_git_identity "%SETUP_DIR%"

REM Copy start script (Windows only)
copy "%SCRIPT_DIR%start-sandbox.bat" "%SETUP_DIR%\" >nul
echo [OK] Copied start-sandbox.bat

REM Update .gitignore
call :update_gitignore "%SETUP_DIR%"

:skip_file_copy

REM Merge CLAUDE.md (always done, even for update-only)
call :merge_claude_md "%SETUP_DIR%"

echo.
echo [OK] Setup complete!
echo.
echo Next steps:
echo   1. Edit .env with your API credentials
echo   2. Run start-sandbox.bat to start the sandbox
echo.
exit /b 0

REM ============================================================================
REM Update .gitignore function
REM ============================================================================
:update_gitignore
set "GI_DIR=%~1"
set "GI_FILE=%GI_DIR%\.gitignore"

REM Create .gitignore if it doesn't exist
if not exist "%GI_FILE%" (
    type nul > "%GI_FILE%"
    echo [INFO] Created .gitignore
)

REM Add sandbox files to .gitignore if not already present (Windows only)
set "ADDED_FILES="
for %%F in (docker-compose.yml start-sandbox.bat .env) do (
    findstr /x /c:"%%F" "%GI_FILE%" >nul 2>&1
    if errorlevel 1 (
        echo %%F>> "%GI_FILE%"
        set "ADDED_FILES=!ADDED_FILES! %%F"
    )
)

if defined ADDED_FILES (
    echo [OK] Added to .gitignore:%ADDED_FILES%
) else (
    echo [INFO] .gitignore already up to date
)
exit /b 0

REM ============================================================================
REM Prompt for Git identity function
REM ============================================================================
:prompt_git_identity
set "PGI_DIR=%~1"
set "PGI_ENV=%PGI_DIR%\.env"

REM Skip if .env doesn't exist
if not exist "%PGI_ENV%" exit /b 0

REM Check if GIT_AUTHOR_NAME is already set (uncommented) in .env
set "HAS_NAME="
set "HAS_EMAIL="
for /f "usebackq tokens=1,* delims==" %%A in ("%PGI_ENV%") do (
    if "%%A"=="GIT_AUTHOR_NAME" if not "%%B"=="" set "HAS_NAME=1"
    if "%%A"=="GIT_AUTHOR_EMAIL" if not "%%B"=="" set "HAS_EMAIL=1"
)

if defined HAS_NAME if defined HAS_EMAIL (
    echo [INFO] Git identity already configured in .env
    exit /b 0
)

echo.
echo [INFO] Git identity not configured. This is used for git commits inside the sandbox.
echo.

REM Prompt for name
set "GIT_NAME="
if not defined HAS_NAME (
    set /p "GIT_NAME=Enter your name for git commits (or press Enter to skip): "
)

REM Prompt for email
set "GIT_EMAIL="
if not defined HAS_EMAIL (
    set /p "GIT_EMAIL=Enter your email for git commits (or press Enter to skip): "
)

REM Append to .env if values provided
if defined GIT_NAME (
    echo.>> "%PGI_ENV%"
    echo # Git Identity (added by setup)>> "%PGI_ENV%"
    echo GIT_AUTHOR_NAME=%GIT_NAME%>> "%PGI_ENV%"
    echo GIT_COMMITTER_NAME=%GIT_NAME%>> "%PGI_ENV%"
)
if defined GIT_EMAIL (
    if not defined GIT_NAME (
        echo.>> "%PGI_ENV%"
        echo # Git Identity (added by setup)>> "%PGI_ENV%"
    )
    echo GIT_AUTHOR_EMAIL=%GIT_EMAIL%>> "%PGI_ENV%"
    echo GIT_COMMITTER_EMAIL=%GIT_EMAIL%>> "%PGI_ENV%"
)

if defined GIT_NAME (
    echo [OK] Git identity added to .env
) else if defined GIT_EMAIL (
    echo [OK] Git identity added to .env
) else (
    echo [INFO] Git identity skipped (you can add it later in .env)
)
exit /b 0

REM ============================================================================
REM Merge CLAUDE.md function
REM ============================================================================
:merge_claude_md
set "MC_DIR=%~1"
set "MC_TEMPLATE=%SCRIPT_DIR%CLAUDE.sandbox.md"
set "MC_TARGET=%MC_DIR%\CLAUDE.md"

if not exist "%MC_TEMPLATE%" (
    echo [ERROR] Template file not found: %MC_TEMPLATE%
    exit /b 1
)

REM Check if CLAUDE.md exists
if not exist "%MC_TARGET%" (
    REM Create new CLAUDE.md with markers
    echo %MARKER_BEGIN%> "%MC_TARGET%"
    type "%MC_TEMPLATE%" >> "%MC_TARGET%"
    echo %MARKER_END%>> "%MC_TARGET%"
    echo [OK] Created CLAUDE.md with sandbox instructions
    exit /b 0
)

REM Check if markers already exist
findstr /c:"%MARKER_BEGIN%" "%MC_TARGET%" >nul 2>&1
if errorlevel 1 (
    REM No markers - append with markers
    echo.>> "%MC_TARGET%"
    echo %MARKER_BEGIN%>> "%MC_TARGET%"
    type "%MC_TEMPLATE%" >> "%MC_TARGET%"
    echo %MARKER_END%>> "%MC_TARGET%"
    echo [OK] Appended sandbox instructions to CLAUDE.md
) else (
    REM Markers exist - use PowerShell to replace content
    powershell -Command ^
        "$content = Get-Content '%MC_TARGET%' -Raw; " ^
        "$template = Get-Content '%MC_TEMPLATE%' -Raw; " ^
        "$begin = '%MARKER_BEGIN%'; " ^
        "$end = '%MARKER_END%'; " ^
        "$newSection = $begin + \"`r`n\" + $template + \"`r`n\" + $end; " ^
        "$pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end); " ^
        "$newContent = $content -replace $pattern, $newSection; " ^
        "Set-Content '%MC_TARGET%' -Value $newContent -NoNewline"
    echo [OK] Updated sandbox section in CLAUDE.md
)
exit /b 0

REM ============================================================================
REM Check setup function
REM ============================================================================
:check_setup
set "CS_DIR=%~1"
set "CS_STATUS=0"

echo Checking sandbox setup in: %CS_DIR%
echo.

REM Check for required files
for %%F in (docker-compose.yml start-sandbox.bat .env) do (
    if exist "%CS_DIR%\%%F" (
        echo [OK] %%F exists
    ) else (
        echo [ERROR] %%F missing
        set "CS_STATUS=1"
    )
)

REM Check .gitignore
set "CS_GI=%CS_DIR%\.gitignore"
if exist "%CS_GI%" (
    set "GI_OK=1"
    for %%F in (docker-compose.yml start-sandbox.bat .env) do (
        findstr /x /c:"%%F" "%CS_GI%" >nul 2>&1
        if errorlevel 1 set "GI_OK=0"
    )
    if "!GI_OK!"=="1" (
        echo [OK] .gitignore contains sandbox files
    ) else (
        echo [WARN] .gitignore missing some sandbox files
    )
) else (
    echo [WARN] .gitignore not found
)

REM Check CLAUDE.md for sandbox section
set "CS_CLAUDE=%CS_DIR%\CLAUDE.md"
if exist "%CS_CLAUDE%" (
    findstr /c:"%MARKER_BEGIN%" "%CS_CLAUDE%" >nul 2>&1
    if errorlevel 1 (
        echo [WARN] CLAUDE.md exists but missing sandbox section
    ) else (
        echo [OK] CLAUDE.md contains sandbox instructions
    )
) else (
    echo [WARN] CLAUDE.md not found
)

echo.
if "%CS_STATUS%"=="0" (
    echo [OK] Setup is complete!
) else (
    echo [ERROR] Setup incomplete. Run setup-sandbox.bat to fix.
)
exit /b %CS_STATUS%

REM ============================================================================
REM Uninstall function
REM ============================================================================
:uninstall
set "UI_DIR=%~1"

echo Removing sandbox files from: %UI_DIR%
echo.

REM Remove sandbox files
for %%F in (docker-compose.yml start-sandbox.bat) do (
    if exist "%UI_DIR%\%%F" (
        del "%UI_DIR%\%%F"
        echo [OK] Removed %%F
    )
)

REM Remove sandbox section from CLAUDE.md using PowerShell
set "UI_CLAUDE=%UI_DIR%\CLAUDE.md"
if exist "%UI_CLAUDE%" (
    findstr /c:"%MARKER_BEGIN%" "%UI_CLAUDE%" >nul 2>&1
    if not errorlevel 1 (
        powershell -Command ^
            "$content = Get-Content '%UI_CLAUDE%' -Raw; " ^
            "$begin = '%MARKER_BEGIN%'; " ^
            "$end = '%MARKER_END%'; " ^
            "$pattern = '(?s)\r?\n?' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end) + '\r?\n?'; " ^
            "$newContent = ($content -replace $pattern, '').Trim(); " ^
            "if ($newContent) { Set-Content '%UI_CLAUDE%' -Value $newContent } else { Remove-Item '%UI_CLAUDE%' }"
        if exist "%UI_CLAUDE%" (
            echo [OK] Removed sandbox section from CLAUDE.md
        ) else (
            echo [OK] Removed CLAUDE.md (was empty after removing sandbox section)
        )
    )
)

echo.
echo [WARN] Note: .env and .gitignore were not modified (may contain user data)
echo.
echo [OK] Sandbox files removed. You may manually delete .env if no longer needed.
exit /b 0
