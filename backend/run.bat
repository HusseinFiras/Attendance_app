@echo off
echo Setting up QR Server environment...

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo Creating virtual environment...
    py -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing dependencies...
pip install numpy opencv-python pyzbar pywin32

REM Run the server
echo Starting QR Server...
python qr_server.py 