# Declarative package dependencies

This example pins a theme and a component library for Android, iOS, and Web.
`AxiomDeps.toml` declares the packages, `AxiomPackages.lock` records their
exact contents, and `main.acore` consumes them. The `.axiom` package files are
small data-only examples, not executable binaries.

Use a compatible CLI's package resolve and verify commands before building the
application for a target platform.
