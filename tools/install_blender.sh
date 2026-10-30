#!/usr/bin/env bash
# Downloads the pinned Blender (version in .blender-version) for Linux x86_64 and verifies its checksum.
# Blender only runs the asset pipeline locally (see tools/README.md), never in CI.
#
# Usage: tools/install_blender.sh [DIR]
#
# Unpacks Blender into DIR (default: ~/.local/share/blender-<version>) and prints the path of its binary.
# Does nothing if DIR/blender already exists.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' <"$ROOT/.blender-version")"
DIR="${1:-$HOME/.local/share/blender-$VERSION}"
BIN="$DIR/blender"

if [[ -x "$BIN" ]]; then
	echo "Blender $VERSION already installed." >&2
	echo "$BIN"
	exit 0
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
	echo "Unsupported architecture: $(uname -m) (Blender ships Linux builds for x86_64 only)" >&2
	exit 1
fi

NAME="blender-$VERSION-linux-x64"
URL="https://download.blender.org/release/Blender${VERSION%.*}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Blender $VERSION..." >&2
curl -fsSL -o "$TMP/$NAME.tar.xz" "$URL/$NAME.tar.xz"
curl -fsSL -o "$TMP/blender-$VERSION.sha256" "$URL/blender-$VERSION.sha256"
(cd "$TMP" && grep " $NAME.tar.xz\$" "blender-$VERSION.sha256" | sha256sum --check --quiet -) >&2

tar -xJf "$TMP/$NAME.tar.xz" -C "$TMP"
mkdir -p "$(dirname "$DIR")"
mv "$TMP/$NAME" "$DIR"
echo "Installed Blender $VERSION." >&2
echo "$BIN"
