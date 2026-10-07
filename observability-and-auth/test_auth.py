"""Direct HTTP regression tests; these intentionally bypass all Axiom clients."""
import copy
import json
from pathlib import Path
import logging
import os
import time
import unittest
from unittest.mock import patch

import jwt
from fastapi.testclient import TestClient
import test_server as server


class AuthTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {"AXIOM_AUTH_FIXTURE_DEV": "1", "AXIOM_AUTH_FIXTURE_HOST": "127.0.0.1"})
        self.env.start()
        self.client = TestClient(server.app, client=("127.0.0.1", 50000))
        self.client.__enter__()
        self.claims = {"sub": "test-user", "exp": int(time.time()) + 300, "scopes": ["items:read"]}

    def tearDown(self):
        self.client.__exit__(None, None, None)
        self.env.stop()

    def token(self, claims=None, key=None, algorithm="HS256"):
        return jwt.encode(self.claims if claims is None else claims,
                          server.SECRET_KEY if key is None else key, algorithm=algorithm)

    def assert_denied(self, response, status=401):
        self.assertEqual(response.status_code, status)
        self.assertNotIn("message", response.json())
        self.assertNotIn(server.SECRET_KEY, response.text)
        self.assertNotIn(server.API_KEY, response.text)

    def test_missing_and_malformed_bearer(self):
        for value in [None, "", "Basic abc", "Bearer", "Bearer invalid", "Bearer a b", "Bearer " + "a" * 8193]:
            with self.subTest(value_type="missing" if value is None else "malformed"):
                headers = {} if value is None else {"Authorization": value}
                self.assert_denied(self.client.get("/protected/jwt", headers=headers))

    def test_signature_algorithm_and_expiry(self):
        token = self.token()
        payload = token.split(".")[1]
        altered = payload[:-1] + ("A" if payload[-1] != "A" else "B")
        tampered = token.split(".")[0] + "." + altered + "." + token.split(".")[2]
        cases = [self.token(key="wrong-synthetic-signing-key-that-is-long-enough"), tampered,
                 self.token(key="", algorithm="none"),
                 self.token(key=server.SECRET_KEY * 2, algorithm="HS384"),
                 self.token({**self.claims, "exp": int(time.time()) - 10}),
                 self.token({**self.claims, "nbf": int(time.time()) + 300})]
        for candidate in cases:
            with self.subTest(case=cases.index(candidate)):
                self.assert_denied(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + candidate}))

    def test_required_claims(self):
        for field in ("exp", "sub", "scopes"):
            claims = copy.deepcopy(self.claims)
            del claims[field]
            with self.subTest(missing=field):
                self.assert_denied(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + self.token(claims)}))

    def test_claim_types(self):
        for field, values in {"exp": [True, "9999999999", 9999999999.0, None],
                              "sub": [7, "", "   ", None],
                              "scopes": ["items:read", None, [1], [""] ]}.items():
            for value in values:
                with self.subTest(field=field, value_type=type(value).__name__):
                    self.assert_denied(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + self.token({**self.claims, field: value})}))

    def test_valid_bearer_and_scope(self):
        self.assertEqual(self.client.get("/protected/jwt", headers={"Authorization": "bEaReR " + self.token()}).status_code, 200)
        for scopes in ([], ["profile:write"], ["items:reader"]):
            with self.subTest(scopes=scopes):
                self.assert_denied(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + self.token({**self.claims, "scopes": scopes})}), 403)

    def test_header_api_key(self):
        for value in (None, "", "wrong", server.API_KEY):
            with self.subTest(present=value is not None, correct=value == server.API_KEY):
                response = self.client.get("/protected/api-key-header", headers={} if value is None else {"x-api-key": value})
                self.assertEqual(response.status_code, 200 if value == server.API_KEY else 403)
                self.assertNotIn(server.API_KEY, response.text)

    def test_query_api_key(self):
        for value in (None, "", "wrong", "値", server.API_KEY):
            with self.subTest(present=value is not None, correct=value == server.API_KEY):
                response = self.client.get("/protected/api-key-query", params={} if value is None else {"api_key": value})
                self.assertEqual(response.status_code, 200 if value == server.API_KEY else 403)
                self.assertNotIn(server.API_KEY, response.text)

    def test_multi_or_truth_table(self):
        bearers = [None, "Bearer invalid", "Bearer " + self.token({**self.claims, "scopes": []})]
        keys = [None, "wrong", server.API_KEY]
        for bi, bearer in enumerate(bearers):
            for ki, key in enumerate(keys):
                with self.subTest(bearer=bi, key=ki):
                    headers = {}
                    if bearer is not None:
                        headers["Authorization"] = bearer
                    if key is not None:
                        headers["x-api-key"] = key
                    response = self.client.get("/protected/multi", headers=headers)
                    self.assertEqual(response.status_code, 200 if bi == 2 or ki == 2 else 401)
                    self.assertNotIn(server.API_KEY, response.text)

    def test_committed_contract_client_alignment(self):
        root = Path(__file__).parent
        artifact = json.loads((root / '.axiom').read_text())
        endpoints = artifact['ir']['endpoints']
        self.assertEqual(endpoints['protected_jwt']['auth']['scopes'], ['items:read'])
        self.assertEqual(endpoints['protected_jwt']['auth']['methods'][0]['validation']['secret'], server.SECRET_KEY)
        self.assertEqual(endpoints['protected_multi']['auth']['condition'], 'or')
        generated = (root / 'example/lib/axiom_generated/axiom_sdk.dart').read_text()
        self.assertIn('endpointId: ' + str(endpoints['login']['id']) + ',', generated)
        ui = (root / 'example/lib/main.dart').read_text()
        self.assertEqual(ui.count("'" + server.API_KEY + "'"), 2)

    def test_login_issues_verifiable_synthetic_token(self):
        response = self.client.post("/login")
        self.assertEqual(response.status_code, 200)
        token = response.json()["token"]
        self.assertEqual(server.verify_bearer("Bearer " + token)["sub"], "local-fixture-user")
        self.assertEqual(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + token}).status_code, 200)

    def test_disable_during_runtime(self):
        os.environ["AXIOM_AUTH_FIXTURE_DEV"] = "0"
        self.assert_denied(self.client.post("/login"), 503)
        self.assert_denied(self.client.get("/protected/jwt", headers={"Authorization": "Bearer " + self.token()}), 503)

    def test_external_client_cannot_spoof_loopback(self):
        with TestClient(server.app, client=("203.0.113.10", 50000)) as client:
            for path in ("/login", "/protected/api-key-header"):
                with self.subTest(path=path):
                    response = client.request("POST" if path == "/login" else "GET", path,
                                              headers={"x-forwarded-for": "127.0.0.1", "x-api-key": server.API_KEY})
                    self.assert_denied(response, 403)

    def test_access_log_query_redaction(self):
        record = logging.LogRecord("uvicorn.access", logging.INFO, "", 0, '%s - "%s %s HTTP/%s" %d',
                                  ("127.0.0.1", "GET", "/protected/api-key-query?api_key=" + server.API_KEY + "&token=synthetic-token&other=ok", "1.1", 200), None)
        server.RedactCredentialQuery().filter(record)
        message = record.getMessage()
        self.assertNotIn(server.API_KEY, message)
        self.assertNotIn("synthetic-token", message)
        self.assertIn("other=ok", message)


class StartupTests(unittest.TestCase):
    def test_development_mode_required(self):
        with patch.dict(os.environ, {"AXIOM_AUTH_FIXTURE_DEV": "0"}):
            with self.assertRaisesRegex(RuntimeError, "disabled"):
                with TestClient(server.app, client=("127.0.0.1", 1)):
                    pass

    def test_non_loopback_bind_rejected(self):
        for host in ("0.0.0.0", "::", "203.0.113.10"):
            with self.subTest(host=host), patch.dict(os.environ, {"AXIOM_AUTH_FIXTURE_DEV": "1", "AXIOM_AUTH_FIXTURE_HOST": host}):
                with self.assertRaisesRegex(RuntimeError, "loopback"):
                    with TestClient(server.app, client=("127.0.0.1", 1)):
                        pass


if __name__ == "__main__":
    unittest.main(verbosity=2)
