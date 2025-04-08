#!/bin/bash
set -euo pipefail

NAMESPACE="renovate"
SECRET_NAME="renovate-token"
SEALED_FILE="apps/services/renovate/secret.yaml"
CONTROLLER_NAME="flux-system-sealed-secrets"
CONTROLLER_NAMESPACE="flux-system"

echo "🔐 Paste your new GitHub PAT for Renovate (scopes: repo, workflow):"
read -rs TOKEN

echo "📦 Generating Kubernetes Secret..."
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=token="$TOKEN" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml > tmp-renovate-token.yaml

echo "🔒 Sealing secret using SealedSecrets controller..."
kubeseal \
  --controller-name="$CONTROLLER_NAME" \
  --controller-namespace="$CONTROLLER_NAMESPACE" \
  --format=yaml < tmp-renovate-token.yaml > "$SEALED_FILE"

rm tmp-renovate-token.yaml

echo "✅ SealedSecret saved to $SEALED_FILE"
echo "📤 Commit and push it to apply via Flux."
