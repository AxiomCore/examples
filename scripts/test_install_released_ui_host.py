import unittest

from install_released_ui_host import web_asset


class WebHostSelectionTests(unittest.TestCase):
    def test_selects_only_declared_web_asset(self):
        manifest = {"assets": [
            {"target": "ios", "file": "ios.zip"},
            {"target": "web", "file": "web.zip"},
        ]}
        release = {"assets": [{"name": "ios.zip"}, {"name": "web.zip"}]}
        self.assertEqual(web_asset(manifest, release)["name"], "web.zip")

    def test_rejects_unsafe_or_ambiguous_assets(self):
        release = {"assets": [{"name": "web.zip"}]}
        with self.assertRaisesRegex(RuntimeError, "Unsafe"):
            web_asset({"assets": [{"target": "web", "file": "../web.zip"}]}, release)
        with self.assertRaisesRegex(RuntimeError, "exactly one"):
            web_asset({"assets": [{"target": "web", "file": "web.zip"}] * 2}, release)


if __name__ == "__main__":
    unittest.main()
