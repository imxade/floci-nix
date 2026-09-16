# floci-nix

Reproducible Nix packaging for the complete stable FloCI emulator family and its stable release-image variants.

## Included packages

| Cloud / variant | Official upstream tag form | Systems | Launcher |
| --- | --- | --- | --- |
| AWS standard | `floci/floci:x.y.z` | amd64 + arm64 | `floci-aws` |
| AWS compat (AWS CLI + boto3) | `floci/floci:x.y.z-compat` | amd64 + arm64 | `floci-aws-compat` |
| AWS baseline | `floci/floci:x.y.z-baseline` | arm64 only | `floci-aws-baseline` |
| Azure | `floci/floci-az:x.y.z` | amd64 + arm64 | `floci-az` |
| GCP | `floci/floci-gcp:x.y.z` | amd64 + arm64 | `floci-gcp` |
| OCI standard | `floci/floci-oci:x.y.z` | amd64 + arm64 | `floci-oci` |
| OCI compat (OCI CLI + Python SDK) | `floci/floci-oci:x.y.z-compat` | amd64 + arm64 | `floci-oci-compat` |

The repository also packages the official `floci` CLI from its stable `floci.jar` release artifact.

Nightly and dated-nightly channels are intentionally excluded. They track development rather than stable releases and would create a substantially different reproducibility/update contract.

## Design

The package source never uses a mutable Docker tag such as `latest`.

For each of the AWS, Azure, GCP, and OCI emulator repositories, the updater:

1. queries the official GitHub Releases API;
2. selects the newest non-draft, non-prerelease plain semantic version (`x.y.z` or `vx.y.z`);
3. derives the corresponding documented stable Docker tag (`x.y.z`, `x.y.z-compat`, or `x.y.z-baseline`);
4. resolves that tag separately for each supported architecture;
5. pins the architecture-specific immutable OCI digest;
6. uses `nix-prefetch-docker` to calculate Nix's fixed-output hash for the exact image archive; and
7. stores both values in `sources-images.nix`.

The published derivation uses `dockerTools.pullImage` with the immutable digest and fixed Nix hash. The image is renamed locally to a release-and-digest-derived tag, for example:

```text
floci-nix/aws:2.0.1-sha256-0123456789abcdef
```

If an already-recorded versioned Docker tag changes digest without a new release version, the updater **fails closed** instead of silently accepting the mutation. It also detects a tag changing between registry inspection and prefetching.

The official CLI is handled similarly: the updater requires the stable release's `floci.jar` and `sha256sums.txt`, converts the upstream checksum to Nix SRI format, independently prefetches the same JAR with Nix, and requires both hashes to match. A checksum mutation under an unchanged CLI release tag fails closed.

## Why wrappers are included

The upstream CLI normally defaults to upstream image tags. The Nix launchers prevent that from weakening the package's reproducibility.

For `start` and `restart`, a launcher:

1. loads its exact Nix-store Docker archive if that image is not already present;
2. invokes the official FloCI CLI; and
3. forces `--image` to the local version-and-digest-derived image tag.

Other lifecycle/diagnostic commands are forwarded to the official CLI unchanged.

Two additional wrapper commands are provided:

```bash
floci-aws image   # print the exact pinned local Docker image name/tag
floci-aws load    # load it into Docker without starting an emulator
```

## Supported systems

- `x86_64-linux` / Docker `amd64`
- `aarch64-linux` / Docker `arm64`

AWS baseline is intentionally available only on `aarch64-linux`, matching upstream's purpose for ARM64 systems that need the baseline build.

The updater resolves and hashes every supported architecture before committing metadata. Standard GitHub-hosted CI builds the x86_64 packages and evaluates every aarch64 derivation. Local ARM64 validation additionally builds the baseline image.

## Usage

Official FloCI CLI:

```bash
nix run github:YOUR_USER/floci-nix#floci -- --version
```

Stable standard emulators:

```bash
nix run github:YOUR_USER/floci-nix#aws
nix run github:YOUR_USER/floci-nix#azure
nix run github:YOUR_USER/floci-nix#gcp
nix run github:YOUR_USER/floci-nix#oci
```

Stable compatibility images:

```bash
nix run github:YOUR_USER/floci-nix#aws-compat
nix run github:YOUR_USER/floci-nix#oci-compat
```

On ARM64, the AWS baseline build is also available:

```bash
nix run github:YOUR_USER/floci-nix#aws-baseline
```

With no arguments, each product launcher executes `start`. Arguments behave like the corresponding product-scoped FloCI CLI command:

```bash
nix run .#aws -- start --detach
nix run .#aws -- status
nix run .#aws -- env
nix run .#aws -- stop --remove

nix run .#azure -- start --persist ./azure-data
nix run .#gcp -- doctor
nix run .#oci -- setup
```

