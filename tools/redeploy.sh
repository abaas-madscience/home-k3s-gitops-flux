#!/bin/bash
#!/usr/bin/env bash
set -euo pipefail

echo "🧨 Uninstalling existing K3s (if any)..."
/usr/local/bin/k3s-uninstall.sh || true
/usr/local/bin/k3s-agent-uninstall.sh || true

echo "🧼 Cleaning up old data..."
sudo rm -rf /etc/rancher/k3s /var/lib/rancher/k3s ~/.kube/config ~/.kube/

echo "🚀 Installing fresh K3s..."
curl -sfL https://get.k3s.io | sh -

echo "📂 Setting up kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "✅ Verifying cluster is up..."
until kubectl get nodes &>/dev/null; do
  echo "Waiting for Kubernetes API..."
  sleep 2
done

echo "🧠 Bootstrapping Flux..."
export GITHUB_TOKEN=ghp_your_token_here
flux bootstrap github \
  --owner=abaas-madscience \
  --repository=home-k3s-gitops-flux \
  --branch=main \
  --path=clusters/lab \
  --personal \
  --token-auth

echo "🎉 Done! GitOps is live."
