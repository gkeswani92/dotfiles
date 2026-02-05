#!/bin/bash
#
# Untrack all Graphite branches with CLOSED or MERGED PRs
# Requires: gh CLI authenticated
#
# Usage: bash cleanup-stale-branches.sh
#

set -e

echo "Scanning tracked branches for stale PRs..."

for branch in $(git for-each-ref --format="%(refname:short)" refs/branch-metadata/ | sed "s|branch-metadata/||"); do
  pr_state=$(gh pr view "$branch" --json state -q ".state" 2>/dev/null || echo "NO_PR")

  if [[ "$pr_state" == "CLOSED" || "$pr_state" == "MERGED" ]]; then
    echo "Untracking $branch (PR: $pr_state)"
    gt untrack "$branch" || true
  fi
done

echo ""
echo "Done! Remaining tracked branches:"
git for-each-ref --format='%(refname:short)' refs/branch-metadata/ | sed 's|branch-metadata/||' | wc -l
