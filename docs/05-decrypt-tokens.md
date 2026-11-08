# 05 · Decrypt OAuth tokens from any Claude profile dir

Lets you answer "who is signed in to this profile dir?" without
launching Claude. Also useful if you ever need to migrate a signed-in
state somewhere.

Scope: this works **only on the Windows user account that owns the
DPAPI master key** — i.e. the user who originally signed in. Copying
these files to another user's machine will not decrypt.

## TL;DR — use the helper

```powershell
python '%USERPROFILE%\tools\claude-launcher\scripts\whois.py' `
  '%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>'
```

Expected output:

```
email:   user-b@example.com
name:    Account B
uuid:    00000000-0000-0000-0000-000000000002
plan:    Max  (default_claude_max_20x)
org:     user-b@example.com's Organization  (…)
```

Deps once:

```bash
pip install pywin32 pycryptodome
```

Script source: [../scripts/whois.py](../scripts/whois.py).

## What's happening under the hood

Chromium (Electron inherits this) stores sensitive values with a
two-layer scheme on Windows:

### Layer 1 — the AES master key

- `<profile>/Local State` is a JSON blob.
- Inside: `os_crypt.encrypted_key` is a base64 string.
- First 5 bytes after decoding are the ASCII literal `DPAPI`
  (identifying the format — not v10/v11/v20, the oldest Chromium one;
  no App-Bound Encryption on this install).
- The rest is a DPAPI blob. `CryptUnprotectData` on that gives you a
  32-byte AES-256 key tied to the Windows user's SID + password.

### Layer 2 — AES-256-GCM per value

- `config.json → oauth:tokenCacheV2` (base64).
- Decoded blob is:
  - 3 bytes prefix: `v10` (sometimes `v11`)
  - 12 bytes nonce
  - … ciphertext …
  - 16 bytes tag
- Decrypt with AES-256-GCM using the key from Layer 1.

The plaintext is JSON mapping an `acct:<uuid>|<appUuid>:<orgUuid>:<url>:<scopes>`
key to an object:

```json
{
  "token":        "sk-ant-oat01-<REDACTED>...",
  "refreshToken": "sk-ant-ort01-<REDACTED>...",
  "expiresAt":    1795235415445,
  "subscriptionType": "max",
  "rateLimitTier":    "default_claude_max_5x",
  "identityChecked":  true
}
```

Access token (`sk-ant-oat01-<REDACTED>`) lifetime is ~2 weeks.
Refresh token (`sk-ant-ort01-<REDACTED>`) lifetime appears to be ~1 year.
Both are **opaque** — not JWTs, so you can't decode the email client-side.

### Layer 3 — ask Anthropic who it is

`https://api.anthropic.com/api/oauth/profile` with
`Authorization: Bearer <access_token>` returns:

```json
{
  "account":      {"uuid": "...", "email": "...", "full_name": "...",
                   "has_claude_max": true, ...},
  "organization": {"uuid": "...", "name": "...",
                   "rate_limit_tier": "default_claude_max_20x", ...},
  "application":  {"uuid": "...", "name": "Cowork", "slug": "cowork"},
  "enabled_plugins": []
}
```

`whois.py` just chains all three layers.

## Full standalone recipe (no helper)

```python
import json, base64, urllib.request, os
import win32crypt
from Crypto.Cipher import AES

slot = r'%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>'

# 1. DPAPI-unwrap the AES key
ls = json.load(open(slot + r'\Local State', encoding='utf-8'))
enc_key = base64.b64decode(ls['os_crypt']['encrypted_key'])
if enc_key[:5] == b'DPAPI':
    enc_key = enc_key[5:]
aes_key = win32crypt.CryptUnprotectData(enc_key, None, None, None, 0)[1]

# 2. AES-GCM decrypt tokenCacheV2
cfg = json.load(open(slot + r'\config.json', encoding='utf-8'))
blob = base64.b64decode(cfg['oauth:tokenCacheV2'])
nonce, ct, tag = blob[3:15], blob[15:-16], blob[-16:]
pt = AES.new(aes_key, AES.MODE_GCM, nonce=nonce).decrypt_and_verify(ct, tag)
toks = json.loads(pt)
print(json.dumps(toks, indent=2)[:2000])

# 3. Pick a profile-scoped token, ask Anthropic
tok = next(v['token'] for k,v in toks.items() if 'user:profile' in k)
req = urllib.request.Request(
    "https://api.anthropic.com/api/oauth/profile",
    headers={"Authorization": f"Bearer {tok}", "anthropic-version": "2023-06-01"},
)
print(urllib.request.urlopen(req, timeout=10).read().decode())
```

## Decrypting cookies too (if you ever need to)

Same AES key decrypts `Network/Cookies` SQLite values (column
`encrypted_value`). Any Chromium cookie-dumper (`pycookiecheat`,
Chromium's `chrome-cookies.py`, etc.) pointed at a Claude profile dir
will Just Work provided it reads the `DPAPI`-prefixed key format. Most
modern dumpers assume v20 (App-Bound Encryption); on this install the
key is still raw DPAPI, so the strip-5-bytes step is enough.

## What NOT to do

- Don't send `sk-ant-oat01-<REDACTED>…` or `sk-ant-ort01-<REDACTED>…` to any destination
  that isn't `https://api.anthropic.com`. These are long-lived bearer
  credentials for the signed-in user.
- Don't paste tokens into chat windows, pastebins, Discord, etc.
- Don't commit `config.json` or `Local State` to a public repo.
