# Locus Launcher: High-Level Plan

## Slices

1. **Scaffold**
   - Xcode project, macOS 26 target, Swift 6 with MainActor default
   - SwiftLint set up before any feature code, running on every build with zero violations
     - Build tool plugin from `SimplyDanny/SwiftLintPlugins`, same as locus-todo
     - Copy `.swiftlint.yml` from locus-todo and change its `included` paths to this project's targets
   - Menu bar only, no Dock icon (`LSUIElement`), with a menu bar item that has Quit
   - Developer ID signing and hardened runtime turned on from day one
   - "Hello world" floating panel
   - MIT `LICENSE` file and `.gitignore`

2. **Release pipeline**
   - Script that archives, notarizes and staples the `.app`, then zips it with `ditto -c -k --keepParent` (plain `zip` can break the signature)
   - On first launch outside `/Applications`, offer to move the app there. macOS runs apps opened from Downloads out of a hidden read-only location, which breaks Sparkle updates and launch at login.
   - Sparkle for auto-updates, since there's no App Store to deliver them
   - Doing this early means Gatekeeper and signing problems show up before there's much code to debug

3. **Launcher panel and global hotkey**
   - Register the global hotkey
   - Floating panel with the cursor in the search field
   - Esc or clicking away dismisses it
   - Opens on the active screen
   - Cmd+, opens Settings while the panel has focus
   - Opening the app while it's already running opens Settings

4. **App index**
   - Find apps in `/Applications`, `/System/Applications`, `~/Applications` and any others the system knows about
   - Display names, icons, and live updates when apps are installed or removed

5. **Browse list**
   - Alphabetical sections with letter headers
   - A–Z index on the right, iOS style
   - Arrow key selection, Enter to launch

6. **Fuzzy search and ranking**
   - Fuzzy matcher, first result selected
   - Launch history per search term, which pushes recent picks to the top

