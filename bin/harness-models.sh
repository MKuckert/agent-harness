#!/usr/bin/env bash
set -euo pipefail

# Repository paths and stable role assignments.
VERSION="0.1"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
AGENTS_DIR="$ROOT/.opencode/agents"

HELPERS=(Explorer Librarian Committer)
WORKERS=(Builder Buddy DocumentationEngineer)
THINKERS=(Planner PlanReviewer CodeReviewer Testing)

# User-facing diagnostics and CLI help.
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
usage() {
  cat >&2 <<'EOF'
usage: harness-models anthropic [--dry-run]
       harness-models openai [--dry-run]
       harness-models set [--force] [--dry-run] <helper[@effort]> <worker[@effort]> <thinker[@effort]>
       harness-models models
       harness-models --version
EOF
}

# Handle commands that do not modify agent files.
[[ $# -gt 0 ]] || { usage; exit 2; }
if [[ $1 == --version ]]; then [[ $# -eq 1 ]] || die "--version accepts no arguments"; printf '%s\n' "$VERSION"; exit 0; fi
command -v opencode >/dev/null 2>&1 || die "opencode is required"
if [[ $1 == models ]]; then [[ $# -eq 1 ]] || die "models accepts no arguments"; exec opencode models; fi

# Verify the required yq implementation and frontmatter capability.
command -v yq >/dev/null 2>&1 || die "mikefarah/yq v4 is required"
yq_version=$(yq --version 2>&1) || die "could not run yq --version"
[[ $yq_version =~ version[[:space:]]+v?4\. ]] || die "mikefarah/yq v4 is required (found: $yq_version)"
yq_help=$(yq --help 2>&1) || die "could not inspect yq capabilities"
[[ $yq_help == *--front-matter* ]] || die "yq lacks frontmatter support"

# Parse subcommand options before accepting positional model specifications.
subcommand=$1; shift
force=false; dry_run=false
case $subcommand in
  --help)
    usage
    exit 0
    ;;
  anthropic|openai)
    if [[ ${1-} == --dry-run ]]; then dry_run=true; shift; fi
    [[ $# -eq 0 ]] || die "invalid arguments or option placement for $subcommand"
    ;;
  set)
    while [[ ${1-} == --* ]]; do
      case $1 in
        --force) $force && die "duplicate --force"; force=true ;;
        --dry-run) $dry_run && die "duplicate --dry-run"; dry_run=true ;;
        *) die "unknown option: $1" ;;
      esac
      shift
    done
    [[ $# -eq 3 ]] || die "set requires exactly three model arguments"
    ;;
  *) die "unknown subcommand: $subcommand" ;;
esac

models=() efforts=()

# Split and validate a model[@effort] specification.
parse_spec() {
  local spec=$1 model effort=""
  [[ $spec != -* ]] || die "options must precede positional arguments"
  [[ $spec != *@*@* ]] || die "model IDs must not contain more than one @: $spec"
  if [[ $spec == *@* ]]; then model=${spec%@*}; effort=${spec##*@}; else model=$spec; fi
  [[ $model =~ ^[^/@[:space:]]+/[^/@[:space:]]+$ ]] || die "invalid model ID: $model"
  if [[ -n $effort ]]; then
    [[ $effort == low || $effort == medium || $effort == high ]] || die "invalid effort: $effort"
  elif [[ $spec == *@* ]]; then die "effort must not be empty"; fi
  models+=("$model"); efforts+=("$effort")
}

case $subcommand in
  anthropic)
    parse_spec 'github-copilot/claude-sonnet-5@low'
    parse_spec 'github-copilot/claude-sonnet-5@medium'
    parse_spec 'github-copilot/claude-opus-5@high'
    ;;
  openai)
    parse_spec 'github-copilot/gpt-5.6-luna@medium'
    parse_spec 'github-copilot/gpt-5.6-terra@medium'
    parse_spec 'github-copilot/gpt-5.6-sol@high'
    ;;
  set) parse_spec "$1"; parse_spec "$2"; parse_spec "$3" ;;
esac

# Validate requested models against one captured `opencode models` response.
available=$(opencode models) || die "opencode models failed"
for model in "${models[@]}"; do
  found=false
  while IFS= read -r line; do [[ $line == "$model" ]] && found=true; done <<<"$available"
  if ! $found; then $force && warn "model not reported by opencode models: $model" || die "model not reported by opencode models: $model"; fi
done

# Validate mapped files and report agents outside the stable role mapping.
mapped=("${HELPERS[@]}" "${WORKERS[@]}" "${THINKERS[@]}")
for agent in "${mapped[@]}"; do [[ -f "$AGENTS_DIR/$agent.md" ]] || die "missing mapped agent: $agent.md"; done

shopt -s nullglob
unmapped=()
for file in "$AGENTS_DIR"/*.md; do
  name=${file##*/}; name=${name%.md}; known=false
  for agent in "${mapped[@]}"; do [[ $name == "$agent" ]] && known=true; done
  $known || unmapped+=("$name")
