#!/usr/bin/env bash
# Renders the cert-manager Helm chart to manifests/bundle.yaml.
# Re-run to update when bumping VERSION or changing values.yaml.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="v1.20.0"

helm repo add jetstack https://charts.jetstack.io --force-update >/dev/null
helm repo update jetstack >/dev/null

helm template cert-manager jetstack/cert-manager \
  --version "${VERSION}" \
  --namespace cert-manager \
  --include-crds \
  -f "${SCRIPT_DIR}/values.yaml" \
  > "${SCRIPT_DIR}/../manifests/bundle.yaml"

echo "Rendered cert-manager ${VERSION} → manifests/bundle.yaml"
