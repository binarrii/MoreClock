#!/bin/bash
# Builds the universal Release app with the commit and build time shown in Settings › About.
# Usage: Scripts/build-release.sh [derived-data-path]
# Prints the path of the built MoreClock.app on success.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
derived_data="${1:-$root/build/ReleaseDerivedData}"
log="$derived_data/build-release.log"

commit=$(git -C "$root" rev-parse --short=7 HEAD)
# Mark builds of uncommitted changes, so About never claims a commit it doesn't match.
if [ -n "$(git -C "$root" status --porcelain)" ]; then
    commit="$commit-dirty"
fi
build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$derived_data"
if ! xcodebuild \
    -project "$root/MoreClock.xcodeproj" \
    -scheme MoreClock \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$derived_data" \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS='arm64 x86_64' \
    ENABLE_TESTABILITY=NO \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    MORECLOCK_GIT_COMMIT="$commit" \
    MORECLOCK_BUILD_DATE="$build_date" \
    build > "$log" 2>&1; then
    tail -n 40 "$log" >&2
    printf 'Release build failed; full log: %s\n' "$log" >&2
    exit 1
fi

printf '%s\n' "$derived_data/Build/Products/Release/MoreClock.app"
