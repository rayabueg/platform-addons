#!/usr/bin/env bash
# Renders all four Istio Helm charts to manifests/bundle.yaml.
# Istio is split into four charts; they are concatenated into one bundle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="1.24.3"

helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update >/dev/null
helm repo update istio >/dev/null

{
  helm template istio-base istio/base \
    --version "${VERSION}" \
    --namespace istio-system \
    --include-crds

  helm template istiod istio/istiod \
    --version "${VERSION}" \
    --namespace istio-system \
    -f "${SCRIPT_DIR}/values-istiod.yaml"

  helm template istio-cni istio/cni \
    --version "${VERSION}" \
    --namespace istio-system \
    -f "${SCRIPT_DIR}/values-cni.yaml"

  helm template ztunnel istio/ztunnel \
    --version "${VERSION}" \
    --namespace istio-system
} > "${SCRIPT_DIR}/../manifests/bundle.yaml"

echo "Rendered istio ${VERSION} (base + istiod + cni + ztunnel) → manifests/bundle.yaml"
