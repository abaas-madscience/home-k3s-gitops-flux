# 🚀 home-k3s-gitops-flux

Welcome to the **GitOps** repository for managing your Kubernetes cluster with **Flux**! 🎉

This repository is a living and breathing setup for my home network, evolving over time. Take what you can and enjoy the journey! 🌟

---

## 🛠️ Setting Up Flux

Follow the installation for your operating system, then

### 1 Generate PAT Token in GitHub

Generate a Personal Access Token (PAT) here: [GitHub Tokens](https://github.com/settings/tokens)

### 2 Automate Setup with Ansible

The setup is automated using Ansible after Terraform provisions the cluster. Check out my other repositories for details on this process.

### 3 Bootstap Flux 

```bash
flux bootstrap github \
  --owner=abaas-madsciende \
  --repository=home-k3s-gitops-flux \
  --branch=main \
  --path=clusters/lab \
  --personal \
  --token-auth

```

---

## 🔍 Debugging & Logs

### Common Commands

- **Delete repo in namespace **
  ``bash
  kubectl delete helmrepository longhorn -n longhorn-system
  ``

- **Check Flux Logs:**
  ```bash
  flux logs -f --namespace=flux-system
  ```

- **Check Kustomizations:**
  ```bash
  flux get kustomizations -A -w
  ```
- **Check Stateful sets: **
  ```bash
    kubectl describe statefulset monitoring-infra-victoria-logs-victoria-logs-single-server -n monitoring
  ```

- **Reconcile:**
  ```bash
  flux reconcile kustomization flux-system --with-source
  ```

- **Check HelmRelease Status:**
  ```bash
  kubectl describe helmrelease <release-name> -n <namespace>
  ```

- **Check Controller Logs:**
  ```bash
  kubectl -n flux-system logs deployment/<controller-name>
  ```

- **Kick off Renovate Manually:**
  ```bash
  kubectl create job --from=cronjob/renovate renovate-manual-run -n renovate
  ```

- **Check Renovate Logs:**
  ```bash
  kubectl logs -n renovate deploy/renovate
  ```

---

## 🛠️ Tools

### Scripts for Common Tasks

- **Validate Charts:**
  ```bash
  tools/flux-validate-chart.sh <chart-name>
  ```

- **Watch Flux Resources:**
  ```bash
  chmod +x tools/flux-watch.sh
  ./tools/flux-watch.sh <resource-name> <namespace> <resource-type>
  ```

- **Seal Secrets:**
  ```bash
  tools/seal-renovate-token.sh
  ```

### Debugging Aliases

- **Alias for Flux Debugging:**
  ```bash
  alias fluxdebug='k9s -n flux-system'
  ```

- **Curl Pod for Testing:**
  ```bash
  kubectl run curlpod --rm -it --image=curlimages/curl --restart=Never -- sh
  ```

- **BusyBox Pod for Testing:**
  ```bash
  kubectl run -it --rm --restart=Never busybox -n flux-system --image=busybox
  ```

---

## 🔐 Managing Secrets

### Sealing Secrets

Use the provided script to seal secrets:
```bash
./tools/seal-renovate-token.sh
```

---

## 🧹 Pre-Commit Hook

Add the following pre-commit hook to `.git/hooks/pre-commit` to prevent committing unsealed secrets or sensitive content:

```bash
#!/bin/bash

echo "🔍 Checking for unsealed secrets and sensitive content..."

# Block unsealed secret filenames
if git diff --cached --name-only | grep -E '.*secret.*\.ya?ml' | grep -v 'sealed'; then
  echo "❌ Unsealed secret file detected in staged files!"
  echo "👉 Use SealedSecrets before committing."
  exit 1
fi

# Check for sensitive content in staged lines
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
- **VictoriaLogs** 🔍
- **Promtail** 🔍

---

🎉 **Happy GitOps-ing!** 🚀


