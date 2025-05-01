# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['qr_server.py'],
    pathex=[],
    binaries=[('temp\\zbar\\bin\\libzbar-0.dll', '.')],
    datas=[],
    hiddenimports=['pyzbar.pyzbar', 'win32pipe', 'win32file'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='qr_server',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
