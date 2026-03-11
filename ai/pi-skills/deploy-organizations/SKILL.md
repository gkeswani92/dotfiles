---
name: deploy-organizations
description: Deploy Business Platform (organizations) via Conveyor
---

# Deploy Organizations

Guide a deploy of the Business Platform service (`//areas/platforms/organizations`) using Conveyor.

**Execution model**:
- Run read-only/safe commands (tree list, tec gps, gt checkout, dry-run, CI checks) automatically.
- For every state-changing command, ask the user for explicit confirmation before running.
- Ask the user to collect required inputs (commit SHA, batch size) — never guess these values.

**CRITICAL**: All commands must use `shadowenv exec --` and `/opt/dev/bin/dev` for dev commands. Ensure your cwd is the organizations zone directory.

**CRITICAL**: Conveyor commands that have interactive prompts must be piped with `echo "1" |` to auto-select the first option. Commands that need piping: `start-release-cycle`, `complete-release-cycle`, `publish-release`. Read-only commands like `show-release-cycle` and `show-release-cycle-prs` do not need piping.

## Key Links

- **Deploy dashboard**: https://observe.shopify.io/d/7pzmQMbVz/business-platform-deploy
- **Infra Central**: https://infra-central.shopify.io/deploy/environments/297
- **Slack channel**: `#business-platform-ops`
- **Rollback guide**: [references/rollback.md](references/rollback.md)
- **Monitoring guide**: [references/monitoring.md](references/monitoring.md)

---

## Team Setup

This skill uses an **agent team** with three teammates that run as concurrent tmux panes. The team is created automatically on the first `team_spawn` call.

**Monitoring teammate** (`monitor`) — spawned at Step 4:
- Uses `observe_*` tools to watch the Business Platform Deploy dashboard
- Captures baseline metrics before deploy, then monitors for anomalies after publish

**Slack monitoring teammate** (`slack-monitor`) — spawned at Step 4:
- Uses `slack_history` to watch `#business-platform-ops` and `#organizations-ops` for new error alerts
- Uses `observe_error_group` to enrich alerts with error details
- Captures baseline error fingerprints before deploy, then diffs post-publish to surface new errors

**Publish teammate** (`publisher`) — spawned at Step 7:
- Runs `publish-release --wait` which polls CI checks
- Reports back when publish completes or fails

Use `team_message` to communicate with teammates. Teammates will message you back with results automatically.

---

## Step 0: Set up deployment worktree

Check if the `organizations-deployment` worktree already exists:

```bash
/opt/dev/bin/dev tree list
```

- If it **exists**: switch to it with `/opt/dev/bin/dev tree switch organizations-deployment`
- If it **does not exist**: create and switch to it with `/opt/dev/bin/dev tree add organizations-deployment -s`

After switching, `cd` into `~/world/trees/organizations-deployment/src/areas/platforms/organizations`. Use this as cwd for all subsequent commands.

## Step 1: Verify zone

Run automatically:

```bash
tec gps --full --json
```

Confirm `zone_path` is `//areas/platforms/organizations`. If not, warn the user and stop.

## Step 2: Sync to latest main

Run automatically:

```bash
shadowenv exec -- gt checkout main && shadowenv exec -- gt get
```

## Step 3: Check current release state

Run automatically to get context on the current release cycle:

```bash
shadowenv exec -- /opt/dev/bin/dev conveyor show-release-cycle //areas/platforms/organizations
```

Report the current state to the user before proceeding.

## Step 4: Determine batch size and dry run

**Launch the monitoring teammate** using `team_spawn`:

- **name**: `monitor`
- **task**: The following instructions:

> You are monitoring the Business Platform deploy. Read `references/monitoring.md` — it contains the exact queries and monitoring protocol.
>
> 1. **Baseline**: Run every query in Section 2 of monitoring.md using the `observe_instant_query`, `observe_error_groups`, and `observe_query` tools. Save all values. Save the error grouping hashes + counts.
> 2. **Refresh**: Re-run all baseline queries every 3 min while waiting. Keep a rolling window of the last 3 snapshots per metric (min/median/max band). When the lead messages that deploy is rolling out, freeze the window as your comparison band.
> 3. **Monitor**: When notified that deploy is rolling out, follow Section 3 — run 20 polls, 1 min apart, for 20 min. Track trends across consecutive polls. Output status to your pane after each poll.
> 4. **Alert**: Only flag sustained negative trends (3+ consecutive worsening polls). Send alerts to the lead via `team_message` with metric name, baseline, current value, and trend.
> 5. **Final report**: After 20 min, send a summary to the lead with all metrics vs baseline and any trends observed.
>
> If any `observe_*` tool call fails, retry once, then report the error to the lead. Do not assume tools are unavailable without retrying.

