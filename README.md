# 🚀 home-k3s-gitops-flux

Welcome to the **GitOps** repository for managing your Kubernetes cluster with **Flux**! 🎉

This is a major work in progress and it changes over time.

For now take what you can out of it. it is my living and breathing home network :-)

---

## 📂 Repository Structure

Here's how the repository is organized:

```
.
├── apps
│   ├── services
│   │   ├── http-echo
│   │   ├── renovate
│   │   └── whoami
│   └── system
├── bootstrap
│   └── flux-system
├── clusters
│   └── lab
├── infrastructure
│   ├── cert-manager
│   ├── metallb
│   ├── rancher
│   ├── sealed-secrets
│   └── traefik
├── tools
├── kustomization.yaml
├── LICENSE
└── README.md
```

---

## 🛠️ Setting Up Flux

TODO: This is done through ansible after terraforming the cluster
Check out my other repos for that in the meantime

### 1️⃣ Generate PAT Token in Github

Here: https://github.com/settings/tokens

## 🔍 Debugging & Logs

### Check Logs
```bash
kubectl logs -n flux-system deploy/kustomize-controller -f
```

### Get Kustomizations
```bash
flux get kustomizations
flux get kustomizations -A -w
```

### Reconcile the Entire Cluster
```bash
flux reconcile kustomization flux-system --with-source
```

### Helm Sources
```bash
flux get sources helm rancher-dev -n flux-system
flux get helmreleases -n cattle-system
flux logs --level=error --kind=HelmRelease --name=rancher -n cattle-system
```

---

## 🛠️ Tools

### Flux validate charts
```bash
tools/flux-validate-chart.sh bitnami sealed-secrets

```

### Flux Watch Script
```bash
chmod +x flux-watch.sh
./flux-watch.sh my-app my-namespace helmrelease
```

### Alias for Debugging
```bash
alias fluxdebug='k9s -n flux-system'
```

### Curl Pod for testing
```bash
kubectl run curlpod --rm -it --image=curlimages/curl --restart=Never -- sh
```

---

## 🔐 Managing Secrets

### Create a Secret
```bash
kubectl create secret generic renovate-token \
  --from-literal=token=ghp_...your_new_pat_here... \
  --namespace=renovate \
  --dry-run=client -o yaml > renovate-token.yaml
```

### Seal the Secret
```bash
kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  --format=yaml < renovate-token.yaml > apps/services/renovate/secret.yaml
```

Or use the script:
```bash
tools/pat_token.sh
```

---

## 🧹 Pre-Commit Hook

Add the following pre-commit hook to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "🔍 Checking for unsealed secrets and sensitive content..."

# 1. Block unsealed secret filenames
if git diff --cached --name-only | grep -E '.*secret.*\.ya?ml' | grep -v 'sealed'; then
  echo "❌ Unsealed secret file detected in staged files!"
  echo "👉 Use SealedSecrets before committing."
  exit 1
fi

# 2. Check for dangerous content in staged lines
MATCHES=$(git diff --cached | grep -Ei 'token:|password:|secret:' | grep -vE '^\+?\s*#')

if [[ -n "$MATCHES" ]]; then
  echo "❌ Potential sensitive content detected in staged changes:"
  echo "$MATCHES"
  echo "👉 Remove or seal before committing."
  exit 1
fi

echo "✅ All clear. Commit allowed."
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## 📊 Monitoring

- **Grafana** 📈
- **VictoriaMetrics (VM)** 📊
- **Loki** 🔍

---

🎉 **Happy GitOps-ing!** 🚀


