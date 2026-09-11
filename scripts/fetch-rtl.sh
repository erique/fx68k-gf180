#!/usr/bin/env bash
# Vendor fx68k RTL at the pinned commit into src/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT/src"
REPO_URL="https://github.com/ijor/fx68k.git"
COMMIT="$(tr -d '[:space:]' < "$SRC_DIR/COMMIT")"

if [[ -z "$COMMIT" ]]; then
    echo "error: src/COMMIT is empty" >&2
    exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

git clone --filter=blob:none "$REPO_URL" "$workdir/fx68k"
git -C "$workdir/fx68k" fetch --depth 1 origin "$COMMIT"
git -C "$workdir/fx68k" checkout --detach "$COMMIT"

for f in fx68k.sv fx68kAlu.sv uaddrPla.sv microrom.mem nanorom.mem fx68k.txt LICENSE README.md; do
    cp -a "$workdir/fx68k/$f" "$SRC_DIR/$f"
    # Normalize text files (including ROM images) to Unix LF.
    case "$f" in
        *.sv|*.txt|*.md|*.mem|LICENSE) sed -i 's/\r$//' "$SRC_DIR/$f" ;;
    esac
done

got="$(git -C "$workdir/fx68k" rev-parse HEAD)"
printf '%s\n' "$got" > "$SRC_DIR/COMMIT"
echo "Vendored fx68k at $got into $SRC_DIR"
