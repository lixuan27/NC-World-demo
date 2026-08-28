#!/bin/bash
# Pull the curated NC-World demo bundle onto this machine.
#
#   bash fetch.sh [target-dir]        # default: /Users/lixuan/Desktop/NC-World
#
# Each demo ships as a TRIPLE -- the generated video, the ground-truth video it
# is paired against, and the conditioning the model was given (the real action
# array). A generated clip shown without both of those cannot be judged, which
# is the whole reason the bundle is assembled rather than the videos copied
# loose.
#
# `files.txt` is the COMPLETE definition of the bundle, not an add-list. This
# script therefore also REMOVES files it previously wrote that the manifest no
# longer names. That matters here: the bundle has already been revised three
# times (the general-video clips were replaced once, then the whole domain was
# dropped), and an add-only fetch leaves every superseded revision lying in the
# target directory looking exactly as authoritative as the current one.
#
# ⚠️ It only ever deletes paths recorded in `.ncw-bundle-manifest`, which this
# script writes. Anything else in the target directory -- including files you
# put there yourself -- is never touched. "Delete only what we wrote" is the
# rule; a fetch script that prunes by pattern would eventually eat something it
# did not create.
set -euo pipefail
DEST="${1:-/Users/lixuan/Desktop/NC-World}"
BASE="https://raw.githubusercontent.com/lixuan27/NC-World-demo/main/bundle"
STATE=".ncw-bundle-manifest"

echo "目标目录: $DEST"
mkdir -p "$DEST"

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
  # ground truth or a condition, and what is left looks complete. Do NOT prune
  # after a partial fetch -- a failed download must not be able to trigger a
  # delete.
  echo "⚠️ $FAILED/$TOTAL 个文件未取到 -- 包不完整，**已跳过清理**"
  echo "   重跑本脚本（curl 会覆盖已有文件）"
  exit 1
fi

# ---- adopt the pre-manifest revisions ---------------------------------------
# The manifest only knows what a manifest-aware fetch wrote. Everything written
# by the earlier add-only versions of this script is therefore invisible to the
# prune below and survives forever -- which is not a rounding error, because the
# files that predate the manifest are exactly the ones that were superseded. The
# 14 paths listed here are the union of every `general/` entry across all
# historical versions of files.txt (`git log -- bundle/files.txt`), i.e. the
# complete set this script could ever have written under that prefix. They are
# the retracted general-video demos: selected by a motion metric, they all
# disintegrate around frame 40, and disintegration itself produces large optical
# flow, so the metric scored the worst clips highest.
#
# Enumerated on purpose. The alternative -- prune anything not named in
# files.txt -- would also delete files you put in this directory yourself, and
# no manifest bug is worth trading that rule away for.
LEGACY="general/clip01_generated.mp4 general/clip01_groundtruth.mp4
general/clip03_generated.mp4 general/clip03_groundtruth.mp4
general/clip15_generated.mp4 general/clip15_groundtruth.mp4
general/clip17_generated.mp4 general/clip17_groundtruth.mp4
general/clip20_generated.mp4 general/clip20_groundtruth.mp4
general/clip23_generated.mp4 general/clip23_groundtruth.mp4
general/clip25_generated.mp4 general/clip25_groundtruth.mp4"
for old in $LEGACY; do
  # never adopt a path the current manifest still names -- if `general/` ever
  # comes back, this list must not be able to delete the live copy
  grep -Fxq "$old" "$LIST" && continue
  [ -e "$DEST/$old" ] || continue
  grep -Fxq "$old" "$DEST/$STATE" 2>/dev/null || echo "$old" >> "$DEST/$STATE"
done

# ---- prune: only paths this script wrote before, absent from the new manifest
PRUNED=0
if [ -f "$DEST/$STATE" ]; then
  while IFS= read -r old; do
    [ -z "$old" ] && continue
    if ! grep -Fxq "$old" "$LIST"; then
      if [ -e "$DEST/$old" ]; then
        rm -f "$DEST/$old"
        echo "  已清理（清单外的旧版本）: $old"
        PRUNED=$((PRUNED + 1))
      fi
    fi
  done < "$DEST/$STATE"
  # drop directories that the pruning emptied, never a non-empty one
  find "$DEST" -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

cp "$LIST" "$DEST/$STATE"

echo
echo "✅ $TOTAL 个文件已放入 $DEST"
[ "$PRUNED" -gt 0 ] && echo "   清理了 $PRUNED 个已被取代的旧文件"
echo "   先读 $DEST/README.md"
