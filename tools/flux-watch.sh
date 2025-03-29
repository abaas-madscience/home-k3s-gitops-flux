#!/bin/bash

set -e

NAME="$1"
NAMESPACE="${2:-default}"
RESOURCE="${3:-helmrelease}"

if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <name> [namespace] [resource-type]"
  echo "Example: $0 my-app my-namespace helmrelease"
  exit 1
fi

echo "⏳ Waiting for $RESOURCE/$NAME in $NAMESPACE to become Ready..."

while true; do
  STATUS=$(kubectl get "$RESOURCE" "$NAME" -n "$NAMESPACE" -o jsonpath="{.status.conditions[?(@.type=='Ready')].status}" 2>/dev/null || echo "")
  [[ "$STATUS" == "True" ]] && break
  sleep 1
done

echo "✅ $RESOURCE/$NAME is Ready. Launching k9s in $NAMESPACE..."
sleep 1
k9s -n "$NAMESPACE"
