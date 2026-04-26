# shellcheck shell=bash
#
# Shared helpers for way installer scripts (setup.sh, enable.sh,
# disable.sh). Source this from each script after setting REPO_DIR.
#
# Conventions:
#   - All operations are scoped to <project>; nothing user-global.
#   - PROJECT_DIR is resolved either from --project / first positional
#     arg, or defaults to $(pwd).
#   - Disabled skills are recorded in <project>/.way/disabled-skills.

set -euo pipefail

REPO_DIR="${REPO_DIR:?common.sh requires REPO_DIR}"
SKILLS_DIR="$REPO_DIR/skills"

INSTALL_SENTINEL="# way:installed"
GITIGNORE_SENTINEL="# way:gitignore"

# --- Reporting ---

info() { printf '[done] %s\n' "$1"; }
skip() { printf '[skip] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
err()  { printf 'ERROR: %s\n' "$1" >&2; }

# --- Path helpers ---

# Compute relative path from $1 (from-dir) to $2 (to-path). Prefers GNU
# realpath; falls back to Python.
relpath() {
    local from="$1" to="$2"
    if realpath --relative-to=/ / >/dev/null 2>&1; then
        realpath --relative-to="$from" "$to"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import os.path,sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))' "$from" "$to"
    else
        err "need GNU realpath or python3 to compute relative paths"
        return 1
    fi
}

# Idempotent symlink creation. $1=target string, $2=link path, $3=label.
make_symlink() {
    local target="$1" path="$2" label="$3"
    if [ -L "$path" ]; then
        local existing
        existing="$(readlink "$path")"
        if [ "$existing" = "$target" ]; then
            skip "$label already linked"
        else
            warn "$path points to $existing (expected $target)"
        fi
    elif [ -e "$path" ]; then
        warn "$path exists but is not a symlink — skipping"
    else
        ln -s "$target" "$path"
        info "Linked $label"
    fi
}

# Idempotent symlink removal. $1=link path, $2=label.
remove_symlink() {
    local path="$1" label="$2"
    if [ -L "$path" ]; then
        rm "$path"
        info "Removed $label"
    elif [ -e "$path" ]; then
        warn "$path is not a symlink — leaving alone"
    else
        skip "$label not present"
    fi
}

# --- Project resolution ---

# Resolve and validate PROJECT_DIR. Sets PROJECT_DIR to absolute path.
resolve_project() {
    if [ -z "${PROJECT_DIR:-}" ]; then
        PROJECT_DIR="$(pwd)"
    fi
    if [ ! -d "$PROJECT_DIR" ]; then
        err "project path does not exist: $PROJECT_DIR"
        exit 2
    fi
    PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
}

