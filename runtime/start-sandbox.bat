@echo off
REM start-sandbox.bat - Start the Claude Code sandbox container (Lite)
REM
REM Usage:
REM   start-sandbox.bat                      # Run claude --dangerously-skip-permissions (default)
REM   start-sandbox.bat -p or --permissions  # Run claude (with normal permissions)
REM   start-sandbox.bat -s or --shell        # Run zsh shell
REM   start-sandbox.bat -v or --version VER  # Install specific Claude Code version
REM
REM This script:
REM   1. Starts the container with docker compose up -d
REM   2. Waits for the container to be ready
REM   3. Runs the specified command as the node user
REM   4. When you exit, stops the container with docker compose down

setlocal enabledelayedexpansion

REM Change to script directory
cd /d "%~dp0"
set "SCRIPT_DIR=%~dp0"

REM Ensure sandbox files are in .gitignore
set "GITIGNORE_FILE=%SCRIPT_DIR%.gitignore"

REM Create .gitignore if it doesn't exist
if not exist "%GITIGNORE_FILE%" type nul > "%GITIGNORE_FILE%"

REM Add sandbox files to .gitignore if not already present
for %%F in (docker-compose.yml start-sandbox.sh start-sandbox.bat CLAUDE.md .env) do (
    findstr /x /c:"%%F" "%GITIGNORE_FILE%" >nul 2>&1
    if errorlevel 1 (
        echo %%F>> "%GITIGNORE_FILE%"
    )
)

REM Generate a unique project name based on user and directory
for %%I in ("%SCRIPT_DIR:~0,-1%") do set "PROJECT_NAME=%%~nxI"
REM Use PowerShell for lowercase conversion (more reliable)
for /f "delims=" %%L in ('powershell -Command "('%PROJECT_NAME%' -replace '[^a-zA-Z0-9]','').ToLower()"') do set "PROJECT_NAME_CLEAN=%%L"
set "COMPOSE_PROJECT_NAME=sandbox-%USERNAME%-%PROJECT_NAME_CLEAN%"

REM Load from .env file if it exists
if exist "%SCRIPT_DIR%.env" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%SCRIPT_DIR%.env") do (
        REM Skip comments and empty lines
        set "LINE=%%A"
        if defined LINE (
            if not "!LINE:~0,1!"=="#" (
                set "%%A=%%B"
            )
        )
    )
)

REM Check API configuration
if not defined ANTHROPIC_API_KEY (
    if not defined CLAUDE_CODE_USE_BEDROCK (
        echo WARNING: No API configuration detected.
        echo.
        echo Configure one of the following in .env file:
        echo.
        echo   Option 1 - Direct Anthropic API:
        echo     ANTHROPIC_API_KEY=sk-ant-api03-...
        echo.
        echo   Option 2 - AWS Bedrock Profile-based:
        echo     CLAUDE_CODE_USE_BEDROCK=1
        echo     AWS_PROFILE=your-profile
        echo     AWS_REGION=us-east-1
        echo.
        echo   Option 3 - AWS Bedrock Bearer Token:
        echo     CLAUDE_CODE_USE_BEDROCK=1
        echo     AWS_BEARER_TOKEN_BEDROCK=your-api-key
        echo     AWS_REGION=us-east-1
        echo.
    )
)

REM Set git committer defaults if not set
if not defined GIT_COMMITTER_NAME if defined GIT_AUTHOR_NAME set "GIT_COMMITTER_NAME=%GIT_AUTHOR_NAME%"
if not defined GIT_COMMITTER_EMAIL if defined GIT_AUTHOR_EMAIL set "GIT_COMMITTER_EMAIL=%GIT_AUTHOR_EMAIL%"

REM Set default UID/GID for Windows
if not defined HOST_UID set "HOST_UID=1000"
if not defined HOST_GID set "HOST_GID=1000"

REM Default values
set "MODE=default"
set "CLAUDE_VERSION=latest"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto done_parsing

if "%~1"=="-p" (
    set "MODE=permissions"
    shift
    goto parse_args
)
if "%~1"=="--permissions" (
    set "MODE=permissions"
    shift
    goto parse_args
)
if "%~1"=="-s" (
    set "MODE=shell"
    shift
    goto parse_args
)
if "%~1"=="--shell" (
    set "MODE=shell"
    shift
    goto parse_args
)
if "%~1"=="-v" (
    set "CLAUDE_VERSION=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--version" (
    set "CLAUDE_VERSION=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

echo Unknown option: %~1
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   (none)            Run claude --dangerously-skip-permissions (default)
echo   -p, --permissions Run claude with normal permissions
echo   -s, --shell       Run zsh shell
echo   -v, --version VER Install specific Claude Code version (default: latest)
echo   -h, --help        Show this help message
exit /b 0

:done_parsing

REM Set command based on mode
if "%MODE%"=="default" (
    set "CMD=claude --dangerously-skip-permissions"
    set "DESC=Claude Code (skip permissions)"
)
if "%MODE%"=="permissions" (
    set "CMD=claude"
    set "DESC=Claude Code (with permissions)"
)
if "%MODE%"=="shell" (
    set "CMD=zsh"
    set "DESC=zsh shell"
)

echo Starting Claude Code sandbox (lite)...
docker compose up -d

REM Wait for container to be ready
echo Waiting for container to initialize...
timeout /t 2 /nobreak >nul

REM Check if container is running
docker compose ps --format json | findstr /c:"running" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Container failed to start. Check logs with: docker compose logs
    exit /b 1
)

REM Install Claude Code CLI
echo Installing Claude Code CLI version: %CLAUDE_VERSION%...
docker compose exec claude-code npm install -g @anthropic-ai/claude-code@%CLAUDE_VERSION%
echo Installation complete.

echo Container ready. Starting %DESC% as node user...
echo Type 'exit' to leave and stop the container.
echo ----------------------------------------

REM Enter the container as node user
docker compose exec -u node claude-code %CMD%

echo ----------------------------------------
echo Stopping container...
docker compose down -t 2

echo Done.
endlocal
