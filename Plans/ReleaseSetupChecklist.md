# Release Setup Checklist

Everything in slice 2 is built except the credentials and hosting, which only an account holder can set up. Work through this once, then `Scripts/release.sh <version>` handles every release.

Background and commands for each step are in [`Scripts/README.md`](../Scripts/README.md).

## Signing

- [x] Create a **Developer ID Application** certificate: Xcode → Settings → Accounts → Apple ID → Manage Certificates → **+** → Developer ID Application.
- [x] Confirm it landed: `security find-identity -v -p codesigning` lists `Developer ID Application: … (CQZ49H6WAK)`.

## Notarization

- [x] Create an App Store Connect API key: App Store Connect → Users and Access → Integrations → Team Keys → **+**, role **Developer**. Download the `.p8` (one download only).
- [x] Note the Key ID and the Issuer ID from that page.
- [x] Store the credentials in the Keychain under the name the script expects:
      ```
      xcrun notarytool store-credentials "LocusLauncher" \
        --key ~/Downloads/AuthKey_XXXXXXXX.p8 \
        --key-id XXXXXXXX \
        --issuer <issuer-uuid>
      ```
- [x] Confirm it works: `xcrun notarytool history --keychain-profile "LocusLauncher"`.
- [x] Delete the `.p8` from Downloads.

## Sparkle signing key

The key is already generated and in your login Keychain. Its public half is in `LocusLauncher/SupportingFiles/Info.plist`.

- [x] Back up the private half somewhere safe:
      ```
      Scripts/sparkle-tools.sh generate_keys -x sparkle-private-key.txt
      ```
- [x] Move that file into your password manager or another safe place, and delete the copy on disk. Losing this key means no installed copy can ever be updated again.

## Hosting

- [x] Make the repo public.
- [x] Enable GitHub Pages: repo Settings → Pages → Source **Deploy from a branch**, branch `main`, folder `/docs`.
- [x] Commit and push `docs/` so Pages has something to serve.
- [x] Confirm `https://tjdraper.github.io/locus-launcher/appcast.xml` loads. That URL is the `SUFeedURL` baked into every build, so it has to work before the first release ships.
- [x] Run the app and pick **Check for Updates…**. Against the empty feed it should say you are up to date. An error here means the feed URL is wrong, and it is much cheaper to find out now.

## First release

- [x] `Scripts/release.sh 2026.0.1`
- [x] Run the two commands it prints, in the order it prints them.
- [x] Download the published zip on a Mac that has never run the app, unzip it in Downloads, and open it. You should get no Gatekeeper warning, and the offer to move it to Applications.
- [x] Ship a throwaway `2026.0.2` and let an installed `2026.0.1` update itself. Sparkle problems only show up on the second release, so do this before anyone else is relying on it.

## Not set up on purpose

- **Release notes** are required. Write `docs/LocusLauncher-<version>.md` before running the script. That one file becomes the Sparkle update description and the GitHub release body.
- **Publishing** is not automated. The script stops with the artifacts built and prints the `gh release create` and `git` commands, so nothing goes public without you running it.
