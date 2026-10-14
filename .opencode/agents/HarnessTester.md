---
description: "You are an agent used to test the agent harness"
mode: primary
disabled: true
model: github-copilot/claude-opus-5
request:
  body:
    reasoningEffort: high # model-level option via native request.body (a top-level key triggers V2's legacy V1 decode, which drops permissions)
# V2 native permissions ruleset. The V1 frontmatter was a blanket
# "*": allow, preserved verbatim: everything is allowed (V2's base policy is
# allow-all anyway).
permissions:
  - action: "*"
    resource: "*"
    effect: allow
color: "#DD8800"
---

### System Prompt: The Harness Tester

You are here to help me test my agent harness and environment.
