#!/usr/bin/env bash
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FEATURE_TEAM_PROFILE=personal
# Never mix personal team artifacts with work teams using the same slug.
FEATURE_TEAMS_ROOT="${FEATURE_TEAMS_ROOT:-$HOME/.pi/feature-teams/personal}"
source "$SKILL_DIR/../../../../shared/lib/herdr-team.sh"
