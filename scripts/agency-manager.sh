#!/usr/bin/env bash

# agency-manager.sh -- Centralized management for The Agency agents.
# Handle global symlinks and project initialization.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_AGENTS_DIR="${HOME}/.claude/agents"
ANTIGRAVITY_SKILLS_DIR="${HOME}/.gemini/antigravity/skills"
MASTER_CLAUDE_MD="${HOME}/.claude/CLAUDE.md"

C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[1;33m'
C_RED=$'\033[0;31m'
C_RESET=$'\033[0m'

ok()   { printf "${C_GREEN}[OK]${C_RESET}  %s\n" "$*"; }
warn() { printf "${C_YELLOW}[!!]${C_RESET}  %s\n" "$*"; }
err()  { printf "${C_RED}[ERR]${C_RESET} %s\n" "$*" >&2; }

usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
  setup         Configure global symlinks for Claude Code and Antigravity
  init-project  Initialize current directory with master CLAUDE.md and rules
  sync          Update/refresh global symlinks for new agents
  help          Show this help
EOF
    exit 0
}

cmd_setup() {
    echo "Setting up global symlinks..."
    mkdir -p "$CLAUDE_AGENTS_DIR"
    mkdir -p "$ANTIGRAVITY_SKILLS_DIR"

    # Symlink Claude Agents (flat structure)
    local active_agents=0
    local dir f
    for dir in design engineering game-development marketing paid-media sales product project-management \
                testing support spatial-computing specialized; do
        [[ -d "$REPO_ROOT/$dir" ]] || continue
        while read -r f; do
            # Only link files with YAML frontmatter
            if head -n 1 "$f" | grep -q "^---$"; then
                ln -sf "$f" "$CLAUDE_AGENTS_DIR/$(basename "$f")"
                ((active_agents++)) || true
            fi
        done < <(find "$REPO_ROOT/$dir" -maxdepth 1 -name "*.md" -type f)
    done
    ok "Linked $active_agents agents to $CLAUDE_AGENTS_DIR"

    # Symlink Antigravity Skills
    # First ensure integrations/antigravity exists (generate if needed)
    if [[ ! -d "$REPO_ROOT/integrations/antigravity" ]] || [[ -z "$(ls -A "$REPO_ROOT/integrations/antigravity" 2>/dev/null)" ]]; then
        warn "Antigravity skills missing from integrations/. Generating..."
        "$REPO_ROOT/scripts/convert.sh" --tool antigravity
    fi

    local linked_skills=0
    while read -r d; do
        ln -shf "$d" "$ANTIGRAVITY_SKILLS_DIR/$(basename "$d")"
        ((linked_skills++)) || true
    done < <(find "$REPO_ROOT/integrations/antigravity" -mindepth 1 -maxdepth 1 -type d)
    ok "Linked $linked_skills skills to $ANTIGRAVITY_SKILLS_DIR"
}

cmd_init_project() {
    local target_dir="${PWD}"
    echo "Initializing project in $target_dir..."

    # Symlink master CLAUDE.md
    if [[ -f "$MASTER_CLAUDE_MD" ]]; then
        ln -sf "$MASTER_CLAUDE_MD" "$target_dir/CLAUDE.md"
        ok "Linked master CLAUDE.md to local project root"
    else
        warn "Master CLAUDE.md not found at $MASTER_CLAUDE_MD. Skipping."
    fi

    # Project-scoped rules (Optional: e.g. for Cursor)
    if [[ -d "${REPO_ROOT}/integrations/cursor/rules" ]]; then
        mkdir -p "$target_dir/.cursor/rules"
        find "${REPO_ROOT}/integrations/cursor/rules" -name "*.mdc" | while read -r f; do
            ln -sf "$f" "$target_dir/.cursor/rules/$(basename "$f")"
        done
        ok "Linked Cursor rules to .cursor/rules/"
    fi
    
    # Windsurf rules
    if [[ -f "${REPO_ROOT}/integrations/windsurf/.windsurfrules" ]]; then
        ln -sf "${REPO_ROOT}/integrations/windsurf/.windsurfrules" "$target_dir/.windsurfrules"
        ok "Linked .windsurfrules to local project root"
    fi
}

cmd_sync() {
    # Alias for setup to maintain current links
    cmd_setup
}

[[ $# -lt 1 ]] && usage

case "$1" in
    setup)        cmd_setup ;;
    init-project) cmd_init_project ;;
    sync)         cmd_sync ;;
    help)         usage ;;
    *)            err "Unknown command: $1"; usage ;;
esac
