#!/usr/bin/env bash
# Simulation RTL Xcelium, du full adder au pipeline.

# Pour que certaines erreur communes fassent crasher le code (sinon on peut avoir des bugs caches qui ressortent par la suite)
set -Eeuo pipefail

# Message a afficher pour le -h ou en cas d'erreur d'utilisation du script
usage() {
    cat <<'EOF' # cat jusqu'à EOF
Usage:
  bash scripts/run_sim.sh full_adder_comb [--gui]
  bash scripts/run_sim.sh adder_pipeline [--gui]

Variables optionnelles:
  XRUN_BIN=xrun
  RUN_ROOT=/tmp/digi_tuto_runs
  RUN_ID=nom_du_run
  XRUN_EXTRA_ARGS="..."
EOF
}

############ RECUPERATION DES CHEMINS ############
# Interet :
# 1. Maintenabilite : Centralisation des chemins et noms de modules.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" #${BASH_SOURCE[0]} : Recupere le chemin de ce script (meme si il a ete source).
project_root="$(cd -- "$script_dir/.." && pwd -P)"

############ Initialisation des variables ############
design="" # Design a simuler
gui=0 # Par defaut pas de gui sauf si gui == 1 :

############ LECTURE DE LA COMMANDE ############ 
# Interet :
# 1. Scalabilite : Ajouter un nouveau design = ajouter un case supplementaire.
# 2. Maintenabilite

# while (($# > 0)) : Parcourt tous les arguments passes au script
while (($# > 0)); do
    case "$1" in
        --gui)
            gui=1
            shift
            ;;
        -h|--help) # Le fameux appel en cas de help
            usage
            exit 0
            ;;
        full_adder_comb|adder_pipeline) # Si l argument suivant est un des deux cas traites dans ce script
	    # Verification que pas de doublons).
            [[ -z "$design" ]] || {
                printf 'ERREUR: un seul design est attendu\n' >&2
                exit 2
            }
            design=$1
            shift
            ;;
        *)
            printf 'ERREUR: argument inconnu: %s\n' "$1" >&2 # >&2 : Redirige la sortie d'erreur vers stderr (bonne pratique)
	    usage >&2 #usage permet de garder le message du print en plus de la stderr
            exit 2
            ;;
    esac
done

############ RECUPERATION DES CHEMINS SPECIFIQUES A CHAQUE DESIGN ############
case "$design" in
    full_adder_comb)
        example_dir="$project_root/examples/01_full_adder_comb"
        tb_top=tb_full_adder_comb
        pass_marker="TEST_PASS: full_adder_comb"
        ;;
    adder_pipeline)
        example_dir="$project_root/examples/02_adder_pipeline"
        tb_top=tb_adder_pipeline
        pass_marker="TEST_PASS: adder_pipeline"
        ;;
    *)
        printf 'ERREUR: design absent\n' >&2
        usage >&2
        exit 2
        ;;
esac

############ VERIFICATION QUE XRUN EST RECONNU ############ 

xrun_bin=${XRUN_BIN:-xrun}
if ! command -v "$xrun_bin" >/dev/null 2>&1; then
    printf 'ERREUR: xrun est introuvable; chargez l environnement Cadence\n' >&2
    exit 127 # Code d'erreur standard pour "commande introuvable".
fi

############ CREATION D'UN DOSSIER DE RUN ############ 
# Interet : 
# Tracabilite : Chaque run a un ID unique --> facilite le debogage.
# Isolation : Chaque run est dans son propre dossier --> evite les conflits.
# Reproductibilite : Le run_id peut etre reutilise pour relancer le meme test.


