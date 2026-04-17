@echo off
echo Starting EXPERIMMO API Server...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "api\main.py" (
    echo Please run this script from the flutter_app directory
    pause
    exit /b 1
)

REM Change to API directory
cd api

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Start the API server
echo.
echo Starting API server on http://localhost:8000
echo Press Ctrl+C to stop the server
echo.
python main.py

pause
