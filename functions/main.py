"""Cloud Functions for Home Fairy.

decide: typed suggestions from the TypeSafe decision model for signed-in
users (anonymous guests included). The Jev key stays in Secret Manager.
login: trades a Kakao or Naver access token for a Firebase sign-in token.
"""
import asyncio
import datetime
import hashlib
import json
import secrets
import urllib.error
import urllib.parse
import urllib.request

from firebase_admin import auth, firestore, initialize_app, messaging
from firebase_functions import https_fn, options
from firebase_functions.params import SecretParam
from typesafe_sdk import AsyncTypeSafeClient

import decisions

initialize_app()
JEV_API_KEY = SecretParam('JEV_API_KEY')
FOOD_API_KEY = SecretParam('FOOD_API_KEY')
DAILY_LIMIT = 50  # model calls per user per day; cached answers don't count


def _count_call(uid: str) -> int:
    """Increments today's call count for uid and returns the new value."""
    db = firestore.client()
    day = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')
    ref = db.collection('usage').document(f'{uid}_{day}')

    @firestore.transactional
    def bump(tx):
        snap = ref.get(transaction=tx)
        n = (snap.get('decide') if snap.exists else 0) or 0
        tx.set(ref, {'uid': uid, 'day': day, 'decide': n + 1}, merge=True)
        return n + 1

    return bump(db.transaction())


def _name_key(name: str) -> str:
    """Cache key for an item name. Only this hash is stored, never the name."""
    norm = ' '.join(name.lower().split())
    return hashlib.sha256(f'classify-v1:{norm}'.encode()).hexdigest()


async def _ask(task: str, data: dict, key: str) -> dict:
    async with AsyncTypeSafeClient(api_key=key) as client:
        if task == 'classify':
            return await decisions.classify(client, str(data.get('name', '')))
        items = data.get('items') or []
        return await decisions.find(client, str(data.get('query', '')), [str(i) for i in items])


@https_fn.on_call(
    region='us-central1',
    secrets=[JEV_API_KEY],
    memory=options.MemoryOption.MB_256,
    timeout_sec=20,
    max_instances=10,
    # App Check is enforced once the app sends tokens (Play Integrity needs the
    # signing keys registered); until then only signed-in callers get through.
    enforce_app_check=False,
)
def decide(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, 'sign in first')
    data = req.data if isinstance(req.data, dict) else {}
    task = data.get('task')
    if task not in ('classify', 'find'):
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'unknown task')
    if task == 'find' and not isinstance(data.get('items'), list):
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'items must be a list')

    # Common item names repeat across homes, so classify answers are shared.
    cache = None
    if task == 'classify':
        name = str(data.get('name', '')).strip()
        if not name:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'name is empty')
        cache = firestore.client().collection('classifyCache').document(_name_key(name))
        hit = cache.get()
        if hit.exists:
            return {**hit.get('result'), 'cached': True}

    if _count_call(req.auth.uid) > DAILY_LIMIT:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED, 'daily limit reached')
    try:
        result = asyncio.run(_ask(task, data, JEV_API_KEY.value))
    except Exception as e:  # the app falls back to its own rules
        print(f'decide failed: {type(e).__name__}')
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAVAILABLE, 'suggestions unavailable') from e
    if cache is not None:
        cache.set({'result': result, 'at': firestore.SERVER_TIMESTAMP})
    return {**result, 'cached': False}


# Who the access token belongs to, asked of the provider that issued it.
_PROFILE_URLS = {
    'kakao': 'https://kapi.kakao.com/v2/user/me',
    'naver': 'https://openapi.naver.com/v1/nid/me',
}


def _profile(provider: str, token: str) -> tuple[str, str | None, str | None]:
    """Returns (provider user id, nickname, photo URL); raises on a bad token."""
    req = urllib.request.Request(_PROFILE_URLS[provider], headers={'Authorization': f'Bearer {token}'})
    with urllib.request.urlopen(req, timeout=8) as r:
        body = json.load(r)
    if provider == 'kakao':
        profile = (body.get('kakao_account') or {}).get('profile') or {}
        props = body.get('properties') or {}
        return (str(body['id']), profile.get('nickname') or props.get('nickname'),
                profile.get('profile_image_url') or props.get('profile_image'))
    if body.get('resultcode') != '00':
        raise ValueError('naver profile refused')
    me = body['response']
    return str(me['id']), me.get('nickname') or me.get('name'), me.get('profile_image')


