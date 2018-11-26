# Written by Synplify Pro version mapact, Build 2172R. Synopsys Run ID: sid1543216503 
# Top Level Design Parameters 

# Clocks 
create_clock -period 20.000 -waveform {0.000 10.000} -name {osc_in} [get_ports {osc_in}] 

# Virtual Clocks 

# Generated Clocks 
create_generated_clock -name {FCCC_0/GL0} -multiply_by {16} -divide_by {5} -source [get_pins {FCCC_0/CLK0_PAD_INST:Y}]  [get_pins {FCCC_0/CCC_INST:GL0}] 

# Paths Between Clocks 

# Multicycle Constraints 

# Point-to-point Delay Constraints 

# False Path Constraints 

# Output Load Constraints 

# Driving Cell Constraints 

# Input Delay Constraints 

# Output Delay Constraints 

# Wire Loads 

# Other Constraints 

# syn_hier Attributes 

# set_case Attributes 

# Clock Delay Constraints 

# syn_mode Attributes 

# Cells 

# Port DRC Rules 

# Input Transition Constraints 

# Unused constraints (intentionally commented out) 

# Non-forward-annotatable constraints (intentionally commented out) 

# Block Path constraints 

