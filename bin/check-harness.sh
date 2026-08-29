#!/usr/bin/env bash
# check-harness — lightweight, dependency-free static checks for the
# OpenCode lifecycle harness (issue #101). Run from the agent-harness repo.
set -u

cd "$(git rev-parse --show-toplevel)" || { echo "not a git repo"; exit 1; }

A=".opencode/agents"
C=".opencode/commands"
fail=0

pass() { printf 'PASS  %s\n' "$1"; }
failmsg() { printf 'FAIL  %s\n' "$1"; fail=1; }

frontmatter() { awk 'NR==1 && $0!="---"{exit} NR>1{if($0=="---")exit; print}' "$1"; }

has() { # $1=file $2=needle $3=description
    if grep -qF -- "$2" "$1" 2>/dev/null; then pass "$3"; else failmsg "$3"; fi
}

# --- agent modes -------------------------------------------------------------
has "$A/Orchestrator.md" 'mode: primary'   "Orchestrator is a primary (selectable/delegable) agent"
if grep -q 'hidden: true' "$A/Orchestrator.md"; then failmsg "Orchestrator must not be hidden"; else pass "Orchestrator must not be hidden"; fi
for a in Planner Builder Testing; do
    if grep -q 'mode: subagent' "$A/$a.md" && grep -q 'hidden: true' "$A/$a.md"; then
        pass "$a is a hidden subagent"
    else
        failmsg "$a must be mode: subagent and hidden: true"
    fi
done
if grep -q 'hidden: true' "$A/Buddy.md" || ! grep -q 'mode: primary' "$A/Buddy.md"; then
    failmsg "Buddy must remain a visible primary agent (default)"
else
    pass "Buddy remains a visible primary agent (default)"
fi

# --- delegation graph (deny-by-default task targets) --------------------------
check_targets() { # $1=agent $2=allowed (space sep) $3=forbidden (space sep)
    local f="$A/$1.md" allowed forbidden ok=0
    local fm; fm=$(frontmatter "$f")
    echo "$fm" | grep -q '"\*": deny' || { failmsg "$1 task targets must be deny-by-default"; ok=1; }
    for allowed in $2; do
        echo "$fm" | grep -q "\"$allowed\": allow" || { failmsg "$1 must allow task target $allowed"; ok=1; }
    done
    for forbidden in $3; do
        if echo "$fm" | grep -q "\"$forbidden\": allow"; then
            failmsg "$1 must NOT allow task target $forbidden"; ok=1
        fi
    done
    [ $ok -eq 0 ] && pass "$1 task target mapping (deny-by-default, expected edges only)"
}
check_targets Buddy        "Orchestrator Explorer Librarian" "Planner Builder Testing PlanReviewer CodeReviewer Committer"
check_targets Orchestrator "Planner Builder Testing PlanReviewer CodeReviewer Explorer Librarian" "Committer Buddy"
check_targets Planner      "Explorer Librarian PlanReviewer" "Builder Testing Committer Buddy Orchestrator"
check_targets Builder      "Committer" "Explorer Librarian Testing PlanReviewer CodeReviewer"
check_targets PlanReviewer "Explorer Librarian" "Builder Testing Committer"
check_targets CodeReviewer "Explorer Librarian" "Builder Testing Committer"
for a in Explorer Librarian Testing Committer; do
    if frontmatter "$A/$a.md" | grep -qE '^\s*task:\s*(deny|\*)'; then
        pass "$a is a leaf (task denied)"
    else
        # allow explicit 'task: deny' or a deny-only mapping
        if frontmatter "$A/$a.md" | grep -q 'task: deny'; then
            pass "$a is a leaf (task denied)"
        else
            failmsg "$a must be a leaf (no task delegation)"
        fi
    fi
done

# --- config ------------------------------------------------------------------
has opencode.jsonc '"build": {' "built-in build agent configured"
for b in build plan general explore; do
    if awk "/\"$b\": \\{/,/\\}/" opencode.jsonc | grep -q '"disable": true'; then
        pass "built-in $b agent disabled"
    else
        failmsg "built-in $b agent must be disabled"
    fi
done
has opencode.jsonc '"subagent_depth": 5' "subagent_depth is 5 in agent-harness/opencode.jsonc"
if [ -f ../opencode/opencode.jsonc ]; then
    has ../opencode/opencode.jsonc '"subagent_depth": 5' "subagent_depth is 5 in opencode/opencode.jsonc (parent runtime config)"
elif [ -f ../opencode.jsonc ]; then
    has ../opencode.jsonc '"subagent_depth": 5' "subagent_depth is 5 in parent opencode.jsonc"
else
    echo "SKIP  no parent opencode runtime config found beside the harness"
fi

# --- commands ----------------------------------------------------------------
[ -f "$C/plan.md" ] && pass "/plan command exists" || failmsg "/plan command missing"
[ ! -f "$C/implement_next_task.md" ] && pass "/implement_next_task removed" || failmsg "/implement_next_task must be removed"
[ -f "$C/continue_implementation.md" ] && pass "/continue_implementation exists" || failmsg "/continue_implementation missing"
for c in plan continue_implementation review_plan review_code research; do
    has "$C/$c.md" 'agent: Orchestrator' "/$c routes through Orchestrator"
done
has "$C/archive_plan.md" 'agent: Buddy' "/archive_plan remains Buddy-owned"
grep -q 'customize-opencode\|SKILL.md' "$C/research.md" && \
    failmsg "/research must no longer generate skills" || pass "/research no longer generates skills"
has "$C/review_code.md" 'identifiable task' "/review_code requires an identifiable task/scope"

# --- planner template ---------------------------------------------------------
for field in "Task ID" "Depends On" "Owned Paths" "Shared Resources" "Parallel Safe" "Validation Commands"; do
    has "$A/Planner.md" "$field" "Planner template includes $field"
done

# --- reviewer / builder contracts --------------------------------------------
has "$A/Builder.md" '"PLAN.md": deny' "Builder cannot edit PLAN.md"
has "$A/Committer.md" 'explicit list' "Committer stages only an explicit path list"
has "$A/CodeReviewer.md" 'exactly one identified task' "CodeReviewer is task/scope-specific"
has "$A/Orchestrator.md" 'at most **two**' "Orchestrator enforces the two-Builder batch limit"
has "$A/Orchestrator.md" 'at most **four**' "Orchestrator enforces the four-Librarian research limit"
has "$A/Orchestrator.md" 'exactly once' "Orchestrator resumes a failed child session exactly once"

# --- librarian write confinement ----------------------------------------------
fm=$(frontmatter "$A/Librarian.md")
if echo "$fm" | grep -q '"\*": deny' && \
   echo "$fm" | grep -q 'research/results/\*\*' ; then
    pass "Librarian write scope confined to research/results/**"
else
    failmsg "Librarian edit permissions must be deny-by-default with only research/results/** allowed"
fi
[ -f research/results/.gitkeep ] && pass "research/results/ destination provisioned in the harness" || failmsg "research/results/ destination missing"

echo
if [ $fail -eq 0 ]; then
    echo "All static checks passed."
else
    echo "One or more static checks FAILED."
fi
exit $fail
