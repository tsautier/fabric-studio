from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import time

class SlowHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(10)  # simulate delay
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'Hello from toolbox!\n')

# Replace HTTPServer with ThreadingHTTPServer
httpd = ThreadingHTTPServer(('0.0.0.0', 8080), SlowHandler)
print("Serving threaded on port 8080...")
httpd.serve_forever()
