#!/usr/bin/env bash
#
# Builds, signs, notarizes and staples a release, then adds it to the Sparkle appcast.
# Publishing is left to you: the script prints the two commands at the end.
#
# One-time setup is documented in Scripts/README.md.

set -euo pipefail

readonly PROJECT="Locus Launcher.xcodeproj"
readonly SCHEME="Locus Launcher"
readonly APP_NAME="Locus Launcher"
readonly ARTIFACT_NAME="LocusLauncher"
readonly GITHUB_REPO="tjdraper/locus-launcher"

readonly NOTARY_PROFILE="${LOCUS_NOTARY_PROFILE:-LocusLauncher}"

cd "$(dirname "${BASH_SOURCE[0]}")/.."
readonly REPO_ROOT="$PWD"
readonly PBXPROJ="$PROJECT/project.pbxproj"
readonly BUILD_DIR="$REPO_ROOT/build"
readonly APPCAST="$REPO_ROOT/docs/appcast.xml"

fail() {
    echo "error: $*" >&2
    exit 1
}

step() {
    echo
    echo "==> $*"
}

# --- Arguments -------------------------------------------------------------

readonly VERSION="${1:-}"
[[ -n "$VERSION" ]] || fail "usage: Scripts/release.sh <version>   (for example: 1.0.1)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || fail "version must look like 1.0 or 1.0.1, got '$VERSION'"

readonly RELEASE_NOTES="$REPO_ROOT/Releases/$VERSION.md"

# --- Preflight -------------------------------------------------------------

step "Checking prerequisites"

[[ -z "$(git status --porcelain)" ]] || fail "working tree is dirty; commit or stash first"

readonly BRANCH="$(git rev-parse --abbrev-ref HEAD)"
UPSTREAM="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)" \
    || fail "$BRANCH has no upstream branch, so there is nothing to tag against"
readonly UPSTREAM

git fetch --quiet --tags

# The build number is the version, so a released version can never be rebuilt under the same name.
git rev-parse --verify --quiet "refs/tags/v$VERSION" >/dev/null \
    && fail "v$VERSION is already tagged; pick a new version"

# The tag has to land on the commit this build came from, so nothing else may be unpushed.
[[ "$(git rev-list --count "$UPSTREAM..HEAD")" == "0" ]] \
    || fail "$BRANCH is ahead of $UPSTREAM; push before releasing"
[[ "$(git rev-list --count "HEAD..$UPSTREAM")" == "0" ]] \
    || fail "$BRANCH is behind $UPSTREAM; pull before releasing"

[[ -f "$RELEASE_NOTES" ]] \
    || fail "write Releases/$VERSION.md first; every release ships with notes"

security find-identity -v -p codesigning | grep -q "Developer ID Application" \
    || fail "no Developer ID Application certificate in the keychain (see Scripts/README.md)"

xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" --output-format json >/dev/null 2>&1 \
    || fail "notarytool profile '$NOTARY_PROFILE' is missing or invalid (see Scripts/README.md)"

# --- Sparkle tools ---------------------------------------------------------

readonly SPARKLE_BIN="$("$REPO_ROOT/Scripts/sparkle-tools.sh")"

"$SPARKLE_BIN/generate_keys" -p >/dev/null 2>&1 \
    || fail "no Sparkle EdDSA signing key in the keychain (see Scripts/README.md)"

# --- Version ---------------------------------------------------------------

step "Setting version $VERSION"
# CFBundleVersion is what Sparkle compares. Keeping it equal to the marketing version leaves one
# number to reason about, at the cost of needing a new version to rebuild a released one.
sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = $VERSION;/g" "$PBXPROJ"

# --- Archive and export ----------------------------------------------------

readonly ARCHIVE="$BUILD_DIR/$ARTIFACT_NAME-$VERSION.xcarchive"
readonly EXPORT_DIR="$BUILD_DIR/export-$VERSION"
readonly EXPORTED_APP="$EXPORT_DIR/$APP_NAME.app"

step "Archiving"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates

step "Exporting a Developer ID build"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$REPO_ROOT/Scripts/ExportOptions.plist" \
    -exportPath "$EXPORT_DIR" \
    -allowProvisioningUpdates

step "Verifying the signature"
codesign --verify --deep --strict --verbose=2 "$EXPORTED_APP"
signature="$(codesign --display --verbose=2 "$EXPORTED_APP" 2>&1)"
grep -q "flags=.*runtime" <<<"$signature" \
    || fail "the exported app is not signed with the hardened runtime"
grep -q "Developer ID Application" <<<"$signature" \
    || fail "the exported app is not signed with a Developer ID Application certificate"

# --- Notarize --------------------------------------------------------------

readonly STAGE_DIR="$BUILD_DIR/appcast-$VERSION"
readonly ZIP="$STAGE_DIR/$ARTIFACT_NAME-$VERSION.zip"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

step "Zipping for notarization"
# Plain `zip` drops the symlinks and extended attributes that a signed bundle needs.
ditto -c -k --keepParent "$EXPORTED_APP" "$ZIP"

step "Notarizing (this waits for Apple)"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

step "Stapling"
xcrun stapler staple "$EXPORTED_APP"
xcrun stapler validate "$EXPORTED_APP"

step "Checking Gatekeeper"
spctl --assess --type exec --verbose=2 "$EXPORTED_APP"

step "Re-zipping the stapled app"
# The ticket has to be inside the archive users download, so the zip is rebuilt after stapling.
rm -f "$ZIP"
ditto -c -k --keepParent "$EXPORTED_APP" "$ZIP"

# --- Appcast ---------------------------------------------------------------

step "Updating the appcast"
cp "$APPCAST" "$STAGE_DIR/appcast.xml"
cp "$RELEASE_NOTES" "$STAGE_DIR/$ARTIFACT_NAME-$VERSION.md"

"$SPARKLE_BIN/generate_appcast" \
    --download-url-prefix "https://github.com/$GITHUB_REPO/releases/download/v$VERSION/" \
    --link "https://github.com/$GITHUB_REPO" \
    -o "$STAGE_DIR/appcast.xml" \
    "$STAGE_DIR"

cp "$STAGE_DIR/appcast.xml" "$APPCAST"

# Sparkle links release notes relative to the feed URL, so they have to ship alongside it.
cp "$RELEASE_NOTES" "$REPO_ROOT/docs/$ARTIFACT_NAME-$VERSION.md"

# --- Next steps ------------------------------------------------------------

cat <<EOF

Built and notarized $APP_NAME $VERSION.

  app: $EXPORTED_APP
  zip: $ZIP

Publish in this order. The tag lands on the release commit, and the download goes live before
the feed points at it:

  git add "$PBXPROJ" docs && git commit -m "Release $VERSION"
  git tag v$VERSION
  git push origin v$VERSION
  gh release create v$VERSION "$ZIP" --repo $GITHUB_REPO --title "$VERSION" --verify-tag --notes-file Releases/$VERSION.md
  git push

If you stop here, undo the version bump and the appcast entry with:

  git checkout -- "$PBXPROJ" docs
EOF
