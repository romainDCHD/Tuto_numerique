# Utilitaires communs au flow Genus du tutoriel.
#
# Les statuts PASS enregistrés ici signifient uniquement que la commande de
# l'étape s'est terminée sans erreur Tcl. Ils ne constituent jamais une preuve
# de fermeture temporelle, de DRC/LVS ou de signoff.

proc tutorial_require_env {name} {
    if {![info exists ::env($name)] || [string trim $::env($name)] eq ""} {
        error "variable d'environnement obligatoire absente: $name"
    }
    return $::env($name)
}

proc tutorial_env_list {name} {
    set raw [tutorial_require_env $name]
    set values [list]
    foreach value [split $raw ":"] {
        set value [string trim $value]
        if {$value ne ""} {
            lappend values $value
        }
    }
    if {[llength $values] == 0} {
        error "la liste $name est vide"
    }
    return $values
}

proc tutorial_now_utc {} {
    return [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
}

proc tutorial_one_line {value} {
    regsub -all {[\r\n\t]+} $value { } value
    return [string trim $value]
}

proc tutorial_record_stage {stage status {detail ""}} {
    set status_file [tutorial_require_env GENUS_STAGE_STATUS]
    set fh [open $status_file a]
    puts $fh "[tutorial_one_line $stage]\t[tutorial_one_line $status]\t[tutorial_now_utc]\t[tutorial_one_line $detail]"
    close $fh
}

proc tutorial_run_stage {stage body} {
    set ::tutorial_current_stage $stage
    tutorial_record_stage $stage RUNNING
    set rc [catch {uplevel 1 $body} result options]
    if {$rc != 0} {
        tutorial_record_stage $stage FAIL $result
        return -options $options $result
    }
    tutorial_record_stage $stage PASS
    return $result
}

proc tutorial_report {path command} {
    file mkdir [file dirname $path]
    # Genus étend Tcl avec la redirection « commande > fichier ».
    if {[catch {uplevel #0 "$command > [list $path]"} result]} {
        set fh [open $path w]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=[tutorial_one_line $command]"
        puts $fh "ERROR=[tutorial_one_line $result]"
        close $fh
        error "échec du rapport '$command': $result"
    }
}

proc tutorial_write_key_values {path pairs} {
    file mkdir [file dirname $path]
    set fh [open $path w]
    foreach {key value} $pairs {
        puts $fh "$key=[tutorial_one_line $value]"
    }
    close $fh
}

proc tutorial_assert_nonempty {path} {
    if {![file exists $path]} {
        error "artefact absent: $path"
    }
    if {[file size $path] <= 0} {
        error "artefact vide: $path"
    }
}

proc tutorial_write_final_status {status detail} {
    set run_dir [tutorial_require_env GENUS_RUN_DIR]
    set mode [tutorial_require_env GENUS_MODE]
    set path [file join $run_dir reports final_status.rpt]

    if {$status eq "PASS"} {
        set flow_status FLOW_COMPLETED
        set artifact_status PASS
    } else {
        set flow_status FAILED
        set artifact_status FAIL
    }

    tutorial_write_key_values $path [list \
        GENUS_STATUS $status \
        FLOW_EXECUTION_STATUS $flow_status \
        ARTIFACT_STATUS $artifact_status \
        TIMING_STATUS REVIEW_REQUIRED \
        CHECK_DESIGN_STATUS REVIEW_REQUIRED \
        VIEW_MODE $mode \
        IMPLEMENTATION_STATUS IMPLEMENTATION_CANDIDATE \
        SIGNOFF_STATUS NOT_SIGNOFF \
        DETAIL $detail]
}
