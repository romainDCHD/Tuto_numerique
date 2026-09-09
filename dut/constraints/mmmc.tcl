################################
# MMMC file
################################

################################
# SDC constraints
################################
create_constraint_mode \
    -name NORMAL_MODE \
    -sdc_files [list $PNR_SDC]


################################
# Create library set for each view
################################
# Typical : TC
create_library_set \
    -name LIB_TC \
    -timing [list $INNOVUS_LIBERTY_TC]
# TODO : option si ?

# BC
create_library_set \
    -name LIB_BC \
    -timing [list $INNOVUS_LIBERTY_BC]

# WC
create_library_set \
    -name LIB_WC \
    -timing [list $INNOVUS_LIBERTY_WC]


################################
# Create corner
################################
create_rc_corner \
    -name RC_TC \
    -temperature $INNOVUS_TEMPERATURE_TC \
    -qrc_tech $INNOVUS_QRC_TC

create_rc_corner \
    -name RC_BC \
    -temperature $INNOVUS_TEMPERATURE_BC \
    -qrc_tech $INNOVUS_QRC_BC

create_rc_corner \
    -name RC_WC \
    -temperature $INNOVUS_TEMPERATURE_WC \
    -qrc_tech $INNOVUS_QRC_WC


################################
# Create timing condition
################################
# create_opcond -name oc_typ    -process 1 -voltage 3.3  -temperature  25
# create_opcond -name oc_min    -process 1 -voltage 3.6 -temperature 0
# create_opcond -name oc_max    -process 1 -voltage 3 -temperature 150
# A mettre ensuite en param de create_timing_condition

create_timing_condition \
    -name TIMING_TC \
    -library_sets [list LIB_TC]
# TODO : option si ?

create_timing_condition \
    -name TIMING_WC \
    -library_sets [list LIB_WC]

create_timing_condition \
    -name TIMING_BC \
    -library_sets [list LIB_BC]


################################
# Delay corner
################################
create_delay_corner \
    -name DELAY_TC \
    -timing_condition TIMING_TC \
    -rc_corner RC_TC

create_delay_corner \
    -name DELAY_BC \
    -timing_condition TIMING_BC \
    -rc_corner RC_BC

create_delay_corner \
    -name DELAY_WC \
    -timing_condition TIMING_WC \
    -rc_corner RC_WC


################################
# Analysis view
################################
create_analysis_view \
    -name VIEW_TC \
    -constraint_mode NORMAL_MODE \
    -delay_corner DELAY_TC

create_analysis_view \
    -name VIEW_BC \
    -constraint_mode NORMAL_MODE \
    -delay_corner DELAY_BC

create_analysis_view \
    -name VIEW_WC \
    -constraint_mode NORMAL_MODE \
    -delay_corner DELAY_WC


################################
# Activation
################################
set_analysis_view \
    -setup { VIEW_WC VIEW_TC VIEW_BC } \
    -hold  { VIEW_BC VIEW_WC VIEW_TC}
