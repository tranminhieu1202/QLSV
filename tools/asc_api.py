"""Gọi App Store Connect API bằng API key (.p8), không cần thư viện ngoài.

Cách dùng:

    python3 tools/asc_api.py GET  "/v1/apps?filter[bundleId]=edu.vnu.qlgd"
    python3 tools/asc_api.py PATCH /v1/appStoreReviewDetails/<id> body.json
    python3 tools/asc_api.py wait-upload <build_number>

Key lấy từ ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 (KHÔNG commit
file .p8). Đổi key qua biến môi trường ASC_KEY_ID / ASC_ISSUER_ID.

`wait-upload` theo dõi lượt upload gần nhất có build number đã cho tới khi
Apple xử lý xong; in lỗi ITMS nếu bị từ chối và trả mã thoát 1.
"""

from __future__ import annotations

import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

KEY_ID = os.environ.get("ASC_KEY_ID", "VU7G87GY2Y")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "5867cb6c-d94b-45b3-90d9-a398566bbfe9")
APP_ID = os.environ.get("ASC_APP_ID", "6826131512")
KEY_PATH = os.path.expanduser(
    f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")


def _b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def _der_to_raw(der: bytes) -> bytes:
    # openssl ký ECDSA ở dạng DER SEQUENCE(r, s); JWT ES256 cần r||s 64 byte.
    i = 2 + (der[1] & 0x7F if der[1] & 0x80 else 0)
    out = b""
    for _ in range(2):
        n = der[i + 1]
        out += der[i + 2:i + 2 + n].lstrip(b"\0").rjust(32, b"\0")
        i += 2 + n
    return out


def _token() -> str:
    now = int(time.time())
    head = _b64(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    claims = _b64(json.dumps({"iss": ISSUER_ID, "iat": now, "exp": now + 1200,
                              "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{head}.{claims}"
    sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
                         input=signing_input.encode(), capture_output=True,
                         check=True).stdout
    return f"{signing_input}.{_b64(_der_to_raw(sig))}"


def call(path: str, method: str = "GET", body: bytes | None = None) -> tuple[int, dict]:
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path, data=body, method=method,
        headers={"Authorization": "Bearer " + _token(),
                 "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            text = r.read().decode()
            return r.status, json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")


def wait_upload(build_number: str, timeout_s: int = 1800) -> int:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        _, d = call(f"/v1/apps/{APP_ID}/buildUploads?limit=5")
        ups = [u for u in d.get("data", [])
               if u["attributes"].get("cfBundleVersion") == build_number]
        if ups:
            st = ups[0]["attributes"]["state"]
            print(f"{time.strftime('%H:%M:%S')} build {build_number}: {st['state']}")
            if st["state"] == "COMPLETE":
                return 0
            if st["state"] == "FAILED":
                for e in st.get("errors", []):
                    print(f"  ITMS-{e['code']}: {e['description']}")
                return 1
        time.sleep(30)
    print("Hết thời gian chờ Apple xử lý build.")
    return 1


def main() -> int:
    if len(sys.argv) >= 3 and sys.argv[1] == "wait-upload":
        return wait_upload(sys.argv[2])
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    method, path = sys.argv[1].upper(), sys.argv[2]
    body = open(sys.argv[3], "rb").read() if len(sys.argv) > 3 else None
    status, data = call(path, method, body)
    print(json.dumps(data, ensure_ascii=False, indent=2))
    return 0 if status < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
