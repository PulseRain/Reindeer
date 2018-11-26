set_component creative_FCCC_0_FCCC
# Microsemi Corp.
# Date: 2018-Nov-25 22:28:00
#

create_clock -period 20 [ get_pins { CCC_INST/CLK0_PAD } ]
create_generated_clock -multiply_by 16 -divide_by 5 -source [ get_pins { CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { CCC_INST/GL0 } ]
