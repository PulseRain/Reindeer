create_clock -name {osc_in} -period 20 [ get_ports { osc_in } ]
create_generated_clock -name {FCCC_0/GL0} -multiply_by 145 -divide_by 50 -source [ get_pins { FCCC_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_0/CCC_INST/GL0 } ]
