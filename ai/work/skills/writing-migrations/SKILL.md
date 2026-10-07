---
name: writing-migrations
description: Database migration safety rules. Use when creating migrations.
---

# Database Migrations

**Migrations MUST be separate PRs from code changes.**

Rolling deployments mean old and new code run simultaneously. A migration that breaks old code will cause errors during deploy.

## Safe Migration Patterns

### Adding a column
- **PR1:** Migration to add the column (with default value if needed)
- **PR2:** Code that uses the column

### Removing a column
- **PR1:** Remove all code that references the column
- **PR2:** Migration to drop the column

### Renaming a column
- **PR1:** Add new column
- **PR2:** Write to both columns, read from new
- **PR3:** Stop writing to old column
- **PR4:** Drop old column

### Adding NOT NULL constraint
- **PR1:** Add column as nullable
- **PR2:** Backfill data
- **PR3:** Add NOT NULL constraint

## Before Migrating

1. **Check current usage** - Query BigQuery to understand data patterns
2. **Consider rollback** - What happens if we need to revert?
3. **Run full test suite** - Especially when dropping columns
4. **Check for dependencies** - Other services may depend on this schema

## Common Mistakes to Avoid

- Adding NOT NULL without a default on existing tables
- Dropping columns before removing code references
- Large data migrations in a single transaction
- Index creation without `algorithm: :concurrently` (PostgreSQL)
