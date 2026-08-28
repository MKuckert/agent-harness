# Issue 104: Agent Model Switcher

## Goal

Create a script that assigns models to OpenCode agents based on three stable roles: helper, worker, and thinker.

## Role mapping

- **Helper:** Explorer, Librarian, Committer
- **Worker:** Builder, Buddy, DocumentationEngineer
- **Thinker:** Planner, PlanReviewer, CodeReviewer, Testing

Agent files not included in this mapping remain unchanged. The script must list their names in a warning but continue execution.

## CLI

```text
harness-models anthropic [--dry-run]
harness-models openai [--dry-run]
harness-models set [--force] [--dry-run] <helper[@effort]> <worker[@effort]> <thinker[@effort]>
harness-models models
harness-models --version
```

Options must follow the subcommand and precede positional arguments.

- `--dry-run` prints the selected mapping and resulting diff without changing files.
- `--force` is available only for `set`. It permits models not reported by `opencode models` but does not bypass any other validation.
- `models` delegates to `opencode models`, accepts no options, and propagates its exit status.
- Valid effort values are `low`, `medium`, and `high`.
- In `model@effort`, the final `@` separates the model from its effort. Model IDs must not otherwise contain `@`.
- `--version` prints the scripts version and exits.

## Presets

### Anthropic

| Role    | Model                                  | Effort |
| ------- | -------------------------------------- | ------ |
| Helper  | `github-copilot/claude-sonnet-5`       | low    |
| Worker  | `github-copilot/claude-sonnet-5`       | medium |
| Thinker | `github-copilot/claude-opus-5`         | high   |

### OpenAI

| Role    | Model                                  | Effort |
| ------- | -------------------------------------- | ------ |
| Helper  | `github-copilot/gpt-5.6-luna`          | medium |
| Worker  | `github-copilot/gpt-5.6-terra`         | medium |
| Thinker | `github-copilot/gpt-5.6-sol`           | high   |

All preset models use the `github-copilot` provider. Therefore, the script writes OpenCode's `reasoningEffort` option for both presets and removes stale `effort` keys. Native Anthropic API option names do not apply to Copilot's OpenAI-compatible transport.

In `set` mode, each role requires exactly one model ID. An optional `@effort` suffix sets `reasoningEffort`; omitting the suffix removes any existing effort setting for that role.

## Validation and updates

Before changing any file, the script must:

1. Validate the subcommand, option order, argument count, effort values, and non-empty `provider/model` IDs.
2. Require mikefarah/yq v4 with frontmatter support.
3. Require `opencode` to be available in the PATH.
4. Run `opencode models` once and require each requested model to match one complete output line.
5. When `--force` is set, warn about each unavailable model instead of rejecting it.
6. Verify that every mapped agent file exists.
7. Discover unmapped `.opencode/agents/*.md` files, list them in a warning, leave them unchanged, and continue.
8. Validate each mapped file before passing it to `yq`:
   - The file starts with an opening `---` delimiter and contains a closing `---` delimiter.
   - The frontmatter contains exactly one unindented `model:` key.
   - Unindented `model:`, `reasoningEffort:`, and `effort:` keys are not duplicated.

Use `yq --front-matter=process` to update frontmatter while preserving the Markdown body. YAML formatting may be normalized; unrelated values and body content must remain semantically unchanged.

Transform and validate every mapped file in place. If replacement fails partway through, report the partial update clearly and instruct the user to inspect or restore the files with Git. No custom rollback is required.

Resolve repository paths relative to the script so it works from any current directory.

## Milestones

- [ ] Implement `bin/harness-models.sh` with preset, explicit, discovery, force, and dry-run modes.
- [ ] Implement model, dependency, agent-file, and frontmatter validation.
- [ ] Update mapped agent frontmatter and report unmapped agents.
- [ ] Add one self-contained shell test script using temporary fixtures and stubbed commands; do not introduce a test framework.
- [ ] Document the CLI, presets, and role assignments in `README.md`.
- [ ] Run syntax and behavior tests.

## Test cases

- Both presets assign the documented model and effort to all ten mapped agents.
- Explicit models map to the correct roles.
- `model@effort` writes `reasoningEffort`; omitting effort removes stale `reasoningEffort` and `effort` keys.
- Known models pass exact-line validation against a stubbed `opencode models` response.
- Unknown models fail before any write; `--force` accepts them and emits a warning.
- The `models` command delegates correctly and propagates failure.
- Invalid subcommands, option placement, argument counts, model IDs, and effort values fail before any write.
- Missing mapped agents and malformed or duplicate frontmatter keys fail before any write.
- Unmapped agents are named in a warning, remain unchanged, and do not cause failure.
- Unrelated frontmatter values and Markdown bodies remain semantically unchanged.
- `--dry-run` reports the intended changes without modifying files.
- The script works when invoked outside the repository directory.
