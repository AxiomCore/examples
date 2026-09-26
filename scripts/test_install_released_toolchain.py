import unittest

from install_released_toolchain import TOOLS, select


class ReleaseSelectionTests(unittest.TestCase):
    def test_cli_selection_ignores_newer_non_cli_releases_and_unusable_cli_tags(self):
        releases = [
            {"tag_name": "ui-host-v9.0.0", "assets": [{"name": "axiom-macos-arm64.tar.gz"}]},
            {"tag_name": "v0.149.0", "assets": []},
            {"tag_name": "v0.148.0", "prerelease": True,
             "assets": [{"name": "axiom-macos-arm64.tar.gz"}]},
            {"tag_name": "v0.147.10", "assets": [{"name": "axiom-macos-arm64.tar.gz"}]},
            {"tag_name": "v0.147.9", "assets": [{"name": "axiom-macos-arm64.tar.gz"}]},
        ]
        release, _ = select(releases, TOOLS[0][0], TOOLS[0][1])
        self.assertEqual(release["tag_name"], "v0.147.10")

    def test_go_extractor_uses_train_tag_not_semver(self):
        releases = [{"tag_name": "extractor-go-2026.09.26.1", "assets": [
            {"name": "axiom-go-extractor-macos-arm64"}]}]
        release, _ = select(releases, TOOLS[2][0], TOOLS[2][1])
        self.assertEqual(release["tag_name"], "extractor-go-2026.09.26.1")


if __name__ == "__main__":
    unittest.main()
