# Not used by Classic (make synth / make core) and not used by the chip pad ring.
#
# Classic is pad-less: do not apply 68000 pin AC to fx68k RTL ports (hold and
# combinational-input failures). Chip pad AC is librelane/chip_top.sdc in the
# parent chip clone; that file sources constraints/fx68k.sdc for core
# multicycle.
#
# UM 10 MHz column: docs/MC68000UM.txt §10.10.
