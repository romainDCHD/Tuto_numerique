## Lecture des résultats de synthèse Genus MMMC

Après la synthèse, les rapports doivent être parcourus dans un ordre logique afin de vérifier successivement l'exécution du flow, la cohérence du design, les contraintes temporelles puis la qualité des résultats.

### `stage_status.tsv`

**But :** vérifier que toutes les étapes du flow se sont exécutées.

Points à regarder :

* `read_rtl`, `read_mmmc`, `read_physical`, `elaborate` : le design et son environnement ont été correctement chargés ;
* `check_design`, `timing_checks` : les vérifications ont été exécutées ;
* `syn_generic`, `syn_map`, `syn_opt` : les trois étapes de synthèse sont terminées ;
* `export` : la netlist et le SDC ont été générés.

Toutes les étapes doivent normalement être `PASS`.

> `PASS` signifie que la commande s'est exécutée sans erreur. Cela ne garantit pas que le timing est respecté.

---

### `reports/final_status.rpt`

**But :** donner le statut global du run.

Points importants :

* `GENUS_STATUS=PASS` : le flow s'est terminé normalement ;
* `FLOW_EXECUTION_STATUS=COMPLETED` : toutes les étapes attendues ont été réalisées ;
* `VIEW=mmmc` : le flow utilise bien la configuration MMMC ;
* `TIMING_STATUS=REVIEW_REQUIRED` : les rapports temporels doivent encore être examinés ;
* `SIGNOFF_STATUS=NOT_SIGNOFF` : la synthèse ne constitue pas une validation signoff.

---

### `reports/elaboration/check_design.rpt`

**But :** vérifier la cohérence structurelle du design après élaboration.

Points à contrôler :

* références RTL non résolues ;
* cellules ou modules manquants ;
* drivers multiples ;
* connexions incorrectes ou inattendues ;
* latches involontaires ;
* cellules technologiques sans représentation physique LEF.

Une valeur non nulle n'est pas nécessairement bloquante, mais chaque anomalie doit être comprise.

Par exemple :

```text
Libcells with no LEF cell : 1
```

indique qu'une cellule connue dans les bibliothèques logiques Liberty n'a pas de cellule physique correspondante trouvée dans les LEF chargés. Il faut identifier cette cellule et vérifier si elle est réellement utilisée dans la netlist.

---

### `reports/elaboration/report_hierarchy.rpt`

**But :** vérifier la structure du design synthétisé.

Points à regarder :

* top correct : `adder_pipeline` ;
* présence ou disparition des sous-modules ;
* aplatissement éventuel de la hiérarchie.

Après mapping, les instances RTL `full_adder_comb` peuvent être remplacées par des cellules standards et ne plus apparaître comme blocs hiérarchiques.

---

### `reports/timing/report_clocks.rpt`

**But :** vérifier que Genus a correctement interprété les horloges.

Pour ce design, on attend notamment :

```text
clock  : clk
source : clk_i
period : 10000 ps
```

soit une période de `10 ns` et une fréquence cible de `100 MHz`.

Une horloge absente ou incorrecte rend les rapports de timing suivants non pertinents.

---

### `reports/timing/check_timing_intent.rpt`

**But :** vérifier que le design est correctement contraint.

Points à rechercher :

* entrées ou sorties non contraintes ;
* endpoints sans horloge ;
* chemins non contraints ;
* contraintes SDC absentes ou incohérentes ;
* exceptions temporelles inattendues.

Pour `adder_pipeline` :

* `a_i`, `b_i`, `cin_i`, `valid_i` et `rst_ni` doivent être temporisés ;
* `sum_o`, `cout_o` et `valid_o` doivent avoir des contraintes de sortie ;
* `rst_ni` reste temporisé car le reset est synchrone.

---

### `reports/timing/report_timing_bc.rpt`

### `reports/timing/report_timing_tc.rpt`

### `reports/timing/report_timing_wc.rpt`

**But :** examiner les chemins temporels dans les différents corners MMMC.

Les trois corners représentent :

* `BC` : Best Case, cellules relativement rapides ;
* `TC` : Typical Case, conditions nominales ;
* `WC` : Worst Case, cellules relativement lentes.

Pour chaque chemin, regarder principalement :

* `Startpoint` : registre ou port depuis lequel part la donnée ;
* `Endpoint` : registre ou port qui capture la donnée ;
* `Data Path` : temps nécessaire à la donnée pour traverser le chemin ;
* `Required Time` : instant maximal auquel la donnée doit arriver ;
* `Slack` : marge temporelle restante.

