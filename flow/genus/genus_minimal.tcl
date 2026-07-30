# Synthèse Genus minimale en vue typique.
# Le wrapper fournit les chemins par variables d'environnement.

set flow_dir [file dirname [file normalize [info script]]]
source [file join $flow_dir helpers.tcl]

proc tutorial_minimal_main {} {
    set root       [tutorial_require_env TUTORIAL_ROOT]
    set run_dir    [tutorial_require_env GENUS_RUN_DIR]
    set top        [tutorial_require_env GENUS_TOP_MODULE]
    set filelist   [tutorial_require_env GENUS_FILELIST]
    set sdc        [tutorial_require_env GENUS_SDC]
    set report_dir [file join $run_dir reports]
    set output_dir [file join $run_dir outputs]

    file mkdir $report_dir
    file mkdir $output_dir

    set_db hdl_language sv
    set_db library [tutorial_env_list GENUS_LIBERTY_TC]
    set_db init_hdl_search_path [list $root]
    cd $root

    tutorial_run_stage read_rtl {
        read_hdl -sv -f $filelist
    }
    tutorial_run_stage elaborate {
        elaborate $top
    }
    tutorial_run_stage read_constraints {
        read_sdc $sdc
    }
    tutorial_run_stage checks {
        tutorial_report [file join $report_dir check_design.rpt] \
            {check_design -all}
        tutorial_report [file join $report_dir check_timing_intent.rpt] \
            {check_timing_intent -verbose}
    }
    tutorial_run_stage synthesis {
        syn_generic
        syn_map
        syn_opt
    }
    tutorial_run_stage reports {
        tutorial_report [file join $report_dir report_timing.rpt] \
            {report_timing -max_paths 20}
        tutorial_report [file join $report_dir report_area.rpt] \
            {report_area}
        tutorial_report [file join $report_dir report_qor.rpt] \
            {report_qor}
    }

    set mapped_v   [file join $output_dir ${top}.mapped.v]
    set mapped_sdc [file join $output_dir ${top}.mapped.sdc]
    tutorial_run_stage export {
        write_hdl > $mapped_v
        write_sdc > $mapped_sdc
        tutorial_assert_nonempty $mapped_v
        tutorial_assert_nonempty $mapped_sdc
    }

    tutorial_write_final_status PASS \
        "niveau basic terminé; netlist et SDC disponibles"
    tutorial_record_stage final_status PASS
}

set rc [catch {tutorial_minimal_main} message options]
if {$rc != 0} {
    catch {tutorial_write_final_status FAIL [tutorial_one_line $message]}
    puts stderr "GENUS_TUTORIAL_ERROR: $message"
    if {[dict exists $options -errorinfo]} {
        puts stderr [dict get $options -errorinfo]
    }
    exit 20
}

puts "GENUS_TUTORIAL_STATUS: BASIC_FLOW_COMPLETED"
exit 0
