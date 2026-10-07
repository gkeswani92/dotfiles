# Template variables

Dashboards can define variables that users change at the top of the dashboard. Variable values are referenced with `$variable_name` — in PromQL expressions for metrics, or in filter `value` fields for analytics logs.

## When to use

- A field/label has **multiple distinct values** (e.g., `verifier_type`, `region`, `shop_id`, `application`)
- Users will want to **drill down** into specific values or **compare** across values
- You're creating **separate panels for each value** — that's a sign you should use a variable instead
- The dashboard would benefit from **"All" vs "specific" views**

When you spot 3+ hardcoded panels that differ only by a label/column filter (e.g., `type="foo"`, `type="bar"`, `type="baz"`), consolidate them into one panel with a variable.

## When not to use

- There are only 2-3 fixed values that are always relevant together
- The values represent fundamentally different things that need different visualizations
- Overview dashboards where you always want to see everything

## Variable types

| Type      | Description                                          | Use case                                                            |
| --------- | ---------------------------------------------------- | ------------------------------------------------------------------- |
| `query`   | Dynamic dropdown populated from a datasource query   | Prometheus `label_values()` — pulls live values from a metric label |
| `custom`  | Dropdown with predefined options (comma-separated)   | Static known set, e.g., `Shopify,storefront-renderer`               |
| `textbox` | Free-text input with a default value                 | Open-ended IDs (shop_id, request_id, query_hash)                    |

## `query` type — Prometheus (`promql-query-builder` datasource)

The `promql-query-builder` datasource requires a specific query format — a plain `label_values()` string won't work. The `query` object must include `mode: "builder"`, `metric`, and `label` fields:

```json
{
  "allValue": ".*",
  "current": { "text": ["All"], "value": ["$__all"] },
  "datasource": {
    "type": "promql-query-builder",
    "uid": "metrics_mainorg"
  },
  "definition": "label_values(your_metric_name, label_name)",
  "includeAll": true,
  "label": "Display Label",
  "multi": true,
  "name": "variable_name",
  "options": [],
  "query": {
    "advanced_query": "",
    "label": "label_name",
    "metric": "your_metric_name",
    "metricLabels": [],
    "mode": "builder",
    "qryType": 1,
    "query": "label_values(your_metric_name, label_name)",
    "refId": "PrometheusVariableQueryEditor-VariableQuery"
  },
  "refresh": 2,
  "regex": "",
  "sort": 1,
  "type": "query"
}
```

Reference in PromQL with regex matching:

```promql
sum by (tag)(rate(metric{label_name=~"$variable_name"}[$__rate_interval]))
```

## `custom` and `textbox` types — analytics logs and static dropdowns

```json
{
  "templating": {
    "list": [
      {
        "name": "application",
        "type": "custom",
        "query": "Shopify,storefront-renderer",
        "current": { "text": "Shopify", "value": "Shopify" },
        "options": [
          { "selected": true, "text": "Shopify", "value": "Shopify" },
          { "selected": false, "text": "storefront-renderer", "value": "storefront-renderer" }
        ]
      },
      {
        "name": "shop_id",
        "type": "textbox",
        "query": "89188368714",
        "current": { "text": "89188368714", "value": "89188368714" },
        "options": [{ "selected": true, "text": "89188368714", "value": "89188368714" }]
      }
    ]
  }
}
```

Reference in analytics-log filters:

```json
{ "column": "shop_id", "op": "=", "value": "$shop_id" }
```

You can also interpolate a variable inside a literal value: `"value": "shard$pod_id"` substitutes `$pod_id` into the string at query time.
