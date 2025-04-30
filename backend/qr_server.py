import win32pipe, win32file, win32api
import cv2
import numpy as np
import pyzbar.pyzbar as pyzbar
import json
import base64
import threading
import os
import time
import sys

PIPE_NAME = r'\\.\pipe\attendance_qr_scanner'
DEBUG_MODE = True

# Performance tracking
processing_times = []
total_frames = 0
successful_detections = 0

def log(message):
    if DEBUG_MODE:
        print(f"[QRServer] {message}")
        sys.stdout.flush()

def process_qr_image(image_data):
    global total_frames, successful_detections, processing_times
    
    start_time = time.time()
    total_frames += 1
    
    try:
        # Decode image from base64
        image_bytes = base64.b64decode(image_data)
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            return json.dumps({'error': 'Invalid image data'})
        
        # Multiple detection approaches for better results
        results = []
        
        # 1. Try direct detection on original image
        qr_codes = pyzbar.decode(image)
        if qr_codes:
            results.extend(qr_codes)
        
        # 2. If no results, try with grayscale
        if not results:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            qr_codes = pyzbar.decode(gray)
            results.extend(qr_codes)
        
        # 3. If still no results, try with adaptive threshold
        if not results:
            thresh = cv2.adaptiveThreshold(
                gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                cv2.THRESH_BINARY, 11, 2
            )
            qr_codes = pyzbar.decode(thresh)
            results.extend(qr_codes)
        
        # Process results
        parsed_results = []
        for qr in results:
            data = qr.data.decode('utf-8')
            
            # Try to validate if it's an employee QR
            is_valid = False
            try:
                # Check if it's valid JSON with required fields
                qr_json = json.loads(data)
                is_valid = all(key in qr_json for key in ['id', 'name', 'department'])
            except:
                # Not valid JSON
                is_valid = False
            
            parsed_results.append({
                'data': data,
                'type': str(qr.type),
                'valid': is_valid,
                'points': [[p.x, p.y] for p in qr.polygon]
            })
            
            # Draw for debug image
            points = np.array([[[p.x, p.y]] for p in qr.polygon], dtype=np.int32)
            cv2.polylines(image, [points], True, (0, 255, 0), 3)
            
            # Add text with QR data
            cv2.putText(
                image, f"ID: {qr_json.get('id', 'Unknown')}", 
                (qr.polygon[0].x, qr.polygon[0].y - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2
            )
        
        if parsed_results:
            successful_detections += 1
        
        # Create debug image
        _, buffer = cv2.imencode('.jpg', image)
        debug_image = base64.b64encode(buffer).decode('utf-8')
        
        # Calculate processing time
        processing_time = time.time() - start_time
        processing_times.append(processing_time)
        
        # Keep only the last 100 measurements
        if len(processing_times) > 100:
            processing_times.pop(0)
        
        avg_time = sum(processing_times) / max(1, len(processing_times))
        
        return json.dumps({
            'results': parsed_results,
            'debug_image': debug_image,
            'processing_time_ms': processing_time * 1000,
            'average_time_ms': avg_time * 1000,
            'total_frames': total_frames,
            'successful_detections': successful_detections
        })
    
    except Exception as e:
        log(f"Error processing image: {str(e)}")
        return json.dumps({'error': str(e)})

def server_thread():
    log("QR Server starting...")
    
    while True:
        try:
            pipe = win32pipe.CreateNamedPipe(
                PIPE_NAME,
                win32pipe.PIPE_ACCESS_DUPLEX,
                win32pipe.PIPE_TYPE_MESSAGE | win32pipe.PIPE_READMODE_MESSAGE | win32pipe.PIPE_WAIT,
                1, 65536, 65536, 0, None)
            
            log("Waiting for client connection...")
            win32pipe.ConnectNamedPipe(pipe, None)
            log("Client connected")
            
            while True:
                try:
                    # Read request
                    resp = win32file.ReadFile(pipe, 65536)
                    if resp[0] != 0:
                        log("Client disconnected")
                        break
                    
                    data = resp[1].decode('utf-8')
                    request = json.loads(data)
                    
                    # Process QR code
                    result = process_qr_image(request['image'])
                    
                    # Send response
                    win32file.WriteFile(pipe, result.encode('utf-8'))
                except Exception as e:
                    log(f"Error in pipe communication: {str(e)}")
                    break
        except Exception as e:
            log(f"Error creating pipe: {str(e)}")
            time.sleep(1)  # Wait before retrying
        finally:
            try:
                win32file.CloseHandle(pipe)
            except:
                pass

if __name__ == "__main__":
    log(f"QR Server v1.0 starting on pipe: {PIPE_NAME}")
    
    # Start server thread
    server = threading.Thread(target=server_thread)
    server.daemon = True
    server.start()
    
    # Keep main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("Server shutting down...") 