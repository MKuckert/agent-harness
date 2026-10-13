#!/usr/bin/env bash
# check-harness — lightweight, dependency-free static checks for the
# OpenCode V2 lifecycle harness (issue #101; V2-native frontmatter since #113).
# Run from the agent-harness repo.
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

# V2 permissions frontmatter is an ordered YAML list of rules:
#   - action: <action>
#     resource: <resource>
#     effect: allow|ask|deny
# perm <file> <action> <resource> <effect> succeeds if that exact rule exists.
perm() { # $1=file $2=action $3=resource $4=effect
    frontmatter "$1" | awk -v a="$2" -v r="$3" -v e="$4" '
        /action:/   {act=$NF;  sub(/^"/,"",act); sub(/"$/,"",act)}
        /resource:/ {res=$NF;  sub(/^"/,"",res); sub(/"$/,"",res)}
        /effect:/   {eff=$NF;  sub(/^"/,"",eff); sub(/"$/,"",eff)
                          if (act==a && res==r && eff==e) {found=1; exit}}
        END {exit found?0:1}'
}

# is_leaf <file>: no explicit subagent allow rule (the leading "*" deny
# covers subagent, so absence of an allow means the agent cannot delegate).
is_leaf() { # $1=file
    frontmatter "$1" | awk '
        /action:/ && $NF=="subagent" {in_sub=1; next}
        in_sub && /effect:/ {if ($NF=="allow") exit 1; in_sub=0}
        END {exit 0}'
}

# --- agent modes -------------------------------------------------------------
has "$A/Orchestrator.md" 'mode: all'       "Orchestrator is selectable and subagent-launching"
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
has opencode.jsonc '"default_agent": "Buddy"' "Buddy is the configured default agent"

# --- delegation graph (deny-by-default subagent targets) ----------------------
check_targets() { # $1=agent $2=allowed (space sep) $3=forbidden (space sep)
    local f="$A/$1.md" ok=0
    perm "$f" "*" "*" deny || { failmsg "$1 permissions must be deny-by-default"; ok=1; }
    for t in $2; do
        perm "$f" subagent "$t" allow || { failmsg "$1 must allow subagent target $t"; ok=1; }
    done
    for t in $3; do
        if perm "$f" subagent "$t" allow; then
            failmsg "$1 must NOT allow subagent target $t"; ok=1
        fi
    done
    [ $ok -eq 0 ] && pass "$1 subagent target mapping (deny-by-default, expected edges only)"
}
check_targets Buddy        "Orchestrator Explorer Librarian" "Planner Builder Testing PlanReviewer CodeReviewer Committer"
check_targets Orchestrator "Planner Builder Testing PlanReviewer CodeReviewer Explorer Librarian" "Committer Buddy"
check_targets Planner      "Explorer Librarian PlanReviewer" "Builder Testing Committer Buddy Orchestrator"
check_targets Builder      "Committer" "Explorer Librarian Testing PlanReviewer CodeReviewer"
check_targets PlanReviewer "Explorer Librarian" "Builder Testing Committer"
check_targets CodeReviewer "Explorer Librarian" "Builder Testing Committer"
for a in Explorer Librarian Testing Committer; do
    if is_leaf "$A/$a.md"; then
        pass "$a is a leaf (no subagent delegation)"
    else
        failmsg "$a must be a leaf (no subagent delegation)"
    fi
done

# --- config ------------------------------------------------------------------
has opencode.jsonc '"build": {' "built-in build agent configured"
for b in build plan general explore; do
    if awk "/\"$b\": \\{/,/\\}/" opencode.jsonc | grep -q '"disabled": true'; then
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
perm "$A/Builder.md" edit "PLAN.md" deny && pass "Builder cannot edit PLAN.md" || failmsg "Builder cannot edit PLAN.md"
has "$A/Committer.md" 'explicit list' "Committer stages only an explicit path list"
has "$A/CodeReviewer.md" 'exactly one identified task' "CodeReviewer is task/scope-specific"
has "$A/Orchestrator.md" 'at most **two**' "Orchestrator enforces the two-Builder batch limit"
has "$A/Orchestrator.md" 'at most **four**' "Orchestrator enforces the four-Librarian research limit"
has "$A/Orchestrator.md" 'exactly once' "Orchestrator resumes a failed child session exactly once"

# --- librarian write confinement ----------------------------------------------
perm "$A/Librarian.md" grep "research/results/**" allow && \
    pass "Librarian can search research artifacts" || failmsg "Librarian grep permission must allow research/results/**"
if perm "$A/Librarian.md" "*" "*" deny && \
   perm "$A/Librarian.md" edit "research/results/**" allow; then
    # the single edit allow must be research/results/** (no other edit grants)
    n=$(frontmatter "$A/Librarian.md" | awk '
        /action:/ && $NF=="edit" {in_edit=1; next}
        in_edit && /effect:/ {if ($NF=="allow") c++; in_edit=0}
        END {print c+0}')
    if [ "$n" = "1" ]; then
        pass "Librarian write scope confined to research/results/**"
    else
        failmsg "Librarian edit permissions must allow research/results/** only (found $n edit allows)"
    fi
else
    failmsg "Librarian permissions must be deny-by-default with only research/results/** editable"
fi
perm "$A/Librarian.md" glob "research/results/**" allow && \
    pass "Librarian can inspect research/results/** for collisions" || failmsg "Librarian glob permissions must allow research/results/**"
[ -f research/results/.gitkeep ] && pass "research/results/ destination provisioned in the harness" || failmsg "research/results/ destination missing"

echo
if [ $fail -eq 0 ]; then
    echo "All static checks passed."
else
    echo "One or more static checks FAILED."
fi
exit $fail
