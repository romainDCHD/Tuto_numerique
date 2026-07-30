# Utilitaires communs du flow Innovus pedagogique.
#
# Ce fichier ne contient aucun chemin du laboratoire. Toutes les donnees PDK
# arrivent par l'overlay local charge par scripts/run_pnr.sh.

namespace eval ::digi_pnr {
    variable status
    array set status {}

    proc require_env {name} {
        if {![info exists ::env($name)] || [string trim $::env($name)] eq ""} {
            error "PNR_ENV_MANQUANTE: $name"
        }
        return $::env($name)
    }

    proc env_or {name default_value} {
        if {[info exists ::env($name)] && [string trim $::env($name)] ne ""} {
            return $::env($name)
        }
        return $default_value
    }

    proc env_list {name {separator :}} {
        set value [require_env $name]
        set result [list]
        foreach item [split $value $separator] {
            if {[string trim $item] ne ""} {
                lappend result [file normalize $item]
            }
        }
        return $result
    }

    proc require_file {label path} {
        if {![file exists $path] || ![file isfile $path] || [file size $path] == 0} {
            error "PNR_FICHIER_INVALIDE: label=$label path=$path"
        }
        return [file normalize $path]
    }

    proc report_path {tail} {
        return [file join [require_env PNR_RUN_DIR] reports $tail]
    }

    proc output_path {tail} {
        return [file join [require_env PNR_RUN_DIR] outputs $tail]
    }

    proc checkpoint_path {tail} {
        return [file join [require_env PNR_RUN_DIR] checkpoints $tail]
    }

    proc generated_path {tail} {
        return [file join [require_env PNR_RUN_DIR] generated $tail]
    }

    proc initialize_status {} {
        variable status
        array unset status
        array set status {
            PREFLIGHT_STATUS PASS
            IMPORT_STATUS NOT_RUN
            SDC_COVERAGE_STATUS NOT_RUN
            FLOORPLAN_STATUS NOT_RUN
            IO_PIN_STATUS NOT_RUN
            PG_GRID_STATUS NOT_RUN
            PLACEMENT_STATUS NOT_RUN
            CTS_STATUS NOT_RUN
            ROUTE_STATUS NOT_RUN
            DRC_STATUS NOT_RUN
            REGULAR_CONNECTIVITY_STATUS NOT_RUN
            SPECIAL_CONNECTIVITY_STATUS NOT_RUN
            ANTENNA_STATUS NOT_RUN
            EXTRACTION_STATUS NOT_RUN
            SETUP_STATUS NOT_RUN
            HOLD_STATUS NOT_RUN
            EXPORT_STATUS NOT_RUN
            DELIVERABLE_STATUS NOT_RUN
            DRV_STATUS REVIEW_REQUIRED
            ROW_INFRA_STATUS PROVISIONAL
            SIGNOFF_STATUS NOT_ACHIEVED
            GDS_STATUS IMPLEMENTATION_CANDIDATE
            PVS_DRC_STATUS NOT_RUN
            PVS_LVS_STATUS NOT_RUN
            IR_EM_STATUS NOT_RUN
        }
        set status(DESIGN) [require_env DESIGN]
        set status(VIEW) [require_env VIEW]
        set status(TOOL) INNOVUS_22_33
        set status(SIGNAL_ROUTE_LAYERS) MET1-MET3
        set status(PG_RING_LAYERS) MET3-METTP
        set status(POWER_NET) [env_or POWER_NET VDD]
        set status(GROUND_NET) [env_or GROUND_NET VSS]
        set status(STDCELL_POWER_PIN) [env_or STDCELL_POWER_PIN vddi]
        set status(STDCELL_GROUND_PIN) [env_or STDCELL_GROUND_PIN gndi]
        set status(ROW_INFRA_REASON) tap_endcap_cells_not_confirmed_in_public_overlay
        set status(SIGNOFF_REASON) educational_implementation_candidate_without_pvs_ir_em
    }

    proc set_status {key value {evidence ""}} {
        variable status
        set status($key) $value
        if {$evidence ne ""} {
            set status(${key}_EVIDENCE) $evidence
        }
    }

    proc write_status {} {
        variable status
        set path [report_path final_status.rpt]
        set fh [open $path w]
        puts $fh "# Statuts independants du flow Innovus pedagogique"
        foreach key [lsort [array names status]] {
            puts $fh "$key=$status($key)"
        }
        close $fh
        return $path
    }

    proc append_manifest {key value} {
        set path [file join [require_env PNR_RUN_DIR] manifest.env]
        set fh [open $path a]
        regsub -all {[\r\n]} $value { } clean_value
        puts $fh "$key=$clean_value"
        close $fh
    }

