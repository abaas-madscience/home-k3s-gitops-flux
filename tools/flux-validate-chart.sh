#!/bin/bash
set -e

REPO_NAME="$1"
CHART_NAME="$2"

if [[ -z "$REPO_NAME" || -z "$CHART_NAME" ]]; then
  echo "Usage: $0 <repo-name> <chart-name>"
  echo "Example: $0 bitnami sealed-secrets"
  exit 1
fi

echo "📡 Fetching available versions of '$CHART_NAME' from Helm repo '$REPO_NAME'..."

helm repo add "$REPO_NAME" "https://charts.$REPO_NAME.com/$REPO_NAME" 2>/dev/null || true
helm repo update > /dev/null

helm search repo "$REPO_NAME/$CHART_NAME" --versions | head -n 10
