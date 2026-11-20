#!/usr/bin/env python3
"""Create a verified user on a running `axiom auth emulate` issuer.

Usage: python3 tool/create_user.py [issuer] [email] [password]
Defaults: http://127.0.0.1:8710/local/api, a fresh address, "correct horse battery".
Prints the email. Reads the sign-up code from the emulator's mail store.
"""
import json, re, sys, time, urllib.request

issuer = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8710/local/api"
email = sys.argv[2] if len(sys.argv) > 2 else f"demo{int(time.time())}@example.com"
password = sys.argv[3] if len(sys.argv) > 3 else "correct horse battery"


def post(path, body):
    req = urllib.request.Request(issuer + path, json.dumps(body).encode(), {"content-type": "application/json"})
    return json.load(urllib.request.urlopen(req))


challenge = post("/v1/signup", {"email": email, "password": password})["challenge_id"]
origin = issuer.split("/local/")[0]
mail = json.load(urllib.request.urlopen(origin + "/local/mail.json"))
text = next(m["body_text"] for m in mail["mail"] if m["challenge_id"] == challenge)
code = re.search(r"Your code is (\d{6})", text).group(1)
post("/v1/signup/verify", {"challenge_id": challenge, "code": code})
print(email)
