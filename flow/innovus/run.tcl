# Orchestrateur Innovus 22.33. Les erreurs sont conservees dans reports/ et le
# processus renvoie un code non nul au wrapper shell.

if {![info exists ::env(PROJECT_ROOT)] || $::env(PROJECT_ROOT) eq ""} {
    puts stderr "PNR_ENV_MANQUANTE: PROJECT_ROOT"
    exit 2
}
set flow_dir [file join $::env(PROJECT_ROOT) flow innovus]
source [file join $flow_dir common.tcl]

foreach required_dir {reports outputs checkpoints generated logs} {
    file mkdir [file join [::digi_pnr::require_env PNR_RUN_DIR] $required_dir]
}

source [::digi_pnr::require_env PNR_DESIGN_CONFIG]
source [file join $flow_dir 10_import.tcl]
source [file join $flow_dir validate.tcl]
source [file join $flow_dir 20_floorplan_pg.tcl]
source [file join $flow_dir 30_place_cts.tcl]
source [file join $flow_dir 40_route_verify_export.tcl]

::digi_pnr::initialize_status
::digi_pnr::write_status

if {[catch {
    ::digi_pnr::stage import IMPORT_STATUS {
        ::digi_pnr::import_design
        ::digi_pnr::validate_loaded_technology
    }
    ::digi_pnr::stage floorplan_pg FLOORPLAN_STATUS {
        ::digi_pnr::run_floorplan_and_pg
    }
    ::digi_pnr::stage placement PLACEMENT_STATUS {
        ::digi_pnr::place_design_and_optimize
    }
    ::digi_pnr::stage cts CTS_STATUS {
        ::digi_pnr::run_cts_if_applicable
    }
    ::digi_pnr::stage route_verify_export ROUTE_STATUS {
        ::digi_pnr::run_route_verify_export
    }
} flow_error flow_options]} {
    puts stderr $flow_error
    ::digi_pnr::write_status
    exit 2
}

::digi_pnr::write_status
puts "DIGI_PNR_STATUS=PASS"
puts "DIGI_PNR_FINAL_REPORT=[::digi_pnr::report_path final_status.rpt]"
puts "SIGNOFF_STATUS=NOT_ACHIEVED"
exit 0
