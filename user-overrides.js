// theme prefs, appended to betterfox's user.js by install.sh. a pref here replaces betterfox's line for it.
// the toolbar layout (browser.uiCustomization.state) is added from layout.json

// ui
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.nova.enabled", false);
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("sidebar.visibility", "hide-launcher");
user_pref("ui.key.menuAccessKeyFocuses", false);
user_pref("browser.download.autohideButton", true);
user_pref("extensions.unifiedExtensions.button.always_visible", true);

// scroll distance per wheel step, smoothfox's natural scrolling uses 300 (suggests 250-400)
user_pref("mousewheel.default.delta_multiplier_y", 200);
user_pref("general.autoScroll", true);

// hardware video decoding, firefox leaves it off on some gpus (nvidia needs libva-nvidia-driver)
user_pref("media.hardware-video-decoding.force-enabled", true);

// search suggestions in the urlbar, betterfox turns them off; the new tab has no search box
user_pref("browser.search.suggest.enabled", true);

// tabs and session
user_pref("browser.startup.page", 3);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.tabs.loadBookmarksInTabs", true);
user_pref("media.autoplay.default", 5);

// new tab: only the pinned sites
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.weatherfeed", false);

// no ai
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
