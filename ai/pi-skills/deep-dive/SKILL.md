---
name: deep-dive
description: Research a codebase topic and generate a developer textbook with numbered chapters, Mermaid diagrams, glossary, and reading paths. Use when exploring a new system, component, or domain in a codebase.
---

# Deep Dive — Developer Textbook Generator

Build a comprehensive, chapter-based developer textbook for a codebase topic. This produces the kind of document a new developer would use to deeply understand a system — grounded in actual source code, not abstractions.

## Input

The user provides a topic as `$ARGUMENTS`. Parse it to identify:

1. **Subject**: The system, component, or feature to document
2. **Codebase paths**: Where the relevant code lives
3. **Output directory**: Where to write the textbook
4. **Audience**: Who will read this

If any are missing, ask. Default output path pattern: `/Users/gaurav/Documents/notes/Shopify/Shopify/Tutorials/{Topic Name}/`

## Output Structure

A directory containing:

```
{output-dir}/
├── README.md                  # TOC, glossary, reading paths, system diagram
├── 01-system-overview.md      # What, why, architecture, directory layout
├── 02-domain-model.md         # Models, associations, ER diagram
├── 03-{topic-specific}.md     # Core workflows, state machines
├── ...                        # 3-8 topic-specific chapters
├── NN-integrations.md         # External services, APIs, events
└── NN-limitations.md          # Technical debt, gaps, edge cases
```

## Workflow

### Step 1: Research the Codebase

Use the `subagent` tool with parallel tasks to research simultaneously:

```
subagent({
  tasks: [
    { agent: "explorer", task: "Research directory structure, file layout, component boundaries, and package.yml dependencies for [TOPIC] at [PATHS]" },
    { agent: "explorer", task: "Research models, belongs_to/has_many associations, database columns, enums, and validations for [TOPIC] at [PATHS]" },
    { agent: "explorer", task: "Research operations, jobs, state machines, GraphQL mutations, and key code paths for [TOPIC] at [PATHS]" },
    { agent: "explorer", task: "Research external service integrations, Kafka topics, GraphQL APIs, sync mechanisms, and events for [TOPIC] at [PATHS]" }
  ]
})
```

Also use `bash` (with `rg`, `find`) and `read` directly for targeted lookups.

**Depth requirement**: Read actual source files. Reference specific file paths. Include actual column names, association declarations, method signatures. Every claim must be traceable to code.

### Step 2: Propose Chapter Outline

Based on findings, propose numbered chapters. Every textbook includes:

| Required | Purpose |
|----------|---------|
| System Overview | What it is, why it exists, architecture, directory layout |
| Domain Model | All models, relationships, key columns, ER diagram (Mermaid) |
| Core Workflows | Primary operations, lifecycles, state machines |
| Integrations | Connections to other systems, APIs, events |
| Known Limitations | Technical debt, gaps, edge cases, migration concerns |

Plus 3-8 topic-specific chapters covering the major subsystems discovered during research.

**Present the outline to the user and wait for approval before writing.**

### Step 3: Write Chapters

Use the `subagent` tool with parallel tasks to write chapters — one agent per 2-3 chapters:

```
subagent({
  tasks: [
    { agent: "writer", task: "Write chapters 01-03 for [TOPIC] textbook at [OUTPUT_DIR]. [CHAPTER DETAILS + RESEARCH FINDINGS]" },
    { agent: "writer", task: "Write chapters 04-06 for [TOPIC] textbook at [OUTPUT_DIR]. [CHAPTER DETAILS + RESEARCH FINDINGS]" },
    { agent: "writer", task: "Write chapters 07-08 for [TOPIC] textbook at [OUTPUT_DIR]. [CHAPTER DETAILS + RESEARCH FINDINGS]" }
  ]
})
```

Each chapter MUST include:

- **File paths** to actual source files
- **Code excerpts** — key associations, method signatures, enum definitions (focused, not full files)
- **Mermaid diagrams** — at least one per chapter (entity relationships, flows, sequences, state machines)
- **Tables** for column definitions, enum values, config options
- **Cross-references** to other chapters

Chapter style guidelines:
- Written for a developer who has never seen this code
- Explain "why" alongside "what"
- Connect facts into a narrative, don't just list them
- 100-300 lines per chapter — substantial but focused

### Step 4: Write README.md

After all chapters are complete, create README.md:

1. **Title** and one-line description
2. **Table of contents** — numbered, linked, with one-line descriptions per chapter
3. **Reading paths** — 2-4 audience-specific paths (e.g., "New developer onboarding", "Platform architect", "Debugging an issue")
4. **Glossary** — 15-30 key terms defined
5. **System context diagram** — Mermaid diagram showing how this system fits into broader architecture
6. **Quick reference** — file paths, Slack channels, team names, relevant endpoints

## Quality Bar

- Every claim traceable to a file in the codebase
- Mermaid diagrams throughout (not just ASCII trees)
- No speculation — if unclear from code, say so
- Chapters are self-contained but cross-reference each other
- Reading paths let different audiences skip to what matters
