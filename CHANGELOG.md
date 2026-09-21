# Changelog

All notable changes to this project are documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/) with **image-impact
semantics**: PATCH for docs and in-place tweaks with no tool changes, MINOR
for added tools or dotfiles, MAJOR for removed/renamed tools or a base image
change. `make release-check` prints the same three lines against the current
`VERSION`.

Add entries under `[Unreleased]` as you work. Do not edit the version headings
by hand: `make release-<level>` renames `[Unreleased]` to the new version and
re-seeds an empty `[Unreleased]` block above it.

`[Unreleased]` is for *changes since the last release only*.

This changelog is the **only** place in the repo that records dated history or
release state. `README.md` describes how to build and run the image, never
what is currently published. Keep it that way: status notes rot, and a reader
who trusts one plans from a false premise.

## [Unreleased]

### Added

### Changed

### Fixed

- `README.md`: repaired the license and AI-assisted badges, which had a
  stray line break splitting `[![...]` and so rendered as raw text instead
  of clickable images.
- `README.md`: fixed the AI Disclaimer link, which pointed to the
  misspelled `azure-nettols` repo.

## [0.0.5] - 2026-09-20

### Added

### Changed

### Fixed

- `Dockerfile`: renamed the `VERSION` build arg to `APP_VERSION` to match
  what the `publish-acr-image` reusable CI action actually passes. The
  mismatch meant the arg was silently ignored, so every image built via
  `build-deploy.yml` carried the `0.0.0` default in its motd and OCI
  `image.version` label regardless of the real release version.
- `bashrc`: check for `TERM=dumb`, not just unset/empty, before defaulting
  it. Bash itself sets `TERM=dumb` before `.bashrc` runs when none is
  supplied (as in an `az containerapp exec` session), so the previous
  `: "${TERM:=xterm}"` fix never fired and `tput` still failed.

## [0.0.4] - 2026-09-20

### Added

### Changed

- `motd`/`Dockerfile`: the motd now shows the image `VERSION`, substituted
  at build time in place of a `{{VERSION}}` placeholder.

### Fixed

## [0.0.3] - 2026-09-20

### Added

### Changed

### Fixed

- `bashrc`: default `TERM` to `xterm` when unset before the color-support
  check. `az containerapp exec` sessions can leave `TERM` unset or `dumb`,
  which made `tput` fail to resolve color capabilities and print a
  misleading "missing /usr/bin/tput" message even though it was installed.

## [0.0.2] - 2026-09-20

### Added

### Changed

### Fixed

- `Dockerfile`: changed `CMD` from `/bin/bash` to `sleep infinity`. Bash
  exited immediately with no TTY at container start, causing a
  `CrashLoopBackOff` that broke `az containerapp exec`.

## [0.0.1] - 2026-09-20

### Added

- `.github/workflows/aca-create.yml`: provisions the Azure Container App
  estate via the reusable `azure-iac` workflow.
- `.github/workflows/aca-destroy.yml`: destroys the container apps module via
  the reusable `azure-iac` workflow.
- `.github/workflows/build-deploy.yml`: builds and pushes the `nettools`
  image to Azure Container Registry, then updates the Azure Container App.
- `scripts/initvars.sh`: resets this repository's GitHub Actions variables
  and secrets from the shell environment.
- `.github/workflows/release.yml`: verifies a pushed `vX.Y.Z` tag against
  VERSION and CHANGELOG.md, then publishes a GitHub Release.
- `Makefile`: `release-check`/`release-patch`/`release-minor`/`release-major`/
  `release-tag`/`release-push` targets to bump VERSION, roll the changelog,
  and cut a release tag.

### Changed

- `.github/workflows/build-verify.yml`: pins `hadolint/hadolint-action` to
  `v3.1.0`.

### Fixed

- `Dockerfile`: suppressed the intentional hadolint `DL3008` finding on the
  unpinned `apt-get install`, which was failing `build-verify`.
- `Dockerfile`: added `bsdextrautils`, which provides `column` on Debian
  trixie now that it has moved out of `util-linux`; `build-verify` was
  failing on the missing binary.

### Removed
