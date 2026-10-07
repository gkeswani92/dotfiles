# Analytics-log queries (`shopify-trace-analytics`)

Reference for analytics-log panel queries — request structure, fields, datasets, calculation and filter ops, two filter formats, derived fields, common patterns, and the target template.

## Query structure

Analytics log panels use a structured `request` object instead of PromQL expressions. The query is built using a builder UI (`viewMode: "builder"`) or raw JSON (`viewMode: "json"`).

```json
{
  "request": {
    "breakdowns": ["column_name"],
    "calculations": [{ "op": "COUNT" }],
    "datasets": ["core"],
    "filter_group": {
      "conjunction": "AND",
      "filter_groups": [
        {
          "conjunction": "AND",
          "filters": [{ "column": "name", "op": "=", "value": "your.event.name" }]
        }
      ],
      "filters": []
    },
    "filters": [],
    "result_type": "summary"
  }
}
```

## Key `request` fields

| Field                | Description                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| `breakdowns`         | Array of column names to group by (e.g., `["shop_id"]`, `["status", "shop_id"]`). Omit for totals.     |
| `calculations`       | Array of aggregation operations. See calculation ops below.                                            |
| `datasets`           | Array of dataset names to query. See available datasets below.                                         |
| `filter_group`       | Nested filter structure with conjunctions (`AND`/`OR`) and filter groups.                              |
| `filters`            | Flat filter array (simpler alternative to `filter_group`). See filter formats below.                   |
| `filter_combination` | Top-level conjunction for flat `filters` array: `"AND"` or `"OR"`.                                     |
| `result_type`        | `"summary"` for aggregated table/stat results, `"timeseries"` for time-based charts. Omit for summary. |
| `limit`              | Max number of results to return (e.g., `10`). Useful for top-N tables.                                 |
| `orders`             | Ordering rules — see below.                                                                             |
| `derived_fields`     | Array of computed fields using regex transformations. See derived fields section.                      |

### `orders` shape

To order by a calculation, use `op` (and `column` if the op takes one):

```json
[{ "op": "COUNT", "order": "desc" }]
[{ "op": "P99", "column": "duration_ms", "order": "desc" }]
```

To order by a breakdown column, use `column` — and the column must be one of the `breakdowns`:

```json
[{ "column": "shop_id", "order": "asc" }]
```

Ordering by a calculation result with `column: "COUNT"` is rejected by the API.

## Available datasets

| Dataset       | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `core`        | Core application log events (from `Rails.event.notify` etc.) |
| `mysql`       | MySQL slow query logs with query stats                       |
| `otel_traces` | OpenTelemetry trace spans                                    |

## Calculation operations

| Op               | Usage                                         | Example                                           |
| ---------------- | --------------------------------------------- | ------------------------------------------------- |
| `COUNT`          | Count number of matching events               | `{ "op": "COUNT" }`                               |
| `SUM`            | Sum a numeric column                          | `{ "column": "duration_ms", "op": "SUM" }`        |
| `AVG`            | Average of a numeric column                   | `{ "column": "duration_ms", "op": "AVG" }`        |
| `MAX`            | Maximum value of a column                     | `{ "column": "duration_ms", "op": "MAX" }`        |
| `MIN`            | Minimum value of a column                     | `{ "column": "duration_ms", "op": "MIN" }`        |
| `P50`            | 50th percentile of a numeric column           | `{ "column": "duration_ms", "op": "P50" }`        |
| `P90`            | 90th percentile of a numeric column           | `{ "column": "duration_ms", "op": "P90" }`        |
| `P95`            | 95th percentile of a numeric column           | `{ "column": "duration_ms", "op": "P95" }`        |
| `P99`            | 99th percentile of a numeric column           | `{ "column": "duration_ms", "op": "P99" }`        |
| `COUNT_DISTINCT` | Count distinct values of a column             | `{ "column": "shop_id", "op": "COUNT_DISTINCT" }` |
| `DISTINCT`       | Get distinct values of a column (for display) | `{ "column": "message", "op": "DISTINCT" }`       |

## Filter operators

| Op         | Description          | Example                                                       |
| ---------- | -------------------- | ------------------------------------------------------------- |
| `=`        | Equals               | `{ "column": "name", "op": "=", "value": "event.name" }`      |
| `!=`       | Not equals           | `{ "column": "status", "op": "!=", "value": "nil" }`          |
| `contains` | Contains substring   | `{ "column": "name", "op": "contains", "value": "backfill" }` |
| `exists`   | Column exists/is set | `{ "column": "error", "op": "exists" }`                       |
| `>`        | Greater than         | `{ "column": "duration_ms", "op": ">", "value": 0 }`          |
| `<`        | Less than            | `{ "column": "duration_ms", "op": "<", "value": 100 }`        |

Filter values should be passed as their **native types**, not strings:

- Numeric: `"value": 0`, `"value": 1000`
- Boolean: `"value": true`, `"value": false`
- String: `"value": "some_string"`
- Template variable: `"value": "$variable_name"` (see [`template-variables.md`](template-variables.md))
- Variable interpolation inside a literal: `"value": "shard$pod_id"` works — the variable is substituted into the string at query time.

## Two filter formats

### Nested `filter_group` (recommended for AND/OR groups)

```json
{
  "filter_group": {
    "conjunction": "AND",
    "filter_groups": [
      {
        "conjunction": "AND",
        "filters": [
          { "column": "name", "op": "=", "value": "event.name" },
          { "column": "shop_id", "op": "=", "value": "$shop_id" }
        ]
      }
    ],
    "filters": []
  },
  "filters": []
}
```

### Flat `filters` array (simpler, AND-only by default)

