set_family {SmartFusion2}
read_verilog -mode verilog_2k {C:\GitHub\Reindeer\build\par\Microsemi\creative\..\..\..\synth\Microsemi\SmartFusion2\Reindeer.vm}
read_verilog -mode verilog_2k {C:\GitHub\Reindeer\build\par\Microsemi\creative\component\work\creative\FCCC_0\creative_FCCC_0_FCCC.v}
read_verilog -mode verilog_2k {C:\GitHub\Reindeer\build\par\Microsemi\creative\component\work\creative\creative.v}
set_top_level {creative}
map_netlist
read_sdc {C:\GitHub\Reindeer\build\par\Microsemi\creative\constraint\Reindeer.sdc}
check_constraints {C:\GitHub\Reindeer\build\par\Microsemi\creative\constraint\synthesis_sdc_errors.log}
write_fdc {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\synthesis.fdc}
