#!/usr/bin/env bash
# Terminal 1: local auth issuer on 127.0.0.1:8710 (issuer http://127.0.0.1:8710/local/api).
# State lives in api/.axiom/auth-local/; signing keys change on every start.
# AXIOM_SQLITE_LIBRARY: the emulator needs SQLite 3.44 or newer. Debian 12 ships 3.40;
# point this variable at a newer libsqlite3.so.0 if `axiom auth emulate` complains.
set -euo pipefail
cd "$(dirname "$0")"
exec "${AXIOM:-axiom}" auth emulate --port "${EMU_PORT:-8710}"
