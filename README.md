# k3s-gitops

Everything that runs on **k3s-1**, my single-node k3s cluster on a VPS, written as code.
Argo CD watches this repo and makes the cluster match it. If it isn't in git, it isn't
supposed to be running.

| Site | App | Source repo |
|---|---|---|
| [peytonhunter.com](https://peytonhunter.com) | `portfolio` | [pey-code-portfolio](https://github.com/PeyHunter/pey-code-portfolio) |
| [cv.peytonhunter.com](https://cv.peytonhunter.com) | `cv` | [cv](https://github.com/PeyHunter/cv) |
| [pathfinder.peytonhunter.com](https://pathfinder.peytonhunter.com) | `pathfinder` | [pathfinder](https://github.com/PeyHunter/pathfinder) |
| argocd.peytonhunter.com | `argocd` | this repo |

## How it fits together

```
bootstrap/root.yaml          applied once by hand; the only kubectl apply
  └─ apps/                   "app of apps": one Argo CD Application per file
       ├─ argocd.yaml        Argo CD manages its own upgrade   ─► charts/argo-cd
       ├─ cert-manager.yaml  Let's Encrypt certificates        ─► charts/cert-manager
       ├─ external-dns.yaml  Cloudflare DNS records            ─► charts/external-dns
       ├─ sealed-secrets.yaml  decrypts secrets/               ─► charts/sealed-secrets
       ├─ system.yaml        ClusterIssuer                     ─► system/
       ├─ secrets.yaml       encrypted Secrets                 ─► secrets/
       ├─ portfolio.yaml                                       ─► portfolio/
       ├─ cv.yaml                                              ─► cv/
       └─ pathfinder.yaml                                      ─► pathfinder/
```

Adding a file to `apps/` is all it takes to add an app: the `root` app picks it up.

## How a deploy happens

```
push to an app repo ─► GitHub Actions builds the image ─► pushes it to ghcr.io
   ─► commits the new tag to <app>/kustomization.yaml here ─► Argo CD rolls it out
```

Each app repo has a `GITOPS_DEPLOY_KEY` secret: an SSH deploy key with write access to
this repo. CI only ever edits the `newTag:` line. Images are always built in CI, never on
the VPS (it has 2 CPUs and 3.7 GB RAM).

## Helm charts are vendored

Third-party charts live unpacked in `charts/`, pinned in `charts.toml`. Argo CD renders
them from this repo, so an upgrade is a reviewable diff. To upgrade one:

```sh
helm pull <chart> --repo <repo> --version <version> --untar --untardir /tmp/c
rm -rf charts/<chart> && mv /tmp/c/<chart> charts/
# bump the version in charts.toml, commit, push
```

## Secrets

No plain Secret is ever committed. Secrets are sealed with
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets): `kubeseal` encrypts
them with the controller's public key, the encrypted file goes in `secrets/`, and only
the controller in the cluster can turn it back into a Secret. See
[secrets/README.md](secrets/README.md) for the list and the commands.

## Rebuild from zero

1. Install k3s on the VPS.
2. Install Argo CD once with Helm from `charts/argo-cd`, then
   `kubectl apply -f bootstrap/root.yaml`. From here Argo CD installs everything else,
   including itself.
3. Restore the sealing key backup before the controller starts, so `secrets/` decrypts:
   `kubectl apply -f sealed-secrets-key.yaml`.

## Safety settings

- Infrastructure apps (`argocd`, `cert-manager`, `system`, `sealed-secrets`, `secrets`)
  have `prune: false`: deleting a file never deletes live infrastructure or a Secret.
- Every app has `selfHeal: true`: changes made by hand with kubectl get reverted.
