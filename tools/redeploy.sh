#!/usr/bin/env bash
set -euo pipefail

echo "🧨 Uninstalling existing K3s (if any)..."
# Uninstall K3s and K3s agent
/usr/local/bin/k3s-uninstall.sh || true
/usr/local/bin/k3s-agent-uninstall.sh || true

echo "🧼 Cleaning up old data..."
# Fully remove any K3s-related files and directories, including Longhorn volumes
sudo rm -rf /etc/rancher/k3s /var/lib/rancher/k3s ~/.kube/config ~/.kube/
sudo rm -rf /var/lib/longhorn /var/lib/longhorn/*
sudo systemctl stop longhorn-manager.service || true
sudo systemctl disable longhorn-manager.service || true
sudo rm -rf /etc/systemd/system/longhorn-manager.service || true

echo "🚀 Installing fresh K3s..."
# Reinstall K3s
curl -sfL https://get.k3s.io | sh -

echo "📂 Setting up kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "✅ Verifying cluster is up..."
# Wait for the cluster to be ready
until kubectl get nodes &>/dev/null; do
  echo "Waiting for Kubernetes API..."
  sleep 2
done

echo "🧠 Bootstrapping Flux..."
# Bootstrap Flux and link to your Git repository
export GITHUB_TOKEN=ghp_your_token_here
flux bootstrap github \
  --owner=abaas-madscience \
  --repository=home-k3s-gitops-flux \
  --branch=main \
  --path=clusters/lab \
  --personal \
  --token-auth

echo "🎉 Done! GitOps is live."
