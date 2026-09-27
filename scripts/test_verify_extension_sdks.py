"""Keep extension examples pinned to real package registries."""

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from verify_extension_sdks import MANAGED, ROOT, check_registry_lock


class ExtensionRegistryLockTests(unittest.TestCase):
    def test_every_live_example_uses_a_published_sdk(self) -> None:
        for path, _alias, language in MANAGED:
            with self.subTest(project=path):
                check_registry_lock(ROOT / path, language)

    def test_local_rust_sdk_is_rejected(self) -> None:
        source = ROOT / "extension-sandbox"
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            shutil.copy(source / "Cargo.lock", project / "Cargo.lock")
            (project / "Cargo.toml").write_text(
                (source / "Cargo.toml").read_text().replace(
                    'axiom-extension-sdk = "=0.1.0"',
                    'axiom-extension-sdk = { path = "../sdk", version = "=0.1.0" }'
                )
            )
            with self.assertRaisesRegex(RuntimeError, "Rust SDK must pin crates.io"):
                check_registry_lock(project, "rust")

    def test_local_npm_sdk_is_rejected(self) -> None:
        source = ROOT / "axiom-extension-language-samples/typescript"
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            shutil.copy(source / "package.json", project / "package.json")
            lock = json.loads((source / "package-lock.json").read_text())
            lock["packages"]["node_modules/@axiomcore/extension-sdk"]["resolved"] = "file:../sdk"
            (project / "package-lock.json").write_text(json.dumps(lock))
            with self.assertRaisesRegex(RuntimeError, "TypeScript SDK must be locked to npm"):
                check_registry_lock(project, "typescript")

    def test_local_pypi_sdk_is_rejected(self) -> None:
        source = ROOT / "axiom-extension-language-samples/python"
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            shutil.copy(source / "pyproject.toml", project / "pyproject.toml")
            (project / "uv.lock").write_text(
                (source / "uv.lock").read_text().replace(
                    'source = { registry = "https://pypi.org/simple" }',
                    'source = { directory = "../sdk" }'
                )
            )
            with self.assertRaisesRegex(RuntimeError, "Python SDK must be locked to PyPI"):
                check_registry_lock(project, "python")


if __name__ == "__main__":
    unittest.main()
