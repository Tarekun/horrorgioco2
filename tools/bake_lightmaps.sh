#!/usr/bin/env bash
# Bakes a level's LightmapGI and saves it next to the scene, e.g.
#
#   tools/bake_lightmaps.sh scenes/levels/hotel_miramare.tscn
#
# Godot bakes lightmaps only in the editor, on the GPU, so this opens the editor
# (it needs a display) with tools/bake_lightmaps/ enabled for this run, bakes,
# saves the scene and quits. The plugin is enabled by adding it to project.godot,
# which is put back as it was afterwards (override.cfg doesn't reach editor plugins).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-godot}"
SCENE="${1:?usage: tools/bake_lightmaps.sh scenes/levels/<level>.tscn}"
PROJECT="$ROOT/project.godot"
PLUGIN="res://tools/bake_lightmaps/plugin.cfg"

BACKUP="$(mktemp)"
LOG="$(mktemp)"
cp "$PROJECT" "$BACKUP"
trap 'cp "$BACKUP" "$PROJECT"; rm -f "$BACKUP" "$LOG"' EXIT
sed -i "s|^enabled=PackedStringArray(\(.*\))$|enabled=PackedStringArray(\1, \"$PLUGIN\")|" "$PROJECT"
grep -q "$PLUGIN" "$PROJECT" || { echo "bake_lightmaps: no [editor_plugins] in project.godot" >&2; exit 1; }

BAKE_LIGHTMAPS_SCENE="res://${SCENE#res://}" "$GODOT" --editor --path "$ROOT" 2>&1 | tee "$LOG"
grep -q "^bake_lightmaps: res://.*: OK$" "$LOG"
