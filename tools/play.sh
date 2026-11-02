#!/usr/bin/env bash
# Launches the game for playtesting, forcing Godot to reimport first so a stale .godot/ cache
# (e.g. after switching branches) can't make old behavior look like a bug, or a fixed bug look
# like it's still there.
#
# Usage: tools/play.sh [-- GODOT_ARGS...]
#
# Environment:
#   GODOT  Godot 4 editor binary (default: godot)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

GODOT="${GODOT:-godot}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "error: '$GODOT' not found. Install Godot $(cat .godot-version) or set GODOT to its path." >&2
	exit 2
fi

echo "==> Reimporting project"
if ! "$GODOT" --headless --path "$ROOT" --import; then
	echo "error: reimport failed, aborting." >&2
	exit 1
fi

echo "==> Launching game"
exec "$GODOT" --path "$ROOT" "$@"
