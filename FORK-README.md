# Personal Fork: Agency Agents

> [!IMPORTANT]
> **THIS IS A PERSONAL FORK FOR CENTRALIZED USAGE**
>
> This repository is the **Source of Truth** for all local agent-based tools
> (Claude Code, Antigravity, Cursor, etc.).
>
> - **DO NOT** edit files in tool-specific directories (e.g., `~/.claude/agents/`) directly.
> - **ALWAYS** edit agents here and run `./scripts/agency-manager.sh sync`.
> - **Master Template**: `~/.claude/CLAUDE.md` is the global instruction source of truth.

## Quick Project Setup

When starting a new coding project, run this inside the new project directory:

```bash
# General setup
./scripts/agency-manager.sh init-project

# Setup with a specific specialist (e.g., Frontend Developer)
./scripts/agency-manager.sh init-project engineering-frontend-developer
```

## Fork Maintenance

Pull in new agents from upstream while keeping your centralization scripts intact:

1. **Fetch and rebase onto upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```
   - For README conflicts: take `--ours` (upstream) for agent table sections
   - Take `--theirs` only if a conflict is in fork-specific files (`FORK-README.md`, `scripts/`, etc.)

2. **Sync new agents to tool directories**:
   ```bash
   ./scripts/agency-manager.sh sync
   ```

3. **Push to your fork**:
   ```bash
   git push origin main --force-with-lease
   ```

4. **Update changelog** for any significant changes:
   ```bash
   # Document in CHANGELOG-FORK.md
   ```

## Safeguards

- **Agent Rules**: Every AI agent working on this repo is instructed to update `CHANGELOG-FORK.md`.
- **Global Backups**: `agency-manager.sh backup` lets you revert your global Claude config.
- **Git Hooks**: `lefthook` enforces changelog entries when modifying scripts or docs.
