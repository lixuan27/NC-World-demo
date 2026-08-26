#!/bin/bash
# Pull the curated NC-World demo bundle onto this machine.
#
#   bash fetch.sh [target-dir]        # default: /Users/lixuan/Desktop/NC-World
#
# Each demo ships as a TRIPLE -- the generated video, the ground-truth video it
# is paired against, and the conditioning the model was given (the real action
# array for the robot domains, the caption for general video). A generated clip
# shown without both of those cannot be judged, which is the whole reason the
# bundle is assembled rather than the videos being copied loose.
set -euo pipefail
DEST="${1:-/Users/lixuan/Desktop/NC-World}"
BASE="https://raw.githubusercontent.com/lixuan27/NC-World-demo/main/bundle"

echo "目标目录: $DEST"
mkdir -p "$DEST"

# The file list lives beside this script so the two can never disagree about
# what the bundle contains.
LIST="$(mktemp)"
trap 'rm -f "$LIST"' EXIT
curl -fsSL "$BASE/files.txt" -o "$LIST"
TOTAL=$(grep -c . "$LIST")
echo "清单 $TOTAL 个文件"

i=0
FAILED=0
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  i=$((i + 1))
  mkdir -p "$DEST/$(dirname "$rel")"
  printf "  [%2d/%2d] %s ... " "$i" "$TOTAL" "$rel"
  if curl -fsSL "$BASE/$rel" -o "$DEST/$rel"; then
    echo "$(du -h "$DEST/$rel" | cut -f1)"
  else
    echo "失败"
    FAILED=$((FAILED + 1))
  fi
done < "$LIST"

echo
if [ "$FAILED" -ne 0 ]; then
  # A partial bundle is worse than no bundle: the missing file is usually a
  # ground truth or a condition, and what is left looks complete.
  echo "⚠️ $FAILED/$TOTAL 个文件未取到 -- 包不完整，重跑本脚本（curl 会覆盖已有文件）"
  exit 1
fi
echo "✅ $TOTAL 个文件已放入 $DEST"
echo "   先读 $DEST/README.md"