    proc trace_stage {name state} {
        set path [report_path stage_trace.tsv]
        set fh [open $path a]
        puts $fh "$name\t$state"
        close $fh
    }

    proc stage {name status_key body} {
        trace_stage $name START
        if {[catch {uplevel 1 $body} err opts]} {
            set fail_report [report_path "${name}_failed.rpt"]
            set fh [open $fail_report w]
            puts $fh "STAGE=$name"
            puts $fh "STATUS=FAIL"
            puts $fh "ERROR=$err"
            if {[dict exists $opts -errorinfo]} {
                puts $fh "ERROR_INFO_BEGIN"
                puts $fh [dict get $opts -errorinfo]
                puts $fh "ERROR_INFO_END"
            }
            close $fh
            set_status $status_key FAIL $fail_report
            trace_stage $name FAIL
            write_status
            catch {saveDesign [checkpoint_path "${name}_failed.enc"]}
            error "PNR_ETAPE_ECHOUEE: stage=$name report=$fail_report error=$err"
        }
        variable status
        if {![info exists status($status_key)] || $status($status_key) eq "NOT_RUN"} {
            set_status $status_key PASS
        }
        trace_stage $name PASS
        write_status
    }

    proc capture {path body} {
        if {[catch {redirect -file $path $body} err opts]} {
            set fh [open $path w]
            puts $fh "CAPTURE_STATUS=FAIL"
            puts $fh "ERROR=$err"
            if {[dict exists $opts -errorinfo]} {
                puts $fh [dict get $opts -errorinfo]
            }
            close $fh
            error "PNR_COMMANDE_ECHOUEE: report=$path error=$err"
        }
        return $path
    }

    proc read_text {path} {
        require_file report $path
        set fh [open $path r]
        set text [read $fh]
        close $fh
        return $text
    }

    # Innovus 22.33 termine les rapports verify_* par
    # "Verification Complete : N Viol...". UNKNOWN est un echec volontaire :
    # un transcript de routeur ou une commande sans erreur n'est pas une preuve.
    proc verification_count {path} {
        set text [read_text $path]
        foreach pattern {
            {Verification Complete[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]+Viol}
            {Total[[:space:]]+(Number[[:space:]]+of[[:space:]]+)?Violations?[[:space:]]*[:=][[:space:]]*([0-9]+)}
        } {
            if {[regexp -nocase $pattern $text -> first second]} {
                if {$second ne ""} { return $second }
                return $first
            }
        }
        if {[regexp -nocase {No[[:space:]]+(DRC[[:space:]]+)?violations?[[:space:]]+(were[[:space:]]+)?found} $text]} {
            return 0
        }
        return UNKNOWN
    }

    proc require_zero_verification {label path status_key} {
        set count [verification_count $path]
        set_status ${status_key}_COUNT $count $path
        if {$count eq "UNKNOWN" || $count != 0} {
            set_status $status_key FAIL $path
            error "PNR_GATE_NON_PROPRE: label=$label count=$count report=$path"
        }
        set_status $status_key PASS $path
    }

    proc require_no_negative_slack {label path status_key} {
        set text [read_text $path]
        set evidence [list]
        set metric_count 0
        set saw_wns 0
        set saw_tns 0
        foreach line [split $text "\n"] {
            set violated [regexp -nocase {VIOLATED} $line]
            set has_metric [regexp -nocase \
                {(slack|WNS|TNS)[^-+0-9]*([-+]?[0-9]+([.][0-9]+)?)} \
                $line -> metric value]
            if {$has_metric} {
                incr metric_count
                if {[string equal -nocase $metric WNS]} { set saw_wns 1 }
                if {[string equal -nocase $metric TNS]} { set saw_tns 1 }
            }
            set negative [expr {$has_metric && double($value) < -1.0e-6}]
            set nonzero_tns [expr {$has_metric && [string equal -nocase $metric TNS] && abs(double($value)) > 1.0e-6}]
            if {$violated || $negative || $nonzero_tns} {
                lappend evidence [string trim $line]
                if {[llength $evidence] == 5} { break }
            }
        }
        if {[llength $evidence] > 0} {
            set_status $status_key FAIL $path
            error "PNR_TIMING_NEGATIF: label=$label report=$path evidence=$evidence"
        }
        if {$metric_count == 0 || !$saw_wns || !$saw_tns} {
            set_status $status_key FAIL $path
            error "PNR_TIMING_NON_ANALYSABLE: label=$label metrics=$metric_count saw_wns=$saw_wns saw_tns=$saw_tns report=$path"
        }
        set_status $status_key PASS $path
    }

