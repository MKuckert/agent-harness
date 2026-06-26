---
description: Research into Skill
agent: Builder
---

Your task is to thoroughly research a user-specified technical topic, library, or framework version using the `@Librarian` subagent for web search and Context7, then compile these findings into a modular, reusable OpenCode Skill (`SKILL.md`).

Instead of guessing the format, you **must** use the `customize-opencode` skill to fetch the exact schema, frontmatter rules, and directory layout required for OpenCode skill creation.

## Tooling Stack & Skills

1. Use the `@Librarian` subagent for discovery:
   - **Web Search:** Discover high-level concepts, recent ecosystem changes, and known architectural patterns.
   - **Context7:** Extract raw, un-hallucinated, version-specific documentation and official code examples from package registries (`resolve-library-id`, `get-library-docs`).
2. **OpenCode Skill (`use_skill`):** Use skill `customize-opencode` to retrieve the latest structural rules and templates for creating skills.

## Workflow Execution Steps

### Step 1: Information Gathering & Cross-Referencing

- Accept the target topic, package name, and version from the user.
- Spawn `@Librarian` subagent to run a web search and context7 research to identify breaking changes, architectural best practices Anchor the research in real, version-accurate documentation. Extract 1-2 pristine, minimal boilerplate code examples.

### Step 2: Initialize & Fetch Formatting Blueprint

- Load the `customize-opencode` skill.
- Read and internalize the returned specification for creating a `SKILL.md` file, including exact frontmatter keys, naming conventions, and required sections.
- Come up with a good name for the skill.

### Step 3: Synthesis for Machine Consumption

- Translate your findings into explicit instructions tailored for _other AI agents_ (not humans).
- Focus heavily on structural constraints, anti-patterns, required imports, and edge cases that typically cause LLMs to fail.
- Be token sensitive: ensure that the final output is concise, clear, and adheres strictly to the formatting rules retrieved in Step 2.

### Step 4: Output Generation

- Map your technical findings directly into the structural layout and markdown format retrieved from the `customize-opencode` skill in Step 2.
- Add the following attributes to the `metadata` frontmatter and fill accordingly:
  - `created`: The current date in format `YYYY-MM-DD`.
  - `libraries`: Library names and version numbers, if applicable.
  - `tags`: Relevant tags for categorization and discoverability.
  - `sources`: Fill with URLs and inputs used to create the skill.
  - `verified: false`: Add this tags to indicate that the skill has not yet been verified by a human.
- Output the final `SKILL.md` file into the designated destination directory specified by the blueprint.
- Give a short summary of the research findings and how they are reflected in the skill's structure and content. Also the name for the new skill.
- Instruct the user to restart OpenCode in order to use the new skill.

## Topic

The topic to research is:

$ARGUMENTS
