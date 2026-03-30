# Daily Workflow Cheat Sheet

## Branches

- upstream mirror branch:
  - auto-pts: upstream/master
  - zephyr: upstream/v3.7.0-ti-9.10
  - ti-openocd: upstream/ti-release
- integration branch: integration/ti-cc2340r53
- feature branches: feature/<topic>

## Start Work

```bash
git checkout integration/ti-cc2340r53
git pull --ff-only origin integration/ti-cc2340r53
git checkout -b feature/<topic>
```

## Commit and Publish

```bash
git add -A
git commit -m "Describe change"
git push -u origin feature/<topic>
```

## Merge Back to Integration

```bash
git checkout integration/ti-cc2340r53
git pull --ff-only origin integration/ti-cc2340r53
git merge --ff-only feature/<topic> || git merge --no-ff feature/<topic>
git push origin integration/ti-cc2340r53
```

## Bring Upstream Updates

Preferred one-command flow:

```bash
cd /home/david/ti-embedded-stack
bash scripts/refresh_upstream_and_pin.sh
```

Manual flow:

```bash
git fetch upstream --prune
git checkout upstream/<upstream-branch>
git merge --ff-only upstream/<upstream-branch>

git checkout integration/ti-cc2340r53
git rebase upstream/<upstream-branch>

# Resolve conflicts if needed
git add <resolved-files>
git rebase --continue

git push --force-with-lease origin integration/ti-cc2340r53
```

## Update Control Repo Pins

```bash
cd /home/david/ti-embedded-stack
cd auto-pts && git pull --ff-only origin integration/ti-cc2340r53 && cd ..
cd zephyr && git pull --ff-only origin integration/ti-cc2340r53 && cd ..
cd ti-openocd && git pull --ff-only origin integration/ti-cc2340r53 && cd ..

git add auto-pts zephyr ti-openocd
git commit -m "Bump submodules to latest validated revisions"
git push
```

## Create Known-Good Snapshot

```bash
cd /home/david/ti-embedded-stack
git tag -a stack-YYYYMMDD-01 -m "Known-good stack snapshot"
git push origin stack-YYYYMMDD-01
```

## Windows Clone Policy

- Treat Windows clone as pull-only runtime mirror.
- Never develop in both Windows and WSL at the same time.

```powershell
git status --porcelain
# must be empty
git checkout integration/ti-cc2340r53
git pull --ff-only origin integration/ti-cc2340r53
```
