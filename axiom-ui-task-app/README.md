# Acore UI task-app compiler fixture

This is a compiler fixture, not a generated mobile project. It uses the
contract built by `../ui-interaction-demos/04-contract-tasks/backend` rather
than a synthetic lock that cannot be verified by the current CLI.

Run the virtual-only compiler check:

~~~~sh
cd ../ui-interaction-demos/04-contract-tasks/backend
axiom build axiom.acore
cd ../../../axiom-ui-task-app
axiom run main.acore --target web --once
~~~~

The compile-only command emits diagnostics or a graph revision without
opening a browser or simulator. Omit `--once` to serve the web app; add
`--launch` only when you want the browser opened automatically.
