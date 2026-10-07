# Example patterns

Canonical JSON snippets for every panel type, query shape, and styling pattern this skill needs to produce. Each snippet is the minimum viable shape — copy it, then customize.

> **Conventions:** `YOUR_DATASOURCE_UID` is the Prometheus datasource (e.g. `metrics_mainorg`). `PC54C5A0C4A87C717` is the bundled production analytics-log datasource UID. `gridPos` is omitted from most snippets — pick `x`, `y`, `w` (1-24), `h` based on layout (full-width: `w: 24`; half: `w: 12`; quarter: `w: 6`).

## Dashboard skeleton

### Top-level dashboard JSON

The container every panel goes inside. `schemaVersion: 40` matches Grafana 11.x.

```json
{
  "title": "My Dashboard",
  "uid": "",
  "tags": [],
  "schemaVersion": 40,
  "editable": true,
  "graphTooltip": 0,
  "fiscalYearStartMonth": 0,
  "timezone": "browser",
  "weekStart": "",
  "preload": false,
  "time": { "from": "now-3h", "to": "now" },
  "timepicker": {
    "refresh_intervals": ["15s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"]
  },
  "annotations": {
    "list": [{
      "builtIn": 1,
      "datasource": { "type": "grafana", "uid": "-- Grafana --" },
      "enable": true, "hide": true,
      "iconColor": "rgba(0, 211, 255, 1)",
      "name": "Annotations & Alerts", "type": "dashboard"
    }]
  },
  "templating": { "list": [] },
  "links": [],
  "panels": []
}
```

### Row separator

A collapsible/full-width row header. Place above each logical group of panels.

```json
{
  "type": "row",
  "id": 1,
  "title": "Overview",
  "collapsed": false,
  "panels": [],
  "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 }
}
```

## Prometheus panels

### Gauge with thresholds

A percentage gauge for success/match rates. Thresholds drive the red/yellow/green colors.

```json
{
  "type": "gauge",
  "title": "Event Correctness Rate",
  "id": 2,
  "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
  "gridPos": { "h": 5, "w": 6, "x": 0, "y": 1 },
  "fieldConfig": {
    "defaults": {
      "min": 0, "max": 1, "unit": "percentunit",
      "color": { "mode": "thresholds" },
      "thresholds": {
        "mode": "absolute",
        "steps": [
          { "color": "red", "value": null },
          { "color": "yellow", "value": 0.95 },
          { "color": "green", "value": 0.99 }
        ]
      }
    },
    "overrides": []
  },
  "options": {
    "orientation": "auto",
    "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false },
    "showThresholdLabels": false, "showThresholdMarkers": true
  },
  "targets": [{
    "refId": "A",
    "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
    "editorMode": "code",
    "expr": "sum(rate(metric_success[$__rate_interval])) / (sum(rate(metric_success[$__rate_interval])) + sum(rate(metric_failure[$__rate_interval])))",
    "instant": true, "range": false,
    "legendFormat": "Match Rate"
  }]
}
```

### Stat panel (single number)

For a single current value (e.g. p50 latency). Use `unit` to render `ms`, `s`, `decmbytes`, `reqpm`, etc.

```json
{
  "type": "stat",
  "title": "Event-to-DB Lag (p50)",
  "id": 3,
  "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
  "fieldConfig": {
    "defaults": {
      "unit": "ms",
      "color": { "mode": "thresholds" },
      "thresholds": {
        "mode": "absolute",
        "steps": [
          { "color": "green", "value": null },
          { "color": "yellow", "value": 5000 },
          { "color": "red", "value": 30000 }
        ]
      }
    },
    "overrides": []
  },
  "options": {
    "colorMode": "value", "graphMode": "area", "textMode": "auto",
    "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
  },
  "targets": [{
    "refId": "A",
    "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
    "editorMode": "code",
    "expr": "histogram_quantile(0.50, sum(rate(metric_lag_ms[$__rate_interval])) by (le))",
    "instant": true, "range": false, "legendFormat": "p50"
  }]
}
```

