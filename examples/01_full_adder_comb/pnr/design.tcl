# Politique PnR du full adder combinatoire.
# L'horloge de contraintes est virtuelle : aucune cellule CTS ne doit apparaitre.

array set ::DESIGN_CFG {
    top full_adder_comb
    has_clock 0
    clock_port {}
    default_view tc
    west_pin_patterns {^a_i$ ^b_i$ ^cin_i$}
    east_pin_patterns {^sum_o$ ^cout_o$}
    south_pin_patterns {}
}
