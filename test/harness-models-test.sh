#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/harness-models-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/bin" "$TMP/repo/.opencode/agents" "$TMP/stubs"
cp "$ROOT/bin/harness-models.sh" "$TMP/repo/bin/"
for name in Explorer Librarian Committer Builder Buddy DocumentationEngineer Planner PlanReviewer CodeReviewer Testing; do
  printf '%s\n' '---' 'description: fixture' 'model: old/model' 'effort: stale' 'reasoningEffort: low' '---' "body $name" > "$TMP/repo/.opencode/agents/$name.md"
done

cat > "$TMP/stubs/opencode" <<'EOF'
#!/usr/bin/env bash
[[ $1 == models ]] || exit 2
[[ ${OPENCODE_FAIL:-0} == 0 ]] || exit 23
printf '%s\n' github-copilot/claude-sonnet-5 github-copilot/claude-opus-5 github-copilot/gpt-5.6-luna github-copilot/gpt-5.6-terra github-copilot/gpt-5.6-sol custom/helper custom/worker custom/thinker
EOF
cat > "$TMP/stubs/yq" <<'EOF'
#!/usr/bin/env python3
import os, re, sys
if '--version' in sys.argv: print('yq version v4.99.0'); raise SystemExit
if '--help' in sys.argv: print('--front-matter string'); raise SystemExit
p=sys.argv[-1]; s=open(p).read(); model=os.environ['MODEL']; effort=os.environ.get('EFFORT', '')
s=re.sub(r'^model:.*$', 'model: '+model, s, count=1, flags=re.M)
s=re.sub(r'^(effort|reasoningEffort):.*\n', '', s, flags=re.M)
if effort: s=s.replace('\n---\n', '\nreasoningEffort: '+effort+'\n---\n', 1)
open(p,'w').write(s)
EOF
chmod +x "$TMP/stubs/"* "$TMP/repo/bin/harness-models.sh"
export PATH="$TMP/stubs:$PATH"
SCRIPT="$TMP/repo/bin/harness-models.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_contains() { [[ $1 == *"$2"* ]] || fail "expected '$2' in '$1'"; }
assert_fails() { "$@" >/dev/null 2>&1 && fail "expected failure: $*" || return 0; }

[[ $($SCRIPT --version) == 0.1 ]] || fail version
$SCRIPT openai >/dev/null
assert_contains "$(<"$TMP/repo/.opencode/agents/Explorer.md")" 'model: github-copilot/gpt-5.6-luna'
assert_contains "$(<"$TMP/repo/.opencode/agents/Builder.md")" 'reasoningEffort: medium'
assert_contains "$(<"$TMP/repo/.opencode/agents/Planner.md")" 'reasoningEffort: high'
$SCRIPT anthropic >/dev/null
assert_contains "$(<"$TMP/repo/.opencode/agents/CodeReviewer.md")" 'model: github-copilot/claude-opus-5'
$SCRIPT set custom/helper custom/worker custom/thinker >/dev/null
[[ $(<"$TMP/repo/.opencode/agents/Buddy.md") != *reasoningEffort:* ]] || fail 'stale effort retained'
assert_fails "$SCRIPT" set unknown/model custom/worker custom/thinker
$SCRIPT set --force unknown/model custom/worker custom/thinker >/dev/null 2>"$TMP/warn"
assert_contains "$(<"$TMP/warn")" 'warning:'
before=$(<"$TMP/repo/.opencode/agents/Explorer.md")
$SCRIPT openai --dry-run >"$TMP/diff"
[[ $(<"$TMP/repo/.opencode/agents/Explorer.md") == "$before" ]] || fail 'dry-run changed file'
assert_contains "$(<"$TMP/diff")" 'github-copilot/gpt-5.6-luna'
assert_fails "$SCRIPT" set custom/helper --dry-run custom/worker custom/thinker
assert_fails "$SCRIPT" set custom/helper@invalid custom/worker custom/thinker
assert_fails "$SCRIPT" set custom/helper@ custom/worker custom/thinker
assert_fails "$SCRIPT" set invalid custom/worker custom/thinker
body_before=$(printf 'body %s' Explorer)
(cd / && "$SCRIPT" set custom/helper custom/worker custom/thinker >/dev/null)
assert_contains "$(<"$TMP/repo/.opencode/agents/Explorer.md")" "$body_before"
assert_contains "$(<"$TMP/repo/.opencode/agents/Explorer.md")" 'description: fixture'
touch "$TMP/repo/.opencode/agents/Other.md"
out=$($SCRIPT openai 2>&1 >/dev/null); assert_contains "$out" 'Other'
rm "$TMP/repo/.opencode/agents/Testing.md"; assert_fails "$SCRIPT" openai
cp "$TMP/repo/.opencode/agents/Explorer.md" "$TMP/repo/.opencode/agents/Testing.md"
printf '%s\n' 'not frontmatter' > "$TMP/repo/.opencode/agents/Explorer.md"
assert_fails "$SCRIPT" openai
printf '%s\n' '---' 'model: one/model' 'model: two/model' '---' body > "$TMP/repo/.opencode/agents/Explorer.md"
assert_fails "$SCRIPT" openai
set +e; OPENCODE_FAIL=1 "$SCRIPT" models >/dev/null 2>&1; status=$?; set -e
[[ $status -eq 23 ]] || fail 'models status not propagated'
printf 'PASS\n'