### Time series

Standard line chart. For percentiles, repeat the target with different `histogram_quantile` values and `legendFormat: "p50"`/`"p90"`/`"p99"`.

```json
{
  "type": "timeseries",
  "title": "Event Correctness Rate Over Time",
  "id": 7,
  "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
  "fieldConfig": {
    "defaults": {
      "unit": "percentunit", "min": 0, "max": 1,
      "color": { "mode": "palette-classic" },
      "custom": {
        "drawStyle": "line", "lineWidth": 1, "fillOpacity": 10,
        "lineInterpolation": "linear", "showPoints": "auto", "pointSize": 5,
        "spanNulls": false, "stacking": { "group": "A", "mode": "none" },
        "thresholdsStyle": { "mode": "line" }
      },
      "thresholds": {
        "mode": "absolute",
        "steps": [
          { "color": "red", "value": null },
          { "color": "green", "value": 0.99 }
        ]
      }
    },
    "overrides": []
  },
  "options": {
    "legend": { "displayMode": "list", "placement": "bottom", "showLegend": true, "calcs": ["mean", "min"] },
    "tooltip": { "mode": "multi", "sort": "desc" }
  },
  "targets": [{
    "refId": "A",
    "datasource": { "type": "promql-query-builder", "uid": "YOUR_DATASOURCE_UID" },
    "editorMode": "code",
    "expr": "sum(rate(metric_success[$__rate_interval])) / (sum(rate(metric_success[$__rate_interval])) + sum(rate(metric_failure[$__rate_interval])))",
    "range": true, "instant": false, "legendFormat": "Match Rate"
  }]
}
```

### Stacked-percentage time series

For outcome distribution (match/mismatch/skip/error). Set `stacking.mode: "percent"` and `unit: "percentunit"`.

```json
{
  "type": "timeseries",
  "title": "Message Outcome Distribution",
  "fieldConfig": {
    "defaults": {
      "unit": "percentunit",
      "custom": { "stacking": { "group": "A", "mode": "percent" }, "fillOpacity": 70 }
    }
  },
  "targets": [
    { "refId": "A", "expr": "sum(rate(metric_match[$__rate_interval]))",    "legendFormat": "match" },
    { "refId": "B", "expr": "sum(rate(metric_mismatch[$__rate_interval]))", "legendFormat": "mismatch" },
    { "refId": "C", "expr": "sum(rate(metric_skipped[$__rate_interval]))",  "legendFormat": "skipped" },
    { "refId": "D", "expr": "sum(rate(metric_error[$__rate_interval]))",    "legendFormat": "error" }
  ]
}
```

## Analytics-log panels (`shopify-trace-analytics`)

### Stat — COUNT

A single-number stat from log events. Wrap any analytics request in a target with `viewMode: "builder"`, `rawDataMode: false`, `queryStep: ""`, `refId: "A"`.

```json
{
  "type": "stat",
  "title": "Total Backfill Log Events",
  "id": 101,
  "datasource": { "type": "shopify-trace-analytics", "uid": "PC54C5A0C4A87C717" },
  "fieldConfig": {
    "defaults": {
      "color": { "mode": "thresholds" },
      "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }] }
    },
    "overrides": []
  },
  "options": {
    "colorMode": "value", "graphMode": "area", "textMode": "auto",
    "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false }
  },
  "targets": [{
    "refId": "A", "viewMode": "builder", "queryStep": "", "rawDataMode": false,
    "datasource": { "type": "shopify-trace-analytics", "uid": "PC54C5A0C4A87C717" },
    "request": {
      "calculations": [{ "op": "COUNT" }],
      "datasets": ["core"],
      "filter_group": {
        "conjunction": "AND",
        "filter_groups": [{
          "conjunction": "AND",
          "filters": [{ "column": "name", "op": "=", "value": "maintenance.backfill_collection_sources" }]
        }],
        "filters": []
      },
      "result_type": "summary"
    }
  }]
}
```

