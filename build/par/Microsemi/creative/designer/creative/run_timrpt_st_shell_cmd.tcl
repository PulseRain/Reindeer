read_sdc -scenario "timing_analysis" -netlist "user" -pin_separator "/" -ignore_errors {C:/GitHub/Reindeer/build/par/Microsemi/creative/designer/creative/timing_analysis.sdc}
set_options -analysis_scenario "timing_analysis" 
save
set max_slow_lv_ht      "not_run"
set min_fast_hv_lt      "not_run"
set max_fast_hv_lt      "not_run"
set min_slow_lv_ht      "not_run"
set max_viol_slow_lv_ht "not_run"
set min_viol_fast_hv_lt "not_run"
set max_viol_fast_hv_lt "not_run"
set min_viol_slow_lv_ht "not_run"
set coverage            "not_run"
set_options -max_opcond worst
set_options -min_opcond best
set max_slow_lv_ht [report \
    -type     timing \
    -analysis max \
    -format   xml \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_max_timing_slow_1.14V_85C.xml} ]
set min_fast_hv_lt [report \
    -type     timing \
    -analysis min \
    -format   xml \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_min_timing_fast_1.26V_0C.xml} ]
set max_viol_slow_lv_ht [report \
    -type     timing_violations \
    -analysis max \
    -format   xml \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_max_timing_violations_slow_1.14V_85C.xml} ]
set min_viol_fast_hv_lt [report \
    -type     timing_violations \
    -analysis min \
    -format   xml \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_min_timing_violations_fast_1.26V_0C.xml} ]
set coverage [report \
    -type     constraints_coverage \
    -format   xml \
    -slacks   no \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_timing_constraints_coverage.xml} ]
report \
    -type     combinational_loops \
    -format   xml \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_timing_combinational_loops.xml}
set_options -max_opcond best
set_options -min_opcond worst
set has_violations {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_has_violations}
set fp [open $has_violations w]
puts $fp "_max_timing_slow_1.14V_85C $max_slow_lv_ht"
puts $fp "_min_timing_fast_1.26V_0C $min_fast_hv_lt"
puts $fp "_max_timing_fast_1.26V_0C $max_fast_hv_lt"
puts $fp "_min_timing_slow_1.14V_85C $min_slow_lv_ht"
puts $fp "_max_timing_violations_slow_1.14V_85C $max_viol_slow_lv_ht"
puts $fp "_min_timing_violations_fast_1.26V_0C $min_viol_fast_hv_lt"
puts $fp "_max_timing_violations_fast_1.26V_0C $max_viol_fast_hv_lt"
puts $fp "_min_timing_violations_slow_1.14V_85C $min_viol_slow_lv_ht"
puts $fp "_timing_constraints_coverage $coverage"
close $fp
