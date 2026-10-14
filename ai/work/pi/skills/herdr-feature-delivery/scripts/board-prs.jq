# Renders one status-board line per watched PR.
# Input: remote-state.json ({} before the first check). $prs: watched PR numbers in stack order.
def who: sub("@.*$"; "");
def reviews:
  if . == null then "reviews ?"
  elif (.changes | length) > 0 then "changes requested " + (.changes | map(who) | join(","))
  elif (.approved | length) > 0 then "approved " + (.approved | map(who) | join(","))
  else "0 approvals" end;
def threads:
  if . == null then "threads ?"
  else "\(.open) open threads" + (if .open_human > 0 then " (\(.open_human) human)" else "" end) end;
def ci:
  if .sha == null then "CI no data"
  elif (.failed | length) > 0 then "CI failed: " + (.failed | map(sub("^(config-shopify-build-|world-)"; "")) | join(", "))
  elif .pending > 0 then "CI \(.pending) pending"
  else "CI green" end;

(if has("prs") then .prs elif .pr then {(.pr): .} else {} end) as $states
| (.checked_at // "") as $at
| $prs[] as $n
| $states[$n] as $s
| if $s == null then "#\($n) first check pending"
  elif ($s.head // "") == "" then "#\($n) no data from the PR tools at \($at[11:16])Z; retrying"
  else "#\($n)"
    + (if ($s.pr_state // "open") == "open" then "" else " " + ($s.pr_state | ascii_upcase) end)
    + (if $s.draft == true then " draft" else "" end)
    + (if $s.merge == "dirty" then " CONFLICT" else "" end)
    + (if ($s.pr_state // "open") != "open" or (($s.sync.relation // "in_sync") | IN("in_sync", "unpublished")) then ""
       else " sync " + ($s.sync.relation | gsub("_"; " ")) end)
    + " \u00b7 " + ($s.reviews | reviews)
    + " \u00b7 " + ($s.threads | threads)
    + " \u00b7 Binks \($s.binks.outstanding // 0)"
    + " \u00b7 " + ($s.ci | ci)
  end
