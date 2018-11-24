set_family {SmartFusion2}
read_adl {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.adl}
map_netlist
check_constraints {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\placer_coverage.log}
write_sdc -strict {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\place_route.sdc}
