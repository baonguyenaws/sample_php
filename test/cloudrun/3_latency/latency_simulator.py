#!/usr/bin/env python3
"""
Latency Simulator with HTTP server for Cloud Run compatibility
Supports custom latency via LATENCY_MS env variable (in milliseconds)
"""
import time
import os
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import socket
import random

class LatencyHandler(BaseHTTPRequestHandler):
    """HTTP handler that simulates network latency"""
    
    def log_message(self, format, *args):
        """Custom logging with timestamp"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {format % args}")
    
    def do_GET(self):
        """Handle GET requests with configurable latency"""
        start_time = time.time()
        
        # Get latency from environment variable (in milliseconds)
        latency_ms = int(os.getenv('LATENCY_MS', '100'))
        latency_seconds = latency_ms / 1000.0
        
        # Add some variance to make it more realistic (±10%)
        variance = random.uniform(-0.1, 0.1)
        actual_latency = latency_seconds * (1 + variance)
        
        # Simulate latency
        time.sleep(actual_latency)
        
        if self.path == '/health' or self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            
            # Calculate actual response time
            response_time_ms = (time.time() - start_time) * 1000
            
            # Get configuration
            target_latency = os.getenv('LATENCY_MS', '100')
            port = os.getenv('PORT', '8080')
            hostname = socket.gethostname()
            
            html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <title>Latency Simulator - {target_latency}ms</title>
                <meta charset="utf-8">
                <meta http-equiv="refresh" content="5">
                <style>
                    body {{
                        font-family: 'Segoe UI', Arial, sans-serif;
                        max-width: 900px;
                        margin: 50px auto;
                        padding: 20px;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                    }}
                    .container {{
                        background: rgba(255, 255, 255, 0.1);
                        backdrop-filter: blur(10px);
                        border-radius: 20px;
                        padding: 40px;
                        box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
                    }}
                    h1 {{
                        font-size: 2.5em;
                        margin-bottom: 10px;
                        text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
                    }}
                    .status {{
                        background: rgba(76, 175, 80, 0.3);
                        padding: 15px;
                        border-radius: 10px;
                        margin: 20px 0;
                        border: 2px solid #4CAF50;
                    }}
                    .metric {{
                        background: rgba(255, 255, 255, 0.2);
                        padding: 20px;
                        margin: 15px 0;
                        border-radius: 10px;
                        border-left: 5px solid #FFC107;
                    }}
                    .metric-label {{
                        font-size: 0.9em;
                        opacity: 0.8;
                        margin-bottom: 5px;
                    }}
                    .metric-value {{
                        font-size: 2em;
                        font-weight: bold;
                        color: #FFC107;
                    }}
                    .info {{
                        font-size: 0.9em;
                        opacity: 0.8;
                        margin-top: 30px;
                        text-align: center;
                    }}
                    .timestamp {{
                        text-align: center;
                        font-size: 0.9em;
                        opacity: 0.7;
                        margin-top: 20px;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🚀 Latency Simulator</h1>
                    
                    <div class="status">
                        <h2>✅ Service is running</h2>
                        <p>Hostname: {hostname}</p>
                        <p>Port: {port}</p>
                    </div>
                    
                    <div class="metric">
                        <div class="metric-label">Target Latency</div>
                        <div class="metric-value">{target_latency} ms</div>
                    </div>
                    
                    <div class="metric">
                        <div class="metric-label">Actual Response Time</div>
                        <div class="metric-value">{response_time_ms:.2f} ms</div>
                    </div>
                    
                    <div class="metric">
                        <div class="metric-label">Latency Variance</div>
                        <div class="metric-value">±10%</div>
                    </div>
                    
                    <div class="info">
                        <p>💡 This page auto-refreshes every 5 seconds</p>
                        <p>🔧 Configure latency via LATENCY_MS environment variable</p>
                    </div>
                    
                    <div class="timestamp">
                        {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
                    </div>
                </div>
            </body>
            </html>
            """
            
            self.wfile.write(html.encode('utf-8'))
            
        elif self.path == '/api/test':
            # Simple JSON endpoint for testing
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response_time_ms = (time.time() - start_time) * 1000
            
            response = f"""{{
    "status": "ok",
    "target_latency_ms": {latency_ms},
    "actual_response_time_ms": {response_time_ms:.2f},
    "timestamp": "{datetime.now().isoformat()}"
}}"""
            
            self.wfile.write(response.encode('utf-8'))
            
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests with latency"""
        self.do_GET()

def run_server():
    """Start HTTP server"""
    port = int(os.getenv('PORT', '8080'))
    latency_ms = os.getenv('LATENCY_MS', '100')
    
    server_address = ('', port)
    httpd = HTTPServer(server_address, LatencyHandler)
    
    print("=" * 60)
    print(f"🚀 Latency Simulator Started")
    print(f"📊 Target Latency: {latency_ms}ms")
    print(f"🌐 Server running on http://0.0.0.0:{port}")
    print(f"🏥 Health check: http://0.0.0.0:{port}/health")
    print(f"📡 API endpoint: http://0.0.0.0:{port}/api/test")
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