**Also launch the Slack monitoring teammate** using `team_spawn`:

- **name**: `slack-monitor`
- **task**: The following instructions:

> You are monitoring Slack channels for new errors during a Business Platform deploy. You have access to the `slack_history`, `slack_search`, `observe_error_groups`, and `observe_error_group` tools.
>
> **Channels to watch**:
> - `#business-platform-ops` — channel ID `C014TBTTVE1`
> - `#organizations-ops` — channel ID `C02CX753ATY`
>
> **Phase 1 — Baseline** (run immediately):
> 1. For each channel, use `slack_history` with `channel: "<ID>"`, `limit: 100` to fetch recent messages.
> 2. Build a **baseline set** of known error fingerprints. Extract from each message:
>    - Error class (e.g. `PG::ConnectionBad`, `ShopifyI18n::RailsCustomExceptionHandler::MissingTranslation`)
>    - Error message summary (first line of the Message field)
>    - Observe grouping hash — extract from the error details URL (the number at the end of `https://observe.shopify.io/a/observe/errors/<GROUPING_HASH>`)
> 3. Focus on messages from "Observe Alerts" (pattern: "New Error in BP -") and "shopibot" (pattern: "has a failure"), but also note any other error-like messages.
> 4. Save the set of unique (error_class, message_summary, grouping_hash) tuples as your baseline.
> 5. Report to the lead via `team_message`: "Slack baseline captured: N known error fingerprints across both channels."
>
> **Phase 2 — Wait**: Re-check both channels every 3 minutes while waiting. Add any new fingerprints to the baseline (pre-deploy errors are expected). When the lead messages that deploy is rolling out, freeze the baseline. If you have been waiting for more than 45 minutes without a deploy notification, send the lead a message: "Slack monitor still waiting — no deploy notification received in 45 min. Should I continue?" Then stop polling until the lead responds.
>
> **Phase 3 — Monitor** (after deploy rolling out notification):
> The lead will send you the deploy-start Unix timestamp. Poll both channels every 2 minutes for 20 minutes (10 polls). For each poll:
> 1. Fetch recent messages using `slack_history`.
> 2. Extract error fingerprints from new messages.
> 3. Diff against the frozen baseline. A fingerprint is **new** if the (error_class, message_summary) pair was not in the baseline.
> 4. **For each new error fingerprint**: If it has an Observe grouping hash, call `observe_error_group` with the hash to get current error count, rate, and stack trace. Include this data in your alert.
> 5. Output to your pane: "Poll N: X new messages, Y new error fingerprints" (or "no new errors").
>
> **Alerting**:
> - If you see a **new error fingerprint** not in the baseline, immediately send an alert to the lead via `team_message` with: error class, message, Observe URL, error count/rate from Observe, and which channel it appeared in.
> - If you see the **same new error repeat 3+ times** in Slack, or if Observe shows the error count is rapidly increasing, escalate: "Recurring/spiking new error post-deploy: [details including count and rate]"
> - Do NOT alert on errors that were already in the baseline — those are pre-existing.
>
> **Phase 4 — Final report**: After 20 minutes, send a summary to the lead via `team_message`:
> - Total new messages seen in each channel
> - List of new error fingerprints (not in baseline) with counts, Observe URLs, and Observe error counts/rates
> - "All clear" if no new fingerprints appeared
>
> If any `slack_*` or `observe_*` tool call fails, retry once, then report the error to the lead.

The `show-release-cycle` output from Step 3 includes the number of unreleased PRs. Use this count to decide on batch size **before** running the dry-run.

**Batch size decision** (before dry-run):

- If **10 or fewer PRs**: Skip batch size question, proceed directly to dry-run.
- If **more than 10 PRs**: Ask the user: "There are N unreleased PRs. Would you like to reduce the batch size? (Default: all N PRs, or specify a number)"

**Run the dry-run** with `echo "1" |` to auto-select the first commit option.

**WARNING**: The `--dry-run` flag is MANDATORY in this step. Triple-check it is present before running. Without it, you will start an actual release.

