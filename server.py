#!/usr/bin/env python3
"""
Servidor HTTP simple para servir el proyecto Capgemini
Puerto: 3996
"""

import http.server
import socketserver
import os
from pathlib import Path

PORT = 3996
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Agregar headers para evitar caché agresivo durante desarrollo
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
    
    def log_message(self, format, *args):
        # Personalizar formato de logs
        print(f"[{self.log_date_time_string()}] {format % args}")

def run_server():
    """Ejecutar servidor HTTP"""
    handler = MyHTTPRequestHandler
    
    with socketserver.TCPServer(("", PORT), handler) as httpd:
        print(f"=" * 60)
        print(f"🚀 Servidor iniciado")
        print(f"=" * 60)
        print(f"Puerto: {PORT}")
        print(f"URL: http://localhost:{PORT}")
        print(f"Directorio: {DIRECTORY}")
        print(f"=" * 60)
        print(f"Presiona Ctrl+C para detener el servidor")
        print(f"=" * 60)
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print(f"\n\n✅ Servidor detenido correctamente")
            httpd.server_close()

if __name__ == "__main__":
    run_server()
