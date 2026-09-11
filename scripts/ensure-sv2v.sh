#!/usr/bin/env bash
# Install the upstream sv2v binary into tools/sv2v if it is not already there.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SV2V_VERSION="${SV2V_VERSION:-v0.0.13}"
DEST="$ROOT/tools/sv2v"

mkdir -p "$ROOT/tools"

if command -v sv2v >/dev/null 2>&1; then
    exit 0
fi
if [[ -x "$DEST" ]]; then
    exit 0
fi

case "$(uname -s)" in
    Darwin) archive=sv2v-macOS.zip ;;
    Linux)  archive=sv2v-Linux.zip ;;
    MINGW*|MSYS*|CYGWIN*) archive=sv2v-Windows.zip ;;
    *)
        echo "error: no sv2v binary for $(uname -s); install sv2v or set SV2V" >&2
        exit 1
        ;;
esac

url="https://github.com/zachjs/sv2v/releases/download/${SV2V_VERSION}/${archive}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "fetching $url" >&2
curl -fsSL "$url" -o "$workdir/$archive"
unzip -q "$workdir/$archive" -d "$workdir/out"

bin=""
for f in "$workdir/out"/sv2v "$workdir/out"/sv2v.exe "$workdir/out"/*/sv2v "$workdir/out"/*/sv2v.exe; do
    if [[ -f "$f" ]]; then
        bin="$f"
        break
    fi
done
if [[ -z "$bin" ]]; then
    echo "error: sv2v binary not in $archive" >&2
    exit 1
fi

cp -a "$bin" "$DEST"
chmod +x "$DEST"
