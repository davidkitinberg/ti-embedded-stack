#!/usr/bin/env bash
set -euo pipefail

GH_USER="davidkitinberg"

AUTO_PTS_DIR="/home/david/auto-pts"
ZEPHYR_DIR="/home/david/ti-workspace/zephyr"
OPENOCD_DIR="/home/david/ti-openocd"
CONTROL_DIR="/home/david/ti-embedded-stack"

INTEGRATION_BRANCH="integration/ti-cc2340r53"

setup_repo() {
  local repo="$1"
  local upstream_url="$2"
  local fork_url="$3"
  local upstream_branch="$4"

  cd "$repo"

  if ! git remote get-url upstream >/dev/null 2>&1; then
    git remote rename origin upstream
  fi

  git remote set-url upstream "$upstream_url"

  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$fork_url"
  else
    git remote add origin "$fork_url"
  fi

  git fetch --all --prune
  git branch -f "upstream/${upstream_branch}" "upstream/${upstream_branch}"

  if git show-ref --verify --quiet "refs/heads/${INTEGRATION_BRANCH}"; then
    git checkout "${INTEGRATION_BRANCH}"
  else
    git checkout -b "${INTEGRATION_BRANCH}"
  fi

  git push -u origin "${INTEGRATION_BRANCH}"
}

setup_repo "$AUTO_PTS_DIR" \
  "https://github.com/intel/auto-pts.git" \
  "git@github.com:${GH_USER}/auto-pts.git" \
  "master"

setup_repo "$ZEPHYR_DIR" \
  "https://github.com/TexasInstruments/simplelink-zephyr" \
  "git@github.com:${GH_USER}/simplelink-zephyr.git" \
  "v3.7.0-ti-9.10"

setup_repo "$OPENOCD_DIR" \
  "https://github.com/TexasInstruments/ti-openocd.git" \
  "git@github.com:${GH_USER}/ti-openocd.git" \
  "ti-release"

mkdir -p "$CONTROL_DIR"
cd "$CONTROL_DIR"

if [ ! -d .git ]; then
  git init
  git branch -M main
fi

if [ ! -e auto-pts ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/auto-pts.git" auto-pts
fi
if [ ! -e zephyr ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/simplelink-zephyr.git" zephyr
fi
if [ ! -e ti-openocd ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/ti-openocd.git" ti-openocd
fi

git add .gitmodules auto-pts zephyr ti-openocd
if [ -n "$(git status --porcelain)" ]; then
  git commit -m "Initialize reproducible TI embedded stack with pinned submodules"
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "git@github.com:${GH_USER}/ti-embedded-stack.git"
else
  git remote add origin "git@github.com:${GH_USER}/ti-embedded-stack.git"
fi

git push -u origin main

echo "Bootstrap complete."
