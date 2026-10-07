# Computes the next remote watch state and the events worth pinging the planner about.
# Inputs: $pr ("" when no PR is watched), $now (ISO-8601 UTC);
# $ci, $binks, $view (pre-filtered PR JSON, {} when unavailable);
# $sync (Delta/Gitstream branch tips from team.sh, {} when not applicable);
# $prev (previous state, or null on the first run).
# $provider ("gitstream" or "delta") selects wording. Only human (@shopify.com) comments ping: Binks findings
# have their own count, and CI, build, and review bots are noise.
def failing: .status | IN("failure", "error", "timed_out", "canceled", "cancelled");
def finished: failing or (.status | IN("success", "skipped", "neutral"));
def short: if type == "string" and length == 40 then .[0:7] else . end;

(if $pr == "" or ($prev.pr // null) != $pr then null else $prev end) as $pp
| ($pp == null) as $first
| (if $ci.checks then {
      sha: $ci.sha,
      ok: ([$ci.checks[] | select(finished and (failing | not))] | length),
      pending: ([$ci.checks[] | select(finished | not)] | length),
      failed: [$ci.checks[] | select(.required and failing) | .name],
      failed_urls: [$ci.checks[] | select(.required and failing) | .url]
    }
   else ($pp.ci // {sha: null, ok: 0, pending: 0, failed: [], failed_urls: []}) end) as $ci_now
| (if ($ci_now.failed | length) > 0 then "failed"
   elif $ci_now.pending == 0 and $ci_now.ok > 0 then "green"
   else "pending" end) as $ci_status
| "\($ci_now.sha):\($ci_status):\($ci_now.failed | sort | join(","))" as $ci_key
| (if $binks.binks_state then {state: $binks.binks_state.state, outstanding: ($binks.findings.outstanding // 0)}
   else ($pp.binks // {state: null, outstanding: 0}) end) as $binks_now
| (if $view.comments then $view.comments else ($pp.comments // []) end) as $comments
| [($pp.comments // [])[].id] as $seen
| ($view.author // $pp.author) as $author
| ($view.headSha // $ci_now.sha // $pp.head) as $head
| ($view.headRef // $pp.head_ref) as $head_ref
| ($view.state // $pp.pr_state) as $pr_state
| ($prev.sync // null) as $ps
| (if $sync == {} then $ps
   else $sync + {since: (if $ps != null and $ps.delta == $sync.delta and $ps.gitstream == $sync.gitstream
                        then $ps.since else $now end)}
   end) as $sync_now
| "\($sync_now.relation):\($sync_now.delta):\($sync_now.gitstream)" as $sync_key
| (($now | fromdateiso8601) - (($sync_now.since // $now) | fromdateiso8601)) as $sync_age
| (($sync_now.relation // "") | IN("gitstream_ahead", "diverged", "unknown_objects")) as $sync_danger
| ((($sync_now.relation // "") | IN("delta_ahead", "delta_only")) and $sync_age >= 600) as $sync_stuck
| {
    state: {
      pr: (if $pr == "" then null else $pr end), checked_at: $now,
      pr_state: $pr_state, head: $head, head_ref: $head_ref, author: $author,
      ci: $ci_now, binks: $binks_now, comments: $comments,
      notified_ci: (if $ci_status == "pending" then $pp.notified_ci else $ci_key end),
      sync: $sync_now,
      notified_sync: (if $sync_danger or $sync_stuck then $sync_key
                      elif $sync_now.relation == "in_sync" then null
                      else $prev.notified_sync end)
    },
    events: [
      (if $pr == "" then empty else
        (if $ci_status == "failed" and $ci_key != $pp.notified_ci
         then "CI FAILED on \($ci_now.sha | short): \($ci_now.failed | join(", ")) \($ci_now.failed_urls[0] // "")"
         else empty end),
        (if $ci_status == "green" and $ci_key != $pp.notified_ci and ($first | not)
         then "CI GREEN on \($ci_now.sha | short)" else empty end),
        (if $binks_now.outstanding > ($pp.binks.outstanding // 0)
         then "BINKS: \($binks_now.outstanding) outstanding finding(s)" else empty end),
        (if $first then empty
         else [$comments[] | select((.id | IN($seen[])) | not)
                 | select(.author != $author and ((.author // "") | test("@shopify\\.com$")))]
           | if length > 0
             then "NEW COMMENTS: " + (map("\(.author)\(if .review then " (" + .review + ")" else "" end) \(.url)") | join("; "))
             else empty end
         end),
        (if ($first | not) and $head != null and $head != $pp.head and $head != ($sync_now.local // null)
         then "PR HEAD moved to \($head | short), which is not the local branch tip" else empty end),
        (if ($first | not) and $pr_state != $pp.pr_state then "PR is now \($pr_state)" else empty end)
      end),
      (if $sync_danger and $sync_key != $prev.notified_sync then
         (if $sync_now.relation == "unknown_objects"
          then "BRANCH: Delta \($sync_now.delta | short) and Gitstream \($sync_now.gitstream | short) differ, and a tip is not available locally. Inspect with the Delta skill"
          else "BRANCH: Gitstream \($sync_now.gitstream | short) has commits that Delta \($sync_now.delta | short) lacks, so the next Delta push can overwrite them. Inspect with the Delta skill"
          end)
       else empty end),
      (if $sync_stuck and $sync_key != $prev.notified_sync
       then "BRANCH: Delta-to-Gitstream forwarding pending for \($sync_age / 60 | floor)m (Delta \($sync_now.delta | short), Gitstream \($sync_now.gitstream | short)); \(if $provider == "delta" then "Gitstream and Merge Garden" else "the PR and CI" end) can't see it yet"
       else empty end),
      (if $sync_now.relation == "in_sync" and $prev.notified_sync != null
       then "BRANCH: Delta and Gitstream are back in sync at \($sync_now.delta | short)" else empty end)
    ]
  }
