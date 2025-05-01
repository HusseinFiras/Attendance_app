import win32pipe, win32file

PIPE_NAME = r'\\.\pipe\attendance_qr_scanner'

try:
    # Try to open the pipe
    pipe = win32file.CreateFile(
        PIPE_NAME,
        win32file.GENERIC_READ | win32file.GENERIC_WRITE,
        0,
        None,
        win32file.OPEN_EXISTING,
        0,
        None
    )
    print("Successfully connected to pipe!")
    win32file.CloseHandle(pipe)
except Exception as e:
    print(f"Error connecting to pipe: {e}") 