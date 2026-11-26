#!/usr/bin/env bash
# Release gate: develop's head commit must have a completed, successful CI run.
# Fails closed on a missing run, a run still in progress, or any non-success conclusion.
set -euo pipefail

: "${REPO:?REPO is required}" "${CI_WORKFLOW:?CI_WORKFLOW is required}"

head_sha=$(gh api "repos/${REPO}/git/ref/heads/develop" --jq '.object.sha')

# Runs for the head commit only; a run on an older develop commit does not vouch for this one.
# No event filter: python CI runs as workflow_run, go CI as push.
run_state=$(gh api --method GET "repos/${REPO}/actions/workflows/${CI_WORKFLOW}/runs" \
  -f branch=develop -f head_sha="${head_sha}" -f per_page=100 \
  --jq "([.workflow_runs[] | select(.head_sha == \"${head_sha}\")] | first // empty) | \"\(.status) \(.conclusion)\"")

if [ -z "${run_state}" ]; then
  echo "::error::No ${CI_WORKFLOW} push run found for develop head ${head_sha} in ${REPO}. Refusing to release."
  exit 1
fi

read -r status conclusion <<<"${run_state}"

if [ "${status}" != "completed" ]; then
  echo "::error::${CI_WORKFLOW} for develop head ${head_sha} is ${status}. Wait for it to finish, then retry."
  exit 1
fi

if [ "${conclusion}" != "success" ]; then
  echo "::error::${CI_WORKFLOW} for develop head ${head_sha} concluded '${conclusion}'. Fix develop CI before releasing."
  exit 1
fi

echo "develop head ${head_sha}: ${CI_WORKFLOW} succeeded."
