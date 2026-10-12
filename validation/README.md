# Local validation and release

Builds, checks and artifact uploads are owned by the local release cycle.
GitHub Actions is reserved for SDK publication; push, pull-request, scheduled
and release-tag CI jobs are disabled.

Run release operations from the sibling private `Axiom-release-plane` checkout:

```sh
just release containers
just release web
```

Useful repository checks:

```sh
python3.12 -m unittest discover -s scripts -p "test_*.py"
# Full released CLI/host, frontend, backend/Dart and extension checks run
# locally after verified publication, using an isolated release-SSD workspace.
```

Frontend component props use the contract alias's audience-visible models
(for example, `Workspace.taskMemberCard` and `Shop.productShopper`). A query's
nullable `data` is read with optional access and explicit defaults. Gallery
collection fixtures declare their local `Task` models before using them in
typed lists. The package composition example uses neutral accessibility
metadata supported by the package reader and pins the matching export and
artifact hashes in `AxiomPackages.lock`.

`former-github-actions/` preserves the previous command recipes for reference;
these files are outside GitHub's workflow directory and cannot start Actions.
Setup steps and GitHub expressions in those recipes are historical, not a
local execution interface. Use the commands above and the controller's operator guide. Native/editor acceptance on this Mac covers macOS ARM64;
Windows and other host-platform qualification must run on those platforms.
Upstream Lynx qualification remains available through the private controller's
qualification scripts when evaluating a new engine version.
