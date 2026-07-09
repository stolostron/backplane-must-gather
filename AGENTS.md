# backplane-must-gather — Agent Instructions

This repository contains the must-gather tool for debugging RHACM/MCE installations.

## What this tool does

The backplane-must-gather collects diagnostic data from MCE/RHACM clusters for troubleshooting:

- Multicluster Engine (MCE) operator logs and resources
- Cluster lifecycle components (Hive, assisted-service)
- Managed cluster resources and status
- Addon configurations and status
- System-level diagnostics (events, node info, operator logs)

## Repository layout

- `collection-scripts/` - Data collection scripts (organized by component)
- `must-gather` - Main entry point script
- `Dockerfile` - Must-gather image Dockerfile
- `hack/` - Build and development scripts

## Usage

### Collect must-gather data

```bash
# Using oc adm must-gather
oc adm must-gather --image=quay.io/stolostron/backplane-must-gather:latest

# Output saved to must-gather.local.<timestamp>/
```

### Collect specific components

```bash
# Gather only MCE operator data
oc adm must-gather --image=quay.io/stolostron/backplane-must-gather:latest -- /usr/bin/gather_mce

# Gather cluster lifecycle data
oc adm must-gather --image=quay.io/stolostron/backplane-must-gather:latest -- /usr/bin/gather_clc
```

## Dependencies

- **OpenShift CLI (oc)** - Must-gather framework
- **jq** - JSON parsing in collection scripts
- **bash** - Collection script runtime

## Documentation

- [Must-Gather Usage Guide](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Debugging MCE Issues](docs/)
- [Collection Scripts Reference](collection-scripts/README.md)

## Common tasks

### Build must-gather image

```bash
# Build image
make docker-build

# Push to registry
export QUAY_USER=<your-quay-username>
make docker-push
```

### Test collection locally

```bash
# Run must-gather with local image
oc adm must-gather --image=quay.io/$QUAY_USER/backplane-must-gather:latest

# Inspect collected data
ls -la must-gather.local.*/
```

### Add new collection script

```bash
# Create script under collection-scripts/
vi collection-scripts/gather_new_component

# Make executable
chmod +x collection-scripts/gather_new_component

# Rebuild image
make docker-build
```
