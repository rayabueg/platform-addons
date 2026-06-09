#!/usr/bin/env bash
# Renders the external-dns Helm chart to manifests/bundle.yaml.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VERSION="1.20.0"

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ --force-update >/dev/null
helm repo update external-dns >/dev/null

helm template external-dns external-dns/external-dns \
  --version "${VERSION}" \
  --namespace external-dns \
  -f "${SCRIPT_DIR}/values.yaml" \
  > "${SCRIPT_DIR}/../manifests/bundle.yaml"

echo "Rendered external-dns ${VERSION} → manifests/bundle.yaml"
