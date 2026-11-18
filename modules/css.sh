#!/usr/bin/env bash
# sourced by install.sh, copies the css into the profile's chrome folder

mkdir -p "$profile/chrome"
for f in userChrome.css userContent.css tst.css; do
  dst=$profile/chrome/$f
  [[ $src/$f -ef $dst ]] && continue
  # keep only the first backup, so a rerun can't replace the original with the theme
  [[ -f $dst && ! -f $dst.bak ]] && cp "$dst" "$dst.bak"
  cp "$src/$f" "$dst"
done
