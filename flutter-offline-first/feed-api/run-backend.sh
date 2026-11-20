#!/usr/bin/env bash
# Check, build and run the offline feed backend.
# Usage: ./run-backend.sh            (port 8080)
#        PORT=8720 ./run-backend.sh  (another port)
set -euo pipefail
cd "$(dirname "$0")"
AXIOM="${AXIOM:-axiom}"
"$AXIOM" check main.acore
"$AXIOM" build main.acore --out backend.axiom
# axiom refuses to overwrite a deployment file, so keep the previous one aside.
[ -f deployment.json ] && mv -f deployment.json deployment.json.prev
"$AXIOM" server deployment backend.axiom backend.server.json --output deployment.json
exec "$AXIOM" run main.acore --deployment deployment.json --port "${PORT:-8080}"
