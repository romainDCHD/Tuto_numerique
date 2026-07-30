# Contraintes pédagogiques de l'additionneur pipeline 8 bits / 100 MHz.
# rst_ni est synchrone actif bas : il reste temporisé comme une entrée de
# données. Il n'existe volontairement aucun set_false_path sur ce reset.
set_units -time 1000ps
set_units -capacitance 1000fF

set CLOCK_PERIOD_NS       10.000
set IO_DELAY_NS            1.000
set CLOCK_UNCERTAINTY_NS   0.200
set TRANSITION_NS          0.100
set OUTPUT_LOAD_PF         0.050

create_clock -name clk -period $CLOCK_PERIOD_NS [get_ports clk_i]
set_clock_uncertainty $CLOCK_UNCERTAINTY_NS [get_clocks clk]
set_clock_transition  $TRANSITION_NS        [get_clocks clk]

set timed_inputs [remove_from_collection [all_inputs] [get_ports clk_i]]
set_input_delay  $IO_DELAY_NS -clock clk $timed_inputs
set_output_delay $IO_DELAY_NS -clock clk [all_outputs]
set_input_transition $TRANSITION_NS $timed_inputs
set_load $OUTPUT_LOAD_PF [all_outputs]
