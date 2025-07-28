from http.server import BaseHTTPRequestHandler, HTTPServer
import time

class SlowHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(10)  # simulate delay
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Hello from toolbox!\n')

httpd = HTTPServer(('0.0.0.0', 8080), SlowHandler)
print("Serving on port 8080...")
httpd.serve_forever()
