# Panel styling: data links, column overrides, transformations, dashboard links

## Data links on table columns

Make table cells clickable by adding `links` in field overrides. Use `${__data.fields.column_name}` to inject cell values into URLs.

For columns whose name contains a dot (very common with analytics logs, e.g. `attrs.shop_id`, `resource.service.name`), use bracket notation:

- Plain column: `${__data.fields.request_id}`
- Dotted column: `${__data.fields["attrs.shop_id"]}`

```json
{
  "overrides": [
    {
      "matcher": { "id": "byName", "options": "request_id" },
      "properties": [
        {
          "id": "links",
          "value": [
            {
              "targetBlank": true,
              "title": "Investigate request",
              "url": "https://observe.shopify.io/a/observe/investigate/requests?any_id=${__data.fields.request_id}"
            }
          ]
        }
      ]
    },
    {
      "matcher": { "id": "byName", "options": "attrs.shop_id" },
      "properties": [
        {
          "id": "links",
          "value": [
            {
              "targetBlank": true,
              "title": "Services Internal",
              "url": "https://app.shopify.com/services/internal/shops/${__data.fields[\"attrs.shop_id\"]}"
            }
          ]
        }
      ]
    }
  ]
}
```

## Column display overrides

Rename columns, set units, and configure widths using field overrides. Match columns by their auto-generated name (format: `summary OP(column)` for analytics logs):

```json
{
  "overrides": [
    {
      "matcher": { "id": "byName", "options": "summary P99(real_query_time)" },
      "properties": [
        { "id": "displayName", "value": "Query Time (P99)" },
        { "id": "unit", "value": "s" }
      ]
    },
    {
      "matcher": { "id": "byName", "options": "summary query" },
      "properties": [{ "id": "custom.minWidth", "value": 500 }]
    },
    {
      "matcher": { "id": "byFrameRefID", "options": "A" },
      "properties": [{ "id": "displayName", "value": "Custom Name" }]
    }
  ]
}
```

### Override matchers

- `byName` — Match by column name (e.g., `"summary COUNT"`, `"shop_id"`)
- `byFrameRefID` — Match by target refId (e.g., `"A"`, `"B"`); useful for multi-target panels

### Common override properties

- `displayName` — Rename the column/series
- `unit` — Set the display unit (`"s"`, `"ms"`, `"decmbytes"`, `"percentunit"`, `"reqpm"`)
- `custom.width` — Fixed column width in pixels (for tables) — most common
- `custom.minWidth` — Minimum column width in pixels (for tables)
- `custom.hidden` — `true` to hide a column entirely
- `custom.inspect` — `true` to allow inspecting the cell value
- `links` — Make cells clickable with data links
- `color` — Override series color

Any other Grafana `custom.*` field can also be set via overrides — see the bundled example dashboards for additional patterns.

## Grafana transformations

Transformations post-process query results. Useful for combining multiple targets into computed values.

```json
{
  "transformations": [
    {
      "id": "calculateField",
      "options": {
        "alias": "timed_out %",
        "binary": {
          "left": "timed_out_count",
          "operator": "/",
          "right": "total_count"
        },
        "mode": "binary",
        "reduce": { "reducer": "sum" }
      }
    }
  ]
}
```

Common transformation pattern: use two hidden targets (A and B with `hide: true`) and a `calculateField` transformation to compute ratios, percentages, or differences.

## Dashboard links

Add navigation links at the dashboard level:

```json
{
  "links": [
    {
      "asDropdown": false,
      "icon": "external link",
      "includeVars": true,
      "keepTime": true,
      "tags": [],
      "targetBlank": true,
      "title": "Related Dashboard",
      "tooltip": "Description of the link",
      "type": "link",
      "url": "https://observe.shopify.io/d/uid/dashboard-name"
    }
  ]
}
```

Key options: `includeVars: true` passes template variables to the linked dashboard; `keepTime: true` preserves the time range.
