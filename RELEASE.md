# Release & uprev workflow

How addon changes flow from this library into running clusters. The library is
versioned by **git tag** (`platform-vX.Y.Z`); the consumer
[`cluster-addons`](https://github.com/rayabueg/cluster-addons) pins a tag per
`base/<addon>`. All changes go through a branch + PR — except the one-time
initial import, which seeds `main` (a brand-new repo has no base branch to PR
into yet).

## One-time: publish the library

```bash
cd ~/code/personal/k8s-lab/platform-addons
gh repo create rayabueg/platform-addons --public --source=. --remote=origin --push
git push origin platform-v0.1.0     # the release tag
```

Use `--private` instead of `--public` if you prefer — but then Argo CD needs repo
credentials for this repo before any `base/<addon>` remote ref will resolve
in-cluster.

## Cutting a new version (branch → PR → tag)

1. **Change an addon.** Edit values / bump the chart version, then re-render:

   ```bash
   git switch -c uprev-v0.2.0
   bash <addon>/hack/render.sh        # regenerates <addon>/manifests/bundle.yaml
   ```

   Raw-YAML addons (no `hack/`) are edited directly under `<addon>/manifests/`.

2. **PR the manifest diff.**

   ```bash
   git commit -am "<addon>: <what changed>"
   git push -u origin uprev-v0.2.0
   gh pr create --fill --base main --head uprev-v0.2.0
   gh pr merge uprev-v0.2.0 --squash --delete-branch
   ```

3. **Tag the merged commit.** A tag freezes every addon together — it's the unit
   `cluster-addons` pins.

   ```bash
   git switch main && git pull
   git tag platform-v0.2.0
   git push origin platform-v0.2.0
   ```

4. **Roll it out in `cluster-addons`** (separate PR there):

   ```bash
   cd ~/code/personal/k8s-lab/cluster-addons
   git switch -c uprev-v0.2.0
   # bump ?ref=platform-v0.1.0 → platform-v0.2.0 across base/*/kustomization.yaml
   sed -i '' 's/platform-v0.1.0/platform-v0.2.0/' base/*/kustomization.yaml   # macOS sed
   git commit -am "base: uprev platform-v0.2.0"
   git push -u origin uprev-v0.2.0
   gh pr create --fill
   ```

   `base/<addon>` is the only uprev surface; per-cluster patches under
   `clusters/<cluster>/addons/<addon>/` don't move. Argo CD reconciles on merge.

## Versioning convention

`platform-vMAJOR.MINOR.PATCH`. Pre-releases use `platform-vX.Y.Z-rc.N` and are
pinned only on a non-prod cluster for validation. There are no `latest` / `stable`
channels — the tag is the channel.

## Validation before tagging

```bash
# every addon's manifests build standalone
for a in */; do
  [ -f "${a}manifests/kustomization.yaml" ] || continue
  kustomize build "${a}manifests" >/dev/null && echo "ok: $a" || echo "FAIL: $a"
done
```
