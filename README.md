# platform-addons

Versioned **addon library** for the k8s-lab platform. This is the source-of-truth
for *what an addon is*; the cluster-config repo
[`cluster-addons`](https://github.com/rayabueg/cluster-addons) decides *where each
addon runs* by subscribing to a pinned tag here.

This split mirrors the Gen2 `sdp-addons` / `sdp-cluster-addons` model:

```
platform-addons  (this repo)   → addon manifests, versioned by git tag
cluster-addons   (consumer)    → per-cluster subscriptions: base/<addon> ?ref=platform-vX.Y.Z
```

## Layout

```
<addon>/
  manifests/         # the addon's Kustomize-buildable manifests (rendered Helm output or raw YAML)
    kustomization.yaml
    bundle.yaml      # Helm addons: `helm template` output
    ...
  hack/              # Helm addons only — how manifests/ is regenerated
    render.sh        # re-renders the chart into manifests/bundle.yaml
    values*.yaml     # Helm values
  metadata.yaml      # declares which cluster tag sets this addon is eligible for
```

Consumers reference an addon by its `manifests/` dir at a pinned tag:

```
https://github.com/rayabueg/platform-addons.git//<addon>/manifests?ref=platform-v0.1.0
```

## Versioning & promotion (no waves)

The library is versioned by **git tag** `platform-vX.Y.Z`. A tag is an immutable
bundle of every addon at a known-good revision — the unit `cluster-addons` pins.

The Gen1 `latest`/`stable`/`rc` channels and `promote.sh` are **retired**:

| Gen1 channel concept | platform-addons equivalent |
|---|---|
| `base/latest` | `manifests/` on `main` (untagged tip) |
| `base/rc` | a pre-release tag `platform-vX.Y.Z-rc.N` |
| `base/stable` + `promote.sh` | cutting a release tag `platform-vX.Y.Z` |

See [RELEASE.md](RELEASE.md) for the full publish + uprev workflow (branch → PR → tag).

### Uprev flow

1. Edit `<addon>/hack/values.yaml` and/or bump the chart `VERSION` in `render.sh`.
2. `bash <addon>/hack/render.sh` — regenerates `<addon>/manifests/bundle.yaml`.
3. Review the manifest diff, commit on `main`.
4. Cut a tag: `git tag platform-vX.Y.Z && git push --tags`.
5. In `cluster-addons`, bump every `base/<addon>/kustomization.yaml` `?ref=` to the
   new tag (the single uprev surface there). Argo CD reconciles the change.

## Addons

| Addon | Type | `metadata.yaml` tags |
|---|---|---|
| `argocd-config` | Raw YAML | application |
| `cert-manager` | Helm | application appservice utility |
| `core-dns` | Raw YAML | application appservice utility kubeadm |
| `crds` | Raw YAML | application appservice utility |
| `descheduler` | Helm | application appservice utility |
| `envoy-gateway` | Raw YAML | application |
| `external-dns` | Helm | application appservice utility |
| `external-secrets` | Helm | application appservice utility |
| `hubble` | Helm | application |
| `istio` | Helm | application |
| `namespaces` | Raw YAML | application appservice utility |

`metadata.yaml spec.clusters` declares where an addon *can* run. It is intentionally
permissive; the cluster matcher in `cluster-addons` decides where it *should*.

## Validation

```bash
# every addon's manifests build standalone
for a in */; do
  [ -f "${a}manifests/kustomization.yaml" ] || continue
  kustomize build "${a}manifests" >/dev/null && echo "ok: $a" || echo "FAIL: $a"
done
```
