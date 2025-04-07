#!/usr/bin/env bash
set -euo pipefail

# === Config ===
ENV_FILE=".env"
REPO_OWNER="abaas-madscience"
REPO_NAME="home-k3s-gitops-flux"
REPO_BRANCH="main"
REPO_PATH="clusters/lab"
NODE_IP="192.168.178.2"  # Set you own ip

# === Dependency Checks ===
if [[ ! -f $ENV_FILE ]]; then
  echo "❌ Missing .env file with GITHUB_TOKEN"
  exit 1
fi

source $ENV_FILE

if ! command -v hostname &>/dev/null && ! command -v ip &>/dev/null; then
  echo "❌ Missing required commands: 'hostname' or 'ip'"
  echo "🔧 Install with: sudo pacman -S inetutils iproute2"
  exit 1
fi

echo "🌐 Detected node IP: $NODE_IP"

# === Cleanup Phase ===
echo "🧨 Uninstalling K3s..."
/usr/local/bin/k3s-uninstall.sh || true
/usr/local/bin/k3s-agent-uninstall.sh || true

echo "🧼 Removing residual data..."
sudo rm -rf /etc/rancher/k3s /var/lib/rancher/k3s ~/.kube/config ~/.kube/
sudo rm -rf /var/lib/longhorn /var/lib/longhorn/*
sudo systemctl stop longhorn-manager.service || true
sudo systemctl disable longhorn-manager.service || true
sudo rm -rf /etc/systemd/system/longhorn-manager.service || true

# === K3s Install ===
echo "🚀 Installing fresh K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --disable local-storage" sh -

# === Wait for kubeconfig & certs ===
echo "⏳ Waiting for K3s to generate kubeconfig and certs..."
until [ -f /etc/rancher/k3s/k3s.yaml ]; do
  sleep 2
done

# === Configure Kubeconfig ===
echo "📂 Setting up kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Replace 127.0.0.1 with real IP
sed -i "s/127.0.0.1/$NODE_IP/" ~/.kube/config
export KUBECONFIG=~/.kube/config

# === Wait for Ready node ===
echo "✅ Waiting for node to be Ready..."
until kubectl get nodes | grep -q "Ready"; do
  sleep 2
done

# === GitOps Bootstrap ===
echo "🧠 Bootstrapping Flux from Git..."
flux bootstrap github \
  --owner="$REPO_OWNER" \
  --repository="$REPO_NAME" \
  --branch="$REPO_BRANCH" \
  --path="$REPO_PATH" \
  --personal \
  --token-auth

echo "🎉 Done. Your GitOps cluster is live and clean."
