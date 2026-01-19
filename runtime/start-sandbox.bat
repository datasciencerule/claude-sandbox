@echo off
REM start-sandbox.bat - Start the Claude Code sandbox container (Lite)
REM
REM Usage:
REM   start-sandbox.bat                      # Run claude --dangerously-skip-permissions (default)
REM   start-sandbox.bat -p or --permissions  # Run claude (with normal permissions)
REM   start-sandbox.bat -s or --shell        # Run zsh shell
REM   start-sandbox.bat -c or --continue     # Continue most recent conversation
REM   start-sandbox.bat -r or --resume [ID]  # Resume by session ID or open picker
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
set "API_CONFIGURED="
if defined ANTHROPIC_API_KEY set "API_CONFIGURED=1"
if defined ANTHROPIC_AUTH_TOKEN set "API_CONFIGURED=1"
if defined CLAUDE_CODE_USE_BEDROCK set "API_CONFIGURED=1"

if not defined API_CONFIGURED (
    echo WARNING: No API configuration in .env file.
    echo   1^) ANTHROPIC_API_KEY=sk-ant-...      ^(Direct API^)
    echo   2^) ANTHROPIC_AUTH_TOKEN=...         ^(Gateway/Proxy^)
    echo   3^) CLAUDE_CODE_USE_BEDROCK=1        ^(AWS Bedrock^)
    echo.
)

REM When using Bedrock, clear ANTHROPIC_API_KEY to prevent conflicts
REM (host environment may have this set from another Claude session)
if defined CLAUDE_CODE_USE_BEDROCK (
    set "ANTHROPIC_API_KEY="
)

REM Export API configuration for Gateway/Proxy
if defined ANTHROPIC_AUTH_TOKEN set "ANTHROPIC_AUTH_TOKEN=%ANTHROPIC_AUTH_TOKEN%"
if defined ANTHROPIC_BASE_URL set "ANTHROPIC_BASE_URL=%ANTHROPIC_BASE_URL%"
if defined ANTHROPIC_MODEL set "ANTHROPIC_MODEL=%ANTHROPIC_MODEL%"

REM Export model defaults if set
if defined ANTHROPIC_DEFAULT_HAIKU_MODEL set "ANTHROPIC_DEFAULT_HAIKU_MODEL=%ANTHROPIC_DEFAULT_HAIKU_MODEL%"
if defined ANTHROPIC_DEFAULT_OPUS_MODEL set "ANTHROPIC_DEFAULT_OPUS_MODEL=%ANTHROPIC_DEFAULT_OPUS_MODEL%"
if defined ANTHROPIC_DEFAULT_SONNET_MODEL set "ANTHROPIC_DEFAULT_SONNET_MODEL=%ANTHROPIC_DEFAULT_SONNET_MODEL%"

REM Export runtime configuration if set
if defined CLAUDE_CODE_ENTRYPOINT set "CLAUDE_CODE_ENTRYPOINT=%CLAUDE_CODE_ENTRYPOINT%"
if defined CLAUDE_CODE_SSE_PORT set "CLAUDE_CODE_SSE_PORT=%CLAUDE_CODE_SSE_PORT%"
if defined CLAUDE_CODE_GIT_BASH_PATH set "CLAUDE_CODE_GIT_BASH_PATH=%CLAUDE_CODE_GIT_BASH_PATH%"

REM Set default UID/GID for Windows
if not defined HOST_UID set "HOST_UID=1000"
if not defined HOST_GID set "HOST_GID=1000"

REM Ensure HOME is set (Windows uses USERPROFILE, but docker-compose needs HOME)
if not defined HOME set "HOME=%USERPROFILE%"

REM Default values
set "MODE=default"
set "CLAUDE_VERSION=latest"
set "SESSION_OPT="
set "SESSION_ID="

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
if "%~1"=="-c" (
    set "SESSION_OPT=--continue"
    shift
    goto parse_args
)
if "%~1"=="--continue" (
    set "SESSION_OPT=--continue"
    shift
    goto parse_args
)
if "%~1"=="-r" (
    set "SESSION_OPT=--resume"
    REM Check if next arg is a session ID (not another flag)
    if not "%~2"=="" (
        set "NEXT_ARG=%~2"
        if not "!NEXT_ARG:~0,1!"=="-" (
            set "SESSION_ID=%~2"
            shift
        )
    )
    shift
    goto parse_args
)
if "%~1"=="--resume" (
    set "SESSION_OPT=--resume"
    REM Check if next arg is a session ID (not another flag)
    if not "%~2"=="" (
        set "NEXT_ARG=%~2"
        if not "!NEXT_ARG:~0,1!"=="-" (
            set "SESSION_ID=%~2"
            shift
        )
    )
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
echo   -c, --continue    Continue the most recent conversation
echo   -r, --resume [ID] Resume by session ID or open picker
echo   -v, --version VER Install specific Claude Code version (default: latest)
echo   -h, --help        Show this help message
exit /b 0

:done_parsing

REM Set command based on mode
if "%MODE%"=="default" (
    set "CMD=claude --dangerously-skip-permissions %SESSION_OPT% %SESSION_ID%"
    set "DESC=Claude Code (skip permissions)"
)
if "%MODE%"=="permissions" (
    set "CMD=claude %SESSION_OPT% %SESSION_ID%"
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
docker compose exec claude-code npm install -g --loglevel=error --no-fund --no-update-notifier @anthropic-ai/claude-code@%CLAUDE_VERSION%
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
