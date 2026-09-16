# Publication review checklist

The archive is a bootstrap repository. Complete this checklist on NixOS before publication.

- [ ] `nix flake lock` created a concrete nixpkgs lock.
- [ ] `nix develop -c ./scripts/update-sources` replaced every bootstrap hash/digest.
- [ ] Each emulator source uses the newest stable semantic GitHub release, not `latest` or `nightly`.
- [ ] AWS standard + compat are valid on amd64/arm64.
- [ ] AWS baseline is valid on arm64 and is not exposed on x86_64.
- [ ] Azure standard is valid on amd64/arm64.
- [ ] GCP standard is valid on amd64/arm64.
- [ ] OCI standard + compat are valid on amd64/arm64.
- [ ] Every image digest independently matches its exact versioned upstream Docker tag.
- [ ] Every image Nix hash independently matches `nix-prefetch-docker`.
- [ ] FloCI CLI JAR checksum independently matches `sha256sums.txt` and Nix prefetch.
- [ ] `bash -n`, ShellCheck, and actionlint pass.
- [ ] `./scripts/check-sources` passes.
- [ ] `nix fmt -- --check ...` passes.
- [ ] `nix flake show` and both architecture evaluations pass.
- [ ] `nix flake check --print-build-logs` passes.
- [ ] Every local-architecture stable image/launcher builds.
- [ ] Docker runtime smoke tests pass for every locally available stable variant.
- [ ] Running containers use `floci-nix/...:<version>-sha256-...`, not upstream mutable tags.
- [ ] Updater is idempotent.
- [ ] A simulated stale/bootstrap source is correctly regenerated.
- [ ] Same-version digest/checksum mutation paths fail closed.
- [ ] GitHub Actions references are immutable full commit SHAs.
- [ ] No credentials, local paths, result symlinks, Docker state, or downloaded archives are staged.
- [ ] Push CI passes.
- [ ] One-time Update FloCI dispatch passes.
- [ ] One-time Monthly Maintenance dispatch passes.

The transitive-sidecar limitation documented in README is expected and is not a failure of the main package reproducibility contract.
