#!/usr/bin/env bash
# Regenerate launcher icons from a single source PNG.
#
# Prerequisites:
#   - ImageMagick 7 (`magick`) or 6 (`convert`)
#   - A source image at assets/branding/icon.png (1024x1024 or larger,
#     rounded square or full-bleed — the script will resize).
#
# Usage:
#   bash scripts/generate_icons.sh
#
# Outputs: ic_launcher.png and ic_launcher_round.png at every
# Android mipmap density, plus a Play Store 512x512.

set -euo pipefail

SRC="${SRC:-assets/branding/icon.png}"
RES="android/app/src/main/res"

if [ ! -f "$SRC" ]; then
  echo "ERROR: source image not found at $SRC"
  echo "Save your icon as assets/branding/icon.png (1024x1024 recommended)."
  exit 1
fi

MAGICK="$(command -v magick || command -v convert || true)"
if [ -z "$MAGICK" ]; then
  echo "ERROR: ImageMagick not installed. On Linux: 'sudo apt install imagemagick'"
  exit 1
fi

# Android launcher icon sizes (48dp baseline at each density)
declare -A SIZES=(
  [mdpi]=48
  [hdpi]=72
  [xhdpi]=96
  [xxhdpi]=144
  [xxxhdpi]=192
)

for d in "${!SIZES[@]}"; do
  px="${SIZES[$d]}"
  dir="$RES/mipmap-$d"
  mkdir -p "$dir"
  echo "Generating $dir/ic_launcher.png (${px}x${px})"
  "$MAGICK" "$SRC" -resize "${px}x${px}" -strip "$dir/ic_launcher.png"
  echo "Generating $dir/ic_launcher_round.png (${px}x${px})"
  "$MAGICK" "$SRC" -resize "${px}x${px}" -strip \
    \( +clone -alpha extract -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
       \( +clone -flip \) -compose Multiply -composite \
       \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite "$dir/ic_launcher_round.png"
done

# Play Store 512x512
mkdir -p assets/branding
echo "Generating Play Store icon (512x512)"
"$MAGICK" "$SRC" -resize 512x512 -strip assets/branding/icon_playstore.png

echo "Done. Now delete any stale 'ic_launcher_foreground.*' or 'ic_launcher_background.*'"
echo "in mipmap-* or drawable-* dirs, and update mipmap-anydpi-v26/ic_launcher.xml"
echo "if it references them."
