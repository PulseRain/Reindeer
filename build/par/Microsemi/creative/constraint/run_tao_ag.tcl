set_device -family {SmartFusion2} -die {M2S025}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\creative\component\work\creative\FCCC_0\creative_FCCC_0_FCCC.v}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\SmartFusion2\Reindeer.vm}
read_verilog -mode verilog_2k {C:\PulseRain\Reindeer\synth\Microsemi\creative\component\work\creative\creative.v}
set_top_level {creative}
read_sdc -component {C:\PulseRain\Reindeer\synth\Microsemi\creative\component\work\creative\FCCC_0\creative_FCCC_0_FCCC.sdc}
derive_constraints
write_sdc {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\creative_derived_constraints.sdc}
write_pdc {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\fp\creative_derived_constraints.pdc}
