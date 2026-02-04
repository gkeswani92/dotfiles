---
description: Use the GitHub CLI to fetch issue and clean it up
---

<github-issue>
$ARGUMENTS
</github-issue>

Use the GitHub CLI to fetch the issue and read through the entire thread, including the original description and all comments. Create a clear, structured issue description that an engineer without context can understand and act on immediately.

Your goal is clarity above all. Capture the key details but strip away tangential discussions, resolved questions, and unnecessary back-and-forth. Be concise while ensuring nothing critical is lost.

Structure your rewrite using the template sections below:

<template>
## Description
[What is the problem or need? What's the current impact? Keep this focused and clear.]

## Proposed Solution
[What approach should be taken? Include key technical details, constraints, or open questions that remain.]

## Original Thread
[Only include this section if there's a Slack archive or substantial previous description worth preserving for reference. If not, omit this section entirely.]
</template>

Do not update the existing issue, but if asked to as a follow-up, make sure to preserve the existing `<details>` block if it exists as it it a carbon copy of the original Slack thread.

