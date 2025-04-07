#!/usr/bin/env bash
set -euo pipefail

# Load secrets
if [[ -f .env ]]; then
  source .env
else
  echo "❌ .env file missing! Please create it with your GitHub token."
  exit 1
fi

echo "🧨 Uninstalling existing K3s (if any)..."
/usr/local/bin/k3s-uninstall.sh || true
/usr/local/bin/k3s-agent-uninstall.sh || true

echo "🧼 Cleaning up old K3s data and Longhorn volumes..."
sudo rm -rf /etc/rancher/k3s /var/lib/rancher/k3s ~/.kube/config ~/.kube/
sudo rm -rf /var/lib/longhorn /var/lib/longhorn/*
sudo systemctl stop longhorn-manager.service || true
sudo systemctl disable longhorn-manager.service || true
sudo rm -rf /etc/systemd/system/longhorn-manager.service || true

echo "🚀 Installing fresh K3s (minimal mode)..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --disable local-storage" sh -

echo "📂 Waiting for kubeconfig and TLS certs to be ready..."
until [ -f /etc/rancher/k3s/k3s.yaml ] && \
      curl --cacert /etc/rancher/k3s/server/tls/server-ca.crt https://127.0.0.1:6443/version &>/dev/null; do
  echo "Waiting for K3s to finish initializing..."
  sleep 2
done

echo "🔐 Configuring kubeconfig access..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
chmod 600 ~/.kube/config

# Replace localhost in kubeconfig with actual IP so Flux can talk to it
IP=$(hostname -I | awk '{print $1}')
sed -i "s/127.0.0.1/$IP/" ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "✅ Waiting for node to become Ready..."
until kubectl get nodes | grep -q "Ready"; do
  sleep 2
done

echo "🧠 Bootstrapping Flux into GitOps mode..."
# Put your token in env or securely load it from somewhere
flux bootstrap github \
  --owner=abaas-madscience \
  --repository=home-k3s-gitops-flux \
  --branch=main \
  --path=clusters/lab \
  --personal \
  --token-auth

echo "🎉 Done! K3s is rebuilt and GitOps is live."
