---
name: create-projectmap
description: Used for a high-level "cognitive map" analysis of a the project. It is intended for scenarios where the user wants to understand what the project does, how modules are divided, how key functions and workflows connect, where the risk areas lie, and where to start when taking over the project. It avoids line-by-line file explanations or the generation of formal specification documents. The output language defaults to the language of the current conversation.
---

# Project Map

This skill transforms a code project into a "project map" that allows an agent to quickly get an overview. The goal is to explain the project's overall purpose, module division, core business loops, key workflows, high-risk boundaries, and the path for taking over the project.

## Usage Scope

Use this skill when:

- The user asks to "build a project map" or "analyze the project structure."
- The existing `PROJECT_MAP.md` is missing, outdated, or insufficient for understanding the current state of the project.

## Core Principles

- Explain the project's purpose before the code structure.
- Explain business or product concepts before providing file references.
- Use file paths only for navigation and as evidence, not as the main body of the explanation.
- Default the output language to english.
- Prioritize natural language, referencing class names, method names, and line numbers.
- Do not exhaustively list every directory, class, or method for the sake of completeness.
- Do not pass off a "directory structure list" as a true understanding of the project.

## Structured Report

Generates a Markdown file `PROJECT_MAP.md` — broken down by overview, modules, processes, risks, and file paths.

Explore the project to understand:

1. The full directory structure
2. The content of `src/app/build.gradle.kts` and `src/gradle/libs.versions.toml` - what libraries are declared, what dependencies are available

## Output Structure

Use the following structure by default, adjusting it based on the project's size:

```md
# Project Map

## Overview

Explain the main problem the project solves in 1–3 sentences.

## Main Execution Flow

Explain, in plain language, the general operation of the project from the entry point to the completion of the core business loop.

## Module Map

### <Module Name>

- Responsibilities:
- Importance:
- Interactions:
- Key Processes:
- Code Anchors:

## High-Risk Areas

Identify areas requiring caution during modification and explain the associated risks.
```
