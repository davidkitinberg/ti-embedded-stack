# TI Embedded Bluetooth Qualification Stack (CC2340R53)

This repository is the control plane for your full embedded Bluetooth qualification stack. It pins exact revisions of:

- auto-pts (Linux/WSL AutoPTS client and report tooling)
- simplelink-zephyr (TI Zephyr fork with board and tester changes)
- ti-openocd (TI OpenOCD fork for flashing/debug)

Primary board target:

- TI LP-EM-CC2340R53

Primary operating model:

- WSL is the canonical development environment
- Windows hosts PTS + dongle tooling
- This repo tracks and reproduces known-good combinations

## 1. System Architecture

At runtime, AutoPTS is split between Windows and WSL:

- Windows runs PTS and AutoPTS server components.
- WSL runs the AutoPTS client and controls the IUT over serial.
- The CC2340R53 board runs Zephyr Bluetooth tester firmware.

At source-control level, this control repo pins the exact submodule SHAs for all three repositories so environments are reproducible.

## 2. Repository Layout

- auto-pts/: AutoPTS framework and TI-specific test flow scripts
- zephyr/: TI Zephyr fork (board support, tester configs, build system)
- ti-openocd/: TI OpenOCD fork used for flashing/debugging
- scripts/bootstrap_stack.sh: initial setup and remote wiring helper
- scripts/refresh_upstream_and_pin.sh: one-command upstream refresh and pin update
- docs/daily_workflow_cheatsheet.md: day-to-day command reference

## 3. Clone and Initialize

Fresh machine setup:

```bash
git clone git@github.com:davidkitinberg/ti-embedded-stack.git
cd ti-embedded-stack
git submodule update --init --recursive
```

If you already have local clones and want to align remotes/branches with this architecture:

```bash
bash scripts/bootstrap_stack.sh
```

## 4. Automation Scripts and HTML Reporting

This project includes two key automation paths: stack-maintenance automation in this repo and AutoPTS execution/report automation in auto-pts.

### 4.1 Stack Maintenance Automation (this repo)

One-command refresh of all submodules from upstream, rebase of integration branches, push to forks, and pin update in this control repo:

```bash
cd /home/david/ti-embedded-stack
bash scripts/refresh_upstream_and_pin.sh
```

Options:

- --no-push: run refresh and pin updates locally without pushing.
- --allow-dirty: bypass clean-tree checks (use only when intentional).

What it does:

1. Validates clean working trees (unless --allow-dirty).
2. For each repo (auto-pts, zephyr, ti-openocd):
	 - Fetches upstream and origin
	 - Updates local upstream/<branch> mirror branch
	 - Rebases integration/ti-cc2340r53 onto upstream mirror
	 - Pushes integration branch to fork (force-with-lease)
3. Updates submodule pointers in this control repo.
4. Commits pin updates and pushes main.

### 4.2 AutoPTS Run Automation and HTML Report (auto-pts repo)

AutoPTS execution and reporting live in the auto-pts repository. Typical report generation flow:

```bash
cd /home/david/auto-pts
python3 tools/autopts_report.py --run-root "$(ls -1dt logs/cli_port_*/* | head -1)"
```

Open the generated report in Windows browser from WSL:

```bash
explorer.exe "$(wslpath -w "$(ls -1dt /home/david/auto-pts/logs/cli_port_*/* | head -1)/report.html")"
```

HTML report details:

- Generated per run directory under logs/cli_port_<port>/<timestamp>/report.html
- Includes per-test pass/fail/error status
- Links to per-test artifacts (AutoPTS results and PTS logs when present)
- Intended for quick triage and sharing run outcomes

## 5. Git Architecture and Branch Strategy

Each submodule repo uses fork + upstream remotes:

- origin: davidkitinberg/* private fork (push target)
- upstream: official project repo (fetch source of truth)

Standard branches:

- upstream mirror branch:
	- auto-pts: upstream/master
	- zephyr: upstream/v3.7.0-ti-9.10
	- ti-openocd: upstream/ti-release
- integration branch: integration/ti-cc2340r53
- feature branches: feature/<topic>

Rules:

- Do active development in WSL clones.
- Keep Windows clones pull-only for runtime/test tools.
- Never commit directly to upstream mirror branches.
- Rebase integration on upstream mirror during sync cycles.

## 6. Maintenance Workflows

### 6.1 Daily Development

```bash
git checkout integration/ti-cc2340r53
git pull --ff-only origin integration/ti-cc2340r53
git checkout -b feature/<topic>
```

```bash
git add -A
git commit -m "Describe change"
git push -u origin feature/<topic>
```

### 6.2 Merge Feature Back

```bash
git checkout integration/ti-cc2340r53
git pull --ff-only origin integration/ti-cc2340r53
git merge --ff-only feature/<topic> || git merge --no-ff feature/<topic>
git push origin integration/ti-cc2340r53
```

### 6.3 Update Whole Stack and Repin

```bash
cd /home/david/ti-embedded-stack
bash scripts/refresh_upstream_and_pin.sh
```

### 6.4 Tag Known-Good Snapshot

```bash
cd /home/david/ti-embedded-stack
git tag -a stack-YYYYMMDD-01 -m "Known-good stack snapshot"
git push origin stack-YYYYMMDD-01
```

## 7. Script Usage Summary

Bootstrap once (or when remotes/branches need repair):

```bash
bash scripts/bootstrap_stack.sh
```

Routine upstream synchronization and pin update:

```bash
bash scripts/refresh_upstream_and_pin.sh
```

For a detailed day-to-day command list, see docs/daily_workflow_cheatsheet.md.
