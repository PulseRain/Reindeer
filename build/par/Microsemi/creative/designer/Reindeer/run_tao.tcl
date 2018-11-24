set_family {SmartFusion2}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\SmartFusion2\Reindeer.vm}
set_top_level {Reindeer}
map_netlist
read_sdc {C:\PulseRain\Reindeer\synth\constraints\Microsemi\Creative\Reindeer.sdc}
check_constraints {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\synthesis_sdc_errors.log}
write_fdc {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\Reindeer\synthesis.fdc}
