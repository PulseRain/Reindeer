open_project -project {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\creative_fp\creative.pro}
set_programming_file -name {M2S025} -file {C:\PulseRain\Reindeer\synth\Microsemi\creative\designer\creative\creative.ipd}
enable_device -name {M2S025} -enable 1
set_programming_action -action {PROGRAM} -name {M2S025} 
run_selected_actions
set_programming_file -name {M2S025} -no_file
save_project
close_project
