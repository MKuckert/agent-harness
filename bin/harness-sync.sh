#!/usr/bin/env bash
# harness-sync — sync opencode harness files between a main repo and project copies.
#
# Model: the project records the main-repo commit it was last synced against
# (the "base") in .harness-sync at the project root. All diffs are computed
# against that base, so both directions are 3-way-aware.
#
# Commands (run from the project root):
#   harness-sync init <main-repo-path> <path>...   record main repo + tracked paths
#   harness-sync status                            show pending drift in both directions
#   harness-sync pull                              main -> project (review patch first)
#   harness-sync push                              project -> main (review patch first)
#
# Tracked paths are relative to BOTH the project root and the main repo root,
# e.g.:  harness-sync init ~/src/agent-harness .opencode opencode.json
set -euo pipefail

STATE=".harness-sync"
EDITOR_BIN=${EDITOR:-vi}

die() { echo "harness-sync: error: $*" >&2; exit 1; }
note() { echo "harness-sync: $*"; }

load_state() {
    [[ -f $STATE ]] || die "no $STATE here — run 'harness-sync init' first"
    MAIN=$(sed -n 's/^main=//p' "$STATE")
    BASE=$(sed -n 's/^base=//p' "$STATE")
    PATHS=$(sed -n 's/^paths=//p' "$STATE")
    [[ -d $MAIN/.git || -f $MAIN/.git ]] || die "main repo not found at $MAIN"
    [[ -n $BASE && -n $PATHS ]] || die "corrupt $STATE"
}

save_state() {
    printf 'main=%s\nbase=%s\npaths=%s\n' "$MAIN" "$BASE" "$PATHS" > "$STATE"
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
    git -C "$MAIN" worktree remove --force "$1" 2>/dev/null || safe-rm -rf "$1"
    git -C "$MAIN" worktree prune
}

cmd_init() {
    [[ $# -ge 2 ]] || die "usage: harness-sync init <main-repo-path> <path>..."
    MAIN=$(cd "$1" && pwd); shift
    [[ -d $MAIN/.git || -f $MAIN/.git ]] || die "$MAIN is not a git repo"
    PATHS=$*
    BASE=$(main_head)
    save_state
    note "initialized: main=$MAIN base=${BASE:0:12} paths=[$PATHS]"
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
    git -C "$MAIN" diff --quiet && git -C "$MAIN" diff --cached --quiet \
        || die "main repo has uncommitted changes — commit or stash them first"
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
    init)   shift; cmd_init "$@" ;;
    status) cmd_status ;;
    pull)   cmd_pull ;;
    push)   cmd_push ;;
    *) sed -n '2,15p' "$0"; exit 1 ;;
esac
