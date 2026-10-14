#!/usr/bin/env bash
# Work resources and behavior stay profile-local; orchestration is shared.
set -euo pipefail
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FEATURE_TEAM_PROFILE=work
source "$SKILL_DIR/../../../../shared/lib/herdr-team.sh"
