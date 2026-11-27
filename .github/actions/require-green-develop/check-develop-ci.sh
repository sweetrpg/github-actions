#!/usr/bin/env bash
# Release gate: every named workflow must have a completed, successful run on develop's head commit.
# Fails closed on a missing run, a run still in progress, or any non-success conclusion.
set -euo pipefail

: "${REPO:?REPO is required}" "${CI_WORKFLOW:?CI_WORKFLOW is required}"

head_sha=$(gh api "repos/${REPO}/git/ref/heads/develop" --jq '.object.sha')

# Checks one workflow file for a run on the head commit only; a run on an older develop commit does not vouch for this one.
check_workflow() {
  local workflow="$1" run_state status conclusion
  # No event filter: python CI runs as workflow_run, go CI as push.
  run_state=$(gh api --method GET "repos/${REPO}/actions/workflows/${workflow}/runs" \
    -f branch=develop -f head_sha="${head_sha}" -f per_page=100 \
    --jq "([.workflow_runs[] | select(.head_sha == \"${head_sha}\")] | first // empty) | \"\(.status) \(.conclusion)\"")

  if [ -z "${run_state}" ]; then
    echo "::error::No ${workflow} push run found for develop head ${head_sha} in ${REPO}. Refusing to release."
    return 1
  fi

  read -r status conclusion <<<"${run_state}"

  if [ "${status}" != "completed" ]; then
    echo "::error::${workflow} for develop head ${head_sha} is ${status}. Wait for it to finish, then retry."
    return 1
  fi

  if [ "${conclusion}" != "success" ]; then
    echo "::error::${workflow} for develop head ${head_sha} concluded '${conclusion}'. Fix develop before releasing."
    return 1
  fi

  echo "develop head ${head_sha}: ${workflow} succeeded."
}

failed=0
check_workflow "${CI_WORKFLOW}" || failed=1
# Image build is optional: repos without one leave IMAGE_WORKFLOW empty and skip this check.
if [ -n "${IMAGE_WORKFLOW:-}" ]; then
  check_workflow "${IMAGE_WORKFLOW}" || failed=1
fi
exit "${failed}"
