## 2026.0.11

### Added
- Apps can have their own hot keys. Select an app in the launcher and press Cmd + K, or choose Manage Hot Keys from its actions menu. An app can have any number of hot keys, and each one either opens the app or opens a new window in it. Opening an app that's already in front does nothing.
- A new hot key starts recording right away, so you can press the keys without clicking the field first.
- If the keys you press already open the launcher or another app, the field is outlined in red and a message says what uses them. When another hot key uses them, Use Here Instead moves them over. If macOS itself uses the keys, a note says the hot key may not work.
- The launcher shows an app's first hot key at the end of its row.
- A new “App Hot Keys window” lists every app with hot keys, with buttons to edit or remove them. Open it from the menu bar menu or with Cmd + Option + K while the launcher is open. Apps that are no longer on this Mac stay in the list, so their hot keys can be removed.
- Each hot key has a "Sync to other Macs" choice, which will take effect when syncing arrives in a later update.

### Changed
- Recording a launcher shortcut that an app hot key already uses shows the same red outline and message in Settings instead of an alert, and Use Here Instead gives the keys to the launcher.
