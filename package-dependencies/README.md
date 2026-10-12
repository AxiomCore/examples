# Declarative package dependencies

This example pins a theme and a component library for Android, iOS, and Web.
`AxiomDeps.toml` declares the packages, `AxiomPackages.lock` records their
exact contents, and `main.acore` consumes them. The `.axiom` package files are
small data-only examples, not executable binaries.

`Card` is a passive composition fixture with a checked required `String` prop.
Its schema has neutral accessibility metadata because non-neutral roles and
labels are not yet lowered by the package execution path. It does not render
the prop as content; its composition schema has no property-binding surface.

Use a compatible CLI's package resolve and verify commands before building the
application for a target platform.