run_root=${RUN_ROOT:-/tmp/digi_tuto_runs}
run_id=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
# if permet de s'assurer qu'il n'y a pas d'espaces ou caracteres speciaux qui pourraient poser probleme dans les chemins 
if [[ ! "$run_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf 'ERREUR: RUN_ID invalide: %s\n' "$run_id" >&2
    exit 2
fi
run_dir="$run_root/xcelium/$design/$run_id"
if [[ -e "$run_dir" ]]; then
    printf 'ERREUR: le dossier existe deja: %s\n' "$run_dir" >&2
    exit 2
fi
mkdir -p "$run_dir"

############ RESOUDRE FILELIST ############
# Transformer un fichier de filelist (ex: rtl.f) contenant des chemins relatifs en chemins absolus ou interpretables par Xcelium.
# Interet :
# Portabilite : Le script peut etre lance depuis n importe quel repertoire.
# Clarte : Xcelium recoit des chemins explicites : evite les erreurs de file not found.
# Flexibilite : Permet d utiliser des chemins relatifs dans les filelists sources.


resolve_filelist() {
    local source_file=$1
    local target_file=$2
    local line
    : > "$target_file"
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%%#*}
        line=${line#"${line%%[![:space:]]*}"}
        line=${line%"${line##*[![:space:]]}"}
        [[ -n "$line" ]] || continue
        if [[ "$line" == /* || "$line" == +* || "$line" == -* ]]; then
            printf '%s\n' "$line" >> "$target_file"
        else
            printf '%s/%s\n' "$project_root" "$line" >> "$target_file"
        fi
    done < "$source_file"
}


resolve_filelist "$example_dir/sim/rtl.f" "$run_dir/rtl.f"
resolve_filelist "$example_dir/sim/tb.f" "$run_dir/tb.f"

############ FICHIER TCL POUR XCELLIUM ############
# Cree le dossier de stockage des coubres (si on veut check "a la main" par la suite). Extension SHM pour "Shared Memory" 
# Cree des sondes ("probes") pour chaque signaux du module tb_top (par ex: tb_adder_pipeline). -depth all --> inclut tous les modules de maniere recursibee

tcl_file="$run_dir/run.tcl"
{
    printf 'database -open waves -into {%s} -default\n' "$run_dir/waves.shm"
    printf 'probe -create %s -all -depth all\n' "$tb_top"
    printf 'run\n'
    if ((gui == 0)); then
        printf 'exit\n'
    fi
} > "$tcl_file"

############ LA COMMANDE XCELIUM A LANCER ############
# Run la simulation

cmd=(
    "$xrun_bin"
    -64bit
    -sv
    -timescale 1ns/1ps
    -access +rwc
    -f "$run_dir/rtl.f"
    -f "$run_dir/tb.f"
    -top "$tb_top"
    -xmlibdirname "$run_dir/xcelium.d"
    -input "$tcl_file"
    -logfile "$run_dir/xrun.log"
)
if ((gui == 1)); then
    cmd+=(-gui)
fi
if [[ -n ${XRUN_EXTRA_ARGS:-} ]]; then
    read -r -a extra_args <<< "$XRUN_EXTRA_ARGS"
    cmd+=("${extra_args[@]}")
fi

############ FIN DU SCRIPT ############
# set -e (par defaut) : Normalement, le script s'arrete si une commande echoue.
# set +e : Desactive ce comportement pour capturer le code de retour de xrun.
# ${cmd[@]} : Expand le tableau cmd en une seule commande (gestion des espaces dans les chemins).


printf 'Simulation Xcelium: %s\n' "$design"
printf 'Resultats: %s\n' "$run_dir"
set +e
"${cmd[@]}"
tool_rc=$?
set -e

# Vérification du resultat 
# Erreur : tool_rc != 0 : Si Xcelium a plante 
if ((tool_rc != 0)); then
    printf 'RESULTAT: FAIL (xrun=%d)\n' "$tool_rc" >&2
    exit "$tool_rc"
fi

# Repere si le markeer : TEST_PASS: de adder_pipeline est bien present (ne pas l'oublier dans le tb)
if ! grep -Fxq "$pass_marker" "$run_dir/xrun.log"; then
    printf 'RESULTAT: FAIL (marqueur final absent)\n' >&2
    exit 1
fi

# Si pas d'erreur : PASS 
printf 'RESULTAT: PASS\n'
