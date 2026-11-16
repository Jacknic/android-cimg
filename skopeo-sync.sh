#!/bin/bash
set -euo pipefail

# This script syncs the built images to GitHub Container Registry (GHCR)

source ./setup-repo.sh

: "${REGISTRY_OWNER:=jacknic}"
REGISTRY_OWNER="${REGISTRY_OWNER,,}"
DEST="ghcr.io/${REGISTRY_OWNER}/"

sync_args=()
if [[ -n "${REGISTRY_USERNAME:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  sync_args+=(--dest-creds "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}")
fi

yq eval '.combiner.combinations[].name' dazzle.yaml | while read -r combination; do
  src="${REPO}:${combination}"
  if ! skopeo inspect --tls-verify=false "docker://${src}" >/dev/null 2>&1; then
    echo "::warning::Skip ${src}: image not found in local registry"
    continue
  fi
  echo "Syncing ${src} -> ${DEST}"
  skopeo sync \
    --src docker \
    --dest docker \
    --src-tls-verify=false \
    "${sync_args[@]}" \
    "${src}" \
    "${DEST}"
done
