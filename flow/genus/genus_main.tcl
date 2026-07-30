# Flow pédagogique Cadence Genus 22.13 : RTL -> netlist mappée.
#
# Ce script est lancé par scripts/run_syn.sh. Il n'embarque aucun chemin de
# laboratoire et ne doit pas être sourcé avant le préflight du wrapper.

set tutorial_script_dir [file dirname [file normalize [info script]]]
source [file join $tutorial_script_dir helpers.tcl]

proc tutorial_main {} {
    set root       [tutorial_require_env TUTORIAL_ROOT]
    set run_dir    [tutorial_require_env GENUS_RUN_DIR]
    set top        [tutorial_require_env GENUS_TOP_MODULE]
    set mode       [tutorial_require_env GENUS_MODE]
    set filelist   [tutorial_require_env GENUS_FILELIST]
    set mmmc_file  [file join $root flow genus mmmc.tcl]
    set report_dir [file join $run_dir reports]
    set output_dir [file join $run_dir outputs]
    foreach dir [list \
        $report_dir \
        [file join $report_dir elaboration] \
        [file join $report_dir timing] \
        [file join $report_dir qor] \
        [file join $report_dir messages] \
        $output_dir] {
        file mkdir $dir
    }

    # Réglages volontairement sobres et déterministes pour les deux exemples.
    set_db source_verbose true
    set_db hdl_language sv
    set_db hdl_error_on_latch true
    set_db detailed_sdc_messages true
    set_db syn_generic_effort high
    set_db syn_map_effort high
    set_db syn_opt_effort high

    cd $root

    tutorial_run_stage read_mmmc {
        # read_mmmc lit Liberty, QRC et SDC via flow/genus/mmmc.tcl.
        read_mmmc $mmmc_file
    }

    tutorial_run_stage read_physical {
        set tutorial_lefs [tutorial_env_list GENUS_LEF_FILES]
        read_physical -lef $tutorial_lefs
    }

    tutorial_run_stage read_rtl {
        set_db init_hdl_search_path [list $root]
        read_hdl -sv -f $filelist
    }

    tutorial_run_stage elaborate {
        elaborate $top
    }

    tutorial_run_stage check_design {
        tutorial_report \
            [file join $report_dir elaboration check_design_unresolved.rpt] \
            {check_design -unresolved}
        tutorial_report \
            [file join $report_dir elaboration check_design_all.rpt] \
            {check_design -all}
        tutorial_report \
            [file join $report_dir elaboration report_hierarchy.rpt] \
            {report_hierarchy}
    }

    tutorial_run_stage init_design {
        init_design
        tutorial_report \
            [file join $report_dir timing check_timing_intent.rpt] \
            {check_timing_intent -verbose}
        tutorial_report \
            [file join $report_dir timing report_clocks.rpt] \
            {report_clocks}
        tutorial_report \
            [file join $report_dir timing report_timing_pre_synth.rpt] \
            {report_timing -max_paths 20}
    }

    tutorial_run_stage syn_generic {
        syn_generic
        tutorial_report \
            [file join $report_dir timing report_timing_post_generic.rpt] \
            {report_timing -max_paths 20}
    }

    tutorial_run_stage syn_map {
        syn_map
        tutorial_report \
            [file join $report_dir timing report_timing_post_map.rpt] \
            {report_timing -max_paths 20}
    }

    tutorial_run_stage syn_opt {
        syn_opt
        tutorial_report \
            [file join $report_dir timing report_timing_post_opt.rpt] \
            {report_timing -max_paths 50}
    }

    tutorial_run_stage reports {
        tutorial_report [file join $report_dir qor report_qor.rpt] \
            {report_qor}
        tutorial_report [file join $report_dir qor report_area.rpt] \
            {report_area}
        tutorial_report [file join $report_dir qor report_gates.rpt] \
            {report_gates}
        tutorial_report [file join $report_dir qor report_power.rpt] \
            {report_power}
        tutorial_report [file join $report_dir qor report_design_rules.rpt] \
            {report_design_rules}
        tutorial_report [file join $report_dir messages report_messages.rpt] \
            {report_messages}

        if {$mode eq "mmmc"} {
            foreach view {tutorial_bc_view tutorial_tc_view tutorial_wc_view} {
                tutorial_report \
                    [file join $report_dir timing report_timing_${view}.rpt] \
                    "report_timing -view $view -max_paths 20"
            }
        } else {
            tutorial_report \
                [file join $report_dir timing report_timing_tutorial_tc_view.rpt] \
                {report_timing -view tutorial_tc_view -max_paths 20}
        }
    }

    set mapped_v   [file join $output_dir ${top}.mapped.v]
    set mapped_sdc [file join $output_dir ${top}.mapped.sdc]

    tutorial_run_stage export {
        write_hdl > $mapped_v
        if {$mode eq "mmmc"} {
            # WC est la vue setup canonique du package physique.
            write_sdc -view tutorial_wc_view > $mapped_sdc
        } else {
            write_sdc -view tutorial_tc_view > $mapped_sdc
        }

        foreach artifact [list $mapped_v $mapped_sdc] {
            tutorial_assert_nonempty $artifact
        }
    }

    tutorial_write_final_status PASS \
        "niveau advanced terminé; netlist et SDC disponibles; rapports à examiner"
    tutorial_record_stage final_status PASS
}

set tutorial_rc [catch {tutorial_main} tutorial_error tutorial_options]
if {$tutorial_rc != 0} {
    catch {tutorial_write_final_status FAIL [tutorial_one_line $tutorial_error]}
    puts stderr "GENUS_TUTORIAL_ERROR: $tutorial_error"
    if {[dict exists $tutorial_options -errorinfo]} {
        puts stderr [dict get $tutorial_options -errorinfo]
    }
    exit 20
}

puts "GENUS_TUTORIAL_STATUS: ADVANCED_FLOW_COMPLETED_NOT_SIGNOFF"
exit 0
