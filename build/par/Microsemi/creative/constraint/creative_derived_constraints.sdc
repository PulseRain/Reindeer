# Microsemi Corp.
# Date: 2018-Nov-17 03:40:27
# This file was generated based on the following SDC source files:
#   C:/PulseRain/Reindeer/synth/Microsemi/creative/component/work/creative/FCCC_0/creative_FCCC_0_FCCC.sdc
#

create_clock -name {osc_in} -period 10 [ get_ports { osc_in } ]
create_generated_clock -name {FCCC_0/GL0} -multiply_by 4 -divide_by 4 -source [ get_pins { FCCC_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_0/CCC_INST/GL0 } ]
