#!/usr/bin/env bash
# sourced by install.sh, writes betterfox, smoothfox, user-overrides(-kde).js and the toolbar layout to user.js

# betterfox's user.js is the base and gets replaced on every run, so it stays at the latest version
bf=https://raw.githubusercontent.com/yokoffing/Betterfox/main
curl -fsSL -o "$tmp/user.js" "$bf/user.js" || { echo "could not download betterfox user.js" >&2; exit 1; }
curl -fsSL -o "$tmp/Smoothfox.js" "$bf/Smoothfox.js" || { echo "could not download Smoothfox.js" >&2; exit 1; }
# smoothfox lists every scrolling option uncommented, so take just the natural one
awk '/OPTION: NATURAL SMOOTH SCROLLING/ { on = 1; next } on && /^\/\*{4}/ { exit } on && /^user_pref/' \
  "$tmp/Smoothfox.js" > "$tmp/smooth.js"
[[ -s $tmp/smooth.js ]] || { echo "natural smooth scrolling section not found in Smoothfox.js" >&2; exit 1; }

# the layout pref is the json as one escaped string
echo "user_pref(\"browser.uiCustomization.state\", $(jq -c . "$src/layout.json" | jq -R .));" > "$tmp/layout.js"

overrides=("$src/user-overrides.js")
[[ -n $kde ]] && overrides+=("$src/user-overrides-kde.js")

# drop earlier lines for the prefs the theme sets, so its values win
grep -ho '^user_pref("[^"]*",' "${overrides[@]}" "$tmp/layout.js" > "$tmp/ours"

js=$profile/user.js
[[ -f $js && ! -f $js.bak ]] && cp "$js" "$js.bak"
{
  { cat "$tmp/user.js"; echo; echo "// smoothfox: natural smooth scrolling"; cat "$tmp/smooth.js"; } \
    | grep -Fv -f "$tmp/ours" || true
  echo
  cat "${overrides[@]}" "$tmp/layout.js"
} > "$js"
