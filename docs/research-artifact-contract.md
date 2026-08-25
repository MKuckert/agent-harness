# Research Artifact Contract

## Scope and Destination

Each Librarian invocation writes exactly one research artifact before its final response. The destination is relative to the invoking workspace:

```text
research/results/<filename>.md
```

Artifacts are version-controlled when their workspace owner stages them, but Librarian does not commit them.

## Filename Contract

Use one filesystem-safe filename for each run:

```text
YYYYMMDDTHHMMZ-<topic-slug>.md
```

- `YYYYMMDDTHHMMZ` is the UTC creation time.
- `<topic-slug>` is a nonempty, lowercase ASCII slug no longer than 80 characters. Normalize the topic by replacing each run of characters outside `[a-z0-9]` with one hyphen, trimming leading and trailing hyphens, and truncating without leaving a trailing hyphen. Do not transliterate Unicode text. Reject an empty slug, a slug containing `/`, `\\`, or `..`, or a topic that cannot produce a valid slug.

## Required Frontmatter

Artifacts use YAML frontmatter analogous to an OpenCode skill. Every required value, including every `metadata` entry, is a YAML string. Quote scalar values with double quotes and escape backslashes, double quotes, and control characters before serialization. Do not interpolate untrusted text as YAML structure.

```md
---
name: "research-<topic-slug>"
description: "Research findings for <human-readable topic>"
metadata:
  created: "YYYY-MM-DDTHH:MMZ"
  libraries:
    - "Library name, versions 1"
    - "Other library name, versions 2"
  tags: "comma-separated tags"
  sources:
    - "https://example.com/docs (accessed)"
    - "https://example.com/api (failed: 404)"
  verified: "false"
  status: "complete"
  researcher:
    agent: "Librarian"
    model: "github-copilot/gpt-4.42-terra"
---
```

Required keys are `name`, `description`, and `metadata.created`, `metadata.libraries`, `metadata.tags`, `metadata.sources`, `metadata.verified`, `metadata.status`, `metadata.researcher.agent` and `metadata.researcher.model`. Validate all required keys and string values before writing. `verified` is always `"false"` until human review. `status` is `"complete"` only when the research supports that claim; otherwise it is `"partial"`.

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

<short summary>
```

If the destination is missing, read-only, symlinked, denied, or the write fails, report the intended workspace-relative path and the tool error; never claim persistence. If research is partial and persistence also fails, report both the research limitations and the persistence failure, with no success-path handoff line.
