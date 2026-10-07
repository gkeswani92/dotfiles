---
name: observe-dashboard-generator
description: Generate Observe dashboards from StatsD metrics or analytics logs in the codebase. Use when creating dashboards for new metrics, visualizing counters/distributions, querying analytics log events, or when the user mentions "dashboard", "observe", "metrics visualization", "observability dashboard", or "analytics logs".
context: fork
---

# Observe Dashboard Generator

Generate Observe dashboard JSON files from StatsD metrics or analytics log events in the codebase.

## Process

### Step 1: Read the canonical patterns reference

**ALWAYS start by reading [`references/example-patterns.md`](references/example-patterns.md) for canonical JSON structures.** It contains a focused snippet for every panel type, query shape, filter format, derived field, template variable, data link, override, transformation, and dashboard-level link this skill needs to produce. Each snippet is the minimum viable shape — copy and customize.

For deeper conceptual coverage of any topic, see the more detailed references linked from later steps.

**Optional**: if your runtime has the Observe MCP available (`get_dashboard`, `parse_observe_url`, `semantic_search`), you can additionally fetch live production dashboards by UID for richer cross-reference. This is a bonus, not a prerequisite — the patterns reference is sufficient on its own.

When this document disagrees with a working dashboard about a field, **trust the working dashboard**.

### Step 2: Gather requirements

1. **What are the goals?** Examples:
   - Validate correctness (e.g., comparing two systems)
   - Monitor replication lag / freshness
   - Track throughput and error rates
   - Track feature rollout progress

2. **What datasource should be used?**
   - **StatsD/Prometheus metrics**: Ask for the Observe datasource UID (e.g., `metrics_mainorg`, `prometheus`). Datasource type: `promql-query-builder`.
   - **Analytics logs**: Datasource type: `shopify-trace-analytics`. The bundled example uses UID `PC54C5A0C4A87C717` (current production Observe), but UIDs vary by org/environment — confirm with the user if unsure.

3. **Existing dashboard to reference for style?** If yes, use it alongside the bundled examples.

### Step 3: Identify the metrics

Find where metrics are emitted:

```bash
git show --stat HEAD  # or specific commit
```

Catalog all StatsD calls:

- **Counters** (`StatsD.increment`): metric name, tags, what it represents
- **Distributions** (`StatsD.distribution`): metric name, unit (ms, bytes, count), what it measures

Note the metric prefix — it helps group related metrics.

### Step 4: Design dashboard structure

Map user goals to panel types.

**StatsD / Prometheus panels:**

| Goal                          | Panel design                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------- |
| **Correctness/Match Rate**    | Gauge (percentage) + time series with threshold line at target (e.g., 99%)      |
| **Replication Lag/Freshness** | Time series with percentiles (p50, p90, p99) + threshold areas for SLO          |
| **Throughput**                | Stat panel for current rate + time series for trend                             |
| **Error Breakdown**           | Stacked time series by error type/reason with distinct colors                   |
| **Comparison (A vs B)**       | Side-by-side panels or overlaid series with clear color coding                  |
| **Rollout Progress**          | Percentage gauge + volume comparison (old vs new path)                          |

**Analytics-log panels:**

| Goal                               | Panel design                                                                     |
| ---------------------------------- | -------------------------------------------------------------------------------- |
| **Event count / volume**           | Table with COUNT calculation, optionally broken down by a column (e.g., shop_id) |
| **Event count over time**          | Time series with COUNT calculation and `result_type: "timeseries"`               |
| **Top N breakdown**                | Table with breakdowns and COUNT, sorted by count                                 |
| **Filtered investigation**         | Table with specific filter_group to narrow down events by name, status, etc.     |
| **Aggregated value (sum/avg/max)** | Stat or table panel using SUM/AVG/MAX/MIN on a numeric column                    |
| **Percentile analysis**            | Stat or time series using P50/P90/P99 calculations                               |

Organize into logical rows:

- **Overview**: At-a-glance stats (gauges, single stats)
- **Core Metrics**: Main functionality panels based on primary goals
- **Operational Health**: Errors, skips, retries — things that indicate problems

### Step 5: Generate the dashboard

#### StatsD → Prometheus metric naming

Dots become underscores: `app.metric.name` → `app_metric_name`.

#### Common PromQL patterns

