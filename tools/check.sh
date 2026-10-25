#!/usr/bin/env bash
# Runs every check an agent should pass before committing.
#
# Usage: tools/check.sh
#
# Environment:
#   GODOT     Godot 4 editor binary (default: godot)
#   GDLINT    gdlint binary (default: gdlint)
#   GDFORMAT  gdformat binary (default: gdformat)
#
# Every step runs even if an earlier one fails; the script exits non-zero if any step failed.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

GODOT="${GODOT:-godot}"
GDLINT="${GDLINT:-gdlint}"
GDFORMAT="${GDFORMAT:-gdformat}"

if [[ -t 1 ]]; then
	BOLD=$'\e[1m' RED=$'\e[31m' GREEN=$'\e[32m' RESET=$'\e[0m'
else
	BOLD="" RED="" GREEN="" RESET=""
fi

FAILED=()

require() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "${RED}error:${RESET} '$1' not found. $2" >&2
		exit 2
	fi
}

# step NAME COMMAND... runs a check and records it as failed on a non-zero exit.
step() {
	local name="$1"
	shift
	echo "${BOLD}==> ${name}${RESET}"
	if "$@"; then
		echo "${GREEN}ok${RESET}: ${name}"
	else
		echo "${RED}FAILED${RESET}: ${name}"
		FAILED+=("$name")
	fi
	echo
}

# godot_run ARGS... runs Godot headless and fails on a non-zero exit or any engine/script error in its output.
godot_run() {
	local output status
	# Strip ANSI colors so progress lines can be filtered and errors matched reliably.
	output="$("$GODOT" --headless --path "$ROOT" "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')"
	status=${PIPESTATUS[0]}
	echo "$output" | grep -vE '^\[|^\s*$'
	if ((status != 0)); then
		return "$status"
	fi
	if echo "$output" | grep -qE '^(SCRIPT )?ERROR:'; then
		echo "${RED}Godot reported errors (see above).${RESET}"
		return 1
	fi
}

gd_files() {
	find . \( -path ./.godot -o -path ./.git -o -path ./addons \) -prune -o -name '*.gd' -print | sort
}

require "$GODOT" "Install Godot $(cat .godot-version) or set GODOT to its path."
require "$GDLINT" "Install gdtoolkit: pip install -r requirements-dev.txt"
require "$GDFORMAT" "Install gdtoolkit: pip install -r requirements-dev.txt"

mapfile -t GD_FILES < <(gd_files)

step "Import project" godot_run --import
step "Load scripts and scenes" godot_run --script res://tools/check_scripts.gd
step "Run main scene" godot_run --quit
step "gdlint" "$GDLINT" "${GD_FILES[@]}"
step "gdformat --check" "$GDFORMAT" --check "${GD_FILES[@]}"

if ((${#FAILED[@]})); then
	echo "${RED}${BOLD}${#FAILED[@]} check(s) failed:${RESET} $(IFS=,; echo "${FAILED[*]}" | sed 's/,/, /g')"
	exit 1
fi
echo "${GREEN}${BOLD}All checks passed.${RESET}"
