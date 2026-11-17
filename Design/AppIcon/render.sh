#!/bin/zsh
# Regenerates the app icon layers and preview renders.
#   ./Design/AppIcon/render.sh            # from the repository root
# Writes layer PNGs into MoreClock/Resources/AppIcon.icon/Assets and previews into Design/AppIcon/renders.
set -e
HERE=${0:A:h}
ICON=$HERE/../../MoreClock/Resources/AppIcon.icon
T="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
swift $HERE/layers.swift $ICON/Assets
mkdir -p $HERE/renders
for r in Default Dark TintedDark ClearLight; do
  "$T" $ICON --export-image --output-file $HERE/renders/$r.png --platform macOS --rendition $r --width 512 --height 512 --scale 1
done
for s in 64 32 16; do
  "$T" $ICON --export-image --output-file $HERE/renders/s$s.png --platform macOS --rendition Default --width $s --height $s --scale 1
done
cd $HERE/renders && swift $HERE/tile.swift $HERE/preview.png Default.png Dark.png TintedDark.png ClearLight.png s64.png s32.png s16.png