Interprétation du slack :

```text
Slack > 0  → timing respecté
Slack = 0  → limite exacte
Slack < 0  → violation temporelle
```

Le premier chemin du rapport est normalement parmi les plus critiques.

Exemple observé dans la vue WC :

```text
Startpoint    : b_q_reg[0]
Endpoint      : cout_o_reg
Data Path     : 7021 ps
Required Time : 9661 ps
Slack         : +2640 ps
```

La contrainte setup est donc respectée avec environ `2.64 ns` de marge.

Pour l'additionneur ripple-carry, un chemin partant d'un bit de poids faible et allant jusqu'à `cout_o` ou à un bit de poids fort de `sum_o` est cohérent : la retenue doit traverser plusieurs niveaux de logique combinatoire.

La comparaison BC / TC / WC permet de visualiser directement l'effet des différents corners technologiques sur les délais.

---

### `reports/qor/report_qor.rpt`

**But :** obtenir un résumé global de la Quality of Results.

Points importants :

#### Timing

* période des différentes vues ;
* `TNS` : Total Negative Slack ;
* nombre de chemins en violation.

Un résultat tel que :

```text
TNS             : 0
Violating Paths : 0
```

indique qu'aucune violation n'est rapportée pour l'analyse concernée.

#### Nombre d'instances

Comparer les résultats avec le RTL.

Pour `adder_pipeline` :

```text
Sequential Instance Count = 100
```

est cohérent avec :

```text
a_q       : 32 registres
b_q       : 32
cin_q      : 1
valid_q    : 1
sum_o     : 32
cout_o     : 1
valid_o    : 1
------------------------
Total     : 100
```

Le nombre d'instances combinatoires indique le nombre de cellules standards utilisées pour implémenter la logique.

#### Fanout

Une valeur comme :

```text
Max Fanout = 100 (clk_i)
```

est cohérente avec les 100 registres pilotés par l'horloge.

À ce stade l'horloge est encore idéale. Le réseau d'horloge réel sera construit plus tard par le CTS dans Innovus.

#### Aire

Les principales valeurs sont :

* `Cell Area` : aire des cellules standards ;
* `Net Area` : estimation de la contribution des interconnexions ;
* `Total Area` : estimation globale.

Ces valeurs constituent surtout une référence permettant de comparer plusieurs synthèses ou plusieurs architectures.

---

### `reports/qor/report_area.rpt`

**But :** obtenir une vue plus détaillée de l'aire.

Points à regarder :

* aire totale des cellules ;
* répartition des cellules ;
* évolution de l'aire entre plusieurs runs.

L'aire est particulièrement utile pour comparer plusieurs implémentations d'un même design.

---

### `outputs/adder_pipeline.mapped.v`

**But :** examiner la netlist réellement produite par Genus.

Le RTL comportemental doit avoir été transformé en instances de cellules technologiques :

```text
RTL SystemVerilog
        ↓
      Genus
        ↓
flip-flops + portes + buffers + cellules complexes
```

Points à vérifier :

* top correct ;
* présence des cellules standards du PDK ;
* présence des registres attendus ;
* absence de logique RTL comportementale non synthétisée.

---

### `outputs/adder_pipeline.mapped.sdc`

**But :** conserver les contraintes temporelles associées au design synthétisé.

Points à retrouver :

* définition de l'horloge ;
* période ;
* input/output delays ;
* uncertainty ;
* autres contraintes nécessaires aux étapes suivantes.

Ce fichier constitue une partie de l'interface entre la synthèse et le flow physique.

---

### Ordre de lecture conseillé

```text
1. stage_status.tsv
2. final_status.rpt
3. check_design.rpt
4. report_clocks.rpt
5. check_timing_intent.rpt
6. report_timing_wc.rpt
7. report_timing_tc.rpt
8. report_timing_bc.rpt
9. report_qor.rpt
10. report_area.rpt
11. adder_pipeline.mapped.v
12. adder_pipeline.mapped.sdc
```

Les trois questions essentielles sont finalement :

1. **Le design est-il correctement lu et contraint ?**
2. **Le timing est-il respecté dans les différentes vues ?**
3. **Quelle netlist, quelle aire et quelle complexité la synthèse a-t-elle produites ?**
