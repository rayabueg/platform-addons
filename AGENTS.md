# Repository Guidelines — platform-addons

Addon **library** repo. Holds addon manifests; does not know about clusters.
The consumer is [`cluster-addons`](https://github.com/rayabueg/cluster-addons).

## What belongs here

- `<addon>/manifests/` — Kustomize-buildable manifests. Helm addons store
  `helm template` output in `bundle.yaml`; raw addons store hand-authored YAML.
- `<addon>/hack/` — `render.sh` + `values*.yaml` for Helm addons. `render.sh`
  writes into `../manifests/`.
- `<addon>/metadata.yaml` — `spec.clusters` tag eligibility.

## What does NOT belong here

- Per-cluster subscriptions, ApplicationSets, or patches. Those live in
  `cluster-addons/clusters/<cluster>/`.
- `latest`/`stable`/`rc` channel folders or `promote.sh`. Retired — versioning
  is by git tag (`platform-vX.Y.Z`).
- Cluster bootstrap (Argo CD install, Cilium CNI). Those are in the `bootstrap`
  submodule and run before Argo exists.

## Conventions

- Addon dir names are kebab-case and must match the consumer's `base/<addon>`.
- A consumer references `<addon>/manifests` at a pinned tag — never `?ref=main`.
- `manifests/kustomization.yaml` must `kustomize build` standalone (only local refs).
- Regenerate Helm addons with `render.sh`; never hand-edit `bundle.yaml`.

## Release

- `git tag platform-vX.Y.Z` on a reviewed `main` commit, then `git push --tags`.
- A tag freezes every addon together; the consumer pins one tag across all
  `base/<addon>`.
