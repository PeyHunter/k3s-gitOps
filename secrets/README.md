# secrets/

Encrypted Secrets (SealedSecrets), one file per Secret. Safe to commit: only the
sealed-secrets controller in the cluster can decrypt them.

| File | Secret | Used by |
|---|---|---|
| `cloudflare-api-token.yaml` | `external-dns/cloudflare-api-token` | external-dns (Cloudflare DNS records) |
| `pathfinder-env.yaml` | `pathfinder/pathfinder-env` | Pathfinder app (API keys) |
| `pathfinder-login.yaml` | `pathfinder/pathfinder-login` | Traefik basic auth in front of Pathfinder |
| `argocd-notifications-secret.yaml` | `argocd/argocd-notifications-secret` | Argo CD email alerts |

## Seal a Secret

Run on k3s-1 (it needs to reach the controller):

```sh
kubectl create secret generic <name> -n <namespace> \
  --from-literal=<key>=<value> --dry-run=client -o yaml \
  | kubeseal --format yaml > secrets/<name>.yaml
```

To take over a Secret that already exists in the cluster, mark the live Secret as
managed (so the controller may overwrite it), then seal a clean copy of it:

```sh
kubectl annotate secret <name> -n <namespace> sealedsecrets.bitnami.com/managed=true
kubectl get secret <name> -n <namespace> -o json \
  | jq 'del(.metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields, .metadata.annotations, .metadata.ownerReferences)' \
  | kubeseal --format yaml > secrets/<name>.yaml
```

## Back up the sealing key

If the cluster is rebuilt without this key, none of these files can be decrypted.
Keep a copy outside the cluster (not in git):

```sh
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.yaml
```
