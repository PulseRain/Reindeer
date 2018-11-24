
report \
    -type     timing \
    -analysis max \
    -format   text \
    creative_timing_r5_s3.rpt
report \
    -type     timing_violations \
    -analysis max \
    -format   text \
    -use_slack_threshold no \
    -max_paths 100 \
    creative_timing_violations_max_r5_s3.rpt
report \
    -type     timing_violations \
    -analysis min \
    -format   text \
    -use_slack_threshold no \
    -max_paths 100 \
    creative_timing_violations_min_r5_s3.rpt
set has_violations {creative_has_violations}
set fp [open $has_violations w]
puts $fp [has_violations -short]
close $fp
