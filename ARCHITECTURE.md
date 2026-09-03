# Architecture: backplane-must-gather

## Overview

`backplane-must-gather` is a diagnostic data-collection tool ("must-gather")
for MultiCluster Engine (MCE), a.k.a. "the backplane." It packages a set of
shell scripts into a container image invoked by `oc adm must-gather` to
collect key resources, namespaces, logs, and custom resources from an
OpenShift cluster running MCE, to aid debugging and support.

This repository is a **subset of the ACM `stolostron/must-gather`
repository** — changes in either repo are intended to be mirrored to the
other. The published image is `quay.io/stolostron/backplane-must-gather`
(community) with a productized Konflux-built counterpart per MCE release
line.

The collection script is environment-aware: it detects at runtime whether it
is running against a **hub** (where the Backplane/MCE operator lives) or a
**managed/spoke** cluster, and adjusts what it collects accordingly,
including special handling for HyperShift-hosted clusters.

## Repository Structure

| Path | Purpose |
|------|---------|
| `README.md` | Usage, invocation examples, description of collected data. |
| `Dockerfile` | Community/upstream image build (`origin-cli` + UBI9 minimal). |
| `collection-scripts/` | The must-gather logic: `gather` (entrypoint) and `mce-gather.sh` (main script). |
| `build/` | Downstream (Konflux) build assets: `Dockerfile.rhtap`, `user_setup`, RPM lockfiles for hermetic builds. |
| `.tekton/` | Konflux PipelineRun definitions (pull-request + push) per MCE release branch. |
| `.github/workflows/` | ShellCheck lint on scripts; `OWNERS` file resync across release branches. |
| `Makefile.prow` | Thin include of the Prow build-harness Makefile. |
| `COMPONENT_NAME` | Component identifier: `backplane-must-gather`. |
| `OWNERS`, `CONTRIBUTING.md`, `DCO`, `LICENSE`, `SECURITY.md` | Governance and contribution docs. |

## Core Components

### Entrypoint chain

`Dockerfile`/`Dockerfile.rhtap` `ENTRYPOINT` → `/usr/bin/gather`, which is a
minimal shim (`collection-scripts/gather`) that sources
`collection-scripts/mce-gather.sh`, the main collection logic.

### `mce-gather.sh` — detection and collection functions

- **Detection**: `check_if_hub()` (via the `multiclusterengines.multicluster.openshift.io` CR and `control-plane=backplane-operator` pod label), `check_if_spoke()` (via the `klusterlets.operator.open-cluster-management.io` CRD), `check_if_hypershift()` (via `hosted-cluster-name=`/`hosted-cluster-namespace=` args).
- **`check_managed_clusters()`**: lists `managedclusters`, inspects each managed-cluster namespace for Hive-related debugging.
- **`gather_hub()`**: the bulk of hub-side collection — pod lists, CSVs, and `oc adm inspect` calls across MCE, OLM, Hive, metal3, OCM (cluster/addon/placement/work), discovery, klusterletconfigs, TALM, and Assisted-Installer API groups.
- **`gather_spoke()`**: inspects klusterlets, clusterclaims, addon and agent namespaces on a managed/spoke cluster.
- **`extract_hypershift_cli()` / `dump_hostedcluster()`**: extracts the `hypershift` CLI from a running pod and dumps hosted-cluster diagnostics (management + guest cluster, secrets excluded).
- **`gather_service_and_event_logs_for_failed_agents()`**: pulls logs/events for failed `agentclusterinstalls`.

### Main flow

`check_if_hub; check_if_spoke; check_if_hypershift "$@"`, then dispatches to
`gather_hub`/`dump_hostedcluster` (hub) or `gather_spoke` (spoke).

## Data / Control Flow

1. An operator/support engineer runs `oc adm must-gather --image=quay.io/stolostron/backplane-must-gather:<tag>` (optionally passing an explicit entrypoint and `hosted-cluster-*` args for HyperShift clusters).
2. `oc adm must-gather` starts a pod from the image; its entrypoint runs `gather` → `mce-gather.sh`.
3. The script writes collected YAML/logs under `/must-gather` (with a fallback path if that location is read-only), detecting hub/spoke/hypershift context first.
4. `oc adm must-gather` copies `/must-gather` back to the client (or a specified `--dest-dir`), which can then be tarred and shared.

## Build, Test & Release

- **Two Dockerfiles**: root `Dockerfile` for the community/upstream image (`origin-cli` builder → UBI9 minimal runtime); `build/Dockerfile.rhtap` for hermetic, multi-arch, productized Konflux builds (adds CPE label for automated security scanning).
- **Hermetic build inputs** (`build/rpms.in.yaml`, `build/rpms.lock.yaml`): pinned RPM lockfiles for `jq`, `tar`, `gzip`, `rsync`, `findutils` across four architectures, refreshed automatically.
- **Konflux/Tekton** (`.tekton/`): PipelineRuns gated on `target_branch == "backplane-<X.Y>"`; multi-arch (`x86_64`, `ppc64le`, `s390x`, `arm64`) on push, `x86_64`-only on PR; pipeline definition resolved remotely from `stolostron/konflux-build-catalog`.
- **GitHub Actions**: ShellCheck lint on `collection-scripts/*` for PRs to `main` and `backplane-[0-9]+.[0-9]+`; automated `OWNERS` file resync from `main` to release branches.
- **Non-root, minimal image**: UBI9-minimal, runs as a dedicated non-root user created by `build/user_setup`.

## Dependencies & Integrations

- **Base images**: OpenShift CLI image (community: `origin-cli`; downstream: `ose-cli-rhel9`) for the builder stage; `ubi9/ubi-minimal` for runtime.
- **CLI tools**: `oc` (primary), plus `jq`, `tar`, `gzip`, `rsync`, `findutils`, `yq`, `curl`; the `hypershift` binary is extracted at runtime rather than baked into the image.
- **Runtime integration point**: OpenShift's `oc adm must-gather` framework.
- **Related repos/components**: `stolostron/must-gather` (ACM superset, mirrored); `backplane-operator` and the `MultiClusterEngine` CR (detected at runtime); Hive, HyperShift, Assisted-Installer, metal3, and OCM subsystems (all inspected); `stolostron/konflux-build-catalog` for shared pipelines.

## Conventions & Patterns

- **Release branches**: `backplane-<major.minor>` (one per MCE release line); `main` tracks the current development line.
- **Two-Dockerfile pattern**: upstream/community vs. hermetic/productized Konflux build.
- **Mirroring convention**: kept in sync with `stolostron/must-gather` (the ACM superset of this repo).
- **Contribution conventions**: Apache 2.0, mandatory DCO sign-off, issue-then-PR workflow, `OWNERS`-based approval, ShellCheck lint gate.
- **OWNERS propagation**: maintained on `main`, automatically synced to release branches.
