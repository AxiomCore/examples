#!/usr/bin/env bash
# Terminal 2 (after run-emulator.sh is up): build the contract and serve it on port 8711.
# GET /me needs a bearer token issued by the running emulator.
set -euo pipefail
cd "$(dirname "$0")"
AXIOM="${AXIOM:-axiom}"
"$AXIOM" check main.acore
"$AXIOM" build main.acore --out backend.axiom
# axiom refuses to overwrite a deployment file, so keep the previous one aside.
[ -f deployment.json ] && mv -f deployment.json deployment.json.prev
# --static-key scaffolds a jwt provider; `auth emulate deployment` points it at the emulator.
"$AXIOM" server deployment backend.axiom backend.server.json --output deployment.json --static-key
"$AXIOM" auth emulate deployment deployment.json
AXIOM_AUTH_LOCAL_PUBLIC_KEY="$(cat .axiom/auth-local/public.pem)" \
  exec "$AXIOM" run main.acore --deployment deployment.json --port "${PORT:-8711}"
