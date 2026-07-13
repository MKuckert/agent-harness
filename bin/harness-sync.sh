#!/usr/bin/env bash
# harness-sync — sync opencode harness files between a main repo and project copies.
#
# Model: the project records the main-repo commit it was last synced against
# (the "base") in .harness-sync at the project root. All diffs are computed
# against that base, so both directions are 3-way-aware.
#
# Commands (run from the project root):
#   harness-sync init [--name <n>] <main-repo-path> <path>...
#                                                  record main repo + tracked paths,
#                                                  register project in main's registry
#   harness-sync status                            show pending drift in both directions
#   harness-sync pull                              main -> project (review patch first)
#   harness-sync push                              project -> main (review patch first)
#
# Commands (run from anywhere; use the registry in the main repo's .harness-sync):
#   harness-sync projects                          list registered projects
#   harness-sync forget <name>                     remove a project from the registry
#
# Tracked paths are relative to BOTH the project root and the main repo root,
# e.g.:  harness-sync init ~/src/agent-harness .opencode opencode.json
#
# State files:
#   project/.harness-sync:  main=<abs path>  name=<registry key>  base=<sha>  paths=<...>
#   main/.harness-sync:     main=true        project[<name>]=<abs project path>
set -euo pipefail

STATE=".harness-sync"
EDITOR_BIN=${EDITOR:-vi}

die() { echo "harness-sync: error: $*" >&2; exit 1; }
note() { echo "harness-sync: $*"; }

is_registry() { [[ -f $1 ]] && grep -qx 'main=true' "$1"; }

load_state() {
    [[ -f $STATE ]] || die "no $STATE here — run 'harness-sync init' first"
    is_registry "$STATE" && \
        die "this is the MAIN repo (main=true); pull/push/status run from a project root"
    MAIN=$(sed -n 's/^main=//p' "$STATE")
    NAME=$(sed -n 's/^name=//p' "$STATE")
    BASE=$(sed -n 's/^base=//p' "$STATE")
    PATHS=$(sed -n 's/^paths=//p' "$STATE")
    [[ -d $MAIN/.git || -f $MAIN/.git ]] || die "main repo not found at $MAIN"
    [[ -n $BASE && -n $PATHS ]] || die "corrupt $STATE"
}

save_state() {
    printf 'main=%s\nname=%s\nbase=%s\npaths=%s\n' "$MAIN" "$NAME" "$BASE" "$PATHS" > "$STATE"
}

# ---- registry (main repo's .harness-sync) -----------------------------------

# Locate the registry file: inside the main repo if we're in a project,
# in the current git toplevel if we're in the main repo itself.
registry_file() {
    if [[ -f $STATE ]] && ! is_registry "$STATE"; then
        echo "$(sed -n 's/^main=//p' "$STATE")/$STATE"
    else
        local top; top=$(git rev-parse --show-toplevel 2>/dev/null) \
            || die "not inside a git repo and no project $STATE found"
        echo "$top/$STATE"
    fi
}

