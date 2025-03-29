# home-k3s-gitops-flux
Gitops repo for using flux


Howto use flux

Create the structure as what I have now

```

```

Then:

```
ssh-keygen -t ed25519 -C "flux@k3s" -f ~/.ssh/flux-ed25519 -N ""

```


Now you'll have:

```
    ~/.ssh/flux-ed25519 (private key)
    ~/.ssh/flux-ed25519.pub (public key)
```

Go to your GitHub repo → Settings → Deploy keys → Add deploy key:

    Title: flux-ed25519

    Key: Paste contents of flux-ed25519.pub

    ✅ Check "Allow write access"


    Or use my abisble playbook

    CHECK LOGS
    kubectl logs -n flux-system deploy/kustomize-controller -f
    flux get kustomizations
    flux get kustomizations -A -w


    # Reconcile the enitre cluster
    flux reconcile kustomization flux-system --with-source

    # Get Helm Sources
    flux get sources helm rancher-dev -n flux-system
    flux get helmreleases -n cattle-system
    flux logs --level=error --kind=HelmRelease --name=rancher -n cattle-system


    Using tools 
    ```
    chmod +x flux-watch.sh
    ./flux-watch.sh my-app my-namespace helmrelease

    ```

    ```
    alias fluxdebug='k9s -n flux-system'
    ```