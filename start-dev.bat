@echo off
setlocal
title RithmXO Dev Environment
echo Starting RithmXO development environment...
echo.

:: Find Git Bash
set "BASH_EXE="
for /f "delims=" %%i in ('where git 2^>nul') do (
    set "GIT_CMD=%%i"
)
if defined GIT_CMD (
    for %%G in ("%GIT_CMD%") do set "GIT_DIR=%%~dpG"
)
if defined GIT_DIR (
    set "BASH_EXE=%GIT_DIR%..\bin\bash.exe"
)

:: Also check common install locations as fallback
if not exist "%BASH_EXE%" set "BASH_EXE=C:\Program Files\Git\bin\bash.exe"
if not exist "%BASH_EXE%" set "BASH_EXE=C:\Program Files (x86)\Git\bin\bash.exe"

if exist "%BASH_EXE%" (
    echo Using Git Bash: %BASH_EXE%
    "%BASH_EXE%" -l -c "cd '%~dp0' && bash start-dev.sh"
) else (
    echo ERROR: Git Bash not found. Please install Git for Windows.
    echo        https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo  Process exited with code %ERRORLEVEL%
echo ==========================================
echo.
pause
