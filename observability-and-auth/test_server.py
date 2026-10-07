"""Loopback-only synthetic auth fixture. Never deploy this login or reuse its keys."""
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
import hmac
import ipaddress
import logging
import os
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import jwt
from fastapi import FastAPI, Header, HTTPException, Query, Request
from fastapi.responses import JSONResponse

# Deliberately public fixture values, shared only with the local example contract.
SECRET_KEY = "development-only-placeholder-auth-fixture-key-2026"
API_KEY = "development-only-api-key"
ALGORITHM = "HS256"


def fixture_enabled():
    return os.environ.get("AXIOM_AUTH_FIXTURE_DEV") == "1"


def loopback(value):
    try:
        return ipaddress.ip_address(value).is_loopback
    except ValueError:
        return value == "localhost"


@asynccontextmanager
async def lifespan(_app):
    if not fixture_enabled():
        raise RuntimeError("Synthetic auth fixture disabled. Set AXIOM_AUTH_FIXTURE_DEV=1 for local tests only.")
    if not loopback(os.environ.get("AXIOM_AUTH_FIXTURE_HOST", "127.0.0.1")):
        raise RuntimeError("Synthetic auth fixture requires a loopback host.")
    yield


app = FastAPI(lifespan=lifespan)


class RedactCredentialQuery(logging.Filter):
    """Cover the standard Uvicorn access-log target without changing requests."""
    def filter(self, record):
        if isinstance(record.args, tuple) and len(record.args) >= 3:
            args = list(record.args)
            if isinstance(args[2], str):
                url = urlsplit(args[2])
                query = [(key, "[redacted]" if key.lower() in {"api_key", "token", "access_token"} else value)
                         for key, value in parse_qsl(url.query, keep_blank_values=True)]
                args[2] = urlunsplit((url.scheme, url.netloc, url.path, urlencode(query), url.fragment))
                record.args = tuple(args)
        return True


logging.getLogger("uvicorn.access").addFilter(RedactCredentialQuery())


@app.middleware("http")
async def local_fixture_boundary(request: Request, call_next):
    if not fixture_enabled():
        return JSONResponse(status_code=503, content={"detail": "Local auth fixture disabled"})
    if request.client is None or not loopback(request.client.host):
        return JSONResponse(status_code=403, content={"detail": "Local auth fixture accepts loopback clients only"})
    return await call_next(request)


def verify_bearer(authorization):
    """Return verified fixture claims or reject; never authorize decoded-only JWTs."""
    parts = authorization.split() if isinstance(authorization, str) else []
    if len(parts) != 2 or parts[0].lower() != "bearer" or len(parts[1]) > 8192 or not parts[1].isascii():
        raise HTTPException(status_code=401, detail="Missing or invalid bearer credential",
                            headers={"WWW-Authenticate": "Bearer"})
    try:
        claims = jwt.decode(parts[1], SECRET_KEY, algorithms=[ALGORITHM],
                            options={"require": ["exp", "sub", "scopes"], "verify_aud": False})
        if (type(claims["exp"]) is not int or not isinstance(claims["sub"], str)
                or not claims["sub"].strip() or not isinstance(claims["scopes"], list)
                or any(not isinstance(scope, str) or not scope.strip() for scope in claims["scopes"])):
            raise jwt.InvalidTokenError("Invalid fixture claim types")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Missing or invalid bearer credential",
                            headers={"WWW-Authenticate": "Bearer"}) from None
    return claims


def valid_api_key(value):
    return isinstance(value, str) and value.isascii() and hmac.compare_digest(value, API_KEY)


@app.post("/login")
def login():
    # No user authentication: only synthetic local identities are issued here.
    now = datetime.now(timezone.utc)
    payload = {"sub": "local-fixture-user", "scopes": ["items:read", "profile:write"],
               "iat": now, "exp": now + timedelta(hours=1)}
    return {"token": jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)}


@app.get("/protected/jwt")
def protected_jwt(authorization: str | None = Header(default=None)):
    claims = verify_bearer(authorization)
    if "items:read" not in claims["scopes"]:
        raise HTTPException(status_code=403, detail="Missing required scope")
    return {"message": "Successfully accessed a JWT protected route"}


@app.get("/protected/api-key-header")
def protected_api_key_header(x_api_key: str | None = Header(default=None)):
    if not valid_api_key(x_api_key):
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return {"message": "You accessed an API Key Header protected route"}


@app.get("/protected/api-key-query")
def protected_api_key_query(api_key: str | None = Query(default=None)):
    if not valid_api_key(api_key):
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return {"message": "You accessed an API Key Query protected route"}


@app.get("/protected/multi")
def protected_multi(authorization: str | None = Header(default=None),
                    x_api_key: str | None = Header(default=None)):
    # Contract OR semantics: one genuinely valid method wins, even if the other is invalid.
    if valid_api_key(x_api_key):
        return {"message": "A valid credential satisfied the OR policy"}
    try:
        verify_bearer(authorization)
    except HTTPException:
        raise HTTPException(status_code=401, detail="A valid bearer token or API key is required") from None
    return {"message": "A valid credential satisfied the OR policy"}


if __name__ == "__main__":
    import uvicorn
    host = os.environ.get("AXIOM_AUTH_FIXTURE_HOST", "127.0.0.1")
    if not fixture_enabled() or not loopback(host):
        raise SystemExit("Enable AXIOM_AUTH_FIXTURE_DEV=1 and use a loopback host for this synthetic fixture.")
    uvicorn.run(app, host=host, port=int(os.environ.get("AXIOM_AUTH_FIXTURE_PORT", "8000")),
                access_log=False, proxy_headers=False)
