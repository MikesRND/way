#!/usr/bin/env bash
set -euo pipefail

# way — Multi-platform installer
#
# Two modes:
#
#   ./setup.sh
#       Global install. Symlinks each skills/way-* into ~/.claude/skills/,
#       ~/.codex/skills/, ~/.cursor/skills/, ~/.github/skills/. Available
#       in every repo you open with that tool.
#
#   ./setup.sh --project <target>
#       Project install. Run from inside this repo when it is mounted as
#       a submodule of <target> (any subpath under <target>/.way/ is fine).
#       Creates per-project symlinks at <target>/.claude/skills/way-* and
#       updates <target>/AGENTS.md. Travels with the project across
#       machines (relative paths only).
#
# Safe to re-run (idempotent). Skips any directory under skills/ that
# lacks a SKILL.md.

# --- Resolve repo root (works from any clone location) ---

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# --- CLI ---

usage() {
    sed -n '4,21p' "$0" | sed 's/^# \{0,1\}//'
}

PROJECT_MODE=false
PROJECT_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            PROJECT_MODE=true
            PROJECT_DIR="${2:-}"
            shift 2 || true
            ;;
        --project=*)
            PROJECT_MODE=true
            PROJECT_DIR="${1#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# --- Helpers ---

info()  { printf '[done] %s\n' "$1"; }
skip()  { printf '[skip] %s\n' "$1"; }
warn()  { printf '[WARN] %s\n' "$1"; }

SENTINEL="# way:installed"

is_interactive() { [ -t 0 ]; }

confirm() {
    local prompt="$1"
    if ! is_interactive; then
        return 1
    fi
    printf '%s [y/N] ' "$prompt"
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Create a symlink, skipping if already correct, warning on conflicts.
link_skill() {
    local target="$1" link_path="$2" name="$3"
    if [ -L "$link_path" ]; then
        local existing
        existing="$(readlink "$link_path")"
        if [ "$existing" = "$target" ]; then
            skip "$name already linked"
        else
            warn "$link_path points to $existing (expected $target)"
        fi
    elif [ -e "$link_path" ]; then
        warn "$link_path exists but is not a symlink — skipping"
    else
        ln -s "$target" "$link_path"
        info "Linked $name"
    fi
}

# Iterate skill directories that contain a SKILL.md. Anything else under
# skills/ (e.g. shared scaffolding) is intentionally not linked.
for_each_skill() {
    local platform_dir="$1" platform_label="$2"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -f "$skill_dir/SKILL.md" ] || { skip "$(basename "$skill_dir") has no SKILL.md"; continue; }
        local skill_name
        skill_name="$(basename "$skill_dir")"
        link_skill "$skill_dir" "$platform_dir/$skill_name" "$platform_label/$skill_name"
    done
}

# ===========================================================================
# Project mode — symlinks scoped to one target project, AGENTS.md update
# ===========================================================================

# Compute relative path from $1 (from-dir) to $2 (to-path).
# Prefers GNU realpath; falls back to Python.
relpath() {
    local from="$1" to="$2"
    if realpath --relative-to=/ / >/dev/null 2>&1; then
        realpath --relative-to="$from" "$to"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os.path,sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$from" "$to"
    else
        echo "ERROR: need GNU realpath or python3 to compute relative paths" >&2
        return 1
    fi
}

if [ "$PROJECT_MODE" = "true" ]; then
    if [ -z "$PROJECT_DIR" ]; then
        echo "ERROR: --project requires a path" >&2
        exit 2
    fi
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "ERROR: project path does not exist: $PROJECT_DIR" >&2
        exit 2
    fi
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

    SUBMOD_REL="$(relpath "$PROJECT_DIR" "$REPO_DIR")"
    case "$SUBMOD_REL" in
        ..*|/*)
            echo "ERROR: way repo at $REPO_DIR is not inside project $PROJECT_DIR." >&2
            echo "       Add way as a submodule of the project first, e.g.:" >&2
            echo "         cd $PROJECT_DIR" >&2
            echo "         git submodule add git@github.com:MikesRND/way.git .way/way" >&2
            echo "         .way/way/setup.sh --project ." >&2
            exit 1
            ;;
    esac

    echo ""
    echo "way Project Setup"
    echo "================="
    echo "Project:    $PROJECT_DIR"
    echo "Submodule:  $SUBMOD_REL"
    echo ""

    # Per-project Claude Code skill symlinks. Relative target so the link
    # survives a fresh clone of <project> on another machine.
    CLAUDE_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
    mkdir -p "$CLAUDE_SKILLS_DIR"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -f "$skill_dir/SKILL.md" ] || { skip "$(basename "$skill_dir") has no SKILL.md"; continue; }
        skill_name="$(basename "$skill_dir")"
        link_target="../../$SUBMOD_REL/skills/$skill_name"
        link_path="$CLAUDE_SKILLS_DIR/$skill_name"
        link_skill "$link_target" "$link_path" ".claude/skills/$skill_name"
    done

    # AGENTS.md — sentinel-guarded for idempotency. Append (don't clobber)
    # so a project that already has AGENTS.md keeps its content.
    AGENTS_MD="$PROJECT_DIR/AGENTS.md"
    if [ -f "$AGENTS_MD" ] && grep -q "^$SENTINEL\$" "$AGENTS_MD" 2>/dev/null; then
        skip "AGENTS.md already configured"
    else
        {
            [ -f "$AGENTS_MD" ] && echo ""
            echo "$SENTINEL"
            echo "## way-* Skills"
            echo ""
            echo "This project uses the **way** workflow framework: nine skills that"
            echo "separate architecture, planning, and implementation with explicit"
            echo "review gates between each stage. Opt-in per element — trivial work"
            echo "bypasses it; substantive design changes flow through it."
            echo ""
            echo "- Source:    \`$SUBMOD_REL/\`"
            echo "- Workflow:  \`.way/elements/<element_key>/\`"
            echo ""
            echo "Start with \`way-advisor\` if unsure which skill applies."
            echo ""
            echo "Available skills:"
            for skill_dir in "$SKILLS_DIR"/*/; do
                [ -f "$skill_dir/SKILL.md" ] || continue
                skill_name="$(basename "$skill_dir")"
                echo "- \`$SUBMOD_REL/skills/$skill_name/SKILL.md\`"
            done
        } >> "$AGENTS_MD"
        info "Updated AGENTS.md"
    fi

    echo ""
    echo "================="
    echo "Project install complete."
    echo "Workflow artifacts go under: $PROJECT_DIR/.way/elements/<element_key>/"
    exit 0
