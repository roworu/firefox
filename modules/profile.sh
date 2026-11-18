#!/usr/bin/env bash
# sourced by install.sh, picks the profile to install into, from the first argument or the profiles firefox knows about

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
