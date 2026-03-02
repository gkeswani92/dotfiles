# Example README.md Structure

This is a reference for what a good textbook README looks like, based on the CLE and PAP textbooks.

## Example: Central Legal Entity (CLE) Developer Textbook

```markdown
# Central Legal Entity (CLE) Developer Textbook

A comprehensive guide to the Central Legal Entity system — Shopify's centralized
legal entity data model that replaces legacy per-shop legal entity storage with a
single org-level source of truth.

## Table of Contents

| # | Chapter | Focus |
|---|---------|-------|
| 01 | [System Overview & Motivation](01-system-overview.md) | What CLE is, why it exists, reading paths |
| 02 | [Domain Model](02-domain-model.md) | All models, relationships, ER diagram |
| 03 | [Organizations: The Central Source](03-organizations-central-source.md) | LegalEntity model, GraphQL API, key operations |
| 04 | [The PAP Bridge](04-pap-bridge.md) | OrganizationIdentity::LegalEntity, entity resolution |
| 05 | [Bidirectional Sync](05-bidirectional-sync.md) | SyncLegalEntity, ResyncFromCentral, lock coordination |
| 06 | [Core: Shop-Level Management](06-core-shop-management.md) | ShopLegalEntity join table, bulk reassignment |
| 07 | [Kafka CDC & Event-Driven Sync](07-kafka-cdc-sync.md) | CDC topics, consumers, processing pipeline |
| 08 | [Completeness Engine](08-completeness-engine.md) | ValidationSchema, evaluation pipeline |
| 09 | [Admin-Web Frontend](09-admin-web-frontend.md) | GraphQL queries, form architecture |
| 10 | [Feature Flags](10-feature-flags-rollout.md) | All CLE flags, rollout phases |
| 11 | [Known Limitations](11-limitations-gaps.md) | 12 documented limitations |
| 12 | [Glossary & Diagrams](12-glossary-diagrams.md) | 28-term glossary, system diagram, file index |

## Reading Paths

**Backend engineer on the Organizations team:**
Start with 01 → 02 → 03 → 04 → 05 → 07 → 08 → 11

**Backend engineer on the Core team:**
Start with 01 → 02 → 06 → 07 → 11

**Frontend engineer working on Admin-Web:**
Start with 01 → 02 → 08 → 09

**Debugging a sync issue:**
Start with 05 → 07 → 11 → 10

## Glossary

| Term | Definition |
|------|-----------|
| **CLE** | Central Legal Entity — the canonical `Entity::LegalEntity` record |
| **LE** | Legal Entity — a real-world business or individual |
| **ShopLegalEntity** | Join table in Core linking a shop to a central LE |
| ... | 25+ more terms |

## System Context

(Mermaid diagram showing system boundaries and data flow)

## Quick Reference

- **Component path**: `areas/platforms/organizations/`
- **Slack**: #channel-name
- **Team**: @Shopify/team-name
```

## Example Chapter Structure

A good chapter has:
1. Opening paragraph explaining what this chapter covers and why it matters
2. Key models/files with actual paths
3. Code excerpts (associations, method signatures)
4. At least one Mermaid diagram
5. Tables for structured data (columns, enums, config)
6. Cross-references to other chapters
