# Dependency resolution examples

`shared/AxiomDeps.toml` declares the exact same `portable-money@1.0.0` package
for two extensions in one compatible Rust environment. The resolver downloads
and stores its immutable bytes once while preserving separate extension
instances, permissions, and audit identities.

`conflict/AxiomDeps.toml` intentionally requests `1.0.0` and `2.0.0` in that
same environment. Resolution fails with both introducing extension aliases;
Axiom never silently chooses one version. These registry URLs are illustrative,
not live package endpoints.
