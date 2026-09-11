# 68000 asynchronous-bus I/O timing vs clk.
# Numbers are the 10 MHz column of NXP MC68000UM Rev. 9 §10.10
# (read/write cycle AC specs). fx68k clk is the 2x core clock;
# tco/setup are still applied to that clk so STA checks the same
# nanosecond budgets the 10 MHz part guarantees at each PHI edge.
#
# Spec 6/6A/9/12/18/20/23/33/34/40/41: clock-to-output max
# Spec 27/47: input setup min (data-in and asynchronous inputs)
# Spec 8/29/53: hold min 0 ns
#
# set_output_delay -max (clk_period - tco_max) encodes tco <= tco_max.
# set_input_delay  -max (clk_period - tsu) encodes tsu >= tsu_min at the pin.

if {![info exists clk_period]} {
    set clk_period 50.0
}
if {![info exists clk_name]} {
    set clk_name clk
}

proc fx68k_out_max {tco_max} {
    global clk_period
    set d [expr {$clk_period - $tco_max}]
    if {$d < 0.0} {
        puts "WARNING: tco_max $tco_max ns > clk_period $clk_period ns; clamping output_delay max to 0"
        set d 0.0
    }
    return $d
}

proc fx68k_in_max {tsu} {
    global clk_period
    set d [expr {$clk_period - $tsu}]
    if {$d < 0.0} {
        puts "WARNING: tsu $tsu ns > clk_period $clk_period ns; clamping input_delay max to 0"
        set d 0.0
    }
    return $d
}

# Spec 6: clock low to address valid, max 50 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 50.0] [get_ports {eab[*]}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {eab[*]}]

# Spec 6A: clock high to FC valid, max 50 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 50.0] [get_ports {FC0 FC1 FC2}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {FC0 FC1 FC2}]

# Spec 9/12: clock to AS/DS assert/negate, max 50 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 50.0] [get_ports {ASn LDSn UDSn}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {ASn LDSn UDSn}]

# Spec 18/20: clock high to R/W high/low, max 45 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 45.0] [get_ports {eRWn}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {eRWn}]

# Spec 23: clock low to data-out valid, max 50 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 50.0] [get_ports {oEdb[*]}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {oEdb[*]}]

# Spec 33/34: clock high to BG assert/negate, max 50 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 50.0] [get_ports {BGn}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {BGn}]

# Spec 40: clock low to VMA asserted, max 70 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 70.0] [get_ports {VMAn}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {VMAn}]

# Spec 41: clock low to E transition, max 45 ns
set_output_delay -clock $clk_name -max [fx68k_out_max 45.0] [get_ports {E}]
set_output_delay -clock $clk_name -min 0.0 [get_ports {E}]

# oRESETn / oHALTEDn have no matching UM number; left unconstrained.

# Spec 27: data-in setup to clock low, min 10 ns
set_input_delay -clock $clk_name -max [fx68k_in_max 10.0] [get_ports {iEdb[*]}]
set_input_delay -clock $clk_name -min 0.0 [get_ports {iEdb[*]}]

# Spec 47: asynchronous input setup, min 10 ns (DTACK, BERR, VPA, BR, BGACK, IPL, HALT)
set_input_delay -clock $clk_name -max [fx68k_in_max 10.0] \
    [get_ports {DTACKn VPAn BERRn BRn BGACKn IPL0n IPL1n IPL2n HALTn}]
set_input_delay -clock $clk_name -min 0.0 \
    [get_ports {DTACKn VPAn BERRn BRn BGACKn IPL0n IPL1n IPL2n HALTn}]

# enPhi1/enPhi2 are core clock enables, not 68000 bus pins. extReset/pwrUp
# are synchronous core controls. Do not apply bus AC numbers to them.
