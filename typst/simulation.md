# Simulation RTL avec Xcelium — Du full adder au testbench réutilisable

## Mode d'emploi Overleaf
Ce document ne dépend d'aucun autre fichier LaTeX. Dans Overleaf, créer un projet vide, téléverser uniquement `simulation.tex`, le sélectionner comme document principal et choisir le compilateur pdfLaTeX.

> **Portée :** Le document explique la simulation RTL. Il n'utilise ni modèles de cellules ni annotation temporelle. Les commandes doivent être adaptées à l'environnement Cadence autorisé du laboratoire.

## Table des matières
- [Progression de la simulation](#progression-de-la-simulation)
  - [Les trois phases](#les-trois-phases)
  - [Méthode en quatre niveaux](#méthode-en-quatre-niveaux)
- [Full adder combinatoire](#full-adder-combinatoire)
  - [Contrat logique](#contrat-logique)
  - [RTL synthétisable](#rtl-synthétisable)
  - [Testbench exhaustif](#testbench-exhaustif)
- [Filelists et commande Xcelium](#filelists-et-commande-xcelium)
  - [Filelist RTL](#filelist-rtl)
  - [Filelist testbench](#filelist-testbench)
  - [Commande minimale](#commande-minimale)
- [Wrapper réutilisable](#wrapper-réutilisable)
  - [Waveforms optionnelles](#waveforms-optionnelles)
  - [Wrapper contrôlé](#wrapper-contrôlé)
- [Augmenter la complexité](#augmenter-la-complexité)
  - [Additionneur pipeliné](#additionneur-pipeliné)
- [Diagnostic](#diagnostic)
- [Checklist finale](#checklist-finale)

---

## Progression de la simulation

### Les trois phases
1. **Compilation** : lecture du SystemVerilog et contrôle de syntaxe.
2. **Élaboration** : construction de la hiérarchie et résolution des modules, paramètres et ports.
3. **Simulation** : exécution des blocs temporels et production du verdict du testbench.

Une erreur de syntaxe appartient généralement à la compilation. Un top inconnu ou un port impossible appartient à l'élaboration. Un `$fatal`, un timeout ou une comparaison incorrecte appartient à la simulation.

### Méthode en quatre niveaux
| Niveau | Objectif |
|---|---|
| 1 | Écrire un petit DUT et un testbench auto-vérifiant. |
| 2 | Séparer RTL et testbench avec deux filelists. |
| 3 | Lancer une commande `xrun` directe et comprendre chaque option. |
| 4 | Ajouter un wrapper, des logs, des waveforms et un second design séquentiel. |

---

## Full adder combinatoire

### Contrat logique
Pour les entrées `a`, `b` et `c_in` :

- `sum = a XOR b XOR c_in`
- `c_out = ab + ac_in + bc_in`

| a | b | c_in | sum | c_out |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 0 | 1 | 1 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 |
| 1 | 1 | 1 | 1 | 1 |

### RTL synthétisable
```systemverilog
`timescale 1ns/1ps

module full_adder_comb (
    input  logic a_i,
    input  logic b_i,
    input  logic cin_i,
    output logic sum_o,
    output logic cout_o
);
    assign sum_o  = a_i ^ b_i ^ cin_i;
    assign cout_o = (a_i & b_i)
                  | (a_i & cin_i)
                  | (b_i & cin_i);
endmodule
```

Le DUT ne contient aucun délai, bloc `initial` ou appel système. Ces éléments appartiennent au testbench.

### Testbench exhaustif
```systemverilog
`timescale 1ns/1ps

module tb_full_adder_comb;
    logic a_i, b_i, cin_i;
    logic sum_o, cout_o;

    full_adder_comb dut (
        .a_i(a_i), .b_i(b_i), .cin_i(cin_i),
        .sum_o(sum_o), .cout_o(cout_o)
    );

    initial begin : test_exhaustif
        logic sum_attendue;
        logic cout_attendue;

        for (int vecteur = 0; vecteur < 8; vecteur++) begin
            {a_i, b_i, cin_i} = vecteur[2:0];
            #10;

            sum_attendue  = a_i ^ b_i ^ cin_i;
            cout_attendue = (a_i & b_i)
                          | (a_i & cin_i)
                          | (b_i & cin_i);

            if ({cout_o, sum_o} !==
                {cout_attendue, sum_attendue}) begin
                $fatal(1,
                    "vecteur=%03b obtenu=%b%b attendu=%b%b",
                    {a_i,b_i,cin_i}, cout_o, sum_o,
                    cout_attendue, sum_attendue);
            end
        end

        $display("TEST_PASS: full_adder_comb");
        $finish;
    end
endmodule
```

> **À retenir :** Un testbench automatisable doit terminer avec `$fatal` en cas d'erreur et imprimer un marqueur final exact uniquement lorsque tous les tests passent.

---

## Filelists et commande Xcelium

### Filelist RTL
`rtl.f`
```text
rtl/full_adder_comb.sv
```

### Filelist testbench
`tb.f`
```text
tb/tb_full_adder_comb.sv
```

Les chemins sont interprétés depuis le dossier où `xrun` est lancé. Une méthode simple consiste à lancer la commande depuis la racine du projet.

### Commande minimale
```bash
xrun -64bit -sv -timescale 1ns/1ps \
  -f sim/rtl.f \
  -f sim/tb.f \
  -top tb_full_adder_comb \
  -R
```

- `-64bit` utilise l'exécutable 64 bits.
- `-sv` active SystemVerilog.
- `-timescale` fixe l'unité et la précision par défaut.
- `-f` lit une filelist.
- `-top` choisit le top élaboré.
- `-R` lance la simulation après l'élaboration.

---

## Wrapper réutilisable

### Waveforms optionnelles
Pour une petite simulation, la visibilité complète peut être activée avec `-access +rwc`. Un fichier Tcl Xcelium peut créer une base SHM :

```tcl
database -open waves -into waves.shm -default
probe -create tb_full_adder_comb -all -depth all
run
exit
```

Puis :

```bash
xrun ... -input waves.tcl
simvision waves.shm
```

### Wrapper contrôlé
Le wrapper suivant crée un dossier de résultat unique, isole la bibliothèque Xcelium, conserve le code retour et vérifie le marqueur final.

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

XRUN_BIN=${XRUN_BIN:-xrun}
RUN_ROOT=${RUN_ROOT:-/tmp/digi_tuto_runs}
RUN_ID=${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}
RUN_DIR="$RUN_ROOT/xcelium/full_adder_comb/$RUN_ID"

command -v "$XRUN_BIN" >/dev/null 2>&1 || {
  echo "ERREUR: xrun introuvable" >&2
  exit 127
}

mkdir -p "$RUN_DIR"

set +e
"$XRUN_BIN" \
  -64bit -sv -timescale 1ns/1ps \
  -access +rwc \
  -f sim/rtl.f \
  -f sim/tb.f \
  -top tb_full_adder_comb \
  -xmlibdirname "$RUN_DIR/xcelium.d" \
  -logfile "$RUN_DIR/xrun.log" \
  -R
XRUN_RC=$?
set -e

if (( XRUN_RC != 0 )); then
  echo "RESULTAT: FAIL (xrun=$XRUN_RC)" >&2
  exit "$XRUN_RC"
fi

grep -Fxq "TEST_PASS: full_adder_comb" \
  "$RUN_DIR/xrun.log" || {
    echo "RESULTAT: FAIL (marqueur absent)" >&2
    exit 1
  }

echo "RESULTAT: PASS"
echo "LOG=$RUN_DIR/xrun.log"
```

---

## Augmenter la complexité

### Additionneur pipeliné
Un second exemple ajoute une clock, un reset synchrone, des registres et un protocole `valid`. Une transaction acceptée avec `valid_i=1` produit un résultat valide un cycle plus tard.

```systemverilog
module adder_pipeline #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             valid_i,
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  logic             cin_i,
    output logic             valid_o,
    output logic [WIDTH-1:0] sum_o,
    output logic             cout_o
);
    logic [WIDTH:0] result_q;
    logic           valid_q;

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            result_q <= '0;
            valid_q  <= 1'b0;
            sum_o    <= '0;
            cout_o   <= 1'b0;
            valid_o  <= 1'b0;
        end else begin
            result_q <= {1'b0,a_i}
                      + {1'b0,b_i}
                      + cin_i;
            valid_q  <= valid_i;
            {cout_o,sum_o} <= result_q;
            valid_o <= valid_q;
        end
    end
endmodule
```

Le scoreboard doit décaler la référence d'un cycle. Les stimuli sont de préférence appliqués au front descendant afin d'éviter une course avec la capture au front montant.

---

## Diagnostic

| Symptôme | Cause probable | Première action |
|---|---|---|
| `xrun` introuvable | environnement non chargé | Vérifier `command -v xrun`. |
| Fichier absent | chemin relatif incorrect | Ouvrir les filelists depuis le dossier de lancement. |
| Top inconnu | mauvais argument `-top` | Vérifier le nom exact du module testbench. |
| Port inconnu | interface DUT/TB différente | Comparer noms, directions et largeurs. |
| Sortie `X` | signal non piloté ou reset absent | Chercher le premier temps où la valeur devient inconnue. |
| Code retour nul sans PASS | testbench terminé trop tôt | Exiger le marqueur terminal exact. |

> **Ordre de debug :** Lire d'abord la première erreur de compilation, puis l'élaboration, puis le premier vecteur fonctionnel en échec. Ouvrir les waveforms seulement après avoir localisé la classe d'erreur.

---

## Checklist finale
1. Le DUT est séparé du testbench.
2. Les deux filelists sont lisibles depuis le dossier de lancement.
3. Le top testbench est explicite.
4. Les huit vecteurs du full adder sont vérifiés.
5. Le code retour Xcelium et le marqueur final sont tous les deux contrôlés.
6. Les résultats sont écrits hors des sources.
7. La GUI sert au diagnostic, pas au verdict.
```