    proc require_clean_checkplace {path} {
        set text [read_text $path]
        set complete [regexp -nocase \
            {Finished[[:space:]]+checkPlace|checkPlace[[:space:]].*complete|Finished[[:space:]]+Check[[:space:]]+Place} \
            $text]
        set unplaced UNKNOWN
        set placed UNKNOWN
        set overlap 0
        set region_fence 0
        set not_of_fence 0
        foreach line [split $text "\n"] {
            set trimmed [string trim $line]
            regexp -nocase {^\*?info:[[:space:]]*Unplaced[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> unplaced
            regexp -nocase {^\*?info:[[:space:]]*Placed[[:space:]]*=[[:space:]]*([0-9]+)} $trimmed -> placed
            regexp -nocase {Overlapping[[:space:]]+with[[:space:]]+other[[:space:]]+instance[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> overlap
            regexp -nocase {Region/Fence[[:space:]]+Violation[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> region_fence
            regexp -nocase {Not-of-Fence[[:space:]]+Violation[[:space:]]*:[[:space:]]*([0-9]+)} $trimmed -> not_of_fence
        }
        if {!$complete || $unplaced eq "UNKNOWN" || $placed eq "UNKNOWN" ||
            $unplaced != 0 || $overlap != 0 || $region_fence != 0 || $not_of_fence != 0} {
            error "PNR_PLACEMENT_NON_PROPRE: complete=$complete placed=$placed unplaced=$unplaced overlap=$overlap region_fence=$region_fence not_of_fence=$not_of_fence report=$path"
        }
    }

    proc save_checkpoint {name} {
        set path [checkpoint_path "${name}.enc"]
        saveDesign $path
        return $path
    }

    proc db_cell_exists {cell_name} {
        set matches [dbGet head.libCells.name $cell_name]
        return [expr {$matches ne "" && $matches ne "0x0"}]
    }

    proc validate_cells {label cells {required 1}} {
        set path [report_path "cell_policy_[string tolower $label].rpt"]
        set fh [open $path w]
        puts $fh "CELL_POLICY=$label"
        puts $fh "REQUIRED=$required"
        set missing [list]
        foreach cell $cells {
            set exists [db_cell_exists $cell]
            puts $fh "CELL_${cell}=[expr {$exists ? {PRESENT} : {MISSING}}]"
            if {!$exists} { lappend missing $cell }
        }
        puts $fh "MISSING_COUNT=[llength $missing]"
        close $fh
        if {$required && ([llength $cells] == 0 || [llength $missing] > 0)} {
            error "PNR_CELLULES_INVALIDES: policy=$label missing=$missing report=$path"
        }
        return [expr {[llength $cells] > 0 && [llength $missing] == 0}]
    }

    proc select_available_cell {label candidates {required 0}} {
        set path [report_path "cell_selection_[string tolower $label].rpt"]
        set fh [open $path w]
        puts $fh "CELL_SELECTION=$label"
        puts $fh "CANDIDATES=$candidates"
        set selected ""
        foreach cell $candidates {
            set exists [db_cell_exists $cell]
            puts $fh "CANDIDATE_${cell}=[expr {$exists ? {PRESENT} : {MISSING}}]"
            if {$selected eq "" && $exists} {
                set selected $cell
            }
        }
        puts $fh "SELECTED_CELL=$selected"
        close $fh
        if {$required && $selected eq ""} {
            error "PNR_AUCUNE_CELLULE_DISPONIBLE: policy=$label candidates=$candidates report=$path"
        }
        return $selected
    }

    proc filter_available_cells {label candidates {required 1}} {
        set path [report_path "cell_filter_[string tolower $label].rpt"]
        set fh [open $path w]
        puts $fh "CELL_FILTER=$label"
        puts $fh "CANDIDATES=$candidates"
        set selected [list]
        foreach cell $candidates {
            set exists [db_cell_exists $cell]
            puts $fh "CANDIDATE_${cell}=[expr {$exists ? {PRESENT} : {MISSING}}]"
            if {$exists} { lappend selected $cell }
        }
        puts $fh "SELECTED_CELLS=$selected"
        puts $fh "SELECTED_COUNT=[llength $selected]"
        close $fh
        if {$required && [llength $selected] == 0} {
            error "PNR_AUCUNE_CELLULE_DISPONIBLE: policy=$label candidates=$candidates report=$path"
        }
        return $selected
    }

    proc require_outputs {paths} {
        foreach path $paths {
            require_file export $path
        }
    }
}
