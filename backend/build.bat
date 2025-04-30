@echo off
echo Building QR Server executable...
pip install -r requirements.txt
pip install pyinstaller
pyinstaller --onefile --hidden-import=pyzbar.pyzbar --hidden-import=win32pipe --hidden-import=win32file qr_server.py
echo Build complete. Executable is in dist/qr_server.exe 