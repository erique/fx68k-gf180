# fx68k core timing constraints.
# Single clock domain: clk is the only clock. enPhi1/enPhi2 are clock enables.

set clk_name clk
set clk_port_name clk
set clk_period 50.0

set clk_port [get_ports $clk_port_name]
create_clock -name $clk_name -period $clk_period $clk_port

set_clock_uncertainty 0.25 [get_clocks $clk_name]

# enPhi1/enPhi2 are synchronous clock enables on clk, not separate clocks.
# They remain ordinary input ports (timed as data).

# Microcode / nanocode address is allowed 2 cycles of setup from Ir
# (1-cycle hold). Translated from src/fx68k.txt.
# After Yosys flatten the flops keep RTL net names on Q (Ir[*],
# microAddr[*], nanoAddr[*]). Constrain the sequential cells that
# drive/load those nets, not every combinational pin on the net.
proc fx68k_reg_cells {net_pat pin_name} {
    set nets [get_nets -quiet $net_pat]
    if {[llength $nets] == 0} {
        puts "WARNING: no nets match $net_pat"
        return {}
    }
    set pins [get_pins -quiet -of_objects $nets -filter "name == $pin_name"]
    if {[llength $pins] == 0} {
        puts "WARNING: no $pin_name pins on nets $net_pat"
        return {}
    }
    return [get_cells -quiet -of_objects $pins]
}

proc fx68k_multicycle {from_net_pat to_net_pat} {
    set from_cells [fx68k_reg_cells $from_net_pat Q]
    set to_cells [fx68k_reg_cells $to_net_pat Q]
    if {[llength $from_cells] == 0 || [llength $to_cells] == 0} {
        puts "WARNING: multicycle path $from_net_pat -> $to_net_pat: registers not found"
        return
    }
    puts "INFO: multicycle 2/1 $from_net_pat -> $to_net_pat ([llength $from_cells] -> [llength $to_cells] regs)"
    set_multicycle_path -setup 2 -from $from_cells -to $to_cells
    set_multicycle_path -hold 1 -from $from_cells -to $to_cells
}

fx68k_multicycle {Ir[*]} {microAddr[*]}
fx68k_multicycle {Ir[*]} {nanoAddr[*]}

# Optional 68000 bus I/O delays: source fx68k_io.sdc (see README).
# Not included in the default GDS flow — I/O hold is not closed without pads.
