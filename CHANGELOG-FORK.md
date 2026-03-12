# Thomas's Agency Agents Changelog

This changelog tracks all modifications, enhancements, and architectural shifts made to this personal fork of the [Agency Agents](https://github.com/msitarzewski/agency-agents) repository.

> [!IMPORTANT]
> **Future Agents**: You are REQUIRED to add an entry to this file whenever you modify the repository's logic, scripts, or core structure. Do not skip this step.

---

## [Unreleased]

### Added
- Git hook enforcement for changelog updates.
- Future agent instructions in `~/.claude/process.md`.

---

## [2026-03-11] - Phase 2: Modular Architecture & Safety

### Added
- **`agency-manager.sh backup`**: Command to create timestamped archives of the global configuration.
- **`agency-manager.sh modularize`**: Idempotent command to split monolithic `CLAUDE.md` into modules.
- **`AGENTS.md`**: Universal instruction template for all AI tools (Cursor, Windsurf, Copilot).
- **On-Demand Specialist Bootstrapping**: `init-project [agent-name]` now allows importing specific specialists via a local `CLAUDE.md` wrapper.

### Changed
- **Modular Master**: Split `~/.claude/CLAUDE.md` into `identity.md`, `standards.md`, and `process.md`.
- **Refined `init-project`**: Now handles modular imports and supports multi-tool rules (Cursor/Windsurf).

### Fixed
- Undefined variable issues and macOS `head` portability in `agency-manager.sh`.

---

## [2026-03-11] - Phase 1: Centralization & Symlinking

### Added
- **`agency-manager.sh`**: Initial release of the centralized management script.
- **Global Symlinking**: Strategy to link agents from the repo to `~/.claude/agents` and `~/.gemini/antigravity/skills`.
- **Master `CLAUDE.md`**: Designated `~/.claude/CLAUDE.md` as the single source of truth for all projects.

### Changed
- **README Updates**: Massive documentation overhaul for fork-specific workflows.
- **Directory Cleanup**: Removed nested agent folders in favor of a flat symlink structure.
