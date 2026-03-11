---
name: optimizing-performance
description: Performance optimization patterns. Use when optimizing queries or improving response times.
---

# Performance Optimization

Optimize for reads. Do work at write time, not read time.

## Counter Caches

Use when you frequently count associated records.

```ruby
# Migration
add_column :prompts, :comments_count, :integer, default: 0, null: false

# Model
belongs_to :prompt, counter_cache: true
```

## Denormalization

Pre-compute values and store them directly. Update via background jobs when source data changes.

```ruby
# Instead of computing on every read:
def total_revenue
  orders.sum(:amount)
end

# Store it:
add_column :shops, :total_revenue_cents, :bigint, default: 0
```

## Decision Framework

| Read Frequency | Write Frequency | Solution |
|----------------|-----------------|----------|
| High | Low | Counter cache / denormalize |
| High | High | Cache with short TTL |
| Low | Any | Don't optimize yet |

## Before Optimizing

Always check simpler solutions first:

1. **Can `includes` fix it?** - N+1 queries are the most common issue
2. **Is there an index?** - Missing indexes cause full table scans
3. **Is the query optimal?** - Check `EXPLAIN ANALYZE`
4. **Is it actually slow?** - Profile before optimizing

## Caching Patterns

```ruby
# Fragment caching
<% cache shop do %>
  <%= render shop %>
<% end %>

# Low-level caching
Rails.cache.fetch("shop/#{shop.id}/stats", expires_in: 1.hour) do
  compute_expensive_stats
end
```

## Common Anti-Patterns

- Premature optimization without profiling
- Caching without invalidation strategy
- N+1 queries in loops
- Loading full objects when you only need IDs