# Compute SUBMOD_REL — way's path relative to project. Errors if way is
# outside the project.
resolve_submodule() {
    SUBMOD_REL="$(relpath "$PROJECT_DIR" "$REPO_DIR")"
    case "$SUBMOD_REL" in
        ..*|/*)
            err "way repo at $REPO_DIR is not inside project $PROJECT_DIR."
            err "       Add way as a submodule of the project first, e.g.:"
            err "         cd $PROJECT_DIR"
            err "         git submodule add https://github.com/MikesRND/way.git .way/way"
            exit 1
            ;;
    esac
}

# --- Skill metadata ---

# List every skill under skills/ that has a SKILL.md, one per line.
list_all_skills() {
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        basename "$skill_dir"
    done | sort
}

# Verify a skill exists under skills/. Errors with usage if not.
require_skill() {
    local skill="$1"
    if [ ! -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
        err "no such skill: $skill"
        echo "Available skills:" >&2
        list_all_skills | sed 's/^/  /' >&2
        exit 2
    fi
}

# --- Disabled-skills state file ---

# Path to <project>/.way/disabled-skills.
disabled_file() {
    echo "$PROJECT_DIR/.way/disabled-skills"
}

# Stream disabled skill names: ignore blank lines and comments.
read_disabled() {
    local file
    file="$(disabled_file)"
    if [ -f "$file" ]; then
        sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$file" | grep -v '^$' || true
    fi
}

# Returns 0 if $1 is in the disabled list.
is_disabled() {
    local skill="$1"
    read_disabled | grep -qx -- "$skill"
}

# Append $1 to disabled list, creating the file with a header comment if
# it does not yet exist. Idempotent.
add_to_disabled() {
    local skill="$1"
    local file
    file="$(disabled_file)"
    mkdir -p "$(dirname "$file")"
    if [ ! -f "$file" ]; then
        cat > "$file" <<'EOF'
# way: disabled skills (one per line; comments after #)
# Skills listed here are skipped by setup.sh and have their symlinks
# removed by disable.sh. Re-enable with `<submod>/enable.sh <skill>`.
# This file is project policy — check it in.
EOF
    fi
    if grep -qx -- "$skill" "$file"; then
        skip "$skill already in $(relpath "$PROJECT_DIR" "$file")"
    else
        echo "$skill" >> "$file"
        info "Recorded $skill in $(relpath "$PROJECT_DIR" "$file")"
    fi
}

# Remove $1 from the disabled list. Idempotent.
remove_from_disabled() {
    local skill="$1"
    local file
    file="$(disabled_file)"
    if [ -f "$file" ] && grep -qx -- "$skill" "$file"; then
        local tmp
        tmp="$(mktemp)"
        grep -vx -- "$skill" "$file" > "$tmp"
        mv "$tmp" "$file"
        info "Removed $skill from $(relpath "$PROJECT_DIR" "$file")"
    fi
}

# --- Discovery layout ---

# Echo one of: missing | dir-symlink | per-skill | other.
# - missing      : <project>/.claude/skills does not exist
# - dir-symlink  : it's a symlink to ../.agents/skills (canonical)
# - per-skill    : real directory; we add per-skill symlinks under it
# - other        : symlink to something else, or a file — leave alone
claude_skills_mode() {
    local p="$PROJECT_DIR/.claude/skills"
    if [ -L "$p" ]; then
        local target
        target="$(readlink "$p")"
        if [ "$target" = "../.agents/skills" ]; then
            echo "dir-symlink"
        else
            echo "other"
        fi
    elif [ -d "$p" ]; then
        echo "per-skill"
    elif [ -e "$p" ]; then
        echo "other"
    else
        echo "missing"
    fi
}

# --- Per-skill enable / disable primitives ---

# Create the symlink(s) for one skill.
enable_skill() {
    local skill="$1"
    local agents_link="$PROJECT_DIR/.agents/skills/$skill"
    local agents_target="../../$SUBMOD_REL/skills/$skill"
    mkdir -p "$PROJECT_DIR/.agents/skills"
    make_symlink "$agents_target" "$agents_link" ".agents/skills/$skill"

    local mode
    mode="$(claude_skills_mode)"
    if [ "$mode" = "per-skill" ]; then
        local claude_link="$PROJECT_DIR/.claude/skills/$skill"
        local claude_target="../../.agents/skills/$skill"
        make_symlink "$claude_target" "$claude_link" ".claude/skills/$skill"
    fi
    # In dir-symlink mode, .claude/skills follows .agents/skills automatically.
    # In missing / other mode, the caller (setup.sh) is responsible for
    # creating the dir-level link first.
}

# Remove the symlink(s) for one skill.
disable_skill_links() {
    local skill="$1"
    remove_symlink "$PROJECT_DIR/.agents/skills/$skill" ".agents/skills/$skill"
    local mode
    mode="$(claude_skills_mode)"
    if [ "$mode" = "per-skill" ]; then
        remove_symlink "$PROJECT_DIR/.claude/skills/$skill" ".claude/skills/$skill"
    fi
}

# --- .gitignore injection ---

# Append way's gitignore entries to <project>/.gitignore if not already
# present. Sentinel-guarded; idempotent.
inject_gitignore() {
    local file="$PROJECT_DIR/.gitignore"
    if [ -f "$file" ] && grep -qF "$GITIGNORE_SENTINEL" "$file"; then
        skip ".gitignore already configured"
        return 0
    fi
    {
        [ -f "$file" ] && echo ""
        echo "$GITIGNORE_SENTINEL"
        echo "# way framework — symlinks recreated by .way/way/setup.sh"
        echo ".agents/"
        echo ".claude/skills/way-*"
    } >> "$file"
    info "Updated .gitignore"
}
