"""Google Play from CI (user request: uploads and store images done here).

  python tool/play.py tracks
  python tool/play.py upload <file.aab> <track>      # e.g. alpha (closed testing)
  python tool/play.py listing <docs/store dir>       # feature graphic + phone screenshots, ko-KR and en-US

Signs in with GOOGLE_APPLICATION_CREDENTIALS (the deploy service account,
invited in Play Console with release and store listing rights).
"""
import glob
import os
import sys

import google.auth
from google.auth.transport.requests import AuthorizedSession

PKG = 'io.github.graviton94.homefairy'
API = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}'
UP = f'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{PKG}'
LANGS = {'ko': 'ko-KR', 'en': 'en-US'}

creds, _ = google.auth.default(scopes=['https://www.googleapis.com/auth/androidpublisher'])
s = AuthorizedSession(creds)


def ok(r):
    if r.status_code >= 300:
        sys.exit(f'Play API {r.request.method} {r.url.split(PKG)[-1]} → HTTP {r.status_code}: {r.text[:400]}')
    return r.json() if r.content else {}


def edit():
    return ok(s.post(f'{API}/edits'))['id']


def commit(e):
    ok(s.post(f'{API}/edits/{e}:commit'))


def tracks():
    e = edit()
    for t in ok(s.get(f'{API}/edits/{e}/tracks')).get('tracks', []):
        print(t['track'], [(r.get('name'), r.get('versionCodes'), r.get('status')) for r in t.get('releases', [])])
    s.delete(f'{API}/edits/{e}')


def upload(aab, track):
    e = edit()
    with open(aab, 'rb') as f:
        b = ok(s.post(f'{UP}/edits/{e}/bundles?uploadType=media', data=f, headers={'Content-Type': 'application/octet-stream'}, timeout=600))
    code = b['versionCode']
    ok(s.put(f'{API}/edits/{e}/tracks/{track}', json={'track': track, 'releases': [{'versionCodes': [str(code)], 'status': 'completed'}]}))
    commit(e)
    print(f'uploaded versionCode {code} to {track}')


def listing(folder):
    e = edit()
    for short, lang in LANGS.items():
        feature = os.path.join(folder, f'{short}-feature.png')
        shots = sorted(glob.glob(os.path.join(folder, f'{short}-[0-9]-*.png')))
        ok(s.delete(f'{API}/edits/{e}/listings/{lang}/featureGraphic'))
        with open(feature, 'rb') as f:
            ok(s.post(f'{UP}/edits/{e}/listings/{lang}/featureGraphic?uploadType=media', data=f, headers={'Content-Type': 'image/png'}))
        ok(s.delete(f'{API}/edits/{e}/listings/{lang}/phoneScreenshots'))
        for p in shots:
            with open(p, 'rb') as f:
                ok(s.post(f'{UP}/edits/{e}/listings/{lang}/phoneScreenshots?uploadType=media', data=f, headers={'Content-Type': 'image/png'}))
        print(f'{lang}: feature graphic + {len(shots)} screenshots')
    commit(e)


if __name__ == '__main__':
    cmd = sys.argv[1]
    {'tracks': lambda: tracks(), 'upload': lambda: upload(sys.argv[2], sys.argv[3]), 'listing': lambda: listing(sys.argv[2])}[cmd]()
