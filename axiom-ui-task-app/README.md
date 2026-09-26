# Acore UI task-app compiler fixture

This is a compiler fixture, not a generated mobile project. Its lock
contains a synthetic, structurally valid signed-contract identity so the UI
compiler can exercise the locked facade boundary without contacting a backend.

Run the virtual-only compiler check:

~~~~sh
axiom ui check main.acore --lock axiom.ui.lock.json --target ios
~~~~

The command emits diagnostics or a graph revision and never writes ReactLynx,
CSS, UI IR, facade, or package files into this directory. A real iOS/Android
Lynx host execution requires the separately deferred native-host fixture.
