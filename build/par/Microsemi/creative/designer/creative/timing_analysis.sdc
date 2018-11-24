# Microsemi Corp.
# Date: 2018-Nov-23 23:33:22
# This file was generated based on the following SDC source files:
#   C:/PulseRain/Reindeer/synth/constraints/Microsemi/Creative/Reindeer.sdc
#

create_clock -name {osc_in} -period 20 [ get_ports { osc_in } ]
create_generated_clock -name {FCCC_0/GL0} -multiply_by 16 -divide_by 5 -source [ get_pins { FCCC_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_0/CCC_INST/GL0 } ]
