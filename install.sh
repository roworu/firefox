#!/usr/bin/env bash
# Install this theme into a firefox profile: copies the css and writes betterfox + the prefs it needs to user.js.
# usage: ./install.sh [profile-dir], without one it updates an existing install or asks which profile
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# scroll distance per wheel step, smoothfox's natural scrolling uses 300 (suggests 250-400)
scroll_multiplier=200

# extensions to sideload, "amo-slug extension-id" per line, add more here
extensions='tree-style-tab treestyletab@piro.sakura.ne.jp
bitwarden-password-manager {446900e4-71c2-419f-a6a7-df9c091e268b}
floccus floccus@handmadeideas.org
ublock-origin uBlock0@raymondhill.net
sponsorblock sponsorBlocker@ajay.app
violentmonkey {aecec67f-0d10-4fa7-b7c7-609a2db280cf}
istilldontcareaboutcookies idcac-pub@guus.ninja'

# every profile listed in a normal, flatpak or macos firefox's profiles.ini
list_profiles() {
  local root path
  for root in "$HOME/Library/Application Support/Firefox" \
              "$HOME/.mozilla/firefox" \
              "$HOME/.config/mozilla/firefox" \
              "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" \
              "$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox"; do
    [[ -f $root/profiles.ini ]] || continue
    while IFS= read -r path; do
      [[ $path == /* ]] && echo "$path" || echo "$root/$path"
    done < <(sed -n 's/^Path=//p' "$root/profiles.ini")
  done
}

profile=${1:-}
if [[ -z $profile ]]; then
  profiles=()
  while IFS= read -r p; do profiles+=("$p"); done < <(list_profiles)
  (( ${#profiles[@]} )) || { echo "no firefox profile found, pass its path as an argument" >&2; exit 1; }
  # tst.css is only ever put there by this script, so it marks an existing install to update
  installed=()
  for p in "${profiles[@]}"; do
    [[ -f $p/chrome/tst.css ]] && installed+=("$p")
  done
  (( ${#installed[@]} )) && profiles=("${installed[@]}")
  if (( ${#profiles[@]} == 1 )); then
    profile=${profiles[0]}
  else
    PS3="install into which profile? "
    select profile in "${profiles[@]}"; do
      [[ -n $profile ]] && break
    done
  fi
fi
[[ -d $profile ]] || { echo "not a directory: $profile" >&2; exit 1; }
echo "profile: $profile"

mkdir -p "$profile/chrome"
for f in userChrome.css tst.css; do
  dst=$profile/chrome/$f
  [[ $src/$f -ef $dst ]] && continue
  # keep only the first backup, so a rerun can't replace the original with the theme
  [[ -f $dst && ! -f $dst.bak ]] && cp "$dst" "$dst.bak"
  cp "$src/$f" "$dst"
done

# betterfox's user.js is the base and gets replaced on every run, so it stays at the latest version
bf=https://raw.githubusercontent.com/yokoffing/Betterfox/main
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/user.js" "$bf/user.js" || { echo "could not download betterfox user.js" >&2; exit 1; }
curl -fsSL -o "$tmp/Smoothfox.js" "$bf/Smoothfox.js" || { echo "could not download Smoothfox.js" >&2; exit 1; }
# smoothfox lists every scrolling option uncommented, so take just the natural one
awk '/OPTION: NATURAL SMOOTH SCROLLING/ { on = 1; next } on && /^\/\*{4}/ { exit } on && /^user_pref/' \
  "$tmp/Smoothfox.js" > "$tmp/smooth.js"
[[ -s $tmp/smooth.js ]] || { echo "natural smooth scrolling section not found in Smoothfox.js" >&2; exit 1; }

# firefox picks up signed xpis named after the extension id from here, autoDisableScopes below makes them enable themselves
mkdir -p "$profile/extensions"
while read -r slug id; do
  curl -fsSL -o "$profile/extensions/$id.xpi" "https://addons.mozilla.org/firefox/downloads/latest/$slug/latest.xpi" \
    || { echo "could not download extension $slug" >&2; exit 1; }
done <<< "$extensions"

js=$profile/user.js
[[ -f $js && ! -f $js.bak ]] && cp "$js" "$js.bak"
{ cat "$tmp/user.js"; echo; echo "// smoothfox: natural smooth scrolling"; cat "$tmp/smooth.js"; echo; echo "// theme"; } > "$js"
while read -r name value; do
  grep -Fv "user_pref(\"$name\"," "$js" > "$js.tmp" || true
  echo "user_pref(\"$name\", $value);" >> "$js.tmp"
  mv "$js.tmp" "$js"
done <<EOF
toolkit.legacyUserProfileCustomizations.stylesheets true
extensions.autoDisableScopes 0
browser.nova.enabled false
browser.compactmode.show true
browser.uidensity 1
sidebar.visibility "hide-launcher"
mousewheel.default.delta_multiplier_y $scroll_multiplier
EOF

cat <<EOF

done, restart firefox to load it.
tree style tab is installed, but its settings can't be set from here, set these in its options page:
  advanced > user style sheet > load from file > $profile/chrome/tst.css
  tick "Unlock Expert Options" at the top, most tree behavior ones below are hidden without it
  appearance > theme: Photon
  appearance > untick "Enable animation effects"
  tree behavior > untick "When a new tree appears, collapse others automatically"
  tree behavior > untick "When a tab gets focus, expand its tree and collapse others automatically"
  tree behavior > untick "Except focus moving caused by closing of the current tab"
  tree behavior > untick "When a tab under a collapsed tree gets focus, expand its tree automatically"
  tree behavior > untick "When a tree under a collapsed native tab group is expanded, expand the group also"
  tree behavior > tick "Don't expand collapsed tree and skip collapsed descendants, while switching focus of tabs via keyboard shortcuts"
EOF