```json
{
  "filter_combination": "AND",
  "filters": [
    { "column": "application", "op": "=", "value": "$application" },
    { "column": "query_hash", "op": "=", "value": "$query_hash" },
    { "column": "shop_id", "op": "=", "value": "$shop_id" }
  ]
}
```

Both formats can coexist in the same request. The nested format supports OR logic between groups.

## Derived fields

Derived fields transform raw data using chained regex operations. Each step takes input from a `source_field` (which can be a previously derived field) and produces an `alias_to` output that can be referenced in `calculations` and `breakdowns`.

| Type            | Purpose                                                          | Required `options`                     |
| --------------- | ---------------------------------------------------------------- | -------------------------------------- |
| `regex-replace` | Substitute matches with a replacement string (cleanup)           | `regex`, `replace`, `source_field`     |
| `regex-extract` | Capture a group from the regex and use it as the field value     | `regex`, `source_field` (no `replace`) |

For `regex-extract`, the value of the derived field is the **first capture group** in the pattern.

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

Derived-field steps can be chained: a later step can read from a previous step's `alias_to`. The "Single Query Analysis" production dashboard chains five `regex-replace` steps to clean SQL out of a raw message column.

## Common analytics-log patterns

```json
// Count events by name (table)
{
  "calculations": [{ "op": "COUNT" }],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "name", "op": "=", "value": "my.event.name" }
    ]}
  ]},
  "datasets": ["core"],
  "result_type": "summary"
}

// Count events broken down by shop_id (table)
{
  "breakdowns": ["shop_id"],
  "calculations": [{ "op": "COUNT" }],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "name", "op": "=", "value": "my.event.name" }
    ]}
  ]},
  "datasets": ["core"],
  "result_type": "summary"
}

// Count events over time (timeseries)
{
  "calculations": [{ "op": "COUNT" }],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "name", "op": "=", "value": "my.event.name" }
    ]}
  ]},
  "datasets": ["core"],
  "result_type": "timeseries"
}

// Multiple calculations with breakdown (table) — e.g., query stats
{
  "breakdowns": ["query"],
  "calculations": [
    { "column": "real_query_time", "op": "P99" },
    { "column": "real_query_time", "op": "SUM" },
    { "column": "max_execution_time", "op": "MAX" },
    { "column": "rows_examined", "op": "AVG" },
    { "op": "COUNT" }
  ],
  "datasets": ["mysql"],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "application", "op": "=", "value": "$application" },
      { "column": "query_hash", "op": "=", "value": "$query_hash" }
    ]}
  ]},
  "filters": []
}

// Top 10 results with limit
{
  "breakdowns": ["span.db.statement.normalized"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["otel_traces"],
  "limit": 10,
  "orders": [{ "op": "COUNT", "order": "desc" }],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "kind", "op": "=", "value": "Client" },
      { "column": "resource.service.name", "op": "=", "value": "shopify" }
    ]}
  ]}
}

// Timeseries with multiple breakdowns
{
  "breakdowns": ["name", "query_source", "query_hash"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["mysql"],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "application", "op": "=", "value": "$application" }
    ]}
  ]},
  "result_type": "timeseries"
}

// Boolean and numeric filter values
{
  "breakdowns": ["timed_out"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["mysql"],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "max_execution_time", "op": ">", "value": 0 },
      { "column": "timed_out", "op": "=", "value": true }
    ]}
  ]},
  "result_type": "timeseries"
}

// Combined summary + timeseries on a single target
{
  "breakdowns": ["query"],
  "calculations": [{ "op": "COUNT" }],
  "datasets": ["mysql"],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "application", "op": "=", "value": "$application" }
    ]}
  ]},
  "result_type": "summary,timeseries"
}

// Using derived fields to extract and clean data
{
  "breakdowns": ["request_id"],
  "calculations": [
    { "column": "unnormalised query", "op": "DISTINCT" }
  ],
  "datasets": ["mysql"],
  "derived_fields": [
    {
      "alias_to": "clean_message",
      "type": "regex-replace",
      "options": { "regex": "# Time:\\s*\\d{4}.*?\\n?", "replace": " ", "source_field": "message" }
    },
    {
      "alias_to": "unnormalised query",
      "type": "regex-replace",
      "options": { "regex": "/\\*.*?\\*/", "replace": "  ", "source_field": "clean_message" }
    }
  ],
  "filter_group": { "conjunction": "AND", "filter_groups": [
    { "conjunction": "AND", "filters": [
      { "column": "application", "op": "=", "value": "$application" }
    ]}
  ]}
}
```

## Analytics-log target template

Every target in an analytics-log panel follows this structure:

```json
{
  "datasource": {
    "type": "shopify-trace-analytics",
    "uid": "PC54C5A0C4A87C717"
  },
  "queryStep": "",
  "rawDataMode": false,
  "refId": "A",
  "request": {
    /* ... see patterns above ... */
  },
  "viewMode": "builder",
  "legendTemplate": "{{column_name}}"
}
```

### Target-level fields

| Field            | Description                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `viewMode`       | `"builder"` for visual builder, `"json"` for raw JSON editing.                           |
| `queryStep`      | Step override for the query (usually `""`).                                              |
| `rawDataMode`    | `false` for aggregated panels; `true` to return raw rows.                                |
| `legendTemplate` | Template string for legend labels, e.g., `"{{shop_id}}"`, `"{{pod_id}}"`.                |
| `dataOption`     | Set to `"summary"` when using the target for transformations/calculations.               |
| `hide`           | Set to `true` to hide a target from display (useful when combining via transformations). |
| `refId`          | Unique identifier for the target (`"A"`, `"B"`, etc.). Used in transformations.          |
