#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status, 
# treat unset variables as an error, and catch pipeline failures.
set -euo pipefail

# --- Configuration Variables ---
GH_USER="davidkitinberg"

# Local paths to your existing cloned repositories in WSL
AUTO_PTS_DIR="/home/david/auto-pts"
ZEPHYR_DIR="/home/david/ti-workspace/zephyr"
OPENOCD_DIR="/home/david/ti-openocd"
CONTROL_DIR="/home/david/ti-embedded-stack"

# The name of your custom branch where all TI-specific work lives
INTEGRATION_BRANCH="integration/ti-cc2340r53"

# --- Helper Function: Setup Repository ---
# This function reconfigures an existing local clone to use a "Fork + Upstream" workflow.
# Arguments:
#   $1: Local repository directory path
#   $2: Official upstream URL (Intel/TI)
#   $3: Your private fork URL on GitHub
#   $4: The main branch name on the upstream repository
setup_repo() {
  local repo="$1"
  local upstream_url="$2"
  local fork_url="$3"
  local upstream_branch="$4"

  echo "Configuring repository at: $repo"
  cd "$repo"

  # Step 1: Manage Remotes
  # If 'upstream' doesn't exist, assume the current 'origin' is the official repo 
  # and rename it to 'upstream' so we don't accidentally push to it.
  if ! git remote get-url upstream >/dev/null 2>&1; then
    git remote rename origin upstream
  fi

  # Explicitly set the upstream URL just to be safe
  git remote set-url upstream "$upstream_url"

  # Assign 'origin' to your private fork so your 'git push' goes to your GitHub account
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$fork_url"
  else
    git remote add origin "$fork_url"
  fi

  # Step 2: Fetch and Sync
  # Fetch all updates from both origin and upstream, removing deleted remote branches
  git fetch --all --prune
  
  # Create or update a local branch that exactly mirrors the official upstream branch
  git branch -f "upstream/${upstream_branch}" "upstream/${upstream_branch}"

  # Step 3: Integration Branch Setup
  # Check if your custom TI integration branch already exists locally
  if git show-ref --verify --quiet "refs/heads/${INTEGRATION_BRANCH}"; then
    git checkout "${INTEGRATION_BRANCH}"
  else
    # Create it if it doesn't exist
    git checkout -b "${INTEGRATION_BRANCH}"
  fi

  # Push the integration branch to your private fork and set it to track
  git push -u origin "${INTEGRATION_BRANCH}"
}

# --- Execute Setup for Each Repository ---

# 1. Setup Auto-PTS
setup_repo "$AUTO_PTS_DIR" \
  "https://github.com/intel/auto-pts.git" \
  "git@github.com:${GH_USER}/auto-pts.git" \
  "master"

# 2. Setup SimpleLink Zephyr (TI)
setup_repo "$ZEPHYR_DIR" \
  "https://github.com/TexasInstruments/simplelink-zephyr" \
  "git@github.com:${GH_USER}/simplelink-zephyr.git" \
  "v3.7.0-ti-9.10"

# 3. Setup TI OpenOCD
setup_repo "$OPENOCD_DIR" \
  "https://github.com/TexasInstruments/ti-openocd.git" \
  "git@github.com:${GH_USER}/ti-openocd.git" \
  "ti-release"

# --- Create and Configure the Control Repository ---
echo "Configuring Control Repository at: $CONTROL_DIR"
mkdir -p "$CONTROL_DIR"
cd "$CONTROL_DIR"

# Initialize a new Git repository if it doesn't exist
if [ ! -d .git ]; then
  git init
  git branch -M main
fi

# Add the 3 repositories as submodules, tracking your custom integration branch.
# We check if they already exist to prevent errors on re-runs.
if [ ! -e auto-pts ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/auto-pts.git" auto-pts
fi
if [ ! -e zephyr ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/simplelink-zephyr.git" zephyr
fi
if [ ! -e ti-openocd ]; then
  git submodule add -b "$INTEGRATION_BRANCH" "git@github.com:${GH_USER}/ti-openocd.git" ti-openocd
fi

# Stage the submodules and the generated .gitmodules file
git add .gitmodules auto-pts zephyr ti-openocd

# Only commit if there are actually changes to commit
if [ -n "$(git status --porcelain)" ]; then
  git commit -m "Initialize reproducible TI embedded stack with pinned submodules"
fi

# Link the control repo to your GitHub account
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "git@github.com:${GH_USER}/ti-embedded-stack.git"
else
  git remote add origin "git@github.com:${GH_USER}/ti-embedded-stack.git"
fi

# Push the control repository to GitHub
git push -u origin main

echo "Bootstrap complete."