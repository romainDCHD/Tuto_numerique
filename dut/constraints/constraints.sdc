# =============================================================================
# Contraintes temporelles - registered_ripple_adder
#
# Objectif :
#
#   FF entree -> N full adders -> FF sortie
#
# Le nombre N pourra etre augmente afin d'observer la degradation du slack
# jusqu'a obtenir une violation de setup.
#
# Horloge unique :
#   clk_i
#
# Reset :
#   rst_ni est synchrone actif bas.
#   Il est donc temporise comme une entree normale.
# =============================================================================


# -----------------------------------------------------------------------------
# Unites
# -----------------------------------------------------------------------------

set_units -time        1000ps
set_units -capacitance 1000fF


# -----------------------------------------------------------------------------
# Parametres temporels
# -----------------------------------------------------------------------------

# 10 ns = 100 MHz
set CLOCK_PERIOD_NS 10.000

# Environnement externe simplifie.
set IO_DELAY_MAX_NS 1.000
set IO_DELAY_MIN_NS 0.000

# Marge temporelle appliquee a l'horloge.
set CLOCK_UNCERTAINTY_SETUP_NS 0.200
set CLOCK_UNCERTAINTY_HOLD_NS  0.050

# Slew suppose des signaux externes.
set INPUT_TRANSITION_NS 0.100

# Charge supposee sur les sorties.
set OUTPUT_LOAD_PF 0.050


# -----------------------------------------------------------------------------
# Horloge
# -----------------------------------------------------------------------------

create_clock \
    -name clk \
    -period $CLOCK_PERIOD_NS \
    [get_ports clk_i]

set_clock_uncertainty \
    -setup $CLOCK_UNCERTAINTY_SETUP_NS \
    [get_clocks clk]

set_clock_uncertainty \
    -hold $CLOCK_UNCERTAINTY_HOLD_NS \
    [get_clocks clk]


# -----------------------------------------------------------------------------
# Entrees
#
# Toutes les entrees sauf clk_i sont supposees provenir de logique synchrone
# commandee par la meme horloge.
#
# rst_ni est synchrone : il reste donc temporise.
# -----------------------------------------------------------------------------

set data_inputs \
    [remove_from_collection \
        [all_inputs] \
        [get_ports clk_i]]

set_input_delay \
    -clock [get_clocks clk] \
    -max $IO_DELAY_MAX_NS \
    $data_inputs

set_input_delay \
    -clock [get_clocks clk] \
    -min $IO_DELAY_MIN_NS \
    $data_inputs

set_input_transition \
    $INPUT_TRANSITION_NS \
    $data_inputs


# -----------------------------------------------------------------------------
# Sorties
# -----------------------------------------------------------------------------

set_output_delay \
    -clock [get_clocks clk] \
    -max $IO_DELAY_MAX_NS \
    [all_outputs]

set_output_delay \
    -clock [get_clocks clk] \
    -min $IO_DELAY_MIN_NS \
    [all_outputs]

set_load \
    $OUTPUT_LOAD_PF \
    [all_outputs]
