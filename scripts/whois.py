"""
whois.py <profile-dir>

Decrypt a Claude Desktop profile dir's OAuth tokens using DPAPI +
Chromium Safe Storage, then ask api.anthropic.com who the account is.

Deps: pywin32, pycryptodome   (pip install pywin32 pycryptodome)

Only works for the Windows user that owns the DPAPI master key
(i.e. the user that originally signed in).
"""
import sys, json, base64, urllib.request, os

if len(sys.argv) < 2:
    print("usage: whois.py <profile-dir>", file=sys.stderr)
    sys.exit(2)

slot = sys.argv[1]
ls_path  = os.path.join(slot, 'Local State')
cfg_path = os.path.join(slot, 'config.json')

if not os.path.exists(ls_path) or not os.path.exists(cfg_path):
    print(f"[err] missing Local State or config.json in {slot}", file=sys.stderr)
    sys.exit(1)

import win32crypt
from Crypto.Cipher import AES

ls = json.load(open(ls_path, 'r', encoding='utf-8'))
enc_key = base64.b64decode(ls['os_crypt']['encrypted_key'])
if enc_key[:5] == b'DPAPI':
    enc_key = enc_key[5:]
aes_key = win32crypt.CryptUnprotectData(enc_key, None, None, None, 0)[1]

cfg = json.load(open(cfg_path, 'r', encoding='utf-8'))
if 'oauth:tokenCacheV2' not in cfg:
    print("[err] no oauth:tokenCacheV2 in config.json (profile is not signed in)", file=sys.stderr)
    sys.exit(1)

blob = base64.b64decode(cfg['oauth:tokenCacheV2'])
nonce = blob[3:15]
ct    = blob[15:-16]
tag   = blob[-16:]
pt    = AES.new(aes_key, AES.MODE_GCM, nonce=nonce).decrypt_and_verify(ct, tag)
toks  = json.loads(pt.decode('utf-8'))

if not toks:
    print("[err] oauth cache decrypted but empty", file=sys.stderr)
    sys.exit(1)

# Prefer a profile-scoped token if present
token = None
for k, v in toks.items():
    if 'user:profile' in k:
        token = v['token']
        break
if token is None:
    token = list(toks.values())[0]['token']

req = urllib.request.Request(
    "https://api.anthropic.com/api/oauth/profile",
    headers={
        "Authorization":     f"Bearer {token}",
        "anthropic-version": "2023-06-01",
        "User-Agent":        "ClaudeDesktop/1.0",
    },
)
with urllib.request.urlopen(req, timeout=10) as r:
    data = json.loads(r.read().decode('utf-8'))

acct = data['account']
org  = data['organization']
plan = ('Max'  if acct.get('has_claude_max') else
        'Pro'  if acct.get('has_claude_pro') else
        'Free')
print(f"email:   {acct['email']}")
print(f"name:    {acct.get('full_name') or acct.get('display_name')}")
print(f"uuid:    {acct['uuid']}")
print(f"plan:    {plan}  ({org.get('rate_limit_tier')})")
print(f"org:     {org['name']}  ({org['uuid']})")
if acct.get('created_at'):
    print(f"created: {acct['created_at']}")
