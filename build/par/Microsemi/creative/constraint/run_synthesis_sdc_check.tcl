set_family {SmartFusion2}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\creative\component\work\creative\creative.v}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\creative\component\work\creative\FCCC_0\creative_FCCC_0_FCCC.v}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\SmartFusion2\Reindeer.vm}
set_top_level {creative}
map_netlist
read_sdc {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\creative_derived_constraints.sdc}
check_constraints {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\synthesis_sdc_check.log}
