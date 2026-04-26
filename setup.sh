#!/usr/bin/env bash
#
# way — Project installer
#
# Run from inside this repo when it is mounted as a submodule of your
# target project (any subpath under <target>/.way/ is fine):
#
#   cd ~/projects/myapp
#   git submodule add https://github.com/MikesRND/way.git .way/way
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
#   <target>/.gitignore              sentinel-guarded entries for .agents/
#                                    and .claude/skills/way-*
#
# Skills listed in <target>/.way/disabled-skills are skipped (and their
# symlinks removed if previously installed). Use enable.sh / disable.sh
# to toggle individual skills.
#
# Idempotent. No user-global writes.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

usage() {
    sed -n '4,30p' "$0" | sed 's/^# \{0,1\}//'
}

# --- CLI ---

PROJECT_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --project) PROJECT_DIR="${2:-}"; shift 2 || true ;;
        --project=*) PROJECT_DIR="${1#*=}"; shift ;;
        --*) err "unknown option: $1"; usage >&2; exit 2 ;;
        *) PROJECT_DIR="$1"; shift ;;
    esac
done

resolve_project
resolve_submodule

echo ""
echo "way Setup"
echo "========="
echo "Project:   $PROJECT_DIR"
echo "Submodule: $SUBMOD_REL"
echo ""

# --- 1. .gitignore injection ---

inject_gitignore

# --- 2. Claude discovery: .claude/skills → ../.agents/skills (or per-skill fallback) ---

CLAUDE_DIR="$PROJECT_DIR/.claude"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR"

claude_mode="$(claude_skills_mode)"
case "$claude_mode" in
    dir-symlink)
        skip ".claude/skills already linked to ../.agents/skills"
        ;;
    missing)
        ln -s ../.agents/skills "$CLAUDE_SKILLS"
        info "Linked .claude/skills → ../.agents/skills"
        ;;
    per-skill)
        info ".claude/skills exists as a directory — using per-skill symlinks"
        ;;
    other)
        warn ".claude/skills exists in an unexpected form — leaving alone"
        ;;
esac

# --- 3. Per-skill links: .agents/skills/way-* (and .claude/skills/way-* in per-skill mode) ---

mkdir -p "$PROJECT_DIR/.agents/skills"

while IFS= read -r skill_name; do
    if is_disabled "$skill_name"; then
        # Skill is disabled — make sure no stale symlinks remain.
        if [ -L "$PROJECT_DIR/.agents/skills/$skill_name" ] || [ -L "$PROJECT_DIR/.claude/skills/$skill_name" ]; then
            disable_skill_links "$skill_name"
        else
            skip "$skill_name disabled"
        fi
    else
        enable_skill "$skill_name"
    fi
done < <(list_all_skills)

# --- 4. AGENTS.md (Codex + any AGENTS.md-aware tool) ---

AGENTS_MD="$PROJECT_DIR/AGENTS.md"
if [ -f "$AGENTS_MD" ] && grep -q "^$INSTALL_SENTINEL\$" "$AGENTS_MD" 2>/dev/null; then
    skip "AGENTS.md already configured"
else
    {
        [ -f "$AGENTS_MD" ] && echo ""
        echo "$INSTALL_SENTINEL"
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
        echo "Start with \`way-advisor\` if unsure which skill applies. Toggle skills"
        echo "with \`$SUBMOD_REL/enable.sh <skill>\` / \`$SUBMOD_REL/disable.sh <skill>\`."
        echo ""
        echo "Available skills:"
        list_all_skills | sed "s|^|- \`.agents/skills/|; s|\$|/SKILL.md\`|"
    } >> "$AGENTS_MD"
    info "Updated AGENTS.md"
fi

echo ""
echo "================="
echo "Project install complete."
echo "Workflow artifacts go under: $PROJECT_DIR/.way/elements/<element_key>/"
