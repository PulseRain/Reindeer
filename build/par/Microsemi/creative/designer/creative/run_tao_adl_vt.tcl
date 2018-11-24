set_family {SmartFusion2}
read_adl {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.adl}
map_netlist
read_sdc {C:\GitHub\Reindeer\build\par\Microsemi\creative\constraint\Reindeer.sdc}
check_constraints {C:\GitHub\Reindeer\build\par\Microsemi\creative\constraint\timing_sdc_errors.log}
write_sdc -strict {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\timing_analysis.sdc}