7. **Settings basics**
   - Fill in the Settings window (slice 3 added a placeholder)
   - Launch at login (`SMAppService`)
   - Shortcut recorder for the launcher hotkey (`KeyboardShortcuts.Recorder`)
   - Turn off Spotlight's Cmd+Space shortcut from the app, with a fallback link to System Settings (see Decisions)
   - Beta updates toggle. Sparkle's channel filter already reads the `ReceiveBetaUpdates` default (slice 2), so this is a checkbox bound to that key, with a line explaining that betas ship more often and may break.
   - Sparkle gentle reminders (https://sparkle-project.org/documentation/gentle-reminders). Today a scheduled check that finds an update brings Sparkle's window to the front at any moment. Instead, show a quiet sign that an update is ready and open the window when the user clicks it. The menu bar icon can be hidden, so the sign can't live only there; a notification or a line in the launcher panel covers that case. Sparkle logs a warning at launch until this is done.

8. **Actions menu and hidden apps**
   - The selected row shows a caret at its trailing edge. Tab, or clicking the caret's area, opens an actions menu for that app. Clicking anywhere else on the row still opens the app. Tab is used because every arrow-key combination already moves the search field's cursor or switches Spaces.
   - While the menu is open, Up and Down arrows move through it and Enter runs the highlighted item. Esc closes only the menu, and the panel stays open.
   - Each menu item shows its keyboard shortcut, and the shortcut works from the panel without opening the menu:
     - Open (Enter)
     - New Window (Cmd+Option+Enter)
     - Reveal in Finder (Cmd+Enter)
     - Hide from Launcher (Cmd+Option+Delete)
   - New Window activates the app and sends Cmd+N, so it needs Accessibility permission (see Decisions). Without it, New Window only activates the app. Slice 9 reuses this for "open new window" shortcuts.
   - Hidden apps drop out of both browse and search
   - Each hidden app has a "Sync to other Macs" choice, on by default and stored per app so slice 10 can sync it. Hiding happens right away with no prompt, since a prompt would slow down a one-keystroke action. The choice is changed in the Hidden Apps window.
   - A Hidden Apps window lists hidden apps, can unhide them, and can change each one's sync choice. It opens from the menu bar menu, or with Cmd+Option+Control+H while the panel has focus. Cmd+Option+H is left alone because it's the system's Hide Others shortcut.

9. **Per-app shortcuts**
   - Assign shortcuts to an app from the actions menu: "Manage Hot Keys" (Cmd+K)
   - An app can have any number of shortcuts, and each one either activates the app or opens a new window. That gives an app a shortcut for each action.
   - An Open shortcut does nothing when its app is already in front. It doesn't hide the app.
   - Apps are matched by bundle identifier, which stays the same across updates. Apps without one fall back to their path and can't sync, the same as hidden apps.
   - Detect conflicting shortcuts: the same keys can't be used by two app shortcuts or by an app shortcut and the launcher. The recorder warns about shortcuts the system uses. Shortcuts other apps register can't be detected.
   - Each shortcut has a "Sync to other Macs" choice, stored for slice 10
   - Shortcuts keep working for hidden apps
   - Show the first of an app's assigned shortcuts in its launcher row
   - An App Hot Keys window, opened from the menu bar menu or with Cmd+Option+K while the panel has focus, lists every app with shortcuts, including apps no longer on this Mac, with a way to edit them. It's a separate window like Hidden Apps, to keep Settings short.

10. **iCloud sync**
    - Shortcut settings sync through iCloud key-value storage
    - Each shortcut is either synced or local to this Mac
    - Hidden apps marked for sync (slice 8) sync the same way
    - Handle a synced shortcut for an app that isn't installed on the other Mac

11. **First-run wizard**
    - A one-page setup checklist shown on first launch, and reopenable from the menu bar menu and Settings
    - Only fresh installs see it at launch. Installs from before this slice are recognized by Sparkle's launched-before flag and skip it.
    - Move to `/Applications` if needed
    - Choose the launcher hotkey, and turn off Spotlight's shortcut if Cmd+Space is chosen
    - Grant Accessibility permission, with an explanation of what it enables (opening new windows) and a way to skip it
    - Launch at login
    - Ask about automatic update checks here. Sparkle otherwise raises its own permission prompt on the second launch, which for a menu bar app that starts at login lands at an arbitrary moment. Take it over with `SPUUpdaterDelegate.updaterShouldPromptForPermissionToCheckForUpdates`. The checklist turns automatic checks on unless the user already chose, matching the default in Sparkle's prompt.
    - Each step reflects the real current state, so granting a permission in System Settings updates the wizard

12. **Polish and first release**
    - App icon, website download, v1
    - Custom menu bar icon to replace the `square.grid.2x2` SF Symbol. It has to keep working with the red update badge, which `MenuBarIcon` draws into the image.

## Decisions

- **Cmd+Space:** macOS gives it to Spotlight. The app offers a button that turns off Spotlight's shortcut by editing `com.apple.symbolichotkeys.plist` (entries 64 and 65) and applying the change without a logout. This is undocumented, so it needs testing on each macOS release, and it falls back to opening the right System Settings page. When the app changed the setting, Settings offers to turn it back on, which matters most after the user picks a different launcher hotkey. Quitting leaves it off, since the app can't tell a normal quit from an uninstall.
- **Accessibility permission:** opening a new window means activating the app and sending it Cmd+N, which needs Accessibility access. The wizard asks for it but the user can skip. Without it, New Window in the actions menu and "open new window" shortcuts only activate the app, and Settings says so next to that option with a way to grant access. Apps that ignore Cmd+N also fall back to activating.
- **No App Sandbox:** sending keystrokes to other apps and editing Spotlight's shortcut don't work in the sandbox. Signing and notarization still work. App Store distribution isn't a goal.
- **Updates:** Sparkle, with release zips on GitHub Releases and the appcast served from GitHub Pages at `https://tjdraper.github.io/locus-launcher/appcast.xml`. Betas ride the same feed on a Sparkle channel.
- **Distribution:** a notarized, stapled `.app` in a zip, not a DMG.
- **Launch history:** stays local to each Mac and isn't synced, since installed apps differ between Macs.
- **iCloud sync:** each synced hot key and hidden app is its own key in iCloud key-value storage, so edits to different entries on two Macs don't overwrite each other. Each Mac remembers what it and iCloud last agreed on, which tells a removal on one Mac apart from an entry the other Mac hasn't sent yet. Turning "Sync to other Macs" off keeps the entry on that Mac and removes it from the others. A synced hot key whose keys this Mac already uses, for another hot key or the launcher, doesn't work here, and App Hot Keys says so until one of them changes. Hot keys for apps that aren't on a Mac aren't registered there, so they don't take keys from other apps.
- **Search scope:** the main launcher searches apps only. No settings search.
- **Hotkeys:** the `KeyboardShortcuts` package (sindresorhus) registers global hotkeys through Carbon, which needs no Accessibility permission. It also provides the shortcut recorder and supports any number of named shortcuts, which per-app shortcuts need. The launcher hotkey defaults to Cmd+Space, so until Spotlight's shortcut is turned off (slice 7), turn it off by hand in System Settings to test.
- **Settings window:** a plain AppKit window hosting a SwiftUI view, not SwiftUI's `Settings` scene, which can only be opened from inside a SwiftUI view. The app shows a Dock icon while Settings is open so the window is reachable with Cmd+Tab.
- **Menu bar icon:** no hide option in the app. macOS's own "Allow in the Menu Bar" setting covers that. With the icon hidden, Settings is still reachable with Cmd+, in the launcher, or by opening Locus Launcher again (from the launcher or Finder) while it's running.
- **License:** MIT.
- **Onboarding:** a first-run wizard (slice 11) covers every setup step, including permissions.

## Future versions

- **Menu bar item toggler** (research project, not in v1)
  - A second global hotkey, Option+Space by default and configurable, opens a panel listing the apps in System Settings → Menu Bar → "Allow in the Menu Bar"
  - Search the list, then flip an item on or off without opening System Settings
  - Apple has no public API for this. The settings live in a protected system folder (`~/Library/Group Containers/com.apple.MenuBar`) that other apps can't read. The fallback is driving the System Settings switch through Accessibility, which is fragile.
  - Option+Space is also ChatGPT's default shortcut and types a non-breaking space, so conflicts need flagging

- **More result actions:** quit a running app, and other actions beyond slice 8's menu. Not in v1.

- **Apps not on this Mac in App Hot Keys:** move apps that aren't installed on this Mac into their own area at the bottom of the App Hot Keys window, collapsed by default. Synced hot keys (slice 10) will bring in apps from other Macs, and they shouldn't crowd out the apps this Mac has. Not in v1.

- **Sync status in App Hot Keys:** show in each row of the App Hot Keys window whether the app's hot keys sync through iCloud. Sync is chosen per hot key, so an app can have some that sync and some that don't, and the row needs a way to show that. Not in v1.

- **Right-click for the actions menu:** right-clicking an app in the launcher panel selects it and opens its actions menu, the same as Tab or clicking the caret. Not in v1.

## Public repo

The GitHub repo will be public, and it will host the release zips and the Sparkle appcast.

- Never commit secrets: signing certificates, notarization credentials, or the Sparkle private key. The release script reads them from the Keychain or environment variables.
- Write everything in the repo (code, comments, commit messages, plans, docs) as if the public will read it.
- `.gitignore` covers `.DS_Store`, `xcuserdata`, build output and local config from the start.
- The Sparkle feed URL is baked into every build and can never change, so moving hosting later means adding a custom domain to the same GitHub Pages site rather than picking a new URL. GitHub redirects the `github.io` address, and Sparkle follows redirects, so installs already in the wild keep updating.

## Useful from locus-todo

- `QuickCapture/` has a floating window and keyboard handling, which is close to what the launcher panel needs.
- `.swiftlint.yml`, the Architecture docs, and the `.icon` workflow.
- Neither app shares a hotkey, iCloud key-value storage or launch-at-login implementation. Locus ToDo syncs through CloudKit, which is a different mechanism.
