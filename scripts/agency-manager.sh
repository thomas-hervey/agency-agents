#!/usr/bin/env bash

# agency-manager.sh -- Centralized management for The Agency agents.
# Handle global symlinks and project initialization.
set -euo pipefail

# Configuration
REPO_ROOT="/Users/thomas/Projects/tools_from_the_web/agency-agents"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"
ANTIGRAVITY_SKILLS_DIR="$HOME/.gemini/antigravity/skills"
MASTER_CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
BACKUP_DIR="$CLAUDE_DIR/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
ok() { echo -e "${GREEN}[OK]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  setup           Clean and create global symlinks for all tools
  sync            Update global symlinks (run after pulling repo updates)
  init-project    Link master CLAUDE.md and local rules to current directory
  backup          Create a timestamped backup of your Claude configuration
  modularize      Safely transition monolithic CLAUDE.md to an import-based structure
  help            Show this help message

Options:
  -n, --dry-run   Preview changes without applying them
EOF
    exit 1
}

backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local target="$BACKUP_DIR/$timestamp"
    mkdir -p "$target"
    ok "Backing up global configuration to $target..."
    
    # Copy all .md files from ~/.claude (excluding the backups dir itself)
    find "$CLAUDE_DIR" -maxdepth 1 -name "*.md" -exec cp {} "$target/" \;
    ok "Backup complete."
}

modularize() {
    if grep -q "@identity.md" "$MASTER_CLAUDE_MD"; then
        warn "CLAUDE.md already appears to be modularized. Skipping."
        return
    fi
    backup
    
    # Extract identity
    sed -n '/## About Me/,/## Stack/p' "$MASTER_CLAUDE_MD" | sed '$d' > "$CLAUDE_DIR/identity.md"
    
    # Extract stack & coding style
    sed -n '/## Stack/,/## Communication Style/p' "$MASTER_CLAUDE_MD" | sed '$d' > "$CLAUDE_DIR/standards.md"
    
    # Extract process (communication and git)
    sed -n '/## Communication Style/,$p' "$MASTER_CLAUDE_MD" > "$CLAUDE_DIR/process.md"
    
    # Create AGENTS.md template if it doesn't exist
    if [ ! -f "$CLAUDE_DIR/AGENTS.md" ]; then
        cat <<EOF > "$CLAUDE_DIR/AGENTS.md"
# Shared Agent Instructions
# These rules are followed by ALL AI tools (Claude, Cursor, Copilot, etc.)

## Shared Build Commands
- Test: pnpm test
- Build: pnpm build
- Lint: pnpm lint

## Common Standards
- Use ES modules
- Prefer named exports
- Maintain 100% test coverage for new features
EOF
        ok "Created AGENTS.md template."
    fi

    # Rewrite Master CLAUDE.md
    cat <<EOF > "$MASTER_CLAUDE_MD"
# Global Instructions

@identity.md
@standards.md
@process.md
@AGENTS.md

## Agency Specialists
# Activated specialists reside in the @agents/ directory.
# Reference specific agents here to load them into every session:
# Example: @agents/senior-developer.md
EOF

    ok "Modularization complete. Files created in $CLAUDE_DIR:"
    ls -1 "$CLAUDE_DIR/identity.md" "$CLAUDE_DIR/standards.md" "$CLAUDE_DIR/process.md" "$CLAUDE_DIR/AGENTS.md"
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
    ok "Initializing project in $(pwd)..."
    
    # Link Master CLAUDE.md
    if [ -f "CLAUDE.md" ]; then
        warn "CLAUDE.md already exists. Skipping link."
    else
        ln -s "$MASTER_CLAUDE_MD" "CLAUDE.md"
        ok "Linked Master CLAUDE.md"
    fi

    # Link Master AGENTS.md
    if [ -f "AGENTS.md" ]; then
        warn "AGENTS.md already exists. Skipping link."
    else
        ln -s "$CLAUDE_DIR/AGENTS.md" "AGENTS.md"
        ok "Linked Master AGENTS.md"
    fi

    # Project-specific rules template
    if [ ! -f ".claude.local.md" ]; then
        cat <<EOF > ".claude.local.md"
# Local Project Rules
# Add project-specific overrides here. This file should be gitignored.
EOF
        ok "Created .claude.local.md"
    fi

    # Optional agent bootstrapping
    if [ $# -gt 0 ]; then
        local agent_name=$1
        # Check if agent exists in global agents dir
        if [ -f "$CLAUDE_AGENTS_DIR/$agent_name.md" ]; then
            # We don't want to modify the symlinked master CLAUDE.md!
            # Instead, we create a local CLAUDE.md that imports the master + the agent.
            rm -f "CLAUDE.md"
            cat <<EOF > "CLAUDE.md"
@$MASTER_CLAUDE_MD
@agents/$agent_name.md
EOF
            ok "Bootstrapped project with $agent_name agent."
        else
            warn "Agent $agent_name not found in $CLAUDE_AGENTS_DIR"
        fi
    fi
    
    # Project-scoped rules (Optional: e.g. for Cursor)
    if [[ -d "${REPO_ROOT}/integrations/cursor/rules" ]]; then
        mkdir -p ".cursor/rules"
        find "${REPO_ROOT}/integrations/cursor/rules" -name "*.mdc" | while read -r f; do
            ln -sf "$f" ".cursor/rules/$(basename "$f")"
        done
        ok "Linked Cursor rules to .cursor/rules/"
    fi
    
    # Windsurf rules
    if [[ -f "${REPO_ROOT}/integrations/windsurf/.windsurfrules" ]]; then
        ln -sf "${REPO_ROOT}/integrations/windsurf/.windsurfrules" ".windsurfrules"
        ok "Linked .windsurfrules to local project root"
    fi
}

cmd_sync() {
    # Alias for setup to maintain current links
    cmd_setup
}

# Main router
case "${1:-help}" in
    setup)        shift; cmd_setup "$@" ;;
    sync)         shift; cmd_sync "$@" ;;
    init-project) shift; cmd_init_project "$@" ;;
    backup)       shift; backup "$@" ;;
    modularize)   shift; modularize "$@" ;;
    help)         usage ;;
    *)            usage ;;
esac
