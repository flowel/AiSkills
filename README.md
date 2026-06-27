# Skill Sync Bundle

This folder is a Git-friendly backup of the user-installed skills from this machine.

## Canonical Location

Recommended repository path on this machine:

`D:\WorkSpace\Skill-Sync`

## Layout

- `skills/codex/`: contents intended for `~/.codex/skills`
- `skills/agents/`: contents intended for `~/.agents/skills`
- `manifests/installed-skills.json`: machine-readable inventory
- `manifests/installed-skills.txt`: human-readable inventory
- `enable-git-source-mode.ps1`: one-time setup to link live skill folders to this repo
- `sync-skills.ps1`: refresh bundle metadata from this repo
- `restore-skills.ps1`: link another Windows machine to this repo

## Notes

- System skills are intentionally excluded.
- Local `.system` is needed for Codex root linking, but it is ignored by Git.
- `projectmaster` is an orchestration skill. Its dependency notes live in:
  - `skills/codex/projectmaster/DEPENDENCIES.md`
  - `skills/codex/projectmaster/dependencies.json`
- Bundled third-party skill pack: `plannotator/effective-html`
  - Installed skills: `html`, `html-diagram`, `html-plan`
  - Source: https://github.com/plannotator/effective-html

## Manifests

This repo now keeps two kinds of manifest:

- Tracked inventory:
  - `manifests/installed-skills.json`
  - `manifests/installed-skills.txt`
- Local machine state:
  - `manifests/local-state.json`
  - `manifests/local-state.txt`

The tracked inventory reflects the repo itself: which skills currently exist under `skills/codex` and `skills/agents`.

The local state reflects the current machine: local paths, link status, and current live counts. These files are intentionally ignored by Git so different machines can use different local paths without blocking `git pull`.

## Git Source Mode

In Git source mode, this repo is the source of truth.

- `~/.codex/skills` becomes a junction to `skills/codex`
- `~/.agents/skills` becomes a junction to `skills/agents`
- New installs made through those live directories land in this repo automatically

### Enable on This Machine

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\enable-git-source-mode.ps1
```

The script will:

- back up the current live skill folders with a timestamped suffix
- seed local `.system` into `skills/codex/.system` if needed
- create junctions from the live skill paths to this repo
- refresh the manifests

## Restore on Another Device

From the folder that contains this README, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\restore-skills.ps1
```

That script links the other machine's live skill folders to this repo location. After that, `git pull` updates the source bundle directly.

Restart Codex after linking or after pulling new skills.

## Refresh This Bundle On The Current Machine

When repo contents change and you want the manifests refreshed, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-skills.ps1
```

That script will:

- refresh `manifests/installed-skills.json`
- refresh `manifests/installed-skills.txt`
- refresh `manifests/local-state.json`
- refresh `manifests/local-state.txt`
- report current skill counts

## Daily Workflow

1. Install or edit skills through the live Codex or agents skill folders
2. Because those folders are linked, changes land in this repo
3. Run `.\sync-skills.ps1`
4. Commit and push
5. On another device, `git pull` and restart Codex
