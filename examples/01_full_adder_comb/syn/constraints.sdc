# Contraintes pédagogiques du full adder combinatoire.
# Unités explicites : 1000 ps = 1 ns et 1000 fF = 1 pF.
set_units -time 1000ps
set_units -capacitance 1000fF

set CLOCK_PERIOD_NS       10.000
set IO_DELAY_NS            1.000
set CLOCK_UNCERTAINTY_NS   0.200
set TRANSITION_NS          0.100
set OUTPUT_LOAD_PF         0.050

# Sans port d'horloge, une horloge virtuelle représente l'environnement.
create_clock -name vclk -period $CLOCK_PERIOD_NS
set_clock_uncertainty $CLOCK_UNCERTAINTY_NS [get_clocks vclk]
set_clock_transition  $TRANSITION_NS        [get_clocks vclk]

set_input_delay  $IO_DELAY_NS -clock vclk [all_inputs]
set_output_delay $IO_DELAY_NS -clock vclk [all_outputs]
set_input_transition $TRANSITION_NS [all_inputs]
set_load $OUTPUT_LOAD_PF [all_outputs]
