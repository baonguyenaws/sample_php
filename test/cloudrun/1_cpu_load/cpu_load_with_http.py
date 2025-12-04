#!/usr/bin/env python3
"""
CPU Load Generator with HTTP server for Cloud Run compatibility
Supports: 75%, 85%, 99% CPU targets via CPU_TARGET env variable
"""
import multiprocessing
import time
import os
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import socket

# Import the existing CPU load logic
from cpu_load import get_container_cpu_quota, cpu_load_worker

# Global flag to track if CPU load should start
cpu_load_ready = threading.Event()

class HealthCheckHandler(BaseHTTPRequestHandler):
    """Simple HTTP handler for Cloud Run health checks"""
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/health' or self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            
            # Get current status
            target_percentage = int(os.getenv('CPU_TARGET', '85'))
            container_cpu = get_container_cpu_quota()
            if container_cpu:
                message = f"CPU Load Generator Running\nCPU Quota: {container_cpu:.2f} cores\nTarget: {target_percentage}% utilization\n"
            else:
                cpu_count = multiprocessing.cpu_count()
                message = f"CPU Load Generator Running\nCPU Cores: {cpu_count}\nTarget: {target_percentage}% utilization\n"
            
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
    # Get target CPU percentage from environment variable (default: 85%)
    target_percentage = int(os.getenv('CPU_TARGET', '85'))
    
    # Validate target percentage
    if target_percentage not in [75, 85, 99]:
        print(f"[{datetime.now()}] Warning: CPU_TARGET={target_percentage} not in [75, 85, 99]. Using default 85%")
        target_percentage = 85
    
    print(f"[{datetime.now()}] ===== CPU Load Generator Started (Cloud Run Mode) =====")
    print(f"[{datetime.now()}] Target: {target_percentage}% CPU utilization")
    
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
    
    # Additional delay before CPU load (configurable)
    startup_delay = int(os.getenv('STARTUP_DELAY', '10'))
    if startup_delay > 0:
        print(f"[{datetime.now()}] Delaying {startup_delay}s before starting CPU load...")
        print(f"[{datetime.now()}] (This ensures Cloud Run health check passes first)")
        time.sleep(startup_delay)
    
    # Get CPU count (considering container limits)
    container_cpu_quota = get_container_cpu_quota()
    if container_cpu_quota:
        cpu_count = container_cpu_quota
        print(f"[{datetime.now()}] Running in: CONTAINER (with CPU limit)")
        print(f"[{datetime.now()}] Container CPU quota: {cpu_count:.2f} cores")
    else:
        cpu_count = multiprocessing.cpu_count()
        print(f"[{datetime.now()}] Running in: HOST (no container limit)")
        print(f"[{datetime.now()}] Detected {cpu_count} CPU cores")
    
    # Calculate target load
    target_processes_float = cpu_count * target_percentage / 100
    target_processes = max(1, int(cpu_count))
    
    if target_processes > 0:
        load_per_process = target_processes_float / target_processes
    else:
        load_per_process = target_percentage / 100
    
    print(f"[{datetime.now()}] Target CPU usage: {target_percentage}%")
    print(f"[{datetime.now()}] CPU count: {cpu_count:.2f}")
    print(f"[{datetime.now()}] Target load: {target_processes_float:.2f} cores")
    print(f"[{datetime.now()}] Spawning {target_processes} process(es)")
    print(f"[{datetime.now()}] Load per process: {load_per_process*100:.1f}%")
    
    print(f"[{datetime.now()}] ===== Starting CPU Load Workers =====")
    
    # Create and start worker processes
    processes = []
    for i in range(target_processes):
        p = multiprocessing.Process(target=cpu_load_worker, args=(load_per_process,))
        p.start()
        processes.append(p)
        print(f"[{datetime.now()}] Started process {i+1}/{target_processes} (PID: {p.pid})")
    
    print(f"[{datetime.now()}] ===== All processes started successfully =====")
    print(f"[{datetime.now()}] HTTP server listening on port {port}")
    print(f"[{datetime.now()}] Press Ctrl+C to stop")
    
    try:
        # Keep main process alive
        for p in processes:
            p.join()
    except KeyboardInterrupt:
        print(f"\n[{datetime.now()}] Stopping all processes...")
        for p in processes:
            p.terminate()
            p.join()
        print(f"[{datetime.now()}] All processes stopped")

if __name__ == "__main__":
    main()
