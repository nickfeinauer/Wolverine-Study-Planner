"""Serve a built Jac mobile browser preview using the running web backend."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port', type=int, default=8010)
parser.add_argument('--backend', default='http://127.0.0.1:8001')
args = parser.parse_args()
assets = Path(__file__).resolve().parents[1] / '.jac/client/mobile/dist'
if not (assets / 'index.html').exists():
    parser.error('Build mobile first: jac build mobile --platform web')

class Preview(SimpleHTTPRequestHandler):
    def do_POST(self):
        self.proxy()

    def do_GET(self):
        if self.path.startswith(('/api/', '/function/', '/walker/', '/user/', '/static/', '/introspect')):
            self.proxy()
        else:
            super().do_GET()

    def proxy(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', '0'))) if self.command == 'POST' else None
        headers = {k: v for k, v in self.headers.items() if k.lower() in ('content-type', 'authorization', 'cookie', 'x-jac-client-contract')}
        request = Request(args.backend.rstrip('/') + self.path, data=body, headers=headers, method=self.command)
        try:
            response = urlopen(request, timeout=30)
        except HTTPError as error:
            response = error
        except OSError:
            self.send_error(502, 'Planner backend unavailable. Start jac run first.')
            return
        with response:
            data = response.read()
            self.send_response(response.code)
            for k, v in response.headers.items():
                if k.lower() in ('content-type', 'set-cookie'):
                    self.send_header(k, v)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)

print(f'Mobile preview: http://localhost:{args.port} (shared backend: {args.backend})', flush=True)
ThreadingHTTPServer(('127.0.0.1', args.port), partial(Preview, directory=str(assets))).serve_forever()
