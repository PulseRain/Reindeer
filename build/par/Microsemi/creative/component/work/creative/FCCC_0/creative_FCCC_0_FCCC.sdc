set_component creative_FCCC_0_FCCC
# Microsemi Corp.
# Date: 2018-Dec-22 16:32:37
#

create_clock -period 20 [ get_pins { CCC_INST/CLK0_PAD } ]
create_generated_clock -multiply_by 29 -divide_by 10 -source [ get_pins { CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { CCC_INST/GL0 } ]
