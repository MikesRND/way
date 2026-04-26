#!/usr/bin/env bash
#
# way — Enable one or more skills in the target project.
#
#   .way/way/enable.sh <skill> [<skill>...]
#   .way/way/enable.sh --project <path> <skill> [<skill>...]
#   .way/way/enable.sh --all
#
# Removes the skill(s) from <project>/.way/disabled-skills and recreates
# the symlinks under <project>/.agents/skills/ (and under
# <project>/.claude/skills/ if it is in per-skill mode).

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

usage() {
    sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'
}

PROJECT_DIR=""
ENABLE_ALL=false
SKILLS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --project) PROJECT_DIR="${2:-}"; shift 2 || true ;;
        --project=*) PROJECT_DIR="${1#*=}"; shift ;;
        --all) ENABLE_ALL=true; shift ;;
        --*) err "unknown option: $1"; usage >&2; exit 2 ;;
        *) SKILLS+=("$1"); shift ;;
    esac
done

if [ "$ENABLE_ALL" = "false" ] && [ ${#SKILLS[@]} -eq 0 ]; then
    err "no skills given"
    usage >&2
    exit 2
fi

resolve_project
resolve_submodule

if [ "$ENABLE_ALL" = "true" ]; then
    while IFS= read -r s; do SKILLS+=("$s"); done < <(read_disabled)
    if [ ${#SKILLS[@]} -eq 0 ]; then
        skip "no disabled skills to enable"
        exit 0
    fi
fi

mkdir -p "$PROJECT_DIR/.agents/skills"

# If .claude/skills doesn't exist yet, create the dir-level symlink so
# enabling a skill is sufficient to make Claude see it.
mode="$(claude_skills_mode)"
if [ "$mode" = "missing" ]; then
    mkdir -p "$PROJECT_DIR/.claude"
    ln -s ../.agents/skills "$PROJECT_DIR/.claude/skills"
    info "Linked .claude/skills → ../.agents/skills"
fi

for skill in "${SKILLS[@]}"; do
    require_skill "$skill"
    remove_from_disabled "$skill"
    enable_skill "$skill"
done
