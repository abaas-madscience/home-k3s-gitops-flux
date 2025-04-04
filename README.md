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

### Check charts
kubectl -n flux-system logs deployment/flux-controller


2. Check HelmRelease Status
```
kubectl get helmrelease kube-db-test/kubernetes-dashboard -n flux-system -o yaml
```


3. Check logs of controller like helm-controller

```
kubectl get deployments -n flux-system
kubectl -n flux-system logs deployment/<flux-controller-name>
```

### Check Service and IP's
```bash
kubectl get svc -n kubernetes-dashboard
```

### Check Logs
```bash
kubectl logs -n flux-system deploy/kustomize-controller -f
```

### Kick off Renovate one time
```
kubectl create job --from=cronjob/renovate renovate-manual-run -n renovate
```

### Check the log of a job
```
kubectl logs job/renovate-manual-run -n renovate
```

### Check renovate Logs
``` bash
kubectl logs -n renovate deploy/renovate
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
### See Helm repos in all namespace
```
kubectl get helmrepositories --all-namespaces
```

## Check on an installation
```
kubectl describe helmrelease loki -n monitoring
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

### Or BusyBox Pod for testing
```bash
kubectl run -it --rm --restart=Never busybox -n flux-system --image=busybox
```

---

## 🔐 Managing Secrets for Renovate

```

Or use the script:
```bash
tools/seal-renovate-token.sh
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


