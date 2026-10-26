@echo off
title Werenga progress
cd /d "%~dp0"
python tool\progress.py
echo.
echo Press any key to close.
pause >nul
