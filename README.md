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

## Daily Workflow

See docs/daily_workflow_cheatsheet.md.
