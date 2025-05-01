@echo off
echo Building QR Server executable...

REM Install dependencies using pre-built wheels with --user flag
echo Installing dependencies...
py -m pip install --user --no-cache-dir --only-binary :all: numpy
py -m pip install --user --no-cache-dir --only-binary :all: opencv-python
py -m pip install --user --no-cache-dir --only-binary :all: pyzbar
py -m pip install --user --no-cache-dir --only-binary :all: pywin32
py -m pip install --user --no-cache-dir --only-binary :all: pyinstaller

REM Create temp directory for zbar files
mkdir temp 2>nul
cd temp

REM Download pre-built zbar DLL
echo Downloading zbar DLL...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NaturalHistoryMuseum/pyzbar/master/pyzbar/libzbar-64.dll' -OutFile 'libzbar-64.dll' }"

REM Build the executable
echo Building executable...
cd ..
py -m PyInstaller --onefile --hidden-import=pyzbar.pyzbar --hidden-import=win32pipe --hidden-import=win32file ^
    --add-binary "temp\libzbar-64.dll;." ^
    qr_server.py

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

REM Clean up
rmdir /s /q temp

echo Build complete. Executable is in dist/qr_server.exe 