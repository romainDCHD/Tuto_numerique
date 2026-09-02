# SDC minimal pour `registered_ripple_adder`

## Objectif du SDC

Le SDC décrit **l'intention temporelle** du design.

Dans ce tutoriel, le DUT est un ripple-carry adder enregistré :

```text
FF d'entrée -> N full adders -> FF de sortie
```

Le but est de garder la fréquence cible constante et d'augmenter progressivement `N` afin d'observer la dégradation du slack jusqu'à obtenir une violation de setup.

Le même SDC peut être utilisé pendant :

```text
Genus
  -> synthèse

Innovus pré-CTS
  -> horloge encore idéale

Innovus post-CTS
  -> arbre d'horloge réel

Innovus post-route
  -> interconnexions routées et délais RC plus réalistes
```

Le SDC est donc utile **avant et après CTS**. La différence est que l'analyse devient de plus en plus réaliste au fur et à mesure que l'implémentation physique progresse.

---

# SDC retenu

```tcl
# =============================================================================
# Contraintes temporelles - registered_ripple_adder
#
# Objectif :
#
#   FF entree -> N full adders -> FF sortie
#
# Le nombre N pourra etre augmente afin d'observer la degradation du slack
# jusqu'a obtenir une violation de setup.
#
# Horloge unique : clk_i
# Reset : rst_ni est synchrone actif bas.
# =============================================================================

set_units -time        1000ps
set_units -capacitance 1000fF

# 10 ns = 100 MHz
set CLOCK_PERIOD_NS 10.000

# Environnement externe simplifie
set IO_DELAY_MAX_NS 1.000
set IO_DELAY_MIN_NS 0.000

# Marges temporelles
set CLOCK_UNCERTAINTY_SETUP_NS 0.200
set CLOCK_UNCERTAINTY_HOLD_NS  0.050

# Slew suppose des entrees
set INPUT_TRANSITION_NS 0.100

# Charge supposee sur les sorties
set OUTPUT_LOAD_PF 0.050

# Horloge
create_clock \
    -name clk \
    -period $CLOCK_PERIOD_NS \
    [get_ports clk_i]

set_clock_uncertainty \
    -setup $CLOCK_UNCERTAINTY_SETUP_NS \
    [get_clocks clk]

set_clock_uncertainty \
    -hold $CLOCK_UNCERTAINTY_HOLD_NS \
    [get_clocks clk]

# Toutes les entrees sauf clk_i sont temporisees
set data_inputs \
    [remove_from_collection \
        [all_inputs] \
        [get_ports clk_i]]

set_input_delay \
    -clock [get_clocks clk] \
    -max $IO_DELAY_MAX_NS \
    $data_inputs

set_input_delay \
    -clock [get_clocks clk] \
    -min $IO_DELAY_MIN_NS \
    $data_inputs

set_input_transition \
    $INPUT_TRANSITION_NS \
    $data_inputs

# Sorties
set_output_delay \
    -clock [get_clocks clk] \
    -max $IO_DELAY_MAX_NS \
    [all_outputs]

set_output_delay \
    -clock [get_clocks clk] \
    -min $IO_DELAY_MIN_NS \
    [all_outputs]

set_load \
    $OUTPUT_LOAD_PF \
    [all_outputs]
```

---

# Lignes critiques du SDC et choix faits

## 1. Unités

```tcl
set_units -time        1000ps
set_units -capacitance 1000fF
```

Choix retenu :

- `1000 ps = 1 ns`
- `1000 fF = 1 pF`

Ainsi, `-period 10.0` signifie `10 ns`, et `set_load 0.050` signifie `0.050 pF = 50 fF`.

Ces unités concernent l'analyse temporelle. Elles sont indépendantes de :

```systemverilog
`timescale 1ns/1ps
```

Le `timescale` concerne la **simulation** ; `set_units` concerne le **SDC / STA / synthèse / PnR**.

---

## 2. Période d'horloge

```tcl
set CLOCK_PERIOD_NS 10.000
```

puis :

```tcl
create_clock \
    -name clk \
    -period $CLOCK_PERIOD_NS \
    [get_ports clk_i]