done
((${#unmapped[@]} == 0)) || warn "unmapped agents left unchanged: ${unmapped[*]}"

# Reject malformed frontmatter before making the first change.
validate_frontmatter() {
  local file=$1 line line_number=0 closed=false model_count=0 reasoning_count=0 effort_count=0
  while IFS= read -r line; do
    ((++line_number))
    if [[ $line_number -eq 1 ]]; then
      [[ $line == '---' ]] || die "missing opening frontmatter delimiter: $file"
      continue
    fi
    if [[ $line == '---' ]]; then closed=true; break; fi
    [[ $line =~ ^model: ]] && ((++model_count))
    [[ $line =~ ^reasoningEffort: ]] && ((++reasoning_count))
    [[ $line =~ ^effort: ]] && ((++effort_count))
  done < "$file"
  [[ $line_number -gt 0 ]] || die "empty agent file: $file"
  $closed || die "missing closing frontmatter delimiter: $file"
  [[ $model_count -eq 1 ]] || die "frontmatter must contain exactly one unindented model key: $file"
  [[ $reasoning_count -le 1 && $effort_count -le 1 ]] || die "duplicate effort key in frontmatter: $file"
}
for agent in "${mapped[@]}"; do validate_frontmatter "$AGENTS_DIR/$agent.md"; done

printf 'helper: %s%s\nworker: %s%s\nthinker: %s%s\n' \
  "${models[0]}" "${efforts[0]:+@${efforts[0]}}" "${models[1]}" "${efforts[1]:+@${efforts[1]}}" "${models[2]}" "${efforts[2]:+@${efforts[2]}}"

# Apply updates in place while making partial failures explicit.
updated=0
trap 'status=$?; if ((status != 0 && updated > 0)); then printf "error: update failed after %d file(s); inspect or restore files with Git\n" "$updated" >&2; fi; exit $status' EXIT
transform() {
  local target=$1 role=$2
  if [[ -n ${efforts[$role]} ]]; then
    MODEL=${models[$role]} EFFORT=${efforts[$role]} yq --front-matter=process -i \
      'del(.effort) | .model = strenv(MODEL) | .reasoningEffort = strenv(EFFORT)' "$target"
  else
    MODEL=${models[$role]} yq --front-matter=process -i \
      'del(.effort) | del(.reasoningEffort) | .model = strenv(MODEL)' "$target"
  fi
}

# Color dry-run diffs on terminals when Git is available. Redirected output,
# NO_COLOR, and systems without Git retain the portable plain-diff behavior.
show_diff() {
  local current=$1 updated_file=$2
  if [[ -t 1 && -z ${NO_COLOR+x} ]] && command -v git >/dev/null 2>&1; then
    git --no-pager diff --no-index --color=always -- "$current" "$updated_file" || [[ $? -eq 1 ]]
  else
    diff -u --label "$current" --label "$current (new)" "$current" "$updated_file" || [[ $? -eq 1 ]]
  fi
}

# Transform temporary copies for dry runs; otherwise update mapped files.
for role in 0 1 2; do
  case $role in 0) role_agents=("${HELPERS[@]}");; 1) role_agents=("${WORKERS[@]}");; 2) role_agents=("${THINKERS[@]}");; esac
  for agent in "${role_agents[@]}"; do
    file="$AGENTS_DIR/$agent.md"
    if $dry_run; then
      tmp=$(mktemp "${TMPDIR:-/tmp}/harness-models.XXXXXX") || die "could not create temporary file"
      cp "$file" "$tmp"; transform "$tmp" "$role" || { rm -f "$tmp"; die "could not transform $agent.md"; }
      show_diff "$file" "$tmp"
      rm -f "$tmp"
    else
      transform "$file" "$role" || die "could not update $agent.md"
      ((++updated))
    fi
  done
done
trap - EXIT
