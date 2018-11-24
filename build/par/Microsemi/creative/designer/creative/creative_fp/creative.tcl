open_project -project {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_fp\creative.pro}\
         -connect_programmers {FALSE}
if { [catch {load_programming_data \
    -name {M2S025} \
    -fpga {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.map} \
    -header {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.hdr} \
    -spm {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.spm} \
    -dca {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative.dca} } return_val] } {
save_project
close_project
exit }
export_single_stapl \
    -name {M2S025} \
    -file {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\export\creative.stp} \
    -secured
export_single_dat \
    -name {M2S025} \
    -file {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\export\creative.dat} \
    -secured
set_programming_file -name {M2S025} -no_file
save_project
close_project