```

C'est la contrainte la plus importante de l'expérience.

Une période de `10 ns` correspond à `100 MHz`.

Cette ligne impose que le chemin logique compris entre deux registres respecte cette période.

Pour le chemin étudié :

```text
FF -> FA0 -> FA1 -> ... -> FA(N-1) -> FF
```

on cherche approximativement à respecter :

```text
Tclk >= Tcq + Tcombinatoire + Tsetup + marges
```

Lorsque `N` augmente :

```text
N augmente
    ↓
délai combinatoire augmente
    ↓
slack setup diminue
    ↓
slack ≈ 0
    ↓
limite de fonctionnement
    ↓
slack < 0
    ↓
timing violation
```

Dans l'expérience, **la période reste constante** et seul `N` varie.

---

## 3. Clock uncertainty

```tcl
set CLOCK_UNCERTAINTY_SETUP_NS 0.200
set CLOCK_UNCERTAINTY_HOLD_NS  0.050
```

puis :

```tcl
set_clock_uncertainty \
    -setup $CLOCK_UNCERTAINTY_SETUP_NS \
    [get_clocks clk]

set_clock_uncertainty \
    -hold $CLOCK_UNCERTAINTY_HOLD_NS \
    [get_clocks clk]
```

L'uncertainty réserve une marge sur l'horloge.

Pour le setup, avec `0.2 ns` d'incertitude, on ne considère pas les `10 ns` comme intégralement disponibles.

Cette marge peut représenter de manière simplifiée :

- jitter ;
- variations du clock ;
- marge de conception ;
- approximation pré-CTS.

Le setup est le critère principal de l'expérience `N full adders`.

Le hold est conservé pour garder un SDC cohérent et réutilisable jusqu'au PnR.

---

## 4. Input delay

```tcl
set IO_DELAY_MAX_NS 1.000
set IO_DELAY_MIN_NS 0.000
```

puis :

```tcl
set_input_delay ...
```

Ces contraintes décrivent l'environnement **avant le bloc**.

Elles indiquent que les signaux externes ne sont pas supposés arriver exactement au front d'horloge.

Les entrées temporisées sont notamment :

```text
a_i
b_i
cin_i
rst_ni
```

Le clock `clk_i` est explicitement retiré :

```tcl
set data_inputs \
    [remove_from_collection \
        [all_inputs] \
        [get_ports clk_i]]
```

Le reset `rst_ni` reste temporisé car il est **synchrone actif bas**. On ne met donc volontairement pas de `set_false_path` sur ce reset.

---

## 5. Input transition

```tcl
set INPUT_TRANSITION_NS 0.100
```

puis :

```tcl
set_input_transition \
    $INPUT_TRANSITION_NS \
    $data_inputs
```

Cette contrainte donne une hypothèse sur la vitesse de transition des signaux externes.

Une transition réelle n'est jamais instantanée.

La valeur `0.1 ns` est ici une hypothèse pédagogique simple. Elle influence notamment :

- le délai des cellules ;
- les slews internes ;
- certaines décisions d'optimisation.

---

## 6. Output delay

```tcl
set_output_delay ...
```

Cette contrainte représente le budget temporel réservé au système situé **après notre bloc**.

Dans notre design, elle concerne notamment :

```text
sum_o
cout_o
```

Elle sert surtout pour les chemins :

```text
FF -> port de sortie
```

Elle n'est pas la contrainte principale de notre expérience `N`.

---

## 7. Charge de sortie

```tcl
set OUTPUT_LOAD_PF 0.050
```

puis :

```tcl
set_load \
    $OUTPUT_LOAD_PF \
    [all_outputs]
```

On suppose une charge externe de `0.050 pF = 50 fF` sur les sorties.

Cela évite de considérer qu'elles ne pilotent aucune charge.

Cette valeur influence notamment :

- délai de sortie ;
- slew ;
- choix de taille des cellules pendant la synthèse.

Cette valeur est une **hypothèse pédagogique** et non une valeur intrinsèque du PDK.

---

# Pourquoi `set_clock_transition` a été retiré

L'ancien SDC contenait :

```tcl
set_clock_transition 0.100 [get_clocks clk]
```

Cette commande peut être utile avant CTS pour décrire une transition supposée sur une horloge idéale.

Elle a été retirée du SDC commun afin de simplifier la séparation entre :

```text
intention temporelle
```

et :

```text
résultat physique du clock tree
```

Avant CTS :

```text
clock idéale
```

Après CTS :

```text
clock tree physique
    ↓
