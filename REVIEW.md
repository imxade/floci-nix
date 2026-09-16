# Publication review checklist

The archive is a bootstrap repository. Complete this checklist on NixOS before publication.

- [x] `nix flake lock` created a concrete nixpkgs lock.
- [x] `nix develop -c ./scripts/update-sources` replaced every bootstrap hash/digest.
- [x] Each emulator source uses the newest stable semantic GitHub release, not `latest` or `nightly`.
- [x] AWS standard + compat are valid on amd64/arm64.
- [x] AWS baseline is valid on arm64 and is not exposed on x86_64.
- [x] Azure standard is valid on amd64/arm64.
- [x] GCP standard is valid on amd64/arm64.
- [x] OCI standard + compat are valid on amd64/arm64.
- [x] Every image digest independently matches its exact versioned upstream Docker tag.
- [x] Every image Nix hash independently matches `nix-prefetch-docker`.
- [x] FloCI CLI JAR checksum independently matches `sha256sums.txt` and Nix prefetch.
- [x] `bash -n`, ShellCheck, and actionlint pass.
- [x] `./scripts/check-sources` passes.
- [x] `nix fmt -- --check ...` passes.
- [x] `nix flake show` and both architecture evaluations pass.
- [x] `nix flake check --print-build-logs` passes.
- [x] Every local-architecture stable image/launcher builds.
- [x] Docker runtime smoke tests pass for every locally available stable variant.
- [x] Running containers use `floci-nix/...:<version>-sha256-...`, not upstream mutable tags.
- [x] Updater is idempotent.
- [x] A simulated stale/bootstrap source is correctly regenerated.
- [x] Same-version digest/checksum mutation paths fail closed.
- [x] GitHub Actions references are immutable full commit SHAs.
- [x] No credentials, local paths, result symlinks, Docker state, or downloaded archives are staged.
- [x] Push CI passes.
- [x] One-time Update FloCI dispatch passes.
- [x] One-time Monthly Maintenance dispatch passes.

The transitive-sidecar limitation documented in README is expected and is not a failure of the main package reproducibility contract.
