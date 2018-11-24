read_sdc -scenario "place_and_route" -netlist "user" -pin_separator "/" -ignore_errors {C:/PulseRain/Reindeer/synth/Microsemi/creative/designer/creative/place_route.sdc}
set_options -tdpr_scenario "place_and_route" 
save
set_options -analysis_scenario "place_and_route"
report -type combinational_loops -format xml {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\creative_layout_combinational_loops.xml}
report -type slack {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\pinslacks.txt}