Without batch size:

```bash
echo "1" | shadowenv exec -- /opt/dev/bin/dev conveyor start-release-cycle //areas/platforms/organizations --dry-run
```

With custom batch size (note: `--dry-run` MUST still be included):

```bash
echo "1" | shadowenv exec -- /opt/dev/bin/dev conveyor start-release-cycle //areas/platforms/organizations --dry-run --batch-size <N>
```

Parse the output for the PR list (URLs + titles) and the selected commit SHA. Ask the user to confirm the parsed SHA.

Save the confirmed SHA, batch size (if any), and PR list for later steps.

## Step 5: Complete previous release and start new one

Completing the previous release cycle is a prerequisite — you cannot start a new release without it. Combine both actions into a single confirmation.

Ask the user: "Ready to complete the previous release and start a new one with commit `<SHA>`?" (include batch size in the prompt if one was chosen).

If confirmed, run both commands sequentially:

```bash
echo "1" | shadowenv exec -- /opt/dev/bin/dev conveyor complete-release-cycle //areas/platforms/organizations
```

Then start the new release. **`--commit-sha` and `--batch-size` are mutually exclusive** — never pass both. The dry-run already resolved any batch size to a specific commit SHA, so always use `--commit-sha` only:

```bash
echo "1" | shadowenv exec -- /opt/dev/bin/dev conveyor start-release-cycle //areas/platforms/organizations --commit-sha <CONFIRMED_SHA>
```

**IMPORTANT**: Do NOT run `start-release-cycle` in the background. After it completes, display the full output to the user — it contains the release branch name and a URL for manual verification. Wait for the user to acknowledge before proceeding to Step 6.

## Step 6: Post deploy announcement to Slack

Use the PR list saved from the dry-run in Step 4. The list is identical — the release was started with the exact SHA from the dry-run, so no PRs can change.

Format each PR line using Slack link syntax — bold PR number, title as clickable link:
```
• *#<PR_NUMBER>* — <PR_URL|PR_TITLE>
```

Example:
```
• *#463404* — <https://github.com/shop/world/pull/463404|Return nil instead of raising PropertyNotFound>
```

Ask the user: "Post this to #business-platform-ops?"

If posting, first ensure npm tokens are fresh:

```bash
/opt/dev/bin/dev rotate-cloudsmith-tokens
```

Then send a **thread-opener**:

```bash
npx -y @shopify-internal/slack-mcp@latest send-message \
  --target 'C014TBTTVE1' \
  --markdown-text ":rocket: Starting a deploy of Business Platform :thread:" \
  --json
```

**Save the message timestamp** from the JSON output (`timestamp` field) — all subsequent messages will thread under it.

Then reply **in-thread** with the PR list:

```bash
npx -y @shopify-internal/slack-mcp@latest send-message \
  --target 'C014TBTTVE1' \
  --thread-ts '<saved_timestamp>' \
  --markdown-text "PRs included:
• *#<PR_NUMBER>* — <PR_URL|PR_TITLE>
• ..."
```

**Note**: `send-message` does not support editing or updating posted messages. If a message is posted incorrectly, repost the corrected version and manually delete the old one in Slack.

If `npx` fails with an **E401 (unauthorized)** error, run `dev rotate-cloudsmith-tokens` and retry once. If it still fails (network issue, package unavailable), show the formatted messages and tell the user to paste them manually into `#business-platform-ops` (`C014TBTTVE1`).

## Step 7: Publish the release

Ask the user: "Ready to publish?"

If confirmed, **launch the publish teammate** using `team_spawn`:

- **name**: `publisher`
- **task**: The following instructions:

> You are publishing the Business Platform release. Run this command:
>
> ```bash
> cd ~/world/trees/organizations-deployment/src/areas/platforms/organizations && echo "1" | shadowenv exec -- /opt/dev/bin/dev conveyor publish-release //areas/platforms/organizations --wait
> ```
>
> This will poll for CI checks and publish when ready. It may take 30+ minutes.
> If it fails, report the full error to the team lead via `team_message`, then call `team_shutdown`.
>
> When publish completes successfully, notify the lead via `team_message`: "Release published. Now tracking rollout."
> Then poll the deploy rollout by running this every 2 minutes:
>
> ```bash
> cd ~/world/trees/organizations-deployment/src/areas/platforms/organizations && shadowenv exec -- /opt/dev/bin/dev conveyor show-release-cycle //areas/platforms/organizations
> ```
>
> Watch for the release cycle state to indicate the deploy has completed (status is no longer deploying/in-progress). Continue polling up to 30 minutes.
> When the deploy completes, send the lead via `team_message`: "Deploy complete — all pods rolled over." Then call `team_shutdown`.
> If 30 minutes pass without completion, send the lead: "Deploy still in progress after 30 min. Check https://infra-central.shopify.io/deploy/environments/297" Then call `team_shutdown`.

