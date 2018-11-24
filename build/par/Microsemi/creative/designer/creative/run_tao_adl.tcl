set_family {SmartFusion2}
read_adl {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\creative.adl}
map_netlist
read_sdc {C:\PulseRain\Reindeer\synth\constraints\Microsemi\Creative\Reindeer.sdc}
check_constraints {C:\PulseRain\Reindeer\synth\Microsemi\creative\constraint\placer_sdc_errors.log}
write_sdc -strict {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\place_route.sdc}
