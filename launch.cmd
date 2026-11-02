@echo off
cd /d "%~dp0"
start "" cmd /c "npm start >nul 2>&1"
