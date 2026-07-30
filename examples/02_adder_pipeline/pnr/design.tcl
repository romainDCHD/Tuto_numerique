# Politique PnR de l'additionneur pipeline 8 bits.

array set ::DESIGN_CFG {
    top adder_pipeline
    has_clock 1
    clock_port clk_i
    default_view mmmc
    west_pin_patterns {^a_i\[[0-9]+\]$ ^b_i\[[0-9]+\]$ ^cin_i$ ^valid_i$}
    east_pin_patterns {^sum_o\[[0-9]+\]$ ^cout_o$ ^valid_o$}
    south_pin_patterns {^clk_i$ ^rst_ni$}
}