fi

# ===========================================================================
# Global mode — per-user installs across detected platforms
# ===========================================================================

# --- Header ---

echo ""
echo "way Setup"
echo "========="
echo "Repo: $REPO_DIR"
echo ""

installed_platforms=()

# ===========================================================================
# 1. Claude Code — ~/.claude/skills/
# ===========================================================================

CLAUDE_DIR="$HOME/.claude"

if command -v claude >/dev/null 2>&1 || [ -d "$CLAUDE_DIR" ]; then
    echo "--- Claude Code ---"
    mkdir -p "$CLAUDE_DIR/skills"
    for_each_skill "$CLAUDE_DIR/skills" "claude/skills"
    installed_platforms+=("Claude Code")
    echo ""
fi

# ===========================================================================
# 2. Codex CLI — ~/.codex/skills/
# ===========================================================================

CODEX_DIR="$HOME/.codex"

if command -v codex >/dev/null 2>&1 || [ -d "$CODEX_DIR" ]; then
    echo "--- Codex CLI ---"
    mkdir -p "$CODEX_DIR/skills"
    for_each_skill "$CODEX_DIR/skills" "codex/skills"

    AGENTS_MD="$REPO_DIR/AGENTS.md"
    if [ -f "$AGENTS_MD" ] && grep -q "$SENTINEL" "$AGENTS_MD" 2>/dev/null; then
        skip "AGENTS.md already configured"
    elif confirm "Create AGENTS.md in the repo for Codex CLI?"; then
        {
            echo "$SENTINEL"
            echo "## Skills Library"
            echo "Skills are available in the skills/ directory. When a task matches one of these"
            echo "skills, read the SKILL.md before starting work."
            echo ""
            echo "Available skills:"
            for skill_dir in "$SKILLS_DIR"/*/; do
                [ -f "$skill_dir/SKILL.md" ] || continue
                skill_name="$(basename "$skill_dir")"
                echo "- \`skills/$skill_name/SKILL.md\`"
            done
        } > "$AGENTS_MD"
        info "Created AGENTS.md"
    else
        skip "AGENTS.md (declined or non-interactive)"
    fi

    installed_platforms+=("Codex CLI")
    echo ""
fi

# ===========================================================================
# 3. Gemini CLI — ~/.gemini/skills/
# ===========================================================================

GEMINI_DIR="$HOME/.gemini"

if command -v gemini >/dev/null 2>&1 || [ -d "$GEMINI_DIR" ]; then
    echo "--- Gemini CLI ---"
    mkdir -p "$GEMINI_DIR/skills"
    for_each_skill "$GEMINI_DIR/skills" "gemini/skills"
    installed_platforms+=("Gemini CLI")
    echo ""
fi

# ===========================================================================
# 4. Cursor — ~/.cursor/skills/
# ===========================================================================

CURSOR_DIR="$HOME/.cursor"

if command -v cursor >/dev/null 2>&1 || [ -d "$CURSOR_DIR" ]; then
    echo "--- Cursor ---"
    mkdir -p "$CURSOR_DIR/skills"
    for_each_skill "$CURSOR_DIR/skills" "cursor/skills"
    installed_platforms+=("Cursor")
    echo ""
fi

# ===========================================================================
# 5. VS Code / Copilot — ~/.github/skills/
# ===========================================================================

GITHUB_DIR="$HOME/.github"

if [ -d "$GITHUB_DIR" ] || command -v code >/dev/null 2>&1; then
    echo "--- VS Code / Copilot ---"
    mkdir -p "$GITHUB_DIR/skills"
    for_each_skill "$GITHUB_DIR/skills" "github/skills"
    installed_platforms+=("VS Code / Copilot")
    echo ""
fi

# ===========================================================================
# Summary
# ===========================================================================

echo "========="
if [ ${#installed_platforms[@]} -eq 0 ]; then
    echo "No supported platforms detected."
    echo "Manually symlink skills/ into your platform's discovery directory."
else
    echo "Installed for: ${installed_platforms[*]}"
fi
echo ""
echo "Usage: invoke a way-* skill from any supported tool, e.g."
echo "  Claude Code: 'use way-advisor on src/auth/'"
echo "  Codex CLI:   'run way-advisor on src/auth/'"
echo ""
echo "To add a new skill, create skills/<name>/SKILL.md and re-run this script."
