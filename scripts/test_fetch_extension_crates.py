import unittest

from fetch_extension_crates import ROOT, manifests


class FetchExtensionCratesTests(unittest.TestCase):
    def test_every_rust_extension_web_example_has_a_lockfile(self):
        self.assertEqual({str(path.parent.relative_to(ROOT)) for path in manifests()}, {
            "axiom-project-management-app/frontend",
            "axiom-shopping-app/frontend",
            "extension-sandbox",
        })


if __name__ == "__main__":
    unittest.main()