insertion delay
skew
slew réel
```

Le SDC reste ainsi simple et réutilisable tout au long du flow.

---

# Pourquoi le SDC reste utile avant CTS

Il serait faux de dire que le SDC n'a de sens qu'après génération du clock tree.

En synthèse, Genus doit connaître `Tclk` pour savoir quelle quantité de logique peut être placée entre deux registres.

Sans :

```tcl
create_clock -period ...
```

il ne sait pas quelle fréquence viser.

Le SDC sert donc déjà pendant :

```text
RTL
 ↓
Genus
 ↓
netlist synthétisée
```

À ce stade, l'horloge est encore idéale et une partie des interconnexions est estimée.

---

# Pourquoi l'analyse post-CTS/post-route est plus réaliste

Après CTS, Innovus connaît réellement la structure du réseau d'horloge :

```text
clock source
    ↓
buffers
    ↓
branches
    ↓
registres
```

Il peut donc prendre en compte notamment :

```text
clock insertion delay
clock skew
clock slew
```

Après routage, il dispose également d'une meilleure estimation des interconnexions et de leurs parasites RC.

On peut résumer :

```text
Synthèse
    ↓
cellules connues
interconnexions estimées
clock idéale

Placement
    ↓
positions physiques connues

CTS
    ↓
clock tree réel

Routage
    ↓
interconnexions réelles
RC plus réalistes
```

L'analyse timing gagne donc progressivement en précision.

---

# Chemin réellement étudié dans le tutoriel

Le chemin principal n'est pas :

```text
entrée -> FF
```

ni :

```text
FF -> sortie
```

mais :

```text
REG -> REG
```

c'est-à-dire :

```text
registre d'entrée
       ↓
     FA0
       ↓
     FA1
       ↓
     ...
       ↓
   FA(N-1)
       ↓
registre de sortie
```

Les `set_input_delay` et `set_output_delay` restent nécessaires pour décrire correctement l'environnement du bloc, mais ils ne pilotent pas directement cette expérience.

La contrainte dominante est :

```tcl
create_clock -period 10.0
```

---

# Expérience prévue avec le ripple-carry

Le niveau initial utilise :

```text
N = 4
```

soit :

```text
FF -> FA0 -> FA1 -> FA2 -> FA3 -> FF
```

Au niveau suivant, `N` devient paramétrable :

```text
FF -> N full adders -> FF
```

On garde toutes les contraintes SDC identiques et on augmente uniquement `N`.

Exemple de lecture des résultats :

| N | Worst setup slack | Résultat |
|---:|---:|---|
| 4 | positif | MET |
| 8 | positif | MET |
| 16 | plus faible | MET |
| Ncrit | proche de zéro | limite |
| Ncrit+1 | négatif | VIOLATED |

Les valeurs réelles doivent être mesurées dans le flow et ne doivent pas être supposées à l'avance.

L'objectif est de déterminer expérimentalement `Nmax` tel que :

```text
setup slack >= 0
```

pour :

```text
Tclk = 10 ns
```

---

# Setup versus hold dans cette expérience

L'augmentation du nombre de full adders augmente principalement le **délai maximal** du chemin combinatoire.

Le phénomène étudié est donc surtout le **setup** :

```text
N augmente
    ↓
max delay augmente
    ↓
setup slack diminue
```

Le hold vérifie au contraire que la donnée n'arrive pas trop rapidement après un front.

Ce n'est pas le mécanisme que l'on cherche à provoquer en augmentant `N`.

Le hold reste néanmoins défini dans le SDC afin de conserver une description temporelle correcte du design.

---

# Choix méthodologique final

Pour rendre l'expérience lisible, on garde constants :

```text
même PDK
même corner
même SDC
même période
mêmes I/O delays
même uncertainty
même charge
```

La seule variable expérimentale est :

```text
N = nombre de full adders dans le ripple-carry
```

Ainsi, si le slack évolue, on peut directement relier cette évolution à l'augmentation de la profondeur logique.

La relation étudiée est :

```text
N ↑
  ↓
profondeur combinatoire ↑
  ↓
délai du chemin critique ↑
  ↓
setup slack ↓
  ↓
timing violation
```

C'est cette expérience qui permet de relier clairement :

```text
RTL
→ synthèse
→ timing
→ placement
→ CTS
→ routage
→ fréquence maximale
```