Then present the user with the information saved from Step 5:
- **Release branch**: the `conveyor/release/...` branch name
- **Tracking URL**: the Infra Central URL from `start-release-cycle` output

Tell the user: "Publish is running (visible in the teammate pane). I'll relay updates as they come in. You can also track at [Infra Central URL]."

## Step 8: Completion

The publisher sends two messages during the deploy lifecycle:

**First message — "Release published. Now tracking rollout."**:
- Tell the user the release is published and rollout is in progress.
- Capture the current Unix timestamp (e.g., via `date +%s`) and notify both monitoring teammates:
  ```
  team_message(to: "monitor", content: "Deploy is rolling out. Begin post-publish monitoring now.")
  team_message(to: "slack-monitor", content: "Deploy is rolling out at Unix timestamp <CURRENT_UNIX_TS>. Freeze baseline and begin post-publish monitoring.")
  ```
- Post a status update to `#business-platform-ops`. If `saved_timestamp` is available from Step 6, include `--thread-ts '<saved_timestamp>'` to reply in-thread:
  ```bash
  npx -y @shopify-internal/slack-mcp@latest send-message \
    --target 'C014TBTTVE1' \
    --thread-ts '<saved_timestamp>' \
    --markdown-text ":white_check_mark: *Published* — deploy rolling out. Track at https://infra-central.shopify.io/deploy/environments/297"
  ```
  If `npx` fails with E401, run `/opt/dev/bin/dev rotate-cloudsmith-tokens` and retry once.

**Second message — "Deploy complete" or "30 min timeout"**:
- If deploy complete: Tell the user the deploy is fully rolled out. Post a status update to `#business-platform-ops` (threaded if `saved_timestamp` exists):
  ```bash
  npx -y @shopify-internal/slack-mcp@latest send-message \
    --target 'C014TBTTVE1' \
    --thread-ts '<saved_timestamp>' \
    --markdown-text ":tada: *Deploy complete* — all pods rolled over."
  ```
  If `npx` fails with E401, run `/opt/dev/bin/dev rotate-cloudsmith-tokens` and retry once.
- If 30 min timeout: Tell the user the deploy is still in progress and suggest checking Infra Central manually.

**Failure** (publish itself failed): Show the full error and suggest remediation (see Error Handling below).

When the **monitor** teammate reports back:
- **Anomalies detected**: Immediately alert the user with specifics. Suggest checking the dashboard and considering a rollback (see [references/rollback.md](references/rollback.md)).
- **All clear**: Tell the user the 20-minute Observe monitoring window passed with no issues.

When the **slack-monitor** teammate reports back:
- **New error fingerprints**: Immediately alert the user with the error class, message, Observe URL, and channel. Cross-reference with the Observe monitor's findings — if both flag the same error class, escalate urgency.
- **All clear**: Tell the user no new errors appeared in Slack during the monitoring window.

**Post-publish cleanup**:

1. Switch back to main in the deployment worktree:
   ```bash
   shadowenv exec -- gt checkout main
   ```
2. Shut down teammates via `team_request_shutdown` for `monitor`, `slack-monitor`, and `publisher`
3. Clean up the team via `team_cleanup`

---

## Error Handling

Issue detected during or after deploy? Follow this triage tree:

```
├─ Confirmed user impact
│  → Rollback immediately (see references/rollback.md)
│
├─ Error spikes but no confirmed user impact
│  → Monitor closely, prepare rollback, check deploy dashboard
│
├─ CI checks failing during publish (--wait is polling)
│  → Wait — Conveyor will keep polling until checks pass or timeout
│
├─ "Missing verified commit" error
│  → Post-merge validation is still running. Wait a few minutes and retry.
│
└─ Any other command failure
   → Show full error output and suggest remediation
```

For rollback steps, see [references/rollback.md](references/rollback.md).
