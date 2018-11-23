create_clock -period 8.33 -waveform {0 4.165}  -name [get_ports osc_in]


derive_pll_clocks -create_base_clocks -use_net_name

derive_clock_uncertainty
