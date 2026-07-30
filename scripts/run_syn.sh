#!/usr/bin/env bash
# Synthèse Genus progressive: niveau basic puis niveau advanced.

set -u -o pipefail

usage() {
    cat <<'EOF'
Usage:
  LAB_CONFIG=/chemin/prive/lab.env \
    bash scripts/run_syn.sh --design full_adder_comb

  LAB_CONFIG=/chemin/prive/lab.env \
    bash scripts/run_syn.sh --design adder_pipeline \
      --level advanced --view mmmc

Options:
  --design full_adder_comb|adder_pipeline
  --level  basic|advanced       (défaut: basic)
  --view   tc|mmmc              (défaut: tc)
  --run-id IDENTIFIANT

Variables optionnelles:
  GENUS_BIN=genus
  RUN_ROOT=/tmp/digi_tuto_runs
EOF
}

fail() {
    printf 'ERREUR: %s\n' "$*" >&2
}

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)

design=""
level=basic
view=tc
run_id=${RUN_ID:-}

while (($# > 0)); do
    case "$1" in
        --design)
            (($# >= 2)) || { fail "valeur absente après --design"; exit 2; }
            design=$2
            shift 2
            ;;
        --level)
            (($# >= 2)) || { fail "valeur absente après --level"; exit 2; }
            level=$2
            shift 2
            ;;
        --view)
            (($# >= 2)) || { fail "valeur absente après --view"; exit 2; }
            view=$2
            shift 2
            ;;
        --run-id)
            (($# >= 2)) || { fail "valeur absente après --run-id"; exit 2; }
            run_id=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "option inconnue: $1"
            usage >&2
            exit 2
            ;;
    esac
done

case "$design" in
    full_adder_comb)
        example_dir=examples/01_full_adder_comb
        ;;
    adder_pipeline)
        example_dir=examples/02_adder_pipeline
        ;;
    *)
        fail "design invalide: ${design:-<vide>}"
        usage >&2
        exit 2
        ;;
esac
case "$level" in
    basic|advanced) ;;
    *) fail "level doit valoir basic ou advanced"; exit 2 ;;
esac
case "$view" in
    tc|mmmc) ;;
    *) fail "view doit valoir tc ou mmmc"; exit 2 ;;
esac
if [[ "$level" == basic && "$view" != tc ]]; then
    fail "le niveau basic utilise uniquement la vue tc"
    exit 2
fi

design_config="$project_root/$example_dir/syn/design.env"
[[ -s "$design_config" ]] || {
    fail "configuration design absente: $design_config"
    exit 2
}
set -a
# shellcheck disable=SC1090
. "$design_config"
lab_config=${LAB_CONFIG:-}
if [[ -z "$lab_config" || ! -r "$lab_config" ]]; then
    fail "LAB_CONFIG doit désigner un fichier privé lisible"
    exit 2
fi
# shellcheck disable=SC1090
. "$lab_config"
set +a

if [[ -n ${CADENCE_SETUP:-} ]]; then
    [[ -r "$CADENCE_SETUP" ]] || {
        fail "initialisation Cadence absente: $CADENCE_SETUP"
        exit 2
    }
    # shellcheck disable=SC1090
    . "$CADENCE_SETUP"
fi

genus_bin=${GENUS_BIN:-genus}
command -v "$genus_bin" >/dev/null 2>&1 || {
    fail "Genus est introuvable: $genus_bin"
    exit 127
}

export GENUS_FILELIST="$project_root/$GENUS_FILELIST_REL"
export GENUS_SDC="$project_root/$GENUS_SDC_REL"
for required in "$GENUS_FILELIST" "$GENUS_SDC"; do
    [[ -s "$required" ]] || {
        fail "fichier absent ou vide: $required"
        exit 2
    }
done

check_file_list() {
    local variable_name=$1
    local raw_value=${!variable_name:-}
    local item
    [[ -n "$raw_value" ]] || {
        fail "variable obligatoire absente: $variable_name"
        return 1
    }
    IFS=: read -r -a values <<< "$raw_value"
    for item in "${values[@]}"; do
        [[ -s "$item" ]] || {
            fail "fichier invalide dans $variable_name: $item"
            return 1
        }
    done
}

check_file_list GENUS_LIBERTY_TC || exit 2
if [[ "$level" == advanced ]]; then
    check_file_list GENUS_LEF_FILES || exit 2
    [[ -s ${GENUS_QRC_TC:-} ]] || {
        fail "GENUS_QRC_TC absent ou vide"
        exit 2
    }
    if [[ "$view" == mmmc ]]; then
        check_file_list GENUS_LIBERTY_BC || exit 2
        check_file_list GENUS_LIBERTY_WC || exit 2
        [[ -s ${GENUS_QRC_BC:-} && -s ${GENUS_QRC_WC:-} ]] || {
            fail "les fichiers QRC BC et WC sont obligatoires"
            exit 2
        }
    fi
fi

run_root=${RUN_ROOT:-/tmp/digi_tuto_runs}
run_id=${run_id:-$(date -u +%Y%m%dT%H%M%SZ)}
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    fail "RUN_ID invalide: $run_id"
    exit 2
fi
run_dir="$run_root/genus/$design/$run_id"
if [[ -e "$run_dir" ]]; then
    fail "le dossier existe déjà: $run_dir"
    exit 2
fi
mkdir -p "$run_dir/logs" "$run_dir/reports" "$run_dir/outputs"
printf 'stage\tstatus\tutc\tdetail\n' > "$run_dir/stage_status.tsv"

export TUTORIAL_ROOT="$project_root"
export GENUS_RUN_DIR="$run_dir"
export GENUS_STAGE_STATUS="$run_dir/stage_status.tsv"
export GENUS_MODE="$view"
export GENUS_TOP_MODULE

if [[ "$level" == basic ]]; then
    flow_tcl="$project_root/flow/genus/genus_minimal.tcl"
else
    flow_tcl="$project_root/flow/genus/genus_main.tcl"
fi

printf 'Synthèse Genus: design=%s level=%s view=%s\n' "$design" "$level" "$view"
printf 'Résultats: %s\n' "$run_dir"
set +e
"$genus_bin" -files "$flow_tcl" -log "$run_dir/logs/genus.log" \
    2>&1 | tee "$run_dir/logs/console.log"
pipeline_rc=("${PIPESTATUS[@]}")
set -e
tool_rc=${pipeline_rc[0]}
tee_rc=${pipeline_rc[1]}

if ((tool_rc != 0 || tee_rc != 0)); then
    fail "Genus ou la journalisation a échoué: genus=$tool_rc tee=$tee_rc"
    exit "$((tool_rc != 0 ? tool_rc : tee_rc))"
fi
for artifact in \
    "$run_dir/outputs/$design.mapped.v" \
    "$run_dir/outputs/$design.mapped.sdc" \
    "$run_dir/reports/final_status.rpt"; do
    [[ -s "$artifact" ]] || {
        fail "sortie obligatoire absente: $artifact"
        exit 3
    }
done
grep -Fxq 'GENUS_STATUS=PASS' "$run_dir/reports/final_status.rpt" || {
    fail "le statut final Genus n est pas PASS"
    exit 3
}

printf 'RESULTAT: PASS\n'
printf 'NETLIST=%s\n' "$run_dir/outputs/$design.mapped.v"
printf 'SDC=%s\n' "$run_dir/outputs/$design.mapped.sdc"
