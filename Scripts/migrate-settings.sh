#!/bin/bash
# Transfer settings from a previous MoreClock identity without deleting the source data.
# Usage: bash migrate-settings.sh /path/to/previous/MoreClock.app /Applications/MoreClock.app
set -euo pipefail
umask 077

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

if [ "$#" -ne 2 ]; then
    printf 'Usage: bash %s /path/to/previous/MoreClock.app /Applications/MoreClock.app\n' "$0" >&2
    exit 2
fi
old_app="$1"
new_app="$2"
old_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$old_app/Contents/Info.plist")
new_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$new_app/Contents/Info.plist")
old_name=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$old_app/Contents/Info.plist")
[ "$old_name" = MoreClock ] || fail 'The source must be a previous MoreClock application.'
[ "$new_id" = com.skyviiew.MoreClock ] || fail 'The destination must use the Skyviiew application identity.'
[ "$old_id" != "$new_id" ] || fail 'Both applications already use the same settings domain; no transfer is needed.'
case "$old_id" in *[!a-zA-Z0-9.-]*|'') fail 'The previous application identifier is invalid.';; esac

if /usr/bin/pgrep -x MoreClock >/dev/null; then
    fail 'Quit all copies of MoreClock before transferring settings.'
fi

old_data="$HOME/Library/Containers/$old_id/Data"
new_data="$HOME/Library/Containers/$new_id/Data"
old_preferences="$old_data/Library/Preferences/$old_id"
new_preferences="$new_data/Library/Preferences/$new_id"
[ -f "$old_preferences.plist" ] || fail 'No saved preferences were found for the previous application.'
/usr/bin/plutil -lint "$old_preferences.plist" >/dev/null

# Backups stay in the application's private data, never in the repository or disk image.
backup_root="$old_data/Library/Application Support/MoreClock/IdentityUpgradeBackups"
/bin/mkdir -p "$backup_root"
backup=$(/usr/bin/mktemp -d "$backup_root/Upgrade.XXXXXX")
/usr/bin/defaults export "$old_preferences" "$backup/source.plist"

# Let macOS create the destination sandbox container and its metadata; don't fabricate it.
if [ ! -d "$new_data/Library/Preferences" ]; then
    /usr/bin/open -g "$new_app"
    for attempt in $(/usr/bin/seq 1 40); do
        [ -d "$new_data/Library/Preferences" ] && break
        /bin/sleep 0.25
    done
    [ -d "$new_data/Library/Preferences" ] || fail 'The new application did not initialize its container. Open it once, quit it, and retry.'
    /usr/bin/osascript - "$new_app" <<'APPLESCRIPT'
on run arguments
    tell application (item 1 of arguments) to quit
end run
APPLESCRIPT
    for attempt in $(/usr/bin/seq 1 40); do
        /usr/bin/pgrep -x MoreClock >/dev/null || break
        /bin/sleep 0.25
    done
    /usr/bin/pgrep -x MoreClock >/dev/null && fail 'The new application is still running. Quit it and retry.'
fi

# Be idempotent, and never overwrite clocks already configured under the new identity.
if [ -f "$new_preferences.plist" ]; then
    /usr/bin/defaults export "$new_preferences" "$backup/destination-before.plist"
    if target_clocks=$(/usr/bin/plutil -extract clocks raw -o - "$backup/destination-before.plist" 2>/dev/null); then
        source_clocks=$(/usr/bin/plutil -extract clocks raw -o - "$backup/source.plist" 2>/dev/null || true)
        if [ "$target_clocks" = "$source_clocks" ]; then
            printf 'The destination already contains these clocks; no settings were overwritten.\n'
            /usr/bin/open "$new_app"
            exit 0
        fi
        fail 'The new identity already has different saved clocks. Both domains were backed up; no settings were overwritten.'
    fi
fi

/usr/bin/defaults import "$new_preferences" "$backup/source.plist"
# A one-time relaunch request from an earlier process must not carry into this upgrade.
/usr/bin/defaults delete "$new_preferences" reopenSettingsAfterLanguageChange >/dev/null 2>&1 || true
/usr/bin/plutil -lint "$new_preferences.plist" >/dev/null
printf 'Settings transferred. The previous preferences are unchanged.\nBackup: %s\n' "$backup"
printf 'If you used Launch at login, enable it again in the new application.\n'
/usr/bin/open "$new_app"
