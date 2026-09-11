#!/usr/bin/env python3
# Emit synchronous ROM Verilog from $readmemb-format .mem files.
# Width and depth come from the mem file; address width is ceil(log2(depth)).

from __future__ import annotations

import argparse
from pathlib import Path


def load_mem(path: Path) -> tuple[int, list[str]]:
    lines = []
    width = None
    for lineno, raw in enumerate(path.read_text().splitlines(), 1):
        word = raw.strip()
        if not word or word.startswith("//") or word.startswith("#"):
            continue
        if word.startswith("@"):
            raise SystemExit(f"{path}:{lineno}: address tokens are not supported")
        if any(ch not in "01" for ch in word):
            raise SystemExit(f"{path}:{lineno}: expected binary word, got {word!r}")
        if width is None:
            width = len(word)
        elif len(word) != width:
            raise SystemExit(
                f"{path}:{lineno}: width {len(word)} != {width} from first word"
            )
        lines.append(word)
    if width is None or not lines:
        raise SystemExit(f"{path}: no binary words")
    return width, lines


def addr_width(depth: int) -> int:
    if depth < 1:
        raise SystemExit("depth must be >= 1")
    return (depth - 1).bit_length()


def emit_rom(
    *,
    module: str,
    clk: str,
    addr: str,
    data: str,
    mem: Path,
    out: Path,
    src_label: str,
) -> None:
    width, words = load_mem(mem)
    depth = len(words)
    aw = addr_width(depth)
    last = depth - 1
    msb = width - 1
    addr_msb = aw - 1

    body = [
        f"// Generated from {src_label}. Do not hand-edit.",
        f"module {module} (",
        f"\t{clk},",
        f"\t{addr},",
        f"\t{data}",
        ");",
        f"\tinput {clk};",
        f"\tlocalparam ADDR_WIDTH = {aw};",
        f"\tinput [{addr_msb}:0] {addr};",
        f"\tlocalparam WIDTH = {width};",
        f"\toutput reg [{msb}:0] {data};",
        f"\tlocalparam DEPTH = {depth};",
        f"\treg [{msb}:0] ram [0:{last}];",
        "\tinitial begin",
    ]
    for i, word in enumerate(words):
        body.append(f"\t\tram[{i}] = {width}'b{word};")
    body.extend(
        [
            "\tend",
            f"\talways @(posedge {clk}) {data} <= ram[{addr}];",
            "endmodule",
            "",
        ]
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(body), newline="\n")
    print(f"wrote {out} ({depth} x {width})")


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--src",
        type=Path,
        default=root / "src",
        help="directory with microrom.mem and nanorom.mem",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=root / "src_v",
        help="directory for generated Verilog",
    )
    args = parser.parse_args()

    emit_rom(
        module="uRom",
        clk="clk",
        addr="microAddr",
        data="microOutput",
        mem=args.src / "microrom.mem",
        out=args.out_dir / "uRom.v",
        src_label="src/microrom.mem",
    )
    emit_rom(
        module="nanoRom",
        clk="clk",
        addr="nanoAddr",
        data="nanoOutput",
        mem=args.src / "nanorom.mem",
        out=args.out_dir / "nanoRom.v",
        src_label="src/nanorom.mem",
    )


if __name__ == "__main__":
    main()
