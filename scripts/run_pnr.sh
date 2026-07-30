#!/usr/bin/env bash
# Implémentation Innovus progressive: niveau basic puis niveau advanced.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  LAB_CONFIG=/chemin/prive/lab.env \
    bash scripts/run_pnr.sh validate \
      DESIGN=full_adder_comb SYN_RUN_DIR=/tmp/.../genus/full_adder_comb/...

  LAB_CONFIG=/chemin/prive/lab.env \
    bash scripts/run_pnr.sh run \
      DESIGN=full_adder_comb SYN_RUN_DIR=/tmp/.../genus/full_adder_comb/... \
      LEVEL=basic

  LAB_CONFIG=/chemin/prive/lab.env \
    bash scripts/run_pnr.sh run \
      DESIGN=adder_pipeline SYN_RUN_DIR=/tmp/.../genus/adder_pipeline/... \
      LEVEL=advanced VIEW=mmmc

Variables principales:
  LEVEL=basic|advanced          (défaut: basic)
  VIEW=tc|mmmc                 (défaut: tc)
  RUN_ROOT=/tmp/digi_tuto_runs
  RUN_ID=nom_du_run
  INNOVUS_BIN=innovus
EOF
}

die() {
    printf 'ERREUR: %s\n' "$*" >&2
}

mode=${1:-}
case "$mode" in
    validate|run)
        shift
        ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

for assignment in "$@"; do
    if [[ $assignment =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
        export "$assignment"
    else
        die "argument invalide: $assignment"
        exit 2
    fi
done

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/.." && pwd -P)
export PROJECT_ROOT="$project_root"

lab_config=${LAB_CONFIG:-}
if [[ -z "$lab_config" || ! -r "$lab_config" ]]; then
    die "LAB_CONFIG doit désigner un fichier privé lisible"
    exit 2
fi
# shellcheck source=/dev/null
source "$lab_config"
for assignment in "$@"; do
    export "$assignment"
done

if [[ -n ${CADENCE_SETUP:-} ]]; then
    [[ -r "$CADENCE_SETUP" ]] || {
        die "initialisation Cadence absente: $CADENCE_SETUP"
        exit 2
    }
    # shellcheck source=/dev/null
    source "$CADENCE_SETUP"
fi

level=${LEVEL:-basic}
view=${VIEW:-tc}
design=${DESIGN:-}
syn_run_dir=${SYN_RUN_DIR:-}
case "$level" in
    basic|advanced) ;;
    *) die "LEVEL doit valoir basic ou advanced"; exit 2 ;;
esac
case "$view" in
    tc|mmmc) ;;
    *) die "VIEW doit valoir tc ou mmmc"; exit 2 ;;
esac
if [[ -z "$design" || -z "$syn_run_dir" ]]; then
    die "DESIGN et SYN_RUN_DIR sont obligatoires"
    exit 2
fi
syn_run_dir=$(cd -- "$syn_run_dir" 2>/dev/null && pwd -P) || {
    die "dossier Genus introuvable: $syn_run_dir"
    exit 2
}

case "$design" in
    full_adder_comb)
        export PNR_DESIGN_CONFIG="$project_root/examples/01_full_adder_comb/pnr/design.tcl"
        has_clock=0
        ;;
    adder_pipeline)
        export PNR_DESIGN_CONFIG="$project_root/examples/02_adder_pipeline/pnr/design.tcl"
        has_clock=1
        ;;
    *)
        die "design non supporté: $design"
        exit 2
        ;;
esac
if [[ "$level" == basic && "$design" != full_adder_comb ]]; then
    die "le niveau basic est volontairement limité au full adder"
    exit 2
fi
if [[ "$level" == basic && "$view" != tc ]]; then
    die "le niveau basic utilise uniquement la vue tc"
    exit 2
fi

export DESIGN="$design"
export VIEW="$view"
export PNR_NETLIST=${SYN_NETLIST:-$syn_run_dir/outputs/$design.mapped.v}
export PNR_SDC=${SYN_SDC:-$syn_run_dir/outputs/$design.mapped.sdc}
genus_status="$syn_run_dir/reports/final_status.rpt"