@https_fn.on_call(
    region='us-central1',
    memory=options.MemoryOption.MB_256,
    timeout_sec=20,
    max_instances=10,
    enforce_app_check=False,
)
def login(req: https_fn.CallableRequest) -> dict:
    data = req.data if isinstance(req.data, dict) else {}
    provider, token = data.get('provider'), data.get('token')
    if provider not in _PROFILE_URLS or not isinstance(token, str) or not token:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'provider and token required')
    try:
        pid, name, photo = _profile(provider, token)
    except urllib.error.HTTPError as e:
        print(f'login: {provider} refused the token ({e.code})')
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, 'token not accepted') from e
    except Exception as e:
        print(f'login: {provider} check failed: {type(e).__name__}')
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAVAILABLE, 'could not check the token') from e

    # Provider ids are numbers or opaque strings; Firebase uids allow up to 128 characters.
    uid = f'{provider}:{pid}'[:128]
    fields = {'display_name': (name or '')[:100] or None}
    if photo and photo.startswith('http://'):
        photo = 'https://' + photo[len('http://'):]  # Kakao CDN serves both; Firebase wants https
    if photo and photo.startswith('https://'):
        fields['photo_url'] = photo
    try:
        auth.update_user(uid, **fields)
    except auth.UserNotFoundError:
        auth.create_user(uid=uid, **fields)
    return {'token': auth.create_custom_token(uid, {'provider': provider}).decode()}


# Shared homes: homes/{homeId} {name, owner, members: [uid], people: {uid: {name, photo}}, limit},
# users/{uid} {homeId}, invites/{code} {homeId, by, expires}. Only this function changes them;
# the app reads them and writes the home's own documents (spaces, containers, items, log, photos).
FREE_MEMBERS = 2
INVITE_HOURS = 24
_CODE_DIGITS = '0123456789'


def _signed_in(req: https_fn.CallableRequest) -> str:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, 'sign in first')
    provider = ((req.auth.token or {}).get('firebase') or {}).get('sign_in_provider')
    if provider == 'anonymous':
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.PERMISSION_DENIED, 'guests cannot share a home')
    return req.auth.uid


def _person(uid: str) -> dict:
    try:
        u = auth.get_user(uid)
        return {'name': (u.display_name or '')[:60] or None, 'photo': u.photo_url}
    except Exception:
        return {'name': None, 'photo': None}


def _home_of(db, uid: str):
    snap = db.collection('users').document(uid).get()
    home_id = snap.get('homeId') if snap.exists else None
    if not home_id:
        return None, None
    home = db.collection('homes').document(home_id).get()
    if not home.exists or uid not in (home.get('members') or []):
        return None, None
    return home_id, home


def _leave(db, uid: str, home_id: str) -> None:
    ref = db.collection('homes').document(home_id)

    @firestore.transactional
    def out(tx):
        snap = ref.get(transaction=tx)
        if not snap.exists:
            return []
        members = [m for m in (snap.get('members') or []) if m != uid]
        people = dict(snap.get('people') or {})
        people.pop(uid, None)
        tx.update(ref, {'members': members, 'people': people,
                        'owner': snap.get('owner') if snap.get('owner') != uid else (members[0] if members else None)})
        tx.set(db.collection('users').document(uid), {'homeId': None}, merge=True)
        return members

    if not out(db.transaction()):
        db.recursive_delete(ref)  # nobody left: the home and everything in it go


@https_fn.on_call(
    region='us-central1',
    memory=options.MemoryOption.MB_256,
    timeout_sec=60,
    max_instances=10,
    enforce_app_check=False,
)
def household(req: https_fn.CallableRequest) -> dict:
    """action: create {name} | invite | join {code, leaveCurrent} | leave |
    alerts {token, on, lang} | notify {type, names, place}."""
    uid = _signed_in(req)
    data = req.data if isinstance(req.data, dict) else {}
    action = data.get('action')
    db = firestore.client()
    home_id, home = _home_of(db, uid)

    if action == 'create':
        if home_id:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.ALREADY_EXISTS, 'already in a home')
        ref = db.collection('homes').document()
        name = str(data.get('name') or '')[:40]
        ref.set({'name': name, 'owner': uid, 'members': [uid], 'people': {uid: _person(uid)},
                 'limit': FREE_MEMBERS, 'created': firestore.SERVER_TIMESTAMP})
        db.collection('users').document(uid).set({'homeId': ref.id}, merge=True)
        return {'homeId': ref.id}

    if action == 'invite':
        if not home_id:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.FAILED_PRECONDITION, 'no home')
        if len(home.get('members') or []) >= (home.get('limit') or FREE_MEMBERS):
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED, 'home is full')
        now = datetime.datetime.now(datetime.timezone.utc)
        for _ in range(20):
            code = ''.join(secrets.choice(_CODE_DIGITS) for _ in range(6))
            ref = db.collection('invites').document(code)
            snap = ref.get()
            if not snap.exists or snap.get('expires') < now:
                expires = now + datetime.timedelta(hours=INVITE_HOURS)
                ref.set({'homeId': home_id, 'by': uid, 'expires': expires})
                return {'code': code, 'expires': expires.isoformat()}
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAVAILABLE, 'try again')

    if action == 'join':
        code = ''.join(c for c in str(data.get('code') or '') if c.isdigit())
        snap = db.collection('invites').document(code).get() if len(code) == 6 else None
        now = datetime.datetime.now(datetime.timezone.utc)
        if snap is None or not snap.exists or snap.get('expires') < now:
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.NOT_FOUND, 'code not found or expired')
        target = snap.get('homeId')
        if home_id == target:
            return {'homeId': target}
        if home_id and not data.get('leaveCurrent'):
            raise https_fn.HttpsError(https_fn.FunctionsErrorCode.ALREADY_EXISTS, 'already in a home')
        ref = db.collection('homes').document(target)

        @firestore.transactional
        def add(tx):
            h = ref.get(transaction=tx)
            if not h.exists:
                raise https_fn.HttpsError(https_fn.FunctionsErrorCode.NOT_FOUND, 'home is gone')
            members = h.get('members') or []
            if len(members) >= (h.get('limit') or FREE_MEMBERS):
                raise https_fn.HttpsError(https_fn.FunctionsErrorCode.RESOURCE_EXHAUSTED, 'home is full')
            people = dict(h.get('people') or {})
            people[uid] = _person(uid)
            tx.update(ref, {'members': members + [uid], 'people': people})

        add(db.transaction())  # first, so a full home leaves the current one untouched
        if home_id:
            _leave(db, uid, home_id)
        db.collection('users').document(uid).set({'homeId': target}, merge=True)
        return {'homeId': target}

    if action == 'leave':
        if home_id:
            _leave(db, uid, home_id)
        return {}

    if action == 'alerts':
        token = data.get('token')
        lang = 'ko' if data.get('lang') == 'ko' else 'en'
        db.collection('users').document(uid).set(
            {'alerts': bool(data.get('on')), 'fcm': token if isinstance(token, str) else None, 'lang': lang}, merge=True)
        return {}

    if action == 'notify':
        if not home_id:
            return {'sent': 0}
        return {'sent': _notify_family(db, uid, home_id, home, data)}

    raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'unknown action')


_CHANGE_WORDS = {
    'ko': {'add': '넣음', 'move': '옮김', 'use': '씀', 'usedUp': '다 씀', 'edit': '고침', 'remove': '뺌'},
    'en': {'add': 'added', 'move': 'moved', 'use': 'used', 'usedUp': 'used up', 'edit': 'edited', 'remove': 'removed'},
}


