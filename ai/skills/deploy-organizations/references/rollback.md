# Rollback Guide — Business Platform

## When to rollback

- **Confirmed user impact** (errors visible to merchants, broken workflows)
- **Significant error spikes** in the deploy dashboard that correlate with the deploy timing
- **Service degradation** (latency >2x baseline, request volume drops >50%)

When in doubt, rollback first and investigate after. A rollback is always safer than debugging under pressure.

## How to rollback

1. Open [Infra Central — Business Platform deploys](https://infra-central.shopify.io/deploy/environments/297)
2. Find the **last successful deploy** (the one before your current release)
3. Click **"Redeploy this version"**
4. Monitor the deploy dashboard to confirm metrics recover: https://observe.shopify.io/d/7pzmQMbVz/business-platform-deploy

## Recovery after rollback

Once the rollback is live and metrics are stable:

1. **Identify the faulty PR(s)** — check which PRs were in the release that caused the issue
2. **Revert the faulty PR** — open a revert PR, get it merged
3. **Deploy again** — run a normal deploy cycle with the revert included

If a revert isn't straightforward (e.g., migration already ran), consider a **fix-release**:
1. Create a fix PR targeting `main`
2. Get it reviewed and merged
3. Deploy normally — the fix will be included in the next release cycle

## Escalation

If the rollback itself fails or metrics don't recover:
```
@Incident Bot start <description of the problem>
```

Notify `#business-platform-ops` and page the on-call via PagerDuty.
