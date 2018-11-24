# Microsemi Corp.
# Date: 2018-Nov-24 03:41:24
# This file was generated based on the following SDC source files:
#   C:/GitHub/Reindeer/build/par/Microsemi/creative/constraint/Reindeer.sdc
#

create_clock -name {osc_in} -period 20 [ get_ports { osc_in } ]
create_generated_clock -name {FCCC_0/GL0} -multiply_by 16 -divide_by 5 -source [ get_pins { FCCC_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_0/CCC_INST/GL0 } ]