registry_set() { # $1=registry-file $2=name $3=abs-path
    local reg=$1 name=$2 path=$3 tmp
    [[ $name =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid project name '$name' (use A-Za-z0-9._-)"
    local existing
    existing=$(sed -n "s/^project\[$name\]=//p" "$reg" 2>/dev/null || true)
    if [[ -n $existing && $existing != "$path" ]]; then
        die "name '$name' already registered for $existing — pick another with --name"
    fi
    tmp=$(mktemp)
    {
        echo "main=true"
        [[ -f $reg ]] && grep '^project\[' "$reg" | grep -v "^project\[$name\]=" || true
        echo "project[$name]=$path"
    } > "$tmp"
    mv "$tmp" "$reg"
}

cmd_projects() {
    local reg; reg=$(registry_file)
    [[ -f $reg ]] || die "no registry at $reg"
    is_registry "$reg" || die "$reg is not a main-repo registry (missing main=true)"
    local line name path mark
    grep '^project\[' "$reg" | while IFS= read -r line; do
        name=${line#project[}; name=${name%%]=*}
        path=${line#*=}
        mark="ok"
        [[ -f $path/$STATE ]] || mark="MISSING (no $STATE at path)"
        printf '%-20s %s  [%s]\n' "$name" "$path" "$mark"
    done
    grep -q '^project\[' "$reg" || note "no projects registered"
}

cmd_forget() {
    [[ $# -eq 1 ]] || die "usage: harness-sync forget <name>"
    local reg; reg=$(registry_file)
    [[ -f $reg ]] || die "no registry at $reg"
    grep -q "^project\[$1\]=" "$reg" || die "no project named '$1' in $reg"
    sed -i.bak "/^project\[$1\]=/d" "$reg" && rm -f "$reg.bak"
    note "removed '$1' from $reg"
}

main_head() { git -C "$MAIN" rev-parse HEAD; }

# Open the patch in $EDITOR, then confirm. Emptying the file aborts.
review_patch() {
    local patch=$1 label=$2
    if [[ ! -s $patch ]]; then
        note "no changes to $label"
        return 1
    fi
    echo "----------------------------------------------------------------"
    echo " Review the patch ($label). Delete hunks you don't want."
    echo " Save an EMPTY file to abort."
    echo "----------------------------------------------------------------"
    read -rp "Press enter to open editor... " _
    "$EDITOR_BIN" "$patch"
    if [[ ! -s $patch ]]; then
        note "patch emptied — aborted"
        return 1
    fi
    read -rp "Apply this patch? [y/N] " ans
    [[ $ans == y* || $ans == Y* ]] || { note "aborted"; return 1; }
    return 0
}

# Build a temporary worktree of the main repo at $BASE with the project's
# current harness files copied in, index updated. Prints the worktree path.
project_snapshot_worktree() {
    local wt
    wt=$(mktemp -d /tmp/harness-sync.XXXXXX)
    git -C "$MAIN" worktree add --quiet --detach "$wt" "$BASE"
    local p
    for p in $PATHS; do
        rm -rf "${wt:?}/$p"
        if [[ -e $p ]]; then
            mkdir -p "$wt/$(dirname "$p")"
            cp -a "$p" "$wt/$p"
        fi
    done
    ( cd "$wt" && git add -A -- $PATHS )
    echo "$wt"
}

drop_worktree() {
    git -C "$MAIN" worktree remove --force "$1" 2>/dev/null || rm -rf "$1"
    git -C "$MAIN" worktree prune
}

cmd_init() {
    NAME=""
    if [[ ${1:-} == --name ]]; then
        NAME=${2:-}; shift 2 || die "--name needs a value"
    fi
    [[ $# -ge 2 ]] || die "usage: harness-sync init [--name <n>] <main-repo-path> <path>..."
    MAIN=$(cd "$1" && pwd); shift
    [[ -d $MAIN/.git || -f $MAIN/.git ]] || die "$MAIN is not a git repo"
    [[ -n $NAME ]] || NAME=$(basename "$PWD")
    PATHS=$*
    BASE=$(main_head)
    registry_set "$MAIN/$STATE" "$NAME" "$PWD"
    save_state
    note "initialized: main=$MAIN base=${BASE:0:12} paths=[$PATHS]"
    note "registered as project[$NAME] in $MAIN/$STATE"
    note "assuming project files currently match main@${BASE:0:12};"
    note "if not, run 'harness-sync status' to see the drift."
}

cmd_status() {
    load_state
    local head; head=$(main_head)
    echo "main:  $MAIN"
    echo "base:  ${BASE:0:12}    main HEAD: ${head:0:12}"
    echo
    echo "== incoming (effective changes a 'pull' would make) =="
    local wt; wt=$(project_snapshot_worktree)
    ( cd "$wt" && git -c user.name=harness-sync -c user.email=sync@localhost \
          commit --quiet --allow-empty -m "project snapshot" )
    git -C "$MAIN" diff "$BASE" "$head" -- $PATHS \
        | git -C "$wt" apply --3way --whitespace=nowarn 2>/dev/null || true
    ( cd "$wt" && git diff HEAD --stat ) || true
    drop_worktree "$wt"
    echo
    echo "== outgoing (project vs base, would leave on 'push') =="
    wt=$(project_snapshot_worktree)
    ( cd "$wt" && git diff --cached --stat ) || true
    drop_worktree "$wt"
}

cmd_pull() {
    load_state
    local head; head=$(main_head)
    if [[ $head == "$BASE" ]]; then
        note "already up to date with main (${BASE:0:12})"
        exit 0
    fi

    # 3-way merge in a temp worktree: start from the project's CURRENT files
    # (committed as a snapshot on top of base), merge in main's base..HEAD
    # changes via git apply --3way, then diff the merge result against the
    # snapshot. The reviewed patch therefore contains only the *effective*
    # changes for this project — hunks you already have (e.g. from a previous
    # push, or identical local edits) disappear instead of breaking apply.
    local wt; wt=$(project_snapshot_worktree)
    ( cd "$wt" && git -c user.name=harness-sync -c user.email=sync@localhost \
          commit --quiet --allow-empty -m "project snapshot" )
    local conflicts=0
    git -C "$MAIN" diff "$BASE" "$head" -- $PATHS \
        | git -C "$wt" apply --3way --whitespace=nowarn || conflicts=1

    local patch; patch=$(mktemp /tmp/harness-pull.XXXXXX.patch)
    git -C "$wt" diff HEAD > "$patch"
    drop_worktree "$wt"

    if [[ ! -s $patch ]]; then
        rm -f "$patch"
        BASE=$head; save_state
        note "project already contains main's changes — base fast-forwarded to ${BASE:0:12}"
        exit 0
    fi
    [[ $conflicts -eq 1 ]] && \
        note "some hunks conflict: patch contains '<<<<<<<' markers — resolve them in the editor or after applying"

    if review_patch "$patch" "main -> project"; then
        # The patch was generated against the exact current project state,
        # so a plain apply suffices (unless you hand-edited hunks).
        if patch -p1 --no-backup-if-mismatch < "$patch"; then
            note "applied cleanly"
        else
            note "some hunks failed (patch was hand-edited?) — check *.rej files"
        fi
        BASE=$head
        save_state
        note "base advanced to ${BASE:0:12}"
    fi
    rm -f "$patch"
}

cmd_push() {
    load_state
    [[ -z $(git -C "$MAIN" status --porcelain -- $PATHS) ]] \
        || die "main repo has uncommitted changes in [$PATHS] — commit or stash them first"
    local wt patch
    wt=$(project_snapshot_worktree)
    patch=$(mktemp /tmp/harness-push.XXXXXX.patch)
    ( cd "$wt" && git diff --cached ) > "$patch"
    drop_worktree "$wt"
    if review_patch "$patch" "project -> main"; then
        # --3way gives a real merge against the base blobs, which the main
        # repo has. Conflicts land as markers in the working tree.
        if git -C "$MAIN" apply --3way "$patch"; then
            note "applied to main working tree"
        else
            note "applied WITH CONFLICTS in $MAIN — resolve, then commit"
        fi
        note "next: review & commit in $MAIN, then run 'harness-sync pull'"
        note "here to fast-forward the base past your own change."
    fi
    rm -f "$patch"
}

case ${1:-} in
    init)     shift; cmd_init "$@" ;;
    status)   cmd_status ;;
    pull)     cmd_pull ;;
    push)     cmd_push ;;
    projects) cmd_projects ;;
    forget)   shift; cmd_forget "$@" ;;
    *) sed -n '2,23p' "$0"; exit 1 ;;
esac
