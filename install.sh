#!/usr/bin/env bash
# Install this theme into a firefox profile: copies the css, writes betterfox + user-overrides.js + layout.json
# to user.js, and policies.json (extensions, their settings and firefox policies) to firefox's policies.
# usage: ./install.sh [profile-dir], without one it updates an existing install or asks which profile
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
command -v jq > /dev/null || { echo "jq is needed" >&2; exit 1; }
# kde gets its own dialogs and plasma integration, from the *-kde files
[[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] && kde=1 || kde=
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for part in profile css userjs policies; do
  # shellcheck source=/dev/null
  source "$src/modules/$part.sh"
done

echo
echo "done, restart firefox to load it."
