#!/usr/bin/env bash
#
# way — Disable one or more skills in the target project.
#
#   .way/way/disable.sh <skill> [<skill>...]
#   .way/way/disable.sh --project <path> <skill> [<skill>...]
#   .way/way/disable.sh --all
#
# Records the skill(s) in <project>/.way/disabled-skills and removes
# the symlinks under <project>/.agents/skills/ (and under
# <project>/.claude/skills/ if it is in per-skill mode). Re-running
# setup.sh keeps disabled skills off until you run enable.sh.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

usage() {
    sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'
}

PROJECT_DIR=""
DISABLE_ALL=false
SKILLS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --project) PROJECT_DIR="${2:-}"; shift 2 || true ;;
        --project=*) PROJECT_DIR="${1#*=}"; shift ;;
        --all) DISABLE_ALL=true; shift ;;
        --*) err "unknown option: $1"; usage >&2; exit 2 ;;
        *) SKILLS+=("$1"); shift ;;
    esac
done

if [ "$DISABLE_ALL" = "false" ] && [ ${#SKILLS[@]} -eq 0 ]; then
    err "no skills given"
    usage >&2
    exit 2
fi

resolve_project
resolve_submodule

if [ "$DISABLE_ALL" = "true" ]; then
    while IFS= read -r s; do SKILLS+=("$s"); done < <(list_all_skills)
fi

for skill in "${SKILLS[@]}"; do
    require_skill "$skill"
    add_to_disabled "$skill"
    disable_skill_links "$skill"
done
