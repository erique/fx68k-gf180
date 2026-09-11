#!/usr/bin/env bash
# Refresh docs/MC68000UM.txt from the NXP-hosted PDF.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOC_DIR="$ROOT/docs"
URL="https://www.nxp.com/docs/en/reference-manual/MC68000UM.pdf"
EXPECT_SHA256="89b690b1923f8a3cff508567090bcab0bcd07511c2deff8ffa393a08efda18e1"

if ! command -v pdftotext >/dev/null 2>&1; then
    echo "error: pdftotext not found (poppler-utils)" >&2
    exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL -o "$workdir/MC68000UM.pdf" "$URL"
got="$(sha256sum "$workdir/MC68000UM.pdf" | awk '{print $1}')"
if [[ "$got" != "$EXPECT_SHA256" ]]; then
    echo "warning: PDF SHA-256 is $got (expected $EXPECT_SHA256)" >&2
    echo "warning: NXP may have replaced the file; inspect before relying on page maps" >&2
fi

pdftotext -layout -eol unix -enc UTF-8 "$workdir/MC68000UM.pdf" "$workdir/raw.txt"

python3 - "$workdir/raw.txt" "$DOC_DIR/MC68000UM.txt" <<'PY'
import pathlib, sys
raw = pathlib.Path(sys.argv[1]).read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
text = raw.decode("utf-8", errors="replace")
pages = text.split("\f")
if pages and pages[-1].strip() == "":
    pages = pages[:-1]
n = len(pages)
out = [f"===== MC68000UM text extract: {n} PDF pages =====\n"]
for i, page in enumerate(pages, 1):
    body = page.rstrip("\n")
    out.append(f"\n===== PDF page {i}/{n} =====\n")
    out.append(body)
    out.append("\n")
pathlib.Path(sys.argv[2]).write_text("".join(out), encoding="utf-8", newline="\n")
print(f"wrote {sys.argv[2]} ({n} pages)")
PY