require_file() {
    local label=$1
    local path=$2
    [[ -s "$path" ]] || {
        die "$label absent ou vide: $path"
        return 1
    }
}
require_list() {
    local label=$1
    local raw=$2
    local item
    [[ -n "$raw" ]] || {
        die "$label est vide"
        return 1
    }
    IFS=: read -r -a items <<< "$raw"
    for item in "${items[@]}"; do
        require_file "$label" "$item" || return 1
    done
}

require_file "netlist Genus" "$PNR_NETLIST" || exit 2
require_file "SDC Genus" "$PNR_SDC" || exit 2
require_file "statut Genus" "$genus_status" || exit 2
grep -Fxq 'GENUS_STATUS=PASS' "$genus_status" || {
    die "le run Genus fourni n est pas PASS"
    exit 2
}

export TECH_LEF=${TECH_LEF:-${INNOVUS_TECH_LEF:-}}
export STDCELL_LEFS=${STDCELL_LEFS:-${INNOVUS_STDCELL_LEF:-}}
export LIB_TC=${LIB_TC:-${INNOVUS_LIBERTY_TC:-}}
export LIB_BC=${LIB_BC:-${INNOVUS_LIBERTY_BC:-}}
export LIB_WC=${LIB_WC:-${INNOVUS_LIBERTY_WC:-}}
export QRC_TECH_FILE_TC=${QRC_TECH_FILE_TC:-${INNOVUS_QRC_TC:-}}
export QRC_TECH_FILE_BC=${QRC_TECH_FILE_BC:-${INNOVUS_QRC_BC:-${QRC_TECH_FILE_TC:-}}}
export QRC_TECH_FILE_WC=${QRC_TECH_FILE_WC:-${INNOVUS_QRC_WC:-${QRC_TECH_FILE_TC:-}}}
export STREAM_MAP=${STREAM_MAP:-${INNOVUS_STREAM_MAP:-}}
export STDCELL_GDS=${STDCELL_GDS:-${INNOVUS_STDCELL_GDS:-}}
export STDCELL_SITE=${STDCELL_SITE:-}
export STDCELL_POWER_PIN=${STDCELL_POWER_PIN:-vddi}
export STDCELL_GROUND_PIN=${STDCELL_GROUND_PIN:-gndi}
export POWER_NET=${POWER_NET:-VDD}
export GROUND_NET=${GROUND_NET:-VSS}
export FILLER_CELLS=${FILLER_CELLS:-${INNOVUS_FILLER_CELLS:-}}
export CTS_BUFFER_CELLS=${CTS_BUFFER_CELLS:-${INNOVUS_CTS_BUFFERS:-}}
export CTS_INVERTER_CELLS=${CTS_INVERTER_CELLS:-${INNOVUS_CTS_INVERTERS:-}}
export TIEHI_CELLS=${TIEHI_CELLS:-${INNOVUS_TIE_HIGH_CELLS:-}}
export TIELO_CELLS=${TIELO_CELLS:-${INNOVUS_TIE_LOW_CELLS:-}}
export ANTENNA_CELLS=${ANTENNA_CELLS:-${INNOVUS_ANTENNA_CELLS:-}}
export TIEHI_CELL=""
export TIELO_CELL=""
export ANTENNA_CELL=""
export TEMP_TC=${TEMP_TC:-${GENUS_TEMPERATURE_TC:-25}}
export TEMP_BC=${TEMP_BC:-${GENUS_TEMPERATURE_BC:--40}}
export TEMP_WC=${TEMP_WC:-${GENUS_TEMPERATURE_WC:-125}}

require_list TECH_LEF "$TECH_LEF" || exit 2
require_list STDCELL_LEFS "$STDCELL_LEFS" || exit 2
require_list LIB_TC "$LIB_TC" || exit 2
require_file QRC_TECH_FILE_TC "$QRC_TECH_FILE_TC" || exit 2
[[ -n "$STDCELL_SITE" ]] || {
    die "STDCELL_SITE est obligatoire"
    exit 2
}