### Stat — COUNT_DISTINCT

Cardinality of a column. Same panel shape as above; only the calculation changes.

```json
{
  "calculations": [{ "column": "attrs.shop_id", "op": "COUNT_DISTINCT" }],
  "datasets": ["core"],
  "filter_group": { "conjunction": "AND", "filter_groups": [{ "conjunction": "AND", "filters": [
    { "column": "name", "op": "=", "value": "my.event.name" }
  ]}], "filters": [] },
  "result_type": "summary"
}
```

### Time series with breakdown

Set `result_type: "timeseries"`, add a `breakdowns` column, and set `legendTemplate: "{{column_name}}"` on the target.

```json
{
  "type": "timeseries",
  "title": "Backfill Log Events by Status Over Time",
  "datasource": { "type": "shopify-trace-analytics", "uid": "PC54C5A0C4A87C717" },
  "fieldConfig": {
    "defaults": {
      "color": { "mode": "palette-classic" },
      "custom": { "drawStyle": "line", "fillOpacity": 10, "stacking": { "group": "A", "mode": "normal" } }
    }
  },
  "targets": [{
    "refId": "A", "viewMode": "builder", "queryStep": "", "rawDataMode": false,
    "legendTemplate": "{{attrs.status}}",
    "datasource": { "type": "shopify-trace-analytics", "uid": "PC54C5A0C4A87C717" },
    "request": {
      "breakdowns": ["attrs.status"],
      "calculations": [{ "op": "COUNT" }],
      "datasets": ["core"],
      "filter_group": { "conjunction": "AND", "filter_groups": [{ "conjunction": "AND", "filters": [
        { "column": "name", "op": "=", "value": "maintenance.backfill_collection_sources" }
      ]}], "filters": [] },
      "result_type": "timeseries"
    }
  }]
}
```

### Table — multiple calculations + breakdowns

Combine `COUNT`, `SUM`, `AVG`, `P99` in one request. Each calc becomes a column named `summary OP(column)`.

```json
{
  "breakdowns": ["shop_id"],
  "calculations": [
    { "op": "COUNT" },
    { "column": "attrs.collects_count", "op": "SUM" },
    { "column": "attrs.added_count", "op": "SUM" },
    { "column": "attrs.duration_ms", "op": "AVG" },
    { "column": "attrs.duration_ms", "op": "P99" }
  ],
  "datasets": ["core"],
  "filter_group": { "conjunction": "AND", "filter_groups": [{ "conjunction": "AND", "filters": [
    { "column": "name", "op": "=", "value": "LegacyManualMembershipConverter.sync_completed" }
  ]}], "filters": [] },
  "result_type": "summary"
}
```

### Top-N table (`limit` + `orders`)

Use `limit` to cap rows. Order by a calculation with `op` (and `column` if the op needs one); order by a breakdown with `column`. Ordering by `column: "COUNT"` is rejected by the API.

```json
{
  "breakdowns": ["span.db.statement.normalized"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["otel_traces"],
  "limit": 10,
  "orders": [{ "op": "COUNT", "order": "desc" }],
  "filter_group": { "conjunction": "AND", "filter_groups": [{ "conjunction": "AND", "filters": [
    { "column": "kind", "op": "=", "value": "Client" },
    { "column": "resource.service.name", "op": "=", "value": "shopify" }
  ]}], "filters": [] }
}
```

### Combined `summary,timeseries`

Some panels (e.g. histograms) accept both result types from a single target.

```json
{
  "breakdowns": ["query"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["mysql"],
  "filter_group": { "conjunction": "AND", "filter_groups": [{ "conjunction": "AND", "filters": [
    { "column": "application", "op": "=", "value": "$application" }
  ]}], "filters": [] },
  "result_type": "summary,timeseries"
}
```

## Filters

### Nested `filter_group` with OR between groups

Use the nested format when you need OR. Each inner group is AND; the top-level `conjunction` ties groups together.

