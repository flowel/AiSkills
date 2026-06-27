# Skill-Sync Agent Notes

This directory is the canonical Git-backed skill bundle for cross-device sync.

## What This Folder Is

- `skills/codex/`: user-installable skills for `~/.codex/skills`
- `skills/agents/`: user-installable skills for `~/.agents/skills`
- `manifests/`: inventories of what is currently bundled

## Git Source Mode

This repo is intended to become the live source of truth.

- `~/.codex/skills` should be a junction to `skills/codex`
- `~/.agents/skills` should be a junction to `skills/agents`
- `skills/codex/.system` is local-only and should stay untracked

## What To Do On A New Device

If the user asks to restore skills from this repo on Windows:

1. Open a shell in this directory
2. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\restore-skills.ps1
```

3. Tell the user to restart Codex

## What To Do After Installing New Skills On This Device

If the machine is already in Git source mode and the bundle needs its manifests refreshed:

1. Open a shell in this directory
2. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\sync-skills.ps1
```

3. Commit the changed files to Git if the user wants the new state synced to other devices

## Important Notes

- Do not commit `.system`
- Do not commit `manifests/local-state.json` or `manifests/local-state.txt`
- Keep `projectmaster` dependency files in sync
- This folder is intended to be the maintainable source of truth for cross-device sync, not a one-off export
