---
name: linting-ruby
description: Rubocop linting conventions and when to disable rules. Use when addressing lint violations.
---

# Rubocop Linting

Run linting before committing:

```bash
shadowenv exec -- dev style           # Check style
shadowenv exec -- dev style --fix     # Auto-fix issues
```

## Disabling Rules

Only disable rules per-line with a comment explaining why:

```ruby
# rubocop:disable Rails/SkipsModelValidations -- counter update doesn't need validations
record.update_columns(counter: record.counter + 1)
# rubocop:enable Rails/SkipsModelValidations
```

## Acceptable Exceptions

These cops can be disabled when justified:

| Cop | When to Disable |
|-----|-----------------|
| `Rails/SkipsModelValidations` | Counter updates, bulk operations where validations aren't needed |
| `Metrics/AbcSize` | Complex but readable methods that can't be simplified |
| `Metrics/MethodLength` | Methods with many simple steps (e.g., building a hash) |
| `Style/GuardClause` | When early return hurts readability |

## Red Flags

If you're disabling the same cop repeatedly, the code pattern needs rethinking:

- Multiple `Metrics/` disables = method needs refactoring
- Multiple `Rails/` disables = consider a different approach
- Disabling in a test file = tests may be too complex

## Project-Specific Rules

Check `.rubocop.yml` for project overrides. Some teams have different conventions.
