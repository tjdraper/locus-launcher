## 2026.1

The first full release of Locus Launcher: a fast, fully Mac native, keyboard-first app launcher for macOS 26 and later. Press `⌘Space` (or your chosen key combination), type a few letters, and hit Return. Or give any app a hot key of its own.

### Why I made it

This launcher is inspired somewhat by [Omarchy](https://omarchy.org/) and its keyboard-driven workflow. With Siri being ever more incorporated into `⌘Space` (Spotlight) on the Mac, I find it increasingly difficult to use Spotlight as an application launcher, which is, quite honestly, all I ever do with `⌘Space`.

Having installed and played around with Omarchy on an old custom-built PC, I like a lot of its keyboard-driven app launching, even if I really dislike its window manager. So, being a software engineer, I cooked up an app to solve both issues. And, being a longtime Mac guy, I made the app as [Mac-assed](https://daringfireball.net/linked/2020/03/20/mac-assed-mac-apps) as I possibly could.

Locus Launcher does one thing, and does it well (well, I think so, anyway): it launches applications. Invoke the launcher, start typing, hit Return. It’s **fast**. And if you use the arrow keys to get to an app that’s not the first result for what you typed, it remembers, and makes that app the first result the next time you type the same thing.

And, Omarchy style, you can assign a keyboard shortcut to any app, and choose whether that shortcut activates the app or opens a new window for it. Press `⌘K` with an app selected to bring up its hot key settings, and give it a hot key or two.

And if you’re like me, you still want Siri occasionally, particularly the new Apple Foundation Model-powered Siri. So do what I do: assign Locus Launcher to `⌘Space`, then in System Settings, assign Spotlight to `⌃Space`, and you can have both!

— TJ

### Changed
- If you ran the betas, Locus Launcher asks whether you want to keep getting betas now that you’re on a full release.

### Added
- Press `⌘Space` (by default) to open the launcher on the screen the pointer is on, with the cursor in the search field. Press the shortcut again, press Esc, or click outside the launcher to close it. You can choose a different shortcut in Settings.
- Type to search your apps. The letters you type just have to appear in order, so “saf” finds Safari and “vsc” finds Visual Studio Code. Case and accents don’t matter. The best match is selected, so Return opens it right away.
- The launcher learns which app you open for what you type and puts it first next time. Recent choices count more than old ones, so the order follows your habits as they change. This history stays on your Mac.
- Move the selection with the arrow keys and press Return to open the app, or click an app to open it.
- The app list finds apps in your Applications folders, the system app folders, and anywhere else Spotlight knows about, including external drives. Each app is listed once, and the list updates on its own when apps are installed or removed, or when a drive is connected or ejected.
- If you close the launcher and open it again within 10 seconds, it picks up where you left off.
- Each app has an actions menu. Press Tab, press the Right arrow at the end of the search text, or click the arrow at the end of the row to open it. The actions are Open (`↩`), New Window (`⌥⌘↩`), Reveal in Finder (`⌘↩`), Manage Hot Keys (`⌘K`), and Hide from Launcher (`⌥⌘⌫`). Each shortcut also works without opening the menu.
- New Window brings the app forward and opens a new window for the app. This feature needs Accessibility access, which Locus Launcher asks for the first time you use it.
- Give any app its own hot keys, configurable to either bring the app forward (or open it if its closed), or open a new window for the app. The launcher shows an app’s first hot key at the end of its row. If the keys you pick are already in use, Locus Launcher says what uses them and can move them over.
- The App Hot Keys window lists every app with hot keys, with buttons to edit or remove them. Open it from the menu bar menu or with `⌥⌘K` while the launcher is open.
- Hide apps you never launch. The Hidden Apps window lists them and lets you unhide them. Open it from the menu bar menu or with `⌃⌥⌘H` while the launcher is open.
- Hot keys and hidden apps can sync through iCloud to your other Macs signed in to the same account. Turn on “Sync to other Macs” for each one you want synced. If a synced hot key uses keys this Mac already uses, this Mac’s keeps working and the synced one is marked so you can change it.
- Since spotlight uses `⌘Space` out of the box, Locus Launcher settings shows when Spotlight’s shortcut is in the way and turns it off with one click, and can turn it back on later.
- A setup checklist walks through moving the app to Applications, choosing the launcher shortcut, allowing Accessibility access, opening at login, and checking for updates automatically. It opens on the first launch and comes back each launch until you click Done. Open it anytime from Setup Checklist in the menu bar menu.
- Settings has switches for opening at login, checking for updates automatically, and getting beta updates, plus a Permissions section that shows whether Accessibility access is allowed.
- Locus Launcher updates itself. When an update is ready, a red dot appears on the menu bar icon and an Update button appears next to the launcher’s search field, instead of a window popping up while you work.
