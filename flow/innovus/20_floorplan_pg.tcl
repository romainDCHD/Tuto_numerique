# Etape 2 : floorplan, placement deterministe des ports et anneau PG.

proc ::digi_pnr::core_box {} {
    set box [dbGet top.fPlan.coreBox]
    if {[llength $box] == 1 && [llength [lindex $box 0]] == 4} {
        set box [lindex $box 0]
    }
    if {[llength $box] != 4} {
        error "PNR_CORE_BOX_INDISPONIBLE: raw=$box"
    }
    return $box
}

proc ::digi_pnr::box_width {box} {
    return [expr {double([lindex $box 2]) - double([lindex $box 0])}]
}

proc ::digi_pnr::box_height {box} {
    return [expr {double([lindex $box 3]) - double([lindex $box 1])}]
}

proc ::digi_pnr::apply_floorplan {} {
    set site [require_env STDCELL_SITE]
    set util [env_or CORE_UTILIZATION 0.60]
    set aspect [env_or CORE_ASPECT_RATIO 1.0]
    set margin [env_or CORE_MARGIN_UM 20.0]
    set min_core [env_or MIN_CORE_SIDE_UM 60.0]

    floorPlan -site $site -r $aspect $util $margin $margin $margin $margin
    set box [core_box]
    set width [box_width $box]
    set height [box_height $box]

    # Les tres petits exemples produisent sinon un coeur illisible. Le minimum
    # pedagogique prime sur la densite cible, sans jamais agrandir arbitrairement
    # un design deja superieur a 60 um.
    if {$width < $min_core || $height < $min_core} {
        set die_width [expr {max($width, $min_core) + 2.0 * $margin}]
        set die_height [expr {max($height, $min_core) + 2.0 * $margin}]
        floorPlan -site $site -s $die_width $die_height $margin $margin $margin $margin
        set box [core_box]
        set width [box_width $box]
        set height [box_height $box]
    }

    set report [report_path floorplan.rpt]
    set fh [open $report w]
    puts $fh "FLOORPLAN_TARGET_UTILIZATION=$util"
    puts $fh "FLOORPLAN_TARGET_ASPECT_RATIO=$aspect"
    puts $fh "CORE_MARGIN_UM=$margin"
    puts $fh "MIN_CORE_SIDE_UM=$min_core"
    puts $fh "CORE_BOX=$box"
    puts $fh "CORE_WIDTH_UM=[format %.3f $width]"
    puts $fh "CORE_HEIGHT_UM=[format %.3f $height]"
    puts $fh "ROW_INFRA_STATUS=PROVISIONAL"
    puts $fh "ROW_INFRA_REASON=no_confirmed_tap_or_endcap_cells_in_public_configuration"
    close $fh

    if {$width + 1.0e-6 < $min_core || $height + 1.0e-6 < $min_core} {
        error "PNR_CORE_TROP_PETIT: width=$width height=$height required=$min_core report=$report"
    }
    set_status FLOORPLAN_STATUS PASS $report
}

proc ::digi_pnr::pins_matching {patterns} {
    set result [list]
    foreach pin [dbGet top.terms.name] {
        foreach pattern $patterns {
            if {[regexp $pattern $pin]} {
                lappend result $pin
                break
            }
        }
    }
    return [lsort -dictionary -unique $result]
}

proc ::digi_pnr::place_pin_group {pins side layer} {
    if {[llength $pins] == 0} { return }
    set spacing [env_or IO_PIN_SPACING_UM 1.0]
    set width [env_or IO_PIN_WIDTH_UM 0.40]
    set depth [env_or IO_PIN_DEPTH_UM 0.80]
    set command [list editPin -pin $pins -side $side -layer $layer \
        -spreadType SIDE -spacing $spacing -pinWidth $width -pinDepth $depth -fixedPin 1]
    uplevel #0 $command
}

proc ::digi_pnr::place_io_pins {} {
    global DESIGN_CFG
    set west [pins_matching $DESIGN_CFG(west_pin_patterns)]
    set east [pins_matching $DESIGN_CFG(east_pin_patterns)]
    set south [pins_matching $DESIGN_CFG(south_pin_patterns)]
    set all_signal [lsort -dictionary [concat $west $east $south]]
    set all_ports [list]
    foreach pin [dbGet top.terms.name] {
        if {$pin ni [list [env_or POWER_NET VDD] [env_or GROUND_NET VSS]]} {
            lappend all_ports $pin
        }
    }
    set all_ports [lsort -dictionary -unique $all_ports]

    if {[llength $all_signal] != [llength [lsort -unique $all_signal]] || $all_signal ne $all_ports} {
        error "PNR_PIN_POLICY_INCOMPLETE: assigned=$all_signal expected=$all_ports"
    }

    # Une broche sur un bord vertical doit sortir sur une couche horizontale;
    # une broche au sud utilise une couche verticale de la pile xx31.
    place_pin_group $west LEFT MET3
    place_pin_group $east RIGHT MET3
    place_pin_group $south BOTTOM MET2

    set report [report_path io_pin_policy.rpt]
    set fh [open $report w]
    puts $fh "WEST_PINS=$west"
    puts $fh "EAST_PINS=$east"
    puts $fh "SOUTH_PINS=$south"
    puts $fh "WEST_EAST_LAYER=MET3"
    puts $fh "SOUTH_LAYER=MET2"
    puts $fh "PIN_PLACEMENT=FIXED_AND_DETERMINISTIC"
    close $fh
    capture [report_path check_pin_assignment.rpt] {checkPinAssignment}
    set_status IO_PIN_STATUS PASS $report
}

proc ::digi_pnr::build_pg_ring {} {
    set nets [list [env_or POWER_NET VDD] [env_or GROUND_NET VSS]]
    set width [env_or PG_RING_WIDTH_UM 2.0]
    set spacing [env_or PG_RING_SPACING_UM 1.0]
    set offset [env_or PG_RING_OFFSET_UM 2.0]
    addRing -nets $nets -type core_rings -follow core \
        -layer {top MET3 bottom MET3 left METTP right METTP} \
        -width [list top $width bottom $width left $width right $width] \
        -spacing [list top $spacing bottom $spacing left $spacing right $spacing] \
        -offset [list top $offset bottom $offset left $offset right $offset]

    set report [report_path pg_ring_policy.rpt]
    set fh [open $report w]
    puts $fh "PG_NETS=$nets"
    puts $fh "PG_RING_HORIZONTAL_LAYER=MET3"
    puts $fh "PG_RING_VERTICAL_LAYER=METTP"
    puts $fh "PG_RING_WIDTH_UM=$width"
    puts $fh "PG_RING_SPACING_UM=$spacing"
    puts $fh "PG_RING_OFFSET_UM=$offset"
    puts $fh "PG_RAIL_CONNECTION=DEFERRED_UNTIL_STANDARD_CELLS_ARE_PLACED"
    close $fh
    set_status PG_GRID_STATUS PROVISIONAL $report
}

proc ::digi_pnr::run_floorplan_and_pg {} {
    apply_floorplan
    place_io_pins
    build_pg_ring
    defOut -floorplan [output_path "[require_env DESIGN].floorplan.def"]
    save_checkpoint 01_floorplan_pg
}
