# Research Artifact Contract

## Scope and Destination

Each Librarian invocation writes exactly one research artifact before its final response. The destination is relative to the invoking workspace:

```text
research/results/<filename>.md
```

It is not an absolute `/research/results` path. `agent-harness/research/results/` is provisioned only as the canonical harness repository's own runtime destination. It is not a template source and must not be added to `.harness-sync`. Each consuming workspace provisions and tracks its own `research/results/` directory during harness setup. `.gitkeep` retains an otherwise empty destination; it is not a research artifact.

Artifacts are version-controlled when their workspace owner stages them, but Librarian does not commit them. Setup and validation must reject a symlink at either `research` or `research/results` rather than following it.

## Filename Contract

Use one filesystem-safe filename for each run:

```text
YYYYMMDDTHHMMSSmmmZ-<topic-slug>-<suffix>.md
```

- `YYYYMMDDTHHMMSSmmmZ` is the UTC creation time, including milliseconds.
- `<topic-slug>` is a nonempty, lowercase ASCII slug no longer than 80 characters. Normalize the topic by replacing each run of characters outside `[a-z0-9]` with one hyphen, trimming leading and trailing hyphens, and truncating without leaving a trailing hyphen. Do not transliterate Unicode text. Reject an empty slug, a slug containing `/`, `\\`, or `..`, or a topic that cannot produce a valid slug.
- `<suffix>` is at least 128 bits of cryptographically secure random data encoded as lowercase hexadecimal (32 characters).

Before writing, perform a best-effort result-directory glob for the exact filename. If it is returned, fail visibly and refuse to overwrite it. A timestamp and high-entropy suffix make accidental collisions impractical, but `glob` followed by `write` is not atomic. Truly concurrent adversarial collisions cannot be eliminated without an atomic-create tool and are outside this prompt-only design.

## Required Frontmatter

Artifacts use YAML frontmatter analogous to an OpenCode skill. Every required value, including every `metadata` entry, is a YAML string. Quote scalar values with double quotes and escape backslashes, double quotes, and control characters before serialization. Do not interpolate untrusted text as YAML structure.

```md
---
name: "research-<topic-slug>"
description: "Research findings for <human-readable topic>"
metadata:
  created: "2026-08-25T12:34:56.789Z"
  libraries: "Library names and versions, or none"
  tags: "comma-separated tags"
  sources: "https://example.com/docs (accessed); https://example.com/api (failed: 404)"
  verified: "false"
  status: "complete"
---
```

Required keys are `name`, `description`, and `metadata.created`, `metadata.libraries`, `metadata.tags`, `metadata.sources`, `metadata.verified`, and `metadata.status`. Validate all required keys and string values before writing. Missing or invalid metadata prevents writing and is reported as an error. `verified` is always `"false"` until human review. `status` is `"complete"` only when the research supports that claim; otherwise it is `"partial"`.

## Markdown Body Template

Use this section structure after the frontmatter. Render untrusted source or user text as Markdown content, not as frontmatter, and do not include credentials, tokens, cookies, or unrelated proprietary prompt context.

```md
## Findings

<Evidence-based findings.>

## Implementation Notes

<Version constraints, examples, integration guidance, and open decisions.>

## Sources

- <URL> — <access outcome and relevant provenance>

## Limitations

<Unknowns, unavailable sources, timeouts, API errors, or version ambiguity. Write "None" only for complete research with no known limitations.>
```

Sources must include each consulted URL or input and its access outcome. Inaccessible or failed sources are retained with their failure reason; they are never silently omitted.

## Partial Results and Persistence Failures

When search results are empty, a source is inaccessible, a request times out or errors, or version information is ambiguous, write the available research with `metadata.status: "partial"` and explicit limitations. Do not claim verification or completeness.

Persistence happens before the Librarian final response. On success, the final response includes exactly:

```text
Research artifact: research/results/<filename>.md
```

If the destination is missing, read-only, symlinked, denied, or the write fails, report the intended workspace-relative path and the tool error; never claim persistence. If research is partial and persistence also fails, report both the research limitations and the persistence failure, with no success-path handoff line.
