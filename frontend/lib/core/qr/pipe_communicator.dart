import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'dart:convert';

class PipeCommunicator {
  static const String pipeName = r'\\.\pipe\attendance_qr_scanner';
  static const int bufferSize = 65536;
  
  Future<String?> sendMessage(String message) async {
    // Convert pipe name to UTF-16
    final Pointer<Utf16> pipeNameUtf16 = pipeName.toNativeUtf16();
    
    // Open the pipe
    final hPipe = CreateFile(
      pipeNameUtf16,
      GENERIC_READ | GENERIC_WRITE,
      0,
      nullptr,
      OPEN_EXISTING,
      0,
      NULL
    );
    
    // Free the pipe name
    free(pipeNameUtf16);
    
    if (hPipe == INVALID_HANDLE_VALUE) {
      final error = GetLastError();
      throw Exception('Failed to open pipe: error code $error');
    }
    
    try {
      // Convert message to UTF-8 bytes
      final messageBytes = utf8.encode(message);
      final Pointer<Uint8> buffer = calloc<Uint8>(messageBytes.length);
      
      // Copy message to buffer
      for (var i = 0; i < messageBytes.length; i++) {
        buffer[i] = messageBytes[i];
      }
      
      // Write to pipe
      final Pointer<Uint32> bytesWritten = calloc<Uint32>();
      final writeResult = WriteFile(
        hPipe,
        buffer,
        messageBytes.length,
        bytesWritten,
        nullptr
      );
      
      // Free write buffer
      calloc.free(buffer);
      
      if (writeResult == 0) {
        final error = GetLastError();
        calloc.free(bytesWritten);
        throw Exception('Failed to write to pipe: error code $error');
      }
      
      // Read response
      final Pointer<Uint8> responseBuffer = calloc<Uint8>(bufferSize);
      final Pointer<Uint32> bytesRead = calloc<Uint32>();
      final readResult = ReadFile(
        hPipe,
        responseBuffer,
        bufferSize,
        bytesRead,
        nullptr
      );
      
      if (readResult == 0) {
        final error = GetLastError();
        calloc.free(responseBuffer);
        calloc.free(bytesRead);
        calloc.free(bytesWritten);
        throw Exception('Failed to read from pipe: error code $error');
      }
      
      // Convert response to string
      final responseLength = bytesRead.value;
      final List<int> responseBytes = List<int>.generate(
        responseLength,
        (i) => responseBuffer[i]
      );
      
      // Free response buffer
      calloc.free(responseBuffer);
      calloc.free(bytesRead);
      calloc.free(bytesWritten);
      
      return utf8.decode(responseBytes);
    } finally {
      // Close pipe handle
      CloseHandle(hPipe);
    }
  }
} 