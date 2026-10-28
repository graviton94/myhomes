"""Cloud Functions for Home Fairy.

decide: typed suggestions from the TypeSafe decision model for signed-in
users (anonymous guests included). The Jev key stays in Secret Manager.
"""
import asyncio
import datetime
import hashlib

from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn, options
from firebase_functions.params import SecretParam
from typesafe_sdk import AsyncTypeSafeClient

import decisions

initialize_app()
JEV_API_KEY = SecretParam('JEV_API_KEY')
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
