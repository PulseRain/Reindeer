read_sdc -scenario "timing_analysis" -netlist "user" -pin_separator "/" -ignore_errors {C:/PulseRain/Reindeer/synth/Microsemi/creative/designer/creative/timing_analysis.sdc}
set_options -analysis_scenario "timing_analysis" 
save