```json
{
  "filter_group": {
    "conjunction": "OR",
    "filter_groups": [
      { "conjunction": "AND", "filters": [
        { "column": "name", "op": "=", "value": "event.success" },
        { "column": "shop_id", "op": "=", "value": "$shop_id" }
      ]},
      { "conjunction": "AND", "filters": [
        { "column": "name", "op": "=", "value": "event.failure" },
        { "column": "shop_id", "op": "=", "value": "$shop_id" }
      ]}
    ],
    "filters": []
  },
  "filters": []
}
```

### Flat `filters` array (AND-only shortcut)

Simpler shape when you only need AND. `filter_combination` controls the join.

```json
{
  "filter_combination": "AND",
  "filters": [
    { "column": "application", "op": "=",  "value": "$application" },
    { "column": "max_execution_time", "op": ">", "value": 0 },
    { "column": "timed_out", "op": "=",  "value": true },
    { "column": "error", "op": "exists" }
  ]
}
```

### Filter operators with native types

Numeric and boolean values must be passed as native types — never strings. Variables interpolate into string literals.

```json
[
  { "column": "name", "op": "=", "value": "event.name" },
  { "column": "status", "op": "!=", "value": "nil" },
  { "column": "name", "op": "contains", "value": "backfill" },
  { "column": "error", "op": "exists" },
  { "column": "duration_ms", "op": ">", "value": 0 },
  { "column": "duration_ms", "op": "<", "value": 100 },
  { "column": "timed_out", "op": "=", "value": true },
  { "column": "shop_id", "op": "=", "value": "$shop_id" },
  { "column": "host", "op": "=", "value": "shard$pod_id" }
]
```

## Derived fields

### `regex-extract` — capture group becomes the value

The first capture group `(...)` in the pattern is the field's value. Reference the alias in `breakdowns` or `calculations`.

```json
{
  "derived_fields": [
    {
      "alias_to": "error_class",
      "type": "regex-extract",
      "options": {
        "regex": ".*CollectionSourceConditions::(\\w+)\\.",
        "source_field": "attrs.error_message"
      }
    }
  ]
}
```

### `regex-replace` — chained cleanup pipeline

Each step's `alias_to` can be a later step's `source_field`. Useful for stripping timestamps, comments, etc. before extracting.

```json
{
  "derived_fields": [
    {
      "alias_to": "clean_message",
      "type": "regex-replace",
      "options": {
        "regex": "# Time:\\s*\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d+Z\\n?",
        "replace": " ",
        "source_field": "message"
      }
    },
    {
      "alias_to": "unnormalised query",
      "type": "regex-replace",
      "options": {
        "regex": "/\\*.*?\\*/",
        "replace": "  ",
        "source_field": "clean_message"
      }
    }
  ]
}
```

## Template variables

### `query` type — Prometheus `label_values()`

Populates a dropdown from a metric label. The `query` object — not just a `definition` string — is required by the `promql-query-builder` datasource.

```json
{
  "name": "verifier_type",
  "label": "Verifier Type",
  "type": "query",
  "datasource": { "type": "promql-query-builder", "uid": "metrics_mainorg" },
  "definition": "label_values(merchant_subscriptions_billing_change_verifiers_validation, verifier_type)",
  "query": {
    "advanced_query": "",
    "label": "verifier_type",
    "metric": "merchant_subscriptions_billing_change_verifiers_validation",
    "metricLabels": [],
    "mode": "builder",
    "qryType": 1,
    "query": "label_values(merchant_subscriptions_billing_change_verifiers_validation, verifier_type)",
    "refId": "PrometheusVariableQueryEditor-VariableQuery"
  },
  "current": { "text": ["All"], "value": ["$__all"] },
  "options": [],
  "allValue": ".*",
  "includeAll": true, "multi": true,
  "refresh": 2, "regex": "", "sort": 1
}
```

Reference in PromQL with regex matching: `metric{label=~"$verifier_type"}`.

