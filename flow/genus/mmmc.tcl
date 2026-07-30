# Définition MMMC portable du tutoriel.
#
# Toutes les bibliothèques et tous les decks QRC viennent du fichier privé
# désigné par LAB_CONFIG. Les listes Liberty utilisent « : » comme séparateur.

set tutorial_mode [tutorial_require_env GENUS_MODE]
set tutorial_sdc  [tutorial_require_env GENUS_SDC]

create_constraint_mode \
    -name tutorial_functional_mode \
    -sdc_files [list $tutorial_sdc]

if {$tutorial_mode eq "tc"} {
    set tutorial_tc_libs [tutorial_env_list GENUS_LIBERTY_TC]
    set tutorial_tc_qrc  [tutorial_require_env GENUS_QRC_TC]
    set tutorial_tc_temp [tutorial_require_env GENUS_TEMPERATURE_TC]

    create_rc_corner \
        -name tutorial_tc_rc \
        -temperature $tutorial_tc_temp \
        -qrc_tech $tutorial_tc_qrc

    create_library_set \
        -name tutorial_tc_libset \
        -timing $tutorial_tc_libs

    create_timing_condition \
        -name tutorial_tc_condition \
        -library_sets tutorial_tc_libset

    create_delay_corner \
        -name tutorial_tc_corner \
        -timing_condition tutorial_tc_condition \
        -rc_corner tutorial_tc_rc

    create_analysis_view \
        -name tutorial_tc_view \
        -constraint_mode tutorial_functional_mode \
        -delay_corner tutorial_tc_corner

    set_analysis_view \
        -setup tutorial_tc_view \
        -hold  tutorial_tc_view
} elseif {$tutorial_mode eq "mmmc"} {
    set tutorial_bc_libs [tutorial_env_list GENUS_LIBERTY_BC]
    set tutorial_tc_libs [tutorial_env_list GENUS_LIBERTY_TC]
    set tutorial_wc_libs [tutorial_env_list GENUS_LIBERTY_WC]

    foreach corner {bc tc wc} {
        set upper [string toupper $corner]
        set qrc  [tutorial_require_env GENUS_QRC_${upper}]
        set temp [tutorial_require_env GENUS_TEMPERATURE_${upper}]
        create_rc_corner \
            -name tutorial_${corner}_rc \
            -temperature $temp \
            -qrc_tech $qrc
    }

    create_library_set -name tutorial_bc_libset -timing $tutorial_bc_libs
    create_library_set -name tutorial_tc_libset -timing $tutorial_tc_libs
    create_library_set -name tutorial_wc_libset -timing $tutorial_wc_libs

    create_timing_condition \
        -name tutorial_bc_condition \
        -library_sets tutorial_bc_libset
    create_timing_condition \
        -name tutorial_tc_condition \
        -library_sets tutorial_tc_libset
    create_timing_condition \
        -name tutorial_wc_condition \
        -library_sets tutorial_wc_libset

    foreach corner {bc tc wc} {
        create_delay_corner \
            -name tutorial_${corner}_corner \
            -timing_condition tutorial_${corner}_condition \
            -rc_corner tutorial_${corner}_rc

        create_analysis_view \
            -name tutorial_${corner}_view \
            -constraint_mode tutorial_functional_mode \
            -delay_corner tutorial_${corner}_corner
    }

    # WC pilote l'optimisation setup, BC l'optimisation hold. La vue TC reste
    # disponible pour corrélation et possède son propre rapport temporel.
    set_analysis_view \
        -setup tutorial_wc_view \
        -hold  tutorial_bc_view
} else {
    error "GENUS_MODE invalide: $tutorial_mode (attendu: tc ou mmmc)"
}
