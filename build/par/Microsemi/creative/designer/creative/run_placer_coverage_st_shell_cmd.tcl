read_sdc -scenario "place_and_route" -netlist "user" -pin_separator "/" -ignore_errors {C:/GitHub/Reindeer/build/par/Microsemi/creative/designer/creative/place_route.sdc}
set_options -tdpr_scenario "place_and_route" 
save
set_options -analysis_scenario "place_and_route"
set coverage [report \
    -type     constraints_coverage \
    -format   xml \
    -slacks   no \
    {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\creative_place_and_route_constraint_coverage.xml}]
set reportfile {C:\GitHub\Reindeer\build\par\Microsemi\creative\designer\creative\coverage_placeandroute}
set fp [open $reportfile w]
puts $fp $coverage
close $fp
