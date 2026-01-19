@echo off
REM build.bat - Build the Claude Code Sandbox Lite image (Windows)
REM
REM Usage:
REM   build.bat                        # Build with default settings
REM   build.bat --no-cache             # Build without cache
REM   build.bat --version 1.0.75       # Build with specific Claude Code version
REM   build.bat --tag mytag            # Build with specific image tag

setlocal enabledelayedexpansion

REM Change to script directory
cd /d "%~dp0"

REM Default values
set "IMAGE_NAME=ccsandbox-node-py"
set "IMAGE_TAG=latest"
set "CLAUDE_VERSION=latest"
set "BUILD_ARGS="
set "PROXY_ARGS="

REM Parse arguments
:parse_args
if "%~1"=="" goto done_parsing

if "%~1"=="--no-cache" (
    set "BUILD_ARGS=!BUILD_ARGS! --no-cache"
    shift
    goto parse_args
)

if "%~1"=="--version" (
    set "CLAUDE_VERSION=%~2"
    shift
    shift
    goto parse_args
)

if "%~1"=="--tag" (
    set "IMAGE_TAG=%~2"
    shift
    shift
    goto parse_args
)

if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

echo Unknown option: %~1
exit /b 1

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --no-cache        Build without Docker cache
echo   --version VER     Claude Code version (default: latest)
echo   --tag TAG         Image tag (default: latest)
echo   -h, --help        Show this help
exit /b 0

:done_parsing

REM Detect proxy from environment
if defined HTTP_PROXY (
    set "PROXY_ARGS=--build-arg HTTP_PROXY=!HTTP_PROXY! --build-arg HTTPS_PROXY=!HTTP_PROXY!"
    echo Detected proxy: !HTTP_PROXY!
) else if defined http_proxy (
    set "PROXY_ARGS=--build-arg HTTP_PROXY=!http_proxy! --build-arg HTTPS_PROXY=!http_proxy!"
    echo Detected proxy: !http_proxy!
)

echo Building Claude Code Sandbox (Lite)...
echo   Image: %IMAGE_NAME%:%IMAGE_TAG%
echo   Claude Code version: %CLAUDE_VERSION%
echo.

REM Build the Docker image
docker build ^
    %BUILD_ARGS% ^
    %PROXY_ARGS% ^
    --build-arg CLAUDE_CODE_VERSION=%CLAUDE_VERSION% ^
    -t %IMAGE_NAME%:%IMAGE_TAG% ^
    .

if errorlevel 1 (
    echo.
    echo Build failed!
    exit /b 1
)

echo.
echo Build complete!
echo.
echo Image size:
docker images %IMAGE_NAME%:%IMAGE_TAG% --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

endlocal
