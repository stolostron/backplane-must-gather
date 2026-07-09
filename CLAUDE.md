# CLAUDE.md

@AGENTS.md

## Build commands

```bash
make docker-build  # Build must-gather image
make docker-push   # Push must-gather image
```

## Test commands

```bash
# Test collection locally
oc adm must-gather --image=quay.io/<user>/backplane-must-gather:latest

# Test specific collection script
oc adm must-gather --image=quay.io/<user>/backplane-must-gather:latest -- /usr/bin/gather_mce
```

## Local development

### Build and test

```bash
# Build image
export QUAY_USER=<your-quay-username>
make docker-build docker-push

# Run must-gather
oc adm must-gather --image=quay.io/$QUAY_USER/backplane-must-gather:latest

# Inspect output
ls -la must-gather.local.*/
tar -tzf must-gather.local.*/must-gather.tar.gz | head -20
```

### Add new collection script

```bash
# Create script
cat > collection-scripts/gather_new_component <<'EOF'
#!/bin/bash
oc get <resource> -A -o yaml > ${ARTIFACT_DIR}/new_component.yaml
EOF

# Make executable
chmod +x collection-scripts/gather_new_component

# Add to Dockerfile
echo "COPY collection-scripts/gather_new_component /usr/bin/" >> Dockerfile

# Rebuild
make docker-build
```