def _change_text(lang: str, kind: str, names: list, place: str) -> str:
    first = names[0] if names else ''
    if lang == 'ko':
        what = f'{first} 외 {len(names) - 1}개' if len(names) > 1 else first
        text = f'{what} {_CHANGE_WORDS["ko"].get(kind, "바꿈")}'
    else:
        what = f'{first} and {len(names) - 1} more' if len(names) > 1 else first
        text = f'{_CHANGE_WORDS["en"].get(kind, "changed").capitalize()} {what}'
    return f'{text} · {place}' if place else text


def _notify_family(db, uid: str, home_id: str, home, data: dict) -> int:
    """Tells the other members who switched on family alerts what changed."""
    kind = str(data.get('type') or '')
    names = [str(n)[:60] for n in (data.get('names') or [])][:20]
    place = str(data.get('place') or '')[:80]
    if not names:
        return 0
    people = home.get('people') or {}
    who = ((people.get(uid) or {}).get('name')) or ''
    sent = 0
    for member in home.get('members') or []:
        if member == uid:
            continue
        u = db.collection('users').document(member).get()
        if not u.exists or not u.get('alerts') or not u.get('fcm'):
            continue
        lang = u.get('lang') or 'en'
        try:
            messaging.send(messaging.Message(
                token=u.get('fcm'),
                notification=messaging.Notification(
                    title=who or ('가족' if lang == 'ko' else 'Family'), body=_change_text(lang, kind, names, place)),
                # One line per person: a burst of changes replaces the last one.
                android=messaging.AndroidConfig(notification=messaging.AndroidNotification(
                    tag=f'{home_id}-{uid}', icon='ic_stat_fairy', channel_id='family')),
            ))
            sent += 1
        except messaging.UnregisteredError:
            u.reference.set({'fcm': None}, merge=True)
        except Exception as e:
            print(f'notify: {type(e).__name__}')
    return sent


# Food barcodes: the food-safety ministry's C005 service gives product names.
# Answers (and misses) are shared by everyone in barcodeCache/{code}, so each
# barcode is asked once; misses are asked again after a month.
_FOOD_URL = 'https://openapi.foodsafetykorea.go.kr/api/{key}/C005/json/1/1/BAR_CD={code}'
_MISS_DAYS = 30


@https_fn.on_call(
    region='us-central1',
    secrets=[FOOD_API_KEY],
    memory=options.MemoryOption.MB_256,
    timeout_sec=15,
    max_instances=10,
    enforce_app_check=False,
)
def barcode(req: https_fn.CallableRequest) -> dict:
    if req.auth is None:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAUTHENTICATED, 'sign in first')
    code = ''.join(c for c in str((req.data or {}).get('code') or '') if c.isdigit())
    if not 8 <= len(code) <= 14:
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.INVALID_ARGUMENT, 'barcode digits')
    ref = firestore.client().collection('barcodeCache').document(code)
    snap = ref.get()
    now = datetime.datetime.now(datetime.timezone.utc)
    if snap.exists:
        d = snap.to_dict()
        if d.get('name') or (d.get('at') and now - d['at'] < datetime.timedelta(days=_MISS_DAYS)):
            return {'name': d.get('name'), 'maker': d.get('maker')}
    try:
        with urllib.request.urlopen(_FOOD_URL.format(key=urllib.parse.quote(FOOD_API_KEY.value), code=code), timeout=8) as r:
            body = json.load(r)
    except Exception as e:
        print(f'barcode: lookup failed {type(e).__name__}')
        raise https_fn.HttpsError(https_fn.FunctionsErrorCode.UNAVAILABLE, 'lookup failed') from e
    rows = (body.get('C005') or {}).get('row') or []
    name = (rows[0].get('PRDLST_NM') or '').strip()[:80] if rows else ''
    maker = (rows[0].get('BSSH_NM') or '').strip()[:60] if rows else ''
    ref.set({'name': name or None, 'maker': maker or None, 'at': firestore.SERVER_TIMESTAMP})
    return {'name': name or None, 'maker': maker or None}
