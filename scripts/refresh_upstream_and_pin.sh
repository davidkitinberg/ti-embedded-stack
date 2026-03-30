#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTROL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

INTEGRATION_BRANCH="integration/ti-cc2340r53"
NO_PUSH=0
ALLOW_DIRTY=0

usage() {
  cat <<'EOF'
Usage: scripts/refresh_upstream_and_pin.sh [options]

Refresh upstream for all submodules, rebase integration branches, push forks,
and update submodule pins in ti-embedded-stack.

Options:
  --no-push       Perform local refresh and pin commit, but do not push.
  --allow-dirty   Allow dirty working trees in submodules/control repo.
  -h, --help      Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)
      NO_PUSH=1
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

require_clean_repo() {
  local repo_path="$1"
  local repo_name="$2"

  if [[ "$ALLOW_DIRTY" -eq 1 ]]; then
    return
  fi

  if [[ -n "$(git -C "$repo_path" status --porcelain)" ]]; then
    echo "ERROR: ${repo_name} has uncommitted changes. Commit/stash first, or use --allow-dirty." >&2
    exit 1
  fi
}

ensure_submodule_remotes() {
  local repo_path="$1"
  local upstream_url="$2"

  if git -C "$repo_path" remote get-url upstream >/dev/null 2>&1; then
    git -C "$repo_path" remote set-url upstream "$upstream_url"
  else
    git -C "$repo_path" remote add upstream "$upstream_url"
  fi
}

sync_repo() {
  local path="$1"
  local upstream_branch="$2"
  local upstream_url="$3"
  local repo_path="${CONTROL_DIR}/${path}"
  local upstream_ref="refs/remotes/upstream/${upstream_branch}"

  echo "==> Syncing ${path}"
  require_clean_repo "$repo_path" "$path"
  ensure_submodule_remotes "$repo_path" "$upstream_url"

  git -C "$repo_path" fetch upstream --prune
  git -C "$repo_path" fetch origin --prune

  if ! git -C "$repo_path" show-ref --verify --quiet "$upstream_ref"; then
    echo "ERROR: Missing upstream ref ${upstream_ref} in ${path}." >&2
    exit 1
  fi

  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/${INTEGRATION_BRANCH}"; then
    git -C "$repo_path" checkout "${INTEGRATION_BRANCH}"
  else
    git -C "$repo_path" checkout -b "${INTEGRATION_BRANCH}" "origin/${INTEGRATION_BRANCH}"
  fi

  git -C "$repo_path" pull --ff-only origin "${INTEGRATION_BRANCH}"
  git -C "$repo_path" rebase "$upstream_ref"

  if [[ "$NO_PUSH" -eq 0 ]]; then
    git -C "$repo_path" push --force-with-lease origin "${INTEGRATION_BRANCH}"
  fi
}

if ! git -C "$CONTROL_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: ${CONTROL_DIR} is not a git repository." >&2
  exit 1
fi

if [[ ! -f "${CONTROL_DIR}/.gitmodules" ]]; then
  echo "ERROR: ${CONTROL_DIR} does not have .gitmodules." >&2
  exit 1
fi

require_clean_repo "$CONTROL_DIR" "ti-embedded-stack"

sync_repo "auto-pts" "master" "https://github.com/intel/auto-pts.git"
sync_repo "zephyr" "v3.7.0-ti-9.10" "https://github.com/TexasInstruments/simplelink-zephyr"
sync_repo "ti-openocd" "ti-release" "https://github.com/TexasInstruments/ti-openocd.git"

echo "==> Updating submodule pins in control repo"
AUTO_SHA="$(git -C "${CONTROL_DIR}/auto-pts" rev-parse --short HEAD)"
ZEPHYR_SHA="$(git -C "${CONTROL_DIR}/zephyr" rev-parse --short HEAD)"
OPENOCD_SHA="$(git -C "${CONTROL_DIR}/ti-openocd" rev-parse --short HEAD)"

if ! git -C "$CONTROL_DIR" diff --quiet -- auto-pts zephyr ti-openocd; then
  git -C "$CONTROL_DIR" add auto-pts zephyr ti-openocd
  git -C "$CONTROL_DIR" commit -m "chore: refresh upstream and bump submodules (auto-pts ${AUTO_SHA}, zephyr ${ZEPHYR_SHA}, ti-openocd ${OPENOCD_SHA})"
else
  echo "No submodule pin changes detected."
fi

if [[ "$NO_PUSH" -eq 0 ]]; then
  git -C "$CONTROL_DIR" push origin main
fi

echo "Done."
