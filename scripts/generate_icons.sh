#!/usr/bin/env bash
# Regenerate every launcher icon from a single source PNG.
#
# Prerequisites:
#   ImageMagick 7 (`magick`) or 6 (`convert`).
#
# Usage:
#   Place a square icon at assets/branding/icon.png
#   (recommended 1024x1024, with its own background colour — the
#   adaptive icon background is set separately to match).
#   Then:
#     bash scripts/generate_icons.sh
#
# Outputs:
#   - mipmap-*/ic_launcher.png          legacy launcher icon
#   - mipmap-*/ic_launcher_round.png    legacy round icon
#   - mipmap-*/ic_launcher_fg.png       adaptive foreground (108dp base,
#                                       safe zone applied)
#   - assets/branding/icon_playstore.png  Play Store 512x512

set -euo pipefail

SRC="${SRC:-assets/branding/icon.png}"
RES="android/app/src/main/res"

if [ ! -f "$SRC" ]; then
  echo "ERROR: source icon not found at $SRC"
  echo "Save your 1024x1024 icon to that path and re-run."
  exit 1
fi

MAGICK="$(command -v magick || command -v convert || true)"
if [ -z "$MAGICK" ]; then
  echo "ERROR: ImageMagick not installed. Install with one of:"
  echo "  sudo apt install imagemagick"
  echo "  brew install imagemagick"
  exit 1
fi

# Legacy launcher sizes (48dp base)
declare -A LEGACY=(
  [mdpi]=48
  [hdpi]=72
  [xhdpi]=96
  [xxhdpi]=144
  [xxxhdpi]=192
)

# Adaptive foreground: 108dp base, content in inner 72dp safe zone.
# The PNG is 108dp so Android's mask has room to breathe; the safe
# zone is the inner 66% (72/108). We upscale the icon slightly and
# pad with transparent so the visible content sits inside the safe
# zone.
declare -A ADAPTIVE=(
  [mdpi]=108
  [hdpi]=162
  [xhdpi]=216
  [xxhdpi]=324
  [xxxhdpi]=432
)

for d in "${!LEGACY[@]}"; do
  px="${LEGACY[$d]}"
  dir="$RES/mipmap-$d"
  mkdir -p "$dir"

  echo "Generating mipmap-$d/ic_launcher.png (${px}x${px})"
  "$MAGICK" "$SRC" -resize "${px}x${px}" -strip "$dir/ic_launcher.png"

  echo "Generating mipmap-$d/ic_launcher_round.png (${px}x${px})"
  "$MAGICK" "$SRC" -resize "${px}x${px}" -strip \
    \( +clone -alpha extract \
       -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
       \( +clone -flip \) -compose Multiply -composite \
       \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite "$dir/ic_launcher_round.png"

  apx="${ADAPTIVE[$d]}"
  echo "Generating mipmap-$d/ic_launcher_fg.png (${apx}x${apx})"
  # Scale icon to 72/108 of the canvas and centre on transparent
  safe=$(python3 -c "print(int($apx * 72 / 108))")
  "$MAGICK" "$SRC" -resize "${safe}x${safe}" -strip \
    -gravity center -background none -extent "${apx}x${apx}" \
    "$dir/ic_launcher_fg.png"
done

mkdir -p assets/branding
echo "Generating assets/branding/icon_playstore.png (512x512)"
"$MAGICK" "$SRC" -resize 512x512 -strip assets/branding/icon_playstore.png

echo
echo "Done."
echo
echo "Next: rebuild the APK. The adaptive icon will pick up"
echo "mipmap-*/ic_launcher_fg.png automatically. Background colour is"
echo "#0A0A1A (res/values/colors.xml -> ic_launcher_background). If your"
echo "icon's background is a different colour, update that value to match."