if [[ "$level" == advanced ]]; then
    if [[ "$view" == mmmc ]]; then
        require_list LIB_BC "$LIB_BC" || exit 2
        require_list LIB_WC "$LIB_WC" || exit 2
        require_file QRC_TECH_FILE_BC "$QRC_TECH_FILE_BC" || exit 2
        require_file QRC_TECH_FILE_WC "$QRC_TECH_FILE_WC" || exit 2
    fi
    require_file STREAM_MAP "$STREAM_MAP" || exit 2
    require_file STDCELL_GDS "$STDCELL_GDS" || exit 2
    [[ -n "$FILLER_CELLS" ]] || {
        die "FILLER_CELLS est obligatoire au niveau advanced"
        exit 2
    }
    if ((has_clock == 1)); then
        [[ -n "$CTS_BUFFER_CELLS" && -n "$CTS_INVERTER_CELLS" ]] || {
            die "les cellules CTS sont obligatoires pour le pipeline"
            exit 2
        }
    fi
fi

export ALL_LEFS="$TECH_LEF:$STDCELL_LEFS"
export CORE_UTILIZATION=${CORE_UTILIZATION:-0.60}
export CORE_ASPECT_RATIO=${CORE_ASPECT_RATIO:-1.0}
export CORE_MARGIN_UM=${CORE_MARGIN_UM:-20.0}
export MIN_CORE_SIDE_UM=${MIN_CORE_SIDE_UM:-${CORE_MIN_SIDE_UM:-60.0}}

innovus_bin=${INNOVUS_BIN:-innovus}
command -v "$innovus_bin" >/dev/null 2>&1 || {
    die "Innovus est introuvable: $innovus_bin"
    exit 127
}

printf 'PNR_PREFLIGHT_STATUS=PASS\n'
printf 'DESIGN=%s\nLEVEL=%s\nVIEW=%s\n' "$design" "$level" "$view"
if [[ "$mode" == validate ]]; then
    exit 0
fi

run_root=${RUN_ROOT:-/tmp/digi_tuto_runs}
run_id=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    die "RUN_ID invalide: $run_id"
    exit 2
fi
export PNR_RUN_DIR="$run_root/innovus/$design/$run_id"
if [[ -e "$PNR_RUN_DIR" ]]; then
    die "le dossier existe déjà: $PNR_RUN_DIR"
    exit 2
fi
mkdir -p "$PNR_RUN_DIR"/{reports,outputs,checkpoints,generated,logs}
{
    printf 'FLOW=innovus\n'
    printf 'DESIGN=%s\n' "$design"
    printf 'LEVEL=%s\n' "$level"
    printf 'VIEW=%s\n' "$view"
    printf 'GENUS_RUN_DIR=%s\n' "$syn_run_dir"
    printf 'SIGNOFF_STATUS=NOT_ACHIEVED\n'
} > "$PNR_RUN_DIR/manifest.env"

if [[ "$level" == basic ]]; then
    flow_tcl="$project_root/flow/innovus/innovus_minimal.tcl"
else
    flow_tcl="$project_root/flow/innovus/run.tcl"
fi

printf 'Implémentation Innovus: design=%s level=%s view=%s\n' \
    "$design" "$level" "$view"
printf 'Résultats: %s\n' "$PNR_RUN_DIR"
set +e
"$innovus_bin" -no_gui -files "$flow_tcl" \
    -log "$PNR_RUN_DIR/logs/innovus.log"
run_rc=$?
set -e
if ((run_rc != 0)); then
    die "Innovus a échoué: rc=$run_rc"
    exit "$run_rc"
fi
grep -Fxq 'EXPORT_STATUS=PASS' "$PNR_RUN_DIR/reports/final_status.rpt" || {
    die "le statut final Innovus ne contient pas EXPORT_STATUS=PASS"
    exit 3
}

printf 'RESULTAT: PASS\n'
printf 'STATUS_REPORT=%s\n' "$PNR_RUN_DIR/reports/final_status.rpt"
printf 'SIGNOFF_STATUS=NOT_ACHIEVED\n'
