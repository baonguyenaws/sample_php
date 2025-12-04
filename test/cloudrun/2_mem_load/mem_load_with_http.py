#!/usr/bin/env python3
"""
Memory Load Generator with HTTP server for Cloud Run compatibility
Supports: 75%, 85%, 99% memory targets via MEMORY_TARGET env variable
"""
import psutil
import time
import os
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import socket

# Import the existing memory load logic
from memory_load import MemoryLoadGenerator

class HealthCheckHandler(BaseHTTPRequestHandler):
    """Simple HTTP handler for Cloud Run health checks"""
    
    # Store generator instance as class variable
    generator = None
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/health' or self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            
            # Get current status
            target_percentage = int(os.getenv('MEMORY_TARGET', '75'))
            
            if HealthCheckHandler.generator:
                mem_info = HealthCheckHandler.generator.get_memory_info()
                total = HealthCheckHandler.generator.format_bytes(mem_info['total'])
                used = HealthCheckHandler.generator.format_bytes(mem_info['used'])
                message = (f"Memory Load Generator Running\n"
                          f"Total Memory: {total}\n"
                          f"Used Memory: {used}\n"
                          f"Current Usage: {mem_info['percent']:.2f}%\n"
                          f"Target: {target_percentage}% utilization\n")
            else:
                mem = psutil.virtual_memory()
                message = (f"Memory Load Generator Running\n"
                          f"Total Memory: {mem.total / (1024**3):.2f} GB\n"
                          f"Target: {target_percentage}% utilization\n")
            
            self.wfile.write(message.encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def start_http_server(port=8080):
    """Start HTTP server for Cloud Run"""
    try:
        server = HTTPServer(('0.0.0.0', port), HealthCheckHandler)
        print(f"[{datetime.now()}] ✅ HTTP server bound to port {port}")
        print(f"[{datetime.now()}] ✅ Ready to accept health checks")
        server.serve_forever()
    except Exception as e:
        print(f"[{datetime.now()}] ❌ Failed to start HTTP server: {e}")
        raise

def wait_for_port(port, timeout=10):
    """Wait for port to be available"""
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(1)
                result = s.connect_ex(('127.0.0.1', port))
                if result == 0:
                    return True
        except:
            pass
        time.sleep(0.1)
    return False

def main():
    """Main function"""
    # Get target memory percentage from environment variable (default: 75%)
    target_percentage = int(os.getenv('MEMORY_TARGET', '75'))
    
    # Validate target percentage
    if target_percentage not in [75, 85, 99]:
        print(f"[{datetime.now()}] Warning: MEMORY_TARGET={target_percentage} not in [75, 85, 99]. Using default 75%")
        target_percentage = 75
    
    print(f"[{datetime.now()}] ===== Memory Load Generator Started (Cloud Run Mode) =====")
    print(f"[{datetime.now()}] Target: {target_percentage}% Memory utilization")
    
    # Get PORT from environment (Cloud Run sets this)
    port = int(os.environ.get('PORT', 8080))
    print(f"[{datetime.now()}] Port: {port}")
    
    # Start HTTP server in background thread (MUST be ready immediately)
    http_thread = threading.Thread(target=start_http_server, args=(port,), daemon=True)
    http_thread.start()
    
    # Wait for HTTP server to actually be listening
    print(f"[{datetime.now()}] Waiting for HTTP server to bind...")
    if wait_for_port(port, timeout=10):
        print(f"[{datetime.now()}] ✅ HTTP server is ready and listening on port {port}")
    else:
        print(f"[{datetime.now()}] ❌ HTTP server failed to start in time!")
        return
    
    # Additional delay before memory load (configurable)
    startup_delay = int(os.getenv('STARTUP_DELAY', '10'))
    if startup_delay > 0:
        print(f"[{datetime.now()}] Delaying {startup_delay}s before starting memory allocation...")
        print(f"[{datetime.now()}] (This ensures Cloud Run health check passes first)")
        time.sleep(startup_delay)
    
    # Create memory load generator
    print(f"[{datetime.now()}] ===== Starting Memory Allocation =====")
    generator = MemoryLoadGenerator(target_percentage=target_percentage)
    
    # Store generator instance for health check handler
    HealthCheckHandler.generator = generator
    
    print(f"[{datetime.now()}] Starting memory allocation to reach {target_percentage}% usage...")
    
    # Run the generator
    generator.run()

if __name__ == "__main__":
    main()