### Installing packages

```bash
nix profile install github:YOUR_USER/floci-nix#floci
nix profile install github:YOUR_USER/floci-nix#floci-aws
nix profile install github:YOUR_USER/floci-nix#floci-aws-compat
nix profile install github:YOUR_USER/floci-nix#floci-az
nix profile install github:YOUR_USER/floci-nix#floci-gcp
nix profile install github:YOUR_USER/floci-nix#floci-oci
nix profile install github:YOUR_USER/floci-nix#floci-oci-compat
```

On ARM64:

```bash
nix profile install github:YOUR_USER/floci-nix#floci-aws-baseline
```

### Immutable image archives

The Docker archives are first-class packages too:

```bash
nix build .#aws-image
nix build .#aws-compat-image
nix build .#azure-image
nix build .#gcp-image
nix build .#oci-image
nix build .#oci-compat-image
```

On ARM64:

```bash
nix build .#aws-baseline-image
```

Then, for example:

```bash
docker load --input result
```

## Automatic updates

`.github/workflows/update-floci.yml` runs automatically four times per day at:

```text
01:29, 07:29, 13:29, 19:29 UTC
```

No maintainer action is required.

Each scheduled run checks:

- the newest stable FloCI CLI release;
- the newest stable AWS emulator GitHub release;
- the newest stable Azure emulator GitHub release;
- the newest stable GCP emulator GitHub release;
- the newest stable OCI emulator GitHub release;
- every stable release image variant listed above; and
- every supported architecture for each variant.

If nothing changed, it makes no commit. Existing valid hashes are reused, so unchanged image archives are not downloaded again.

When a stable version changes, only the affected images are prefetched. The workflow commits generated metadata only after source validation, formatting, `nix flake check`, x86_64 package builds, and aarch64 evaluation succeed.

The optional `workflow_dispatch` entry is only for initial/manual diagnostics. Normal maintenance relies on the cron schedule.

## Monthly maintenance

`.github/workflows/maintenance.yml` runs on the first of each month at `05:53 UTC`. It:

- updates only the pinned `nixpkgs` flake input;
- resolves the current stable FloCI sources;
- validates/builds the repository; and
- writes `.github/.last-maintenance` only after validation succeeds.

This keeps the Nix toolchain fresh and provides periodic repository activity. GitHub is an external scheduler, so no repository can guarantee scheduled execution indefinitely.

## Bootstrap / first publication

The downloadable bootstrap archive intentionally contains fake source hashes. **Do not publish the archive in that state.**

On a NixOS machine, run:

```bash
./scripts/validate-local
```

It will create `flake.lock`, resolve all current stable releases, replace every bootstrap value, validate the source metadata, run the Nix checks, build the local-architecture packages, verify the CLI, evaluate both architectures, and check updater idempotence.

For the required Docker runtime validation before first publication:

```bash
FLOCI_RUN_DOCKER_SMOKE_TESTS=1 ./scripts/validate-local
```

The current user must have access to a working Docker daemon.

`GEMINI_FLASH_VERIFY_AND_PUBLISH.txt` contains a stricter independent audit/publish prompt intended for the same workflow used for the BrowserOS repository.

## Downstream pinning

This repository autonomously follows FloCI stable releases, but a downstream flake that consumes it will intentionally pin a specific revision in that downstream project's own `flake.lock`.

That distinction is fundamental:

```text
FloCI upstream -> this repo auto-updates -> direct nix run sees current repo HEAD
                                      \
                                       -> downstream flake remains pinned until it updates its own lock
```

## Transitive sidecar limitation

The emulator image and FloCI CLI themselves are fully pinned by this repository. Some FloCI services can dynamically launch additional containers at runtime (for example database, Kafka/Redpanda, k3s, Functions, or other service-specific helper images). Those image defaults are controlled by FloCI/upstream service configuration and may themselves use floating tags.

Therefore this repository guarantees reproducibility of the **FloCI emulator image and CLI payload**, not every transitive sidecar that a user may ask an emulator to create. Fully pinning those service-specific runtime containers would require configuring their documented image override variables or additional upstream support, and is intentionally outside the generic package wrapper.

## Scope

Included automatically maintained stable release variants:

- AWS standard
- AWS compat
- AWS ARM64 baseline
- Azure standard
- GCP standard
- OCI standard
- OCI compat
- official FloCI CLI

Excluded by design:

- floating `latest` as a package source;
- `nightly`;
- dated nightly images; and
- historical releases other than the newest stable release.

FloCI is MIT licensed. This packaging repository is also MIT licensed.
