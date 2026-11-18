// added to user.js only on kde (XDG_CURRENT_DESKTOP contains KDE)

// kde's own open/save dialogs and "open with" through the desktop portal, instead of gtk's
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
