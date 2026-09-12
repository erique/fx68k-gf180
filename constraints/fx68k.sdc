# fx68k core timing constraints (pad-less).
# Single clock domain: clk is the only clock. enPhi1/enPhi2 are clock enables
# (data), not generated clocks.
#
# 68000 asynchronous-bus AC vs package pins is not modeled here. That SDC
# lives in the parent chip (librelane/chip_top.sdc) and sources this file
# for flop-to-flop / microcode multicycle after creating the die clock.
#
# Parent chip may set clk_name / clk_port_name / clk_period before source.
# create_clock is skipped when that clock already exists.

if {![info exists clk_name]} {
    set clk_name clk
}
if {![info exists clk_port_name]} {
    set clk_port_name clk
}
if {![info exists clk_period]} {
    if {[info exists ::env(CLOCK_PERIOD)] && $::env(CLOCK_PERIOD) ne ""} {
        set clk_period $::env(CLOCK_PERIOD)
    } else {
        set clk_period 50.0
    }
}

if {[llength [get_clocks -quiet $clk_name]] == 0} {
    set clk_port [get_ports -quiet $clk_port_name]
    if {[llength $clk_port] == 0} {
        puts "WARNING: clock port $clk_port_name not found; skipping create_clock"
    } else {
        create_clock -name $clk_name -period $clk_period $clk_port
    }
}

if {[llength [get_clocks -quiet $clk_name]]} {
    set_clock_uncertainty 0.25 [get_clocks $clk_name]
}

# enPhi1/enPhi2 are synchronous clock enables on clk, not separate clocks.

# Microcode / nanocode address is allowed 2 cycles of setup from Ir
# (1-cycle hold). Translated from src/fx68k.txt.
# After Yosys flatten the flops keep RTL net names on Q (Ir[*],
# microAddr[*], nanoAddr[*]). Chip flatten prefixes the instance path
# (i_chip_core.u_fx68k.Ir[*]). Constrain the sequential cells that
# drive/load those nets, not every combinational pin on the net.
proc fx68k_reg_cells {net_pat pin_name} {
    set nets [get_nets -quiet $net_pat]
    if {[llength $nets] == 0} {
        set nets [get_nets -quiet *.$net_pat]
    }
    if {[llength $nets] == 0} {
        set nets [get_nets -quiet */$net_pat]
    }
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
