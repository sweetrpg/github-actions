# github-actions

A collection of commonly used, reusable GitHub Actions workflows for sweetrpg repos.

## Go workflows

- `go-ci.yaml` - build/vet/lint/test on push to `develop` (`workflow_call`)
- `go-prepare-release.yaml` - computes the next version from conventional commits, opens a
  `release/<version>` PR
- `go-release.yaml` - on tag push: re-runs tests, creates a GitHub Release, merges the release
  branch back into `develop`
- `go-tag-release.yaml` - tags the release branch when a `release/*` PR merges

See any sweetrpg Go repo's `.github/workflows/{ci,prepare-release,release,tag-release}.yaml`
and `RELEASE.md` for how these are consumed.

## Rust workflows

- `rust-ci.yaml`, `rust-prepare-release.yaml`, `rust-release.yaml`, `rust-tag-release.yaml` -
  copied from [pilgrimagesoftware/github-actions](https://github.com/pilgrimagesoftware/github-actions)
  as a starting point for any future Rust repos. Not currently consumed by any sweetrpg repo.

## Debug

- `debug.yaml` - generic diagnostics workflow (`workflow_call`), also copied from
  pilgrimagesoftware/github-actions.

## ArgoCD

- `argocd-update-deployment.yaml` - bumps a service's deployed image tag in the `argocd` repo's
  Application manifest and pushes the commit, matching by image name in `kustomize.images`
  rather than array position. Language-agnostic; call it from a tag-triggered build workflow
  with `image-name` and `manifest-path` (both repo-specific, so a directory rename in `argocd`
  only needs updating in the caller, not this workflow).
