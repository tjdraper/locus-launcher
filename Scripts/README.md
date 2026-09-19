# Releasing

```
Scripts/release.sh 2026.4
```

The script bumps the version, archives, exports a Developer ID build, notarizes it, staples the ticket, re-zips the stapled app, and adds the release to `docs/appcast.xml`. It does not publish: it prints the `gh release create` and `git` commands to run, in the order that keeps the download live before the feed points at it.

`CFBundleVersion` is set to the same value as the marketing version, so there is only one number to track. Sparkle compares `CFBundleVersion`, which means a version that has shipped can never be rebuilt under the same name — ship a new version instead. The script refuses a version you have already tagged.

Release notes are required. If `docs/LocusLauncher-<version>.md` is missing, the script checks everything else first, then creates the empty file and stops so you can write them. A blank or whitespace-only file fails the next run. Sparkle renders Markdown, so headings, lists, code blocks and tables work. Notes live in `docs/` because that is where Sparkle fetches them from, alongside the appcast; keeping an authoring copy elsewhere would only be the same file twice. The script links the file from the appcast and passes it to `gh release create` as the GitHub release description. It does not need committing first; it goes in with the release commit.

The script refuses to run unless the branch is clean, has an upstream, and is exactly in sync with it. The release tag has to land on the commit the build came from, which is impossible if there is unpushed work in the way.

If a release fails partway, undo the version bump and the appcast entry with `git checkout -- "Locus Launcher.xcodeproj/project.pbxproj" docs`.

## Testing a notarized build

```
Scripts/install-test-build.sh
```

Builds, notarizes, and staples the working tree as it is, without bumping the version or touching the appcast. It then quits the copy running from `/Applications`, moves that copy to the Trash, installs the new build in its place, and opens it. A Debug copy running from Xcode is left alone.

Use it for anything that needs Accessibility access. The Debug build can't get the grant, but this build is signed like a release, so it keeps the grant the released app already has.

The build keeps whatever version the project currently has, so Sparkle may offer to replace it with a newer release.

## Versions and the beta channel

Versions are `YYYY.N` for a release and `YYYY.N.B` for a beta. Betas leading to `2026.4` are numbered `2026.3.1`, `2026.3.2` and so on: each sits above the `2026.3` release and below the `2026.4` it becomes. A year starts its betas at `YYYY.0.1` and its first release at `YYYY.1`.

```
2026.2      release
2026.2.1    beta
2026.2.2    beta
2026.3      release
2027.0.1    beta
2027.1      release
```

The script reads the channel off the shape of the version, so the two cannot disagree. A three-part version is a beta: `generate_appcast` gets `--channel beta`, and the printed `gh release create` gets `--prerelease`.

Beta and release share one appcast. A beta item carries `<sparkle:channel>beta</sparkle:channel>`, which Sparkle only offers to updaters that ask for that channel by name, so everyone else sees releases only.

Opt a Mac in with:

```
defaults write com.buzzingpixel.LocusLauncher ReceiveBetaUpdates -bool YES
```

and back out with `-bool NO`. There is no UI for this yet.

A beta cannot be promoted in place, because `CFBundleVersion` is the version: `2026.3.2` ships again as `2026.4`, rebuilt and re-notarized.

## One-time setup

### Developer ID Application certificate

Xcode → Settings → Accounts → your Apple ID → Manage Certificates → **+** → Developer ID Application. Only the account holder can create one.

### Developer ID provisioning profile

iCloud sync needs the iCloud key-value storage entitlement, and a Developer ID build can only carry it with a Developer ID provisioning profile. `xcodebuild` on the command line can't create one when it has no access to the Xcode account ("No Accounts"), so let Xcode create it once: Product → Archive, then Distribute App → Direct Distribution. After that, the export in `release.sh` finds the profile Xcode keeps.

### Notarization credentials

Create an App Store Connect API key (App Store Connect → Users and Access → Integrations → Team Keys) with the Developer role, download the `.p8`, then:

```
xcrun notarytool store-credentials "LocusLauncher" \
  --key ~/Downloads/AuthKey_XXXXXXXX.p8 \
  --key-id XXXXXXXX \
  --issuer <issuer-uuid>
```

The name must match `LOCUS_NOTARY_PROFILE` in `release.sh`, or set that environment variable to whatever you used. The `.p8` can be deleted afterwards; the credentials live in the Keychain.

### Sparkle signing key

Already generated and stored in the login Keychain. Its public half is `SUPublicEDKey` in `LocusLauncher/SupportingFiles/Info.plist`.

**Back the private key up somewhere safe.** Losing it means no existing install can ever be updated again — the only fix would be asking everyone to download the app by hand.

```
Scripts/sparkle-tools.sh generate_keys -x sparkle-private-key.txt
```

`sparkle-tools.sh` downloads Sparkle's command line tools into `build/tools/` if they aren't there yet, then runs the one you name. With no arguments it prints the directory holding them, which is how `release.sh` uses it.

Keep the exported key file out of the repo.

### GitHub Pages

Repo Settings → Pages → deploy from branch `main`, folder `/docs`. That serves the appcast at `https://tjdraper.github.io/locus-launcher/appcast.xml`, which is the `SUFeedURL` baked into every build.

If the feed ever moves to a custom domain, add it to the same Pages site rather than changing `SUFeedURL`. GitHub redirects the old URL, so installs already in the wild keep updating.
