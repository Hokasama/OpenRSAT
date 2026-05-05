#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-dev}"
ARTIFACT_DIR="${ARTIFACT_DIR:-/home/hoka/artifacts}"
EXE="$ROOT/bin/win64/OpenRSAT.exe"
OUT_EXE="$ARTIFACT_DIR/OpenAdaxes-Console-$VERSION-win64.exe"
OUT_ZIP="$ARTIFACT_DIR/OpenAdaxes-Console-$VERSION-win64.zip"

if [[ ! -f "$EXE" ]]; then
  echo "Missing Windows executable: $EXE" >&2
  echo "Build it first with:" >&2
  echo "  lazbuild --build-mode=win64 sources/OpenRSAT.lpi" >&2
  exit 1
fi

mkdir -p "$ARTIFACT_DIR"
cp -f "$EXE" "$OUT_EXE"
cd "$ARTIFACT_DIR"
rm -f "$(basename "$OUT_ZIP")"
zip -9 -q "$(basename "$OUT_ZIP")" "$(basename "$OUT_EXE")"
sha256sum "$OUT_EXE" "$OUT_ZIP"
