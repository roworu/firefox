# firefox-theme

Firefox with Tree Style Tab (TST) in the sidebar instead of horizontal tabs.

```sh
./install.sh [profile-dir]
```

Without a profile it updates an existing install (the one with `chrome/tst.css`) or asks which profile.
Needs `curl`, `jq`, and `sudo` for `policies.json`. Restart Firefox afterwards.
On Windows run `install.ps1 [-ProfileDir <dir>]` instead, from PowerShell as administrator:
`powershell -ExecutionPolicy Bypass -File install.ps1`.

## What goes where

| File | Installed to | Why there |
| --- | --- | --- |
| `userChrome.css` | `<profile>/chrome/` | firefox loads it for its own ui |
| `userContent.css` | `<profile>/chrome/` | firefox loads it for web and about: pages |
| `tst.css` | `<profile>/chrome/` and `policies.json` | firefox can't load css into extension pages, TST takes it from its policy settings; the profile copy only marks an existing install |
| `user-overrides.js`, `layout.json`, on kde `user-overrides-kde.js` | `<profile>/user.js` | appended to Betterfox and Smoothfox scrolling, firefox applies `user.js` on every start; the layout becomes `browser.uiCustomization.state` |
| `policies.json`, on kde `policies-kde.json` | `/etc/firefox/policies/` (linux), `Firefox.app/Contents/Resources/distribution/` (macos), `C:\Program Files\Mozilla Firefox\distribution\` (windows), the flatpak `systemconfig` extension | policies are per install not per profile; they install extensions and hand settings to them; `tst.css` is added to TST's settings on install |

Existing files get a `.bak` copy once, so reruns never overwrite the original. `user.js` is rebuilt every run to
pick up the latest Betterfox. An existing `policies.json` is merged with `jq`: each policy written here replaces
its old value whole, other policies stay.

## Overrides

### user.js

[Betterfox](https://github.com/yokoffing/Betterfox) `user.js` plus Smoothfox's natural smooth scrolling, then
`user-overrides.js`:

| Pref | Value | Why |
| --- | --- | --- |
| `toolkit.legacyUserProfileCustomizations.stylesheets` | `true` | load `userChrome.css` and `userContent.css` |
| `browser.nova.enabled` | `false` | keep the classic ui |
| `browser.compactmode.show` | `true` | allow compact density |
| `browser.uidensity` | `1` | compact density |
| `sidebar.visibility` | `"hide-launcher"` | no sidebar launcher strip |
| `mousewheel.default.delta_multiplier_y` | `200` | scroll distance per wheel step |
| `general.autoScroll` | `true` | middle click scrolling, off by default on linux |
| `media.hardware-video-decoding.force-enabled` | `true` | hardware video decoding, firefox leaves it off on some gpus (nvidia needs `libva-nvidia-driver`) |
| `browser.search.suggest.enabled` | `true` | search suggestions in the urlbar, Betterfox turns them off |
| `ui.key.menuAccessKeyFocuses` | `false` | alt doesn't show the menubar |
| `browser.startup.page` | `3` | restore the previous session |
| `browser.tabs.closeWindowWithLastTab` | `false` | closing the last tab keeps the window |
| `browser.tabs.loadBookmarksInTabs` | `true` | bookmarks open in a new tab |
| `media.autoplay.default` | `5` | block all autoplay, also muted |
| `browser.newtabpage.activity-stream.showSearch` | `false` | no search box on the new tab |
| `browser.newtabpage.activity-stream.feeds.section.highlights` | `false` | no recent activity on the new tab |
| `browser.newtabpage.activity-stream.showWeather` | `false` | no weather on the new tab |
| `browser.newtabpage.activity-stream.feeds.weatherfeed` | `false` | don't fetch weather |
| `browser.ml.enable` | `false` | no ai features |
| `browser.ml.chat.enabled` | `false` | no ai chatbot |
| `browser.download.autohideButton` | `true` | downloads button only when needed |
| `extensions.unifiedExtensions.button.always_visible` | `true` | extensions button always on the toolbar |
| `browser.uiCustomization.state` | toolbar layout | from `layout.json` |

### policies.json

| Policy | Value |
| --- | --- |
| `ExtensionSettings` | installs the extensions below from AMO (`normal_installed`), buttons in the extensions menu (TST on the toolbar, see `layout.json`) |
| `PasswordManagerEnabled` | `false`, Bitwarden is used instead |
| `OfferToSaveLogins` | `false` |
| `AutofillAddressEnabled` | `false`, Bitwarden fills forms |
| `AutofillCreditCardEnabled` | `false` |
| `GenerativeAI` | all features off |
| `UserMessaging` | no recommendations, onboarding, "More from Mozilla" or Firefox Labs |
| `FirefoxHome` | no sponsored top sites or stories |
| `DontCheckDefaultBrowser` | `true` |
| `NoDefaultBookmarks` | `true` |
| `DisableTelemetry` | `true`, locks what Betterfox sets as prefs |
| `DisableFirefoxStudies` | `true` |
| `DisableFeedbackCommands` | `true`, no "Report broken site" and similar menu items |
| `DisableFirefoxAccounts` | `true`, no Sync, floccus syncs bookmarks |
| `SearchEngines` | `Default`: Google |

Extensions, those marked private also run in private windows:

- Tree Style Tab (private)
- Bitwarden (private)
- uBlock Origin (private)
- floccus
- SponsorBlock
- Violentmonkey
- I still don't care about cookies

### KDE

When `XDG_CURRENT_DESKTOP` contains `KDE`, `install.sh` also adds:

- `user-overrides-kde.js`: `widget.use-xdg-desktop-portal.file-picker` and `.mime-handler` `1`, KDE's open/save
  dialogs and "open with" instead of GTK's
- `policies-kde.json`: Plasma Integration (`plasma-browser-integration@kde.org`), merged into `policies.json`;
  its button is in the extensions menu through `layout.json`, ignored elsewhere

Run `install.sh` as yourself, not with `sudo`, or the desktop isn't detected.

### Tree Style Tab settings

Locked through `policies.json`, so they can't be changed in TST's options:

| Setting | Value |
| --- | --- |
| `style` | `"proton"` |
| `animation` | `false` |
| `autoCollapseExpandSubtreeOnAttach` | `false` |
| `autoCollapseExpandSubtreeOnSelect` | `false` |
| `autoCollapseExpandSubtreeOnSelectExceptActiveTabRemove` | `false` |
| `unfocusableCollapsedTab` | `false` |
| `expandNativeTabGroupByMemberTreeExpansion` | `false` |
| `skipCollapsedTabsForTabSwitchingShortcuts` | `true` |
| `maxTreeLevel` | `3`, indent at most 3 levels |
| `insertNewChildAt` | `3`, next to the last related tab |
| `chunkedUserStyleRules0`-`7` | `tst.css` |

### uBlock Origin filter lists

Replaces the selected lists: user filters, uBlock filters (ads, badware, privacy, unbreak, quick fixes),
EasyList, EasyPrivacy, URLhaus, Peter Lowe's list, uBlock Annoyances, EasyList Annoyances, EasyList Cookie and
uBlock's EasyList Cookie companion.

### userChrome.css

- hide the horizontal tab strip
- show the window buttons on the nav-bar and let its empty space drag the window
- hide the sidebar header
- no outline or shadow around the sidebar
- sidebar uses the toolbar color
- TST sidebar can shrink to favicon width (32px)
- 1px sidebar splitter with a 7px grab area
- hide back/forward, tracking protection, star, reader mode, zoom, page actions, search mode switcher, go button
  and the context menu's navigation row
- no line between toolbox and content
- no bookmarks bar slide animation, it could leave the page under the bar

### userContent.css

- new tab and home page in neutral system colors instead of firefox's purple-tinted grays
- no logo or search box, the pinned sites centered on the page

### tst.css

- tab bar in the Firefox toolbar color, active tab a shade darker, 8px rounded tabs
- flat tabs: no shadow or outline on the active tab, solid hover color
- chrome's thin close x with a round hover circle and thin plus on the new tab button
- no background overlay
- sound button doesn't shrink when the closebox appears
- closebox only on hover, also on the active tab
- hide the "open a new tab as..." arrow next to the new tab button

## Development

Everything the theme sets is in plain files: the css, `user-overrides.js`, `layout.json` and `policies.json`,
plus the `*-kde` files for KDE.
`install.sh` applies them with the scripts in `modules/`, in order: `profile.sh` picks the profile, `css.sh` copies
the css, `userjs.sh` builds `user.js`, `policies.sh` writes the policies. Every change goes through `install.sh`,
then a Firefox restart, policies and `user.js` are only read at startup.
Edit the repo, never the installed copies, the next run overwrites them. Keep the override lists above in sync.

### Adding things

- **Extension:** add an entry to `ExtensionSettings` in `policies.json`, copying an existing one. The install url
  ends in the AMO slug (last part of the AMO url), the id is in `about:support` > Add-ons or `manifest.json`
  (`browser_specific_settings.gecko.id`). `"private_browsing": true` lets it run in private windows.
  Add its button to `unified-extensions-area` in `layout.json` (and `seen`) as `<id>-browser-action`: id lowercased,
  anything outside `[a-z0-9_-]` turned into `_`. Without it in `layout` it lands wherever firefox puts new buttons.
- **Pref:** add a `user_pref(...)` line to `user-overrides.js`. A pref listed there replaces Betterfox's line
  for it. Names and current values are in `about:config`.
- **Firefox policy:** add it to `policies.json`. Check the name and fields against the
  installed version's schema, it changes between releases:
  `unzip -p /usr/lib/firefox/browser/omni.ja modules/policies/policies-schema.json | jq '.properties.<Name>'`
  (unzip warns about the archive, that's fine).
- **TST setting:** add it under `3rdparty.Extensions["treestyletab@piro.sakura.ne.jp"]` in `policies.json`. Keys and defaults are in TST's
  `common/common.js` (`configs` object), constants for numeric values in `common/constants.js`:
  `unzip -p <profile>/extensions/treestyletab@piro.sakura.ne.jp.xpi common/common.js | grep -n '<key>'`.
  A misspelled key is silently ignored, so check the option changed in TST's settings after a restart.
- **uBlock Origin list:** add the token to `filterLists` in `policies.json`. Tokens are the keys of `assets/assets.json` in uBO's
  xpi. The array replaces uBO's whole selection, so keep the defaults in it.
- **Extension settings for other extensions:** only if the extension supports managed storage (look for
  `storage.managed` / `managed_storage` in its source), then add an entry next to uBO's under `3rdparty` in `policies.json`.

### Finding css to override

- **Firefox ui (`userChrome.css`):** Browser Toolbox (`Ctrl+Alt+Shift+I`, needs `devtools.chrome.enabled` and
  `devtools.debugger.remote-enabled` in `about:config`), pick the element, see which rule sets it. Firefox's own
  css is in `browser/omni.ja` under `chrome/browser/skin/classic/browser/`, e.g. `sidebar.css`.
- **TST sidebar (`tst.css`):** `about:debugging` > This Firefox > Tree Style Tab > Inspect, then select the
  sidebar document. TST's styles are in its xpi under `sidebar/styles/`: `base.css` for everything,
  `proton/proton.css` for the theme used here. Most colors are variables (`--tab-surface-active`,
  `--tabbar-bg`, ...), set those before overriding properties. Proton sets some variables on the elements
  themselves, so set them on the same elements (see the first rule in `tst.css`).
- TST's own rules have low specificity but some use `!important`, so overrides here use `!important`.
- `tst.css` goes to TST base64 encoded in 8 slots of 6144 chars, so it must stay under about 36kb;
  `install.sh` stops if it doesn't fit.

### Testing

- `bash -n install.sh modules/*.sh` for syntax, `jq . policies.json layout.json` for json.
- Dry run without touching the system: put stub `curl` and `sudo` scripts first in `PATH` and point `HOME` at a
  temp dir, then run `install.sh <temp-profile>`. The stub `curl` writes a fake `user.js` and a `Smoothfox.js`
  with a `NATURAL SMOOTH SCROLLING` section, the stub `sudo` copies the `policies.json` it gets somewhere to
  inspect with `jq`.
- After a real install and restart:
  - `about:policies` lists active policies and shows errors for unknown or wrong ones.
  - `about:support` shows the profile folder and installed extensions.
  - `about:config` shows the prefs, values from `user.js` show as modified.
  - TST options show the settings from `policies.json`; its user style sheet box shows `tst.css`.
  - uBO dashboard > Filter lists shows the selected lists.
- Check light and dark themes, colors here are derived from system colors (`-moz-dialog`, `-moz-dialogtext`).
