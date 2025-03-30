#!/bin/bash
set -e

NAMESPACE="renovate"
SECRET_NAME="renovate-token"
SEALED_FILE="apps/services/renovate/secret.yaml"

echo "🔐 Paste your GitHub PAT:"
read -rs TOKEN

echo "📦 Generating Kubernetes Secret..."
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=token="$TOKEN" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml > tmp-secret.yaml

echo "🧪 Sealing secret with kubeseal..."
kubeseal \
  --controller-name=kube-system-sealed-secrets \
  --controller-namespace=kube-system \
  --format=yaml < tmp-secret.yaml > "$SEALED_FILE"

rm tmp-secret.yaml
echo "✅ SealedSecret saved to $SEALED_FILE"
echo "📤 Commit & push to deploy."
