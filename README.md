# fx68k on GF180MCU

[fx68k](https://github.com/ijor/fx68k) cycle-accurate 68000 core on the
open GlobalFoundries 180 nm MCU PDK (`gf180mcuD`), via
[LibreLane](https://librelane.readthedocs.io/) Classic flow. No pad ring.

fx68k RTL is GPL-3.0 (`src/LICENSE`).

| Item | Value |
| --- | --- |
| Generic core | Classic GDS closed at 50 ns (20 MHz `clk`, 10 MHz 68000-equivalent). |
| PDK | `gf180mcuD` (Ciel `f6eeac7dad085ffcc829ccfd721f7b4ce39edcf7`) |
| SCL | `gf180mcu_fd_sc_mcu7t5v0` |
| Core RTL | sv2v `src_v/fx68k.v` from `src/` |

## Usage

Pad-less fx68k. `clk` is 50 ns (20 MHz); `enPhi1` and `enPhi2` are clock enables.

```sh
make clone-pdk
make synth          # Yosys + pre-PnR STA → core/runs/synth/
make core           # Classic flow through GDS → core/final/
```

Needs Python 3.10+. `make clone-pdk` creates `.venv` and installs
[Ciel](https://github.com/fossi-foundation/ciel) and LibreLane from
`requirements.txt`.

- **sv2v** — used from `PATH`, or `make sv2v` downloads it to `tools/sv2v`.
- **LibreLane** — host binary if `librelane` and `yosys` are on `PATH`;
  otherwise `.venv` runs `python3 -m librelane --dockerized`.

Constraints: `constraints/fx68k.sdc` (clock and Ir→microAddr/nanoAddr
multicycle). Optional 68000 bus I/O: `constraints/fx68k_io.sdc` (not
sourced by default).

MC68000 user manual extract: `docs/MC68000UM.txt`.
