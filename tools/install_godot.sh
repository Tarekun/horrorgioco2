#!/usr/bin/env bash
# Downloads the pinned Godot editor (version in .godot-version) for Linux x86_64 or arm64 and verifies its checksum.
#
# Usage: tools/install_godot.sh [DIR]
#
# Installs the binary as DIR/godot (default DIR: ~/.local/share/godot-<version>) and prints its path.
# Does nothing if DIR/godot already exists.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' <"$ROOT/.godot-version")"
DIR="${1:-$HOME/.local/share/godot-$VERSION}"
BIN="$DIR/godot"

if [[ -x "$BIN" ]]; then
	echo "Godot $VERSION already installed." >&2
	echo "$BIN"
	exit 0
fi

case "$(uname -m)" in
x86_64) ARCH="x86_64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*)
	echo "Unsupported architecture: $(uname -m)" >&2
	exit 1
	;;
esac

TAG="$VERSION-stable"
NAME="Godot_v${TAG}_linux.$ARCH"
URL="https://github.com/godotengine/godot/releases/download/$TAG"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading Godot $TAG ($ARCH)..." >&2
curl -fsSL -o "$TMP/$NAME.zip" "$URL/$NAME.zip"
curl -fsSL -o "$TMP/SHA512-SUMS.txt" "$URL/SHA512-SUMS.txt"
(cd "$TMP" && grep " $NAME.zip\$" SHA512-SUMS.txt | sha512sum --check --quiet -) >&2

if command -v unzip >/dev/null 2>&1; then
	unzip -q "$TMP/$NAME.zip" -d "$TMP"
else
	python3 -m zipfile -e "$TMP/$NAME.zip" "$TMP"
fi
mkdir -p "$DIR"
mv "$TMP/$NAME" "$BIN"
chmod +x "$BIN"
echo "Installed Godot $VERSION." >&2
echo "$BIN"