```promql
# Counter rate (requests per minute)
sum(rate(metric_name[$__rate_interval])) * 60

# Counter rate by tag
sum by (tag_name)(rate(metric_name[$__rate_interval])) * 60

# Success/match rate (percentage)
sum(rate(success[$__rate_interval])) /
(sum(rate(success[$__rate_interval])) + sum(rate(failure[$__rate_interval])))

# Distribution percentiles
histogram_quantile(0.50, sum(rate(metric_name[$__rate_interval])) by (le))
histogram_quantile(0.90, sum(rate(metric_name[$__rate_interval])) by (le))
histogram_quantile(0.99, sum(rate(metric_name[$__rate_interval])) by (le))
```

#### Analytics-log queries (`shopify-trace-analytics`)

See [`references/analytics-log-queries.md`](references/analytics-log-queries.md) for:

- The `request` object structure and all key fields (`breakdowns`, `calculations`, `filter_group`, `filters`, `filter_combination`, `result_type`, `limit`, `orders`, `derived_fields`)
- Available datasets (`core`, `mysql`, `otel_traces`)
- All 11 calculation operations (COUNT, SUM, AVG, MAX, MIN, P50/90/95/99, COUNT_DISTINCT, DISTINCT)
- All 6 filter operators (`=`, `!=`, `contains`, `exists`, `>`, `<`) and native-type rules
- Both filter formats (nested `filter_group` and flat `filters` + `filter_combination`)
- Both derived-field types (`regex-replace` and `regex-extract`) with chaining
- Common panel patterns (count, top-N, multi-calc, mysql/otel_traces, derived fields, combined `summary,timeseries`)
- The full target template and target-level fields

#### Template variables

See [`references/template-variables.md`](references/template-variables.md) for:

- When to use vs not use template variables
- All three variable types (`query`, `custom`, `textbox`) with full JSON shapes
- Variable interpolation inside literal values (e.g. `"shard$pod_id"`)

#### Panel styling (data links, overrides, transformations, dashboard links)

See [`references/panel-styling.md`](references/panel-styling.md) for:

- Data links on table columns, including bracket notation for dotted column names
- Column display overrides (`displayName`, `unit`, `custom.width`/`minWidth`/`hidden`/`inspect`, `links`, `color`)
- Grafana `calculateField` transformations
- Dashboard-level navigation `links`

#### Threshold guidance

- Success rates: red < 95%, yellow 95–99%, green > 99%
- Latency: depends on context, ask user or use sensible defaults
- Errors: typically no threshold, just track volume

### Step 6: Write and validate

Save to an appropriate location (ask if unclear):

- Component's `dashboards/` directory if it exists
- Or wherever the user specifies

## Examples

All canonical JSON shapes live in [`references/example-patterns.md`](references/example-patterns.md):

- **Prometheus panels**: dashboard skeleton, row separator, gauge with thresholds, stat panel, time series, stacked-percentage time series
- **Analytics-log panels**: stat (COUNT, COUNT_DISTINCT), time series with breakdown, table with multiple calculations, top-N with `limit`/`orders`, combined `result_type: "summary,timeseries"`
- **Filters**: nested `filter_group` with OR, flat `filters` array with `filter_combination`, all 6 operators with native types
- **Derived fields**: `regex-extract` (capture group), chained `regex-replace` cleanup pipeline
- **Template variables**: `query` (Prometheus `label_values()`), `custom` (static dropdown), `textbox` (free-text)
- **Styling**: data links on plain and dotted columns, column rename + unit, width, color, `byFrameRefID` matcher
- **Other**: `calculateField` transformations, dashboard-level links

If your runtime has the Observe MCP, the production dashboard `f194ce87-4e67-4e82-9801-4d52d8c392c1` ("Single Query Analysis") demonstrates many of these patterns combined and can be fetched via `get_dashboard` for additional cross-reference — but only as a bonus.

## Key questions to ask

If the user hasn't provided context:

1. What do you want to observe with this dashboard? (goals)
2. Are you querying **StatsD/Prometheus metrics** or **analytics logs** (trace analytics)?
3. What's your Observe datasource UID?
4. Do you have an example dashboard I can reference for style?

For analytics-log dashboards, also ask:

5. What is the log event `name` you want to filter on? (e.g., `maintenance.backfill_collection_sources`)
6. Which dataset? (`core` for app logs, `mysql` for slow queries, `otel_traces` for spans)
7. What columns do you want to break down by? (e.g., `shop_id`, `status`, `name`)
8. What calculations do you need? (e.g., COUNT, AVG duration, P99 latency, DISTINCT values)
9. Time series charts or summary tables? (determines `result_type`)
10. Any template variables for filtering? (e.g., `$shop_id`, `$application`)
11. Any clickable data links on columns? (e.g., link `request_id` to Investigate)
12. Any derived/computed fields? (e.g., regex extraction from raw messages)
