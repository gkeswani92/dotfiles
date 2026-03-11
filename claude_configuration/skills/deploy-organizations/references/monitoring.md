# Monitoring Protocol — Business Platform Deploy

## Section 1: Setup

Call `mcp__observe-mcp__initialize_observe_session` once at the start of your session. This is required before any other Observe MCP calls.

## Section 2: Baseline Queries

Run all of these before publish. Continue re-running every 3 minutes until publish starts to keep the baseline fresh (see Section 2.1).

### Instant Snapshots (use `instant_metrics_query`)

| Metric | Query |
|--------|-------|
| Total Exceptions (30m) | `sum(increase(BusinessPlatform_production_all_exceptions{exception!="Redlock::LockError"} [30m]))` |
| Web Replicas | `max(kube_deployment_status_replicas_available{namespace="business-platform-production", deployment="web"})` |
| Semian Open Circuits | `sum(rate(BusinessPlatform_production_semian_circuit_open [5m]) * 60)` |
| Destinations GQL P90 | `histogram_quantile(0.9, sum(rate(BusinessPlatform_production_graphql_request_duration{type="destinations"} [5m])))` |
| Organizations GQL P90 | `histogram_quantile(0.9, sum(rate(BusinessPlatform_production_graphql_request_duration{type="organizations"} [5m])))` |
| Job Queue Time P95 | `histogram_quantile(0.95, sum(rate(BusinessPlatform_production_sidekiq_queued_time [5m])))` |
| IDC Overflows | `sum(rate(BusinessPlatform_production_all_exceptions_unfiltered{exception="Dalli::ValueOverMaxSize"} [30m]) * 60)` |

### Rate Metrics (use `instant_metrics_query`)

| Metric | Query |
|--------|-------|
| Operation Success Rate | `(avg(increase(BusinessPlatform_production_operation_successful [5m])) / avg(increase(BusinessPlatform_production_operation_attempted [5m]))) * 100` |
| Operation Failure Rate | `sum(rate(BusinessPlatform_production_operation_failure [5m]) * 60)` |
| Job Success Rate | `(avg(increase(BusinessPlatform_production_job_successful [5m])) / avg(increase(BusinessPlatform_production_job_attempted [5m]))) * 100` |
| Job Failure Rate | `sum(rate(BusinessPlatform_production_job_failure [5m]) * 60)` |
| Edge 500s Rate | `sum(rate(nginx_ingress_controller_requests{namespace="business-platform-production", status="500"} [5m]) * 60)` |
| Slow Queries | `avg(rate(mysql_global_status_slow_queries{tag="katesql", katesql_name="business-platform-production"} [5m]) * 60)` |
| Exception Rate (per min) | `sum(rate(BusinessPlatform_production_all_exceptions{exception!="Redlock::LockError"} [5m]) * 60)` |

### Error Group Snapshot (use `get_error_groups`)

```
get_error_groups(service=["business-platform"], timeRange="now-30m")
```

Save each group's `groupingHash` and `count`. This lets you detect new error types that appear after deploy.

### Error Analytics Timeseries (use `query_dataset`)

```json
{
  "datasets": ["error-analytics-events"],
  "filters": [{"column": "resource.service.name", "op": "=", "value": "business-platform"}],
  "calculations": [{"op": "COUNT"}],
  "breakdowns": ["exception.errorClass"],
  "result_type": "timeseries",
  "granularity": 60,
  "limit": 15
}
```

Use `timeRange: "now-30m"`. This gives you per-minute error counts by class for trend comparison.

## Section 2.1: Baseline Refresh Loop

After the initial baseline capture, continue polling all Section 2 queries every 3 minutes while waiting for publish.

**Rolling window**: Keep the last 3 snapshots for each metric. Each new poll shifts the window (drop oldest, add newest).

**Baseline band**: Your comparison baseline is not a single value — it's a range:
- **min**: lowest of the 3 snapshots
- **median**: middle value
- **max**: highest of the 3 snapshots

Output a short status line after each refresh:
```
[HH:MM] Baseline refresh N — all metrics nominal (exception rate: 12.1–14.8/min)
```

When the lead signals "publish started", stop refreshing. The current 3-snapshot window becomes your comparison band. Proceed to Section 3.

## Section 3: Monitoring Loop

After the lead notifies you that publish has started, run 20 polls yourself, 1 minute apart, for 20 minutes. Execute each poll directly in a loop — do NOT use CronCreate or any scheduling mechanism. Run the queries, output status, sleep ~1 minute, then run the next poll.

Re-run all Section 2 queries each cycle. Compare to baseline.

### Trend Detection

- Compare each poll against the baseline **band** (min/median/max from pre-publish window).
- A value within the band is normal — do not flag.
- A value exceeding the max (or below min for success rates) is notable — track it.
- Flag as **negative trend** only if a metric stays outside the band for 3+ consecutive polls.
- A single spike that returns within band on the next poll is NOT a trend.

### Expected Deploy Behavior (DO NOT flag these)

- **Job queue time spike**: Workers restart during deploy. Queue time can spike to 15-20s. Should recover within ~5 min of deploy completing.
- **Kafka consumer lag spike**: Consumers stop and restart. Lag spikes and should drain within ~5 min.
- **401/499 edge status spikes**: Pods rolling over cause brief auth failures and client disconnects.
- **Brief operation/job failure bump**: Some operations fail during pod restart. Normal if it recovers.

### Alert Conditions (sustained negative trends only)

Flag to the lead if ANY of these persist across 3+ consecutive polls:

- Exception rate trending upward
- GQL P90 latency trending upward
- Operation or job success rate trending downward
- Edge 500s trending upward
- New error class in `get_error_groups` that wasn't in baseline AND its count is growing
- Job queue time or Kafka lag spiked but NOT recovering after 5 min post-deploy
- Web replicas dropping (not just fluctuating during rollover)
- Semian open circuits appearing when baseline was 0

## Section 4: Reporting

### In your pane (after each poll)

```
[HH:MM] Poll N/~20 — All metrics stable vs baseline
```

or if something is trending:

```
[HH:MM] Poll N/~20 — ⚠️ TREND: {metric} rising: {baseline} → {prev} → {current} over last {N} polls
```

### Alert to lead (via SendMessage)

Only when a negative trend has persisted for 3+ consecutive polls. Include:
- Metric name
- Baseline value
- Current value
- Trend direction (values over last 3 polls)
- Dashboard link

### Final report (via SendMessage to lead)

After 20 minutes, send a summary:
- Each metric's baseline vs final value
- Any trends observed during monitoring (even if they recovered)
- Overall assessment: healthy or concerns
- Link: https://observe.shopify.io/d/7pzmQMbVz/business-platform-deploy

## Section 5: Fallback

If Observe MCP calls fail, retry once. If still failing, report to the lead:

> Automated monitoring unavailable. Please monitor manually at: https://observe.shopify.io/d/7pzmQMbVz/business-platform-deploy
