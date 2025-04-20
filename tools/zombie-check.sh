#!/bin/bash

PURGE=$1
DATE=$(date +%Y%m%d-%H%M)
LOGFILE="zombies-$DATE.log"

GITOPS_LABEL="kustomize.toolkit.fluxcd.io/name"
RESOURCE_TYPES=("deployments" "statefulsets" "daemonsets" "services" "secrets" "configmaps" "pvc")

# Skip known valid non-GitOps resources
EXCLUDE_PATTERNS=(
  "kube-root-ca.crt"
  "sh.helm.release.v1"
  "cert-manager"
  "sealed-secrets"
  "letsencrypt-prod-key"
  "http-echo-tls"
  "longhorn"
  "vm-scrape-config"
  "infra-trivy-trivy"
  "kubernetes"
  "flux-system"
  "kustomize-controller"
  "source-controller"
  "helm-controller"
  "notification-controller"
  "sealed-secrets-key"
  "longhorn-ui"
  "csi-attacher"
  "csi-provisioner"
  "csi-resizer"
  "csi-snapshotter"
  "engine-image"
  "longhorn-csi-plugin"
  "longhorn-manager"
)

echo "💀 GitOps Zombie Sweep initiated..." | tee "$LOGFILE"
[[ "$PURGE" == "--purge" ]] && echo "🔥 PURGE MODE ENABLED" | tee -a "$LOGFILE"

kubectl get ns --no-headers -o custom-columns=":metadata.name" | while read -r NAMESPACE; do
  echo "" | tee -a "$LOGFILE"
  echo "🧭 Namespace: $NAMESPACE" | tee -a "$LOGFILE"
  for KIND in "${RESOURCE_TYPES[@]}"; do
    echo "→ Checking $KIND..." | tee -a "$LOGFILE"
    kubectl get "$KIND" -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" 2>/dev/null | while read -r NAME; do
      [[ -z "$NAME" ]] && continue

      # Skip known prefixes
      for PATTERN in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$NAME" == "$PATTERN"* ]]; then
          continue 2
        fi
      done

      # Skip owned resources
      OWNER_REF=$(kubectl get "$KIND" "$NAME" -n "$NAMESPACE" -o jsonpath="{.metadata.ownerReferences[*].kind}" 2>/dev/null)
      if [[ -n "$OWNER_REF" ]]; then
        continue
      fi

      # Skip GitOps-labeled resources
      HAS_LABEL=$(kubectl get "$KIND" "$NAME" -n "$NAMESPACE" -o jsonpath="{.metadata.labels.$GITOPS_LABEL}" 2>/dev/null)
      if [[ -z "$HAS_LABEL" ]]; then
        echo "🧟 $KIND/$NAME is a zombie" | tee -a "$LOGFILE"
        if [[ "$PURGE" == "--purge" ]]; then
          echo "💀 Deleting $KIND/$NAME..." | tee -a "$LOGFILE"
          kubectl delete "$KIND" "$NAME" -n "$NAMESPACE" >> "$LOGFILE" 2>&1
        fi
      fi
    done
  done
done

echo "" | tee -a "$LOGFILE"
echo "✅ Zombie sweep completed. Log saved to $LOGFILE" | tee -a "$LOGFILE"
[[ "$PURGE" != "--purge" ]] && echo "ℹ️  Run again with --purge to remove detected zombies." | tee -a "$LOGFILE"
