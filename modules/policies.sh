#!/usr/bin/env bash
# sourced by install.sh, writes policies.json with tst.css added to tst's settings, merged into firefox's policies

# policies are per firefox install, not per profile, and need root
case $profile in
  "$HOME/Library/"*) policies=/Applications/Firefox.app/Contents/Resources/distribution/policies.json ;;
  # flatpak reads them from its systemconfig extension, mounted at /app/etc/firefox in the sandbox
  "$HOME/.var/app/"*) policies=/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/$(flatpak --default-arch)/stable/policies/policies.json ;;
  *) policies=/etc/firefox/policies/policies.json ;;
esac

# tst stores its user style sheet base64 encoded, split into 6kb chunks over 8 slots, unused slots stay empty
base64 < "$src/tst.css" | tr -d '\n' | fold -w 6144 > "$tmp/chunks"
[[ $(wc -l < "$tmp/chunks") -le 8 ]] || { echo "tst.css is too large for tree style tab" >&2; exit 1; }
base=("$src/policies.json")
[[ -n $kde ]] && base+=("$src/policies-kde.json")
jq -s 'reduce .[] as $p ({}; . * $p)' "${base[@]}" > "$tmp/base.json"
jq --rawfile chunks "$tmp/chunks" '
  ($chunks | split("\n")) as $c
  | .policies["3rdparty"].Extensions["treestyletab@piro.sakura.ne.jp"]
      += (reduce range(8) as $i ({}; .["chunkedUserStyleRules\($i)"] = ($c[$i] // "")))' \
  "$tmp/base.json" > "$tmp/theme.json"

if [[ -f $policies ]]; then
  # merge so other policies survive. each of our entries replaces its old one whole, a deep merge would keep
  # keys an earlier run wrote and this one dropped
  jq -s '.[1].policies as $t | .[0]
    | .policies += ($t | del(.ExtensionSettings, .["3rdparty"]))
    | .policies.ExtensionSettings += $t.ExtensionSettings
    | .policies["3rdparty"].Extensions += $t["3rdparty"].Extensions' \
    "$policies" "$tmp/theme.json" > "$tmp/policies.json"
else
  cp "$tmp/theme.json" "$tmp/policies.json"
fi
echo "writing policies, extensions and their settings to $policies (needs sudo)"
sudo mkdir -p "$(dirname "$policies")"
[[ -f $policies && ! -f $policies.bak ]] && sudo cp "$policies" "$policies.bak"
sudo cp "$tmp/policies.json" "$policies"
sudo chmod 644 "$policies"