### `custom` type — static dropdown

Comma-separated values in `query`; each must also be in `options`.

```json
{
  "name": "application",
  "type": "custom",
  "query": "Shopify,storefront-renderer",
  "current": { "text": "Shopify", "value": "Shopify" },
  "options": [
    { "selected": true,  "text": "Shopify",              "value": "Shopify" },
    { "selected": false, "text": "storefront-renderer",  "value": "storefront-renderer" }
  ]
}
```

### `textbox` type — free-text input

For open-ended IDs (shop_id, request_id, query_hash). `query` is the default value.

```json
{
  "name": "shop_id",
  "type": "textbox",
  "query": "89188368714",
  "current": { "text": "89188368714", "value": "89188368714" },
  "options": [{ "selected": true, "text": "89188368714", "value": "89188368714" }]
}
```

## Data links and column overrides

### Data link — plain column

Make a table cell clickable. `${__data.fields.<col>}` injects the cell value into the URL.

```json
{
  "matcher": { "id": "byName", "options": "request_id" },
  "properties": [{
    "id": "links",
    "value": [{
      "targetBlank": true,
      "title": "Investigate request",
      "url": "https://observe.shopify.io/a/observe/investigate/requests?any_id=${__data.fields.request_id}"
    }]
  }]
}
```

### Data link — dotted column (bracket notation)

For columns whose name contains a dot (`attrs.shop_id`, `resource.service.name`), use bracket notation with escaped quotes.

```json
{
  "matcher": { "id": "byName", "options": "attrs.shop_id" },
  "properties": [{
    "id": "links",
    "value": [{
      "targetBlank": true,
      "title": "Services Internal",
      "url": "https://app.shopify.com/services/internal/shops/${__data.fields[\"attrs.shop_id\"]}"
    }]
  }]
}
```

### Column rename + unit

Match by the auto-generated column name (`summary OP(column)` for analytics logs).

```json
{
  "matcher": { "id": "byName", "options": "summary P99(real_query_time)" },
  "properties": [
    { "id": "displayName", "value": "Query Time (P99)" },
    { "id": "unit", "value": "s" }
  ]
}
```

### Column width

Pixel-fixed width for tables. Use `custom.minWidth` if you want a floor instead.

```json
{
  "matcher": { "id": "byName", "options": "Sub-Message" },
  "properties": [{ "id": "custom.width", "value": 1170 }]
}
```

### Column color

Override the auto-assigned palette color for a single series/column.

```json
{
  "matcher": { "id": "byName", "options": "summary COUNT" },
  "properties": [
    { "id": "color", "value": { "mode": "fixed", "fixedColor": "red" } }
  ]
}
```

### Match by target refId (multi-target panels)

Use `byFrameRefID` when you need to override a whole target's series instead of by column name.

```json
{
  "matcher": { "id": "byFrameRefID", "options": "A" },
  "properties": [{ "id": "displayName", "value": "Successes" }]
}
```

## Transformations and dashboard links

### `calculateField` — ratio from two hidden targets

Use two targets (A and B with `hide: true`) and a binary calculation to compute ratios/percentages without expressing them in PromQL.

```json
{
  "transformations": [{
    "id": "calculateField",
    "options": {
      "alias": "timed_out %",
      "binary": { "left": "timed_out_count", "operator": "/", "right": "total_count" },
      "mode": "binary",
      "reduce": { "reducer": "sum" }
    }
  }]
}
```

### Dashboard-level link

Cross-link to related dashboards. `includeVars: true` forwards the current variable selections; `keepTime: true` keeps the time range.

```json
{
  "links": [{
    "type": "link",
    "title": "Related Dashboard",
    "tooltip": "Description of the link",
    "url": "https://observe.shopify.io/d/uid/dashboard-name",
    "icon": "external link",
    "tags": [],
    "asDropdown": false,
    "includeVars": true,
    "keepTime": true,
    "targetBlank": true
  }]
}
```
