#!/usr/bin/env bash
set -euo pipefail

# way — Project installer
#
# Run from inside this repo when it is mounted as a submodule of your
# target project (any subpath under <target>/.way/ is fine):
#
#   cd ~/projects/myapp
#   git submodule add git@github.com:MikesRND/way.git .way/way
#   .way/way/setup.sh                # uses CWD as target
#   .way/way/setup.sh ~/projects/x   # explicit target
#
# Creates, scoped to the target project only:
#
#   <target>/.agents/skills/way-*    canonical (Codex per-project discovery)
#   <target>/.claude/skills          dir-level symlink → ../.agents/skills
#                                    (Claude per-project discovery; falls back
#                                    to per-skill symlinks if .claude/skills
#                                    already exists as a real directory)
#   <target>/AGENTS.md               sentinel-guarded pointer block, appended
#                                    if the file already exists
#
# Idempotent. No user-global writes. Skips any directory under skills/
# that lacks a SKILL.md.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"
SENTINEL="# way:installed"

info() { printf '[done] %s\n' "$1"; }
skip() { printf '[skip] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }

usage() {
    sed -n '4,25p' "$0" | sed 's/^# \{0,1\}//'
}

# --- CLI ---

PROJECT_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --project)
            PROJECT_DIR="${2:-}"
            shift 2 || true
            ;;
        --project=*)
            PROJECT_DIR="${1#*=}"
            shift
            ;;
        --*)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(pwd)"
fi
if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: project path does not exist: $PROJECT_DIR" >&2
    exit 2
fi
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# --- Helpers ---

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

# --- Submodule path detection ---

SUBMOD_REL="$(relpath "$PROJECT_DIR" "$REPO_DIR")"
case "$SUBMOD_REL" in
    ..*|/*)
        echo "ERROR: way repo at $REPO_DIR is not inside project $PROJECT_DIR." >&2
        echo "       Add way as a submodule of the project first, e.g.:" >&2
        echo "         cd $PROJECT_DIR" >&2
        echo "         git submodule add git@github.com:MikesRND/way.git .way/way" >&2
        echo "         .way/way/setup.sh" >&2
        exit 1
        ;;
esac

echo ""
echo "way Setup"
echo "========="
echo "Project:   $PROJECT_DIR"
echo "Submodule: $SUBMOD_REL"
echo ""

# --- 1. Canonical: <project>/.agents/skills/way-* → submodule ---

AGENTS_SKILLS="$PROJECT_DIR/.agents/skills"
mkdir -p "$AGENTS_SKILLS"
for skill_dir in "$SKILLS_DIR"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || { skip "$(basename "$skill_dir") has no SKILL.md"; continue; }
    skill_name="$(basename "$skill_dir")"
    link_target="../../$SUBMOD_REL/skills/$skill_name"
    link_path="$AGENTS_SKILLS/$skill_name"
    link_skill "$link_target" "$link_path" ".agents/skills/$skill_name"
done

# --- 2. Claude discovery: .claude/skills → ../.agents/skills (or per-skill fallback) ---

CLAUDE_DIR="$PROJECT_DIR/.claude"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR"

if [ -L "$CLAUDE_SKILLS" ]; then
    existing="$(readlink "$CLAUDE_SKILLS")"
    if [ "$existing" = "../.agents/skills" ]; then
        skip ".claude/skills already linked to ../.agents/skills"
    else
        warn ".claude/skills points to $existing (expected ../.agents/skills) — leaving alone"
    fi
elif [ -d "$CLAUDE_SKILLS" ]; then
    info ".claude/skills exists as a directory — adding per-skill symlinks instead of dir-level link"
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        skill_name="$(basename "$skill_dir")"
        link_target="../../.agents/skills/$skill_name"
        link_path="$CLAUDE_SKILLS/$skill_name"
        link_skill "$link_target" "$link_path" ".claude/skills/$skill_name"
    done
elif [ -e "$CLAUDE_SKILLS" ]; then
    warn ".claude/skills exists and is not a directory or symlink — skipping"
else
    ln -s ../.agents/skills "$CLAUDE_SKILLS"
    info "Linked .claude/skills → ../.agents/skills"
fi

# --- 3. AGENTS.md (Codex + any AGENTS.md-aware tool) ---

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
        echo "- Discovery: \`.agents/skills/\` (Codex), \`.claude/skills/\` (Claude — symlinked to \`.agents/skills/\`)"
        echo ""
        echo "Start with \`way-advisor\` if unsure which skill applies."
        echo ""
        echo "Available skills:"
        for skill_dir in "$SKILLS_DIR"/*/; do
            [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name="$(basename "$skill_dir")"
            echo "- \`.agents/skills/$skill_name/SKILL.md\`"
        done
    } >> "$AGENTS_MD"
    info "Updated AGENTS.md"
fi

echo ""
echo "================="
echo "Project install complete."
echo "Workflow artifacts go under: $PROJECT_DIR/.way/elements/<element_key>/"
