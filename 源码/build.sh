#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
output_dir="${1:-$project_dir/build}"
app_dir="$output_dir/小小桌宠.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
spritesheet="$project_dir/Resources/spritesheet.png"

if [[ ! -f "$spritesheet" ]]; then
  print -u2 "缺少动画图集：$spritesheet"
  exit 1
fi

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"

clang \
  -fobjc-arc \
  -O2 \
  -Wall \
  -Wextra \
  -Werror \
  -framework Cocoa \
  "$project_dir/Sources/main.m" \
  -o "$macos_dir/DesktopPet"

cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
cp "$spritesheet" "$resources_dir/spritesheet.png"
xattr -c "$app_dir"
codesign --force --deep --sign - "$app_dir"
print "$app_dir"
