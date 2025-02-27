# Copyright (c) 2021 Red Hat, Inc.
# Copyright Contributors to the Open Cluster Management project

FROM quay.io/openshift/origin-cli:4.20 as builder

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

ENV BASE_COLLECTION_PATH=/must-gather \
    USER_UID=1001 \
    USER_NAME=must-gather

RUN microdnf install -y jq tar gzip rsync findutils

# Copy binaries
COPY --from=builder /usr/bin/oc /usr/bin/oc

# copy all collection scripts to /usr/bin
COPY collection-scripts/* /usr/bin/

# Setup non-root user
COPY build/user_setup /usr/local/bin/
RUN  /usr/local/bin/user_setup
USER 1001

ENTRYPOINT /usr/bin/gather

LABEL name="multicluster-engine/must-gather-rhel9"
LABEL summary="Must-gather scripts for Red Hat multicluster engine for Kubernetes"
LABEL description="Must-gather scripts for Red Hat multicluster engine for Kubernetes"
LABEL io.k8s.display-name="MCE Must-gather"
LABEL io.k8s.description="Must-gather scripts for Red Hat multicluster engine for Kubernetes"
LABEL com.redhat.component="backplane-must-gather-container"
LABEL io.openshift.tags="data,images"
