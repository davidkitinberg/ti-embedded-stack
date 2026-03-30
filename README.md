# TI Embedded Stack Control Repository

This repository pins exact versions of the following components as Git submodules:

- auto-pts
- zephyr (simplelink-zephyr fork)
- ti-openocd

Canonical development environment: WSL.

## Initialize on a New Machine

```bash
git clone git@github.com:davidkitinberg/ti-embedded-stack.git
cd ti-embedded-stack
git submodule update --init --recursive
```

## Bootstrap Existing Local Clones

```bash
bash scripts/bootstrap_stack.sh
```

## One-Command Upstream Refresh + Pin Update

```bash
bash scripts/refresh_upstream_and_pin.sh
```

Optional flags:

- `--no-push`: refresh and commit pin updates locally without pushing.
- `--allow-dirty`: skip clean-tree checks (use with caution).

## Daily Workflow

See docs/daily_workflow_cheatsheet.md.
