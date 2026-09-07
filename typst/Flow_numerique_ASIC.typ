#import "lib.typ": *

#show: template_R.with(
  title: "Prise en main du flow numérique ASIC",
  authors: (
    ("Romain DUCHADEAU", "IP2I / CNRS", "r.duchadeau@ip2i.in2p3.fr"),
  ),
  logos: ("Img/logo_CNRS.jpg", "Img/logo_IP2I.png"), //ex : "Img/logo_CNRS.jpg"
  lang: "fr",
)

// ******************** SECTION ******************** 
// *************************************************
= Introduction

Ce tutoriel s'adresse à un public initié un minimum à l'aise avec linux (étudiant ingénieur ou ingénieur en microélectronique analogique). Il permet une prise en main *concrète* et *rapide* du flow numérique. Ce tutoriel n'a pas pour ambition d'être un guide ultime pour tout comprendre. Pour davantage de détails, il existe de très bonnes ressources sur internet. Parmi elles, la formation "RTL to GDSII" de Cadence ou une très bonne série de vidéo réalisée par Adi Teman dont vous pouvez retrouver le lien #link("https://www.youtube.com/watch?v=GIPhBfenqMc&list=PLZU5hLL_713x0_AV_rVbay0pWmED7992G", "ici") ou le github #link("https://github.com/enics-labs/rtl2gds-demo", "ici").

\
*Note :* Dans ce parcours les encadrés en $#rect(stroke: blue, [#text(fill: blue, [bleu])])$ sont généralement des notes ou des conseils alors que les encadrés en $#rect(stroke: red, [#text(fill: red, [rouge])])$ font référence à des points importants et jalons de progression à ne pas manquer.


\
Le flow numérique (et  a fortiori ce tutoriel) se découpe en trois grandes étapes dont chacune est prise en charge par un outil spécifique \*:

#figure(
  caption: [Méthodologie du flow numérique],
  [#showybox(
  title: [#text(weight: "bold", fill: black, [Etape 1 : Simulation] )],
  title-style: (align: center),
  body-style: (align: center),
  footer-style: (align: center),
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
  footer: "Outil : Xcellium"
)[
  Création des module et *simulation comportementale* / fonctionnelle. A cette étape aucun lien vers un technologie ciblée n'est établie c'est purement des portes logiques sans aspect de timing. Cette étape est elle même sous-divisée en trois étapes : 
  
  *1. Compilation*   $space space$  *2. Élaboration*    $space space$ *3. Simulation*
]

$arrow.b$

#showybox(
  title: [#text(weight: "bold", fill: black, [Etape 2 : Synthèse] )],
  title-style: (align: center),
  body-style: (align: center),
  footer-style: (align: center),
  frame: (
    border-color: olive,
    title-color: olive.lighten(30%),
    body-color: olive.lighten(95%),
    footer-color: olive.lighten(80%)
  ),
  footer: "Outil : Genus"
)[
  A cette étape, on prend le rtl (déjà simulé) et on fait le lien avec la technologie cible pour y introduire des aspects de timing (équivalent des simulations pré-layout). La synthèse va fair le lien entre les portes logiques et le temps de passages dans les gates, les délais etc. propres à la techno. 
]

$arrow.b$

#showybox(
  title: [#text(weight: "bold", fill: black, [Etape 3 : Placement routage (PnR)] )],
  title-style: (align: center),
  body-style: (align: center),
  footer-style: (align: center),
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
  footer: "Outil : Innovus"
)[
  Comme son nom l'indique, placement, routage et simu post-layout. *Innovus* importe la netlist et les vues physiques, construit le floorplan, place les cellules, traite l'horloge si elle existe, route les nets et extrait les parasites. 
]

])<fig-methodologie>


#showybox(
  title: "Note : ",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Chacune de ces étapes est *essentielle*:
  - La simulation répond à des questions fonctionnelles
  - Le STA répond à des questions temporelles
  - Les vérifications physiques répondent aux questions de géométrie et de connectivité.
  
  Ces preuves de fonctionnement sont *complémentaires*.
]

\
*\** Il existe d'autres outils que ceux cités mais ils ne seront pas évoqués dans ce tutoriel. La démarche restant exactement la même d'un outil à l'autre, il faudra simplement réadapter les scripts en cas de changement d'outil.



== Objectif

Pour illustrer les notions vues dans ce tutoriel, nous allons passer ensemble le flow numérique complet (du rtl jusqu'au layout) sur un bloc simple : un additionneur ripple carry 4 bits. 

L'objectif de ce bloc est de faire une simple addition de 4 bits entre deux front d'horloge. Pourquoi les front d'horloge ? Car ceci permet de prendre en main une structure essentielle du flow numérique : un bloc combinatoire (on parle de bloc *combinatoire* quand des opérations sont faites et qu'il n'y a aucune horloge) entre deux *flip flop* (#underline("ie.") bascules) qui font entrer les données sur un front d'horloge et lisent le résultat au front suivant comme illustré sur la @fig-03_circuit_comb:

#v(0.5cm)
#figure(
  image("Img/03_circuit_comb.png", width: 80%),
  caption: [Schema de principe du circuit ],
)<fig-03_circuit_comb>#v(0.5cm)

Ce circuit permet, sans rajouter beaucoup de complexité, d'étudier des problématiques temporelles comme la latence, setup, hold, MMMC, CTS etc...


#v(0.5cm)
#showybox(
  title: [*Méthodologie* : Ne pas mettre la charrue avant les boeufs],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Quand on fait quelque chose de nouveau (a fortiori en microélectronique numérique) la règle d'or est toujours de commencer simple et petit. Commencer petit permet de distinguer une erreur de *méthode* en s'affranchissant des difficultés réelles du design.
]


== Arborescence du dossier du tutoriel


#showybox(
title: "Racine du dossier", 
[Racine principale du git contenant le pdf et README.],
frame: (
    border-color: black,
    title-color: black.lighten(30%),
    body-color: black.lighten(95%),
    footer-color: black.lighten(80%)
  ),
columns(3)[
#showybox(
title-style: (boxed-style: (:)),
title: "dut",
[Dossier contenant les #rouge("fichiers spécifiques") de notre exemple (dut pour design under test). On y retrouve, entre autre :
- Les fichiers rtl, testbench et filelist
- Le dossier _constraints_ : fichiers pour la synthèse
- _design.env_ : variables spécifiques au dut.
],

)

#colbreak()

#showybox(
title-style: (boxed-style: (:)),
title: "config",
[Contient les fichiers de config liés au pdk / Cadence. Sert à faire le lien entre les scripts génériques et la #rouge[config propre au labo].]
)


#colbreak()
#showybox(
title-style: (boxed-style: (:)),
title: "flow",
[ On retrouve les scripts #rouge("génériques") permettant de lancer les $!=$ parties du flow découpé en 3 étapes elles même découpées par niveau:
- 01_simulation
- 02_synthesis
- 03_pnr

Ces scripts sont pensés pour être *réutilisables* dans d'autres contextes que ce tuto.]
)
]
)


#v(0.5cm)
#showybox(
  title: [#text(fill: black, weight: "bold", [*Arborescence*])],
  frame: (
    border-color: red,
    title-color: red.lighten(40%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  En microélectronique numérique il est nécessaire d'être *très au clair* avec l’arborescence des fichiers et des dossier. Il est important de définir *dès le départ* une structure claire. 

  \
  Pour des raisons de répétabilité et de modularité, les scripts ne seront jamais écrits avec des PATH en dur mais seront toujours écrits en utilisant des PATH *absolus* chargés à partir de fichiers spécifiques. 

  \
  La logique ici est que tous les fichiers spécifiques au dut soient dans le dossier _dut_ tandis que les scripts dans _flow_ sont *génériques* et utilisent des PATH ou variables définies dans _config_ et _dut_.
  
  \
  La logique ici est de #rouge[toujours lancer les scripts dans le dossier "workdir" de chaque partie]. Il y a d'autres façons de procéder mais c'est la plus courante. 
]

== Approche pédagogique : méthode en plusieurs niveaux d'abstraction

Chaque chapitre montre d'abord:
1. L'appel direct à l'outil (quand c'est possible) avec une *commande minimale*. C'est le coeur de l'utilisation de l'outil et c'est ce qui sera appelé par les scripts dans la suite donc il est très important de bien maîtriser cette étape.
2. Dans un second temps, on utilise un script (wrapper) pour effectuer des vérifications, lancer la commande minimale, choisir un dossier de résultats et donner le résultat de manière structurée. En pratique, on utilise uniquement ce genre de script en microélectronique numérique car ils permettent de *gagner du temps*, d'*éviter les erreurs*, de *contrôler l'environnement de travail* et sont *réutilisables* et permettent donc à quelqu'un d'autre de l'utiliser et de détecter une potentielle erreur dans notre code.


#v(0.5cm)
#showybox(
  title: [*Méthodologie* : Ne pas automatiser une erreur],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Un script plus long ne corrige pas une mauvaise filelist, un top incorrect ou un SDC incomplet.
  
  *$->$ La commande minimale doit être comprise et validée avant d'ajouter l'automatisation.*
]


== Informations pratiques
// infos 
#rouge("Disclimer: ")Les commandes Cadence sont fondées sur les références installées #footnote[Xcelium Logic Simulation — Command-Line and Tcl Reference. Consulter la version installée et autorisée du laboratoire. Cadence Design Systems.] #footnote[Genus Synthesis Solution — User Guide and Command Reference. Consulter la version installée et autorisée du laboratoire. Cadence Design Systems] #footnote[ Innovus Implementation System — User Guide and Command Reference. Consulter la version installée et autorisée du laboratoire. Cadence Design Systems.]. Leur disponibilité et leur syntaxe exacte doivent être confirmées dans l'environnement du laboratoire

Tout au long du tutoriel, on considère que l'environnement Cadence est chargé et que les commandes de lancement des outils `xrun, genus, innovus` sont chargées 

\
#rouge("Disclimer 2 : ")La microélectronique numérique est une discipline qui fourmille de détails et de cas particuliers. On pourrait écrire 300 pages d'explications simplement sur la synthèse. Ce n'est pas l'objectif ici. Ce tutoriel permet de voir *en surface* les étapes du flow numériques. Il permet de comprendre comment les choses s'imbriquent entre elles et il constitue un bon point de départ pour comprendre le flow numérique dans sa globalité mais il *n'est pas suffisant* pour former un bon numéricien. Il est nécessaire par la suite d'approfondir les notions.


// ******************** SECTION ******************** 
// *************************************************
= Etape 1 : Simulation RTL - outil Xcelium <sec-simu_rtl>
// ----------------- SOUS-SECTION ------------------ 



Cette première étape du flow se décompose elle même en trois phases (cf. @fig-methodologie):
1. *Compilation* : Lecture du SystemVerilog et contrôle de syntaxe.
2. *Élaboration* : Construction de la hiérarchie et résolution des modules, paramètres et ports.
3. *Simulation* : Exécution des blocs temporels et production du verdict du testbench.

\
Dans la pratique, ces trois phases seront effectuées en *même temps* pas Xcellium.

#showybox(
  title: "Note : Erreurs courantes de la simulation",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Généralement, une *erreur de syntaxe* appartient à la *compilation*. Un *top inconnu* ou un port impossible appartient à l'*élaboration*. Un `$fatal`, un timeout ou une comparaison incorrecte appartient à la *simulation*.
]

== Entrées et sorties
Voici les entrées sorties attendues pour cette phase de simulation :

#figure(
[#table(
  columns: (auto, auto, auto),
  inset: 5pt,
  align: center,
  fill: (x, y) => if y == 0 {silver}
  else if y < 3 {green.lighten(80%)}
  else if y >= 3 {orange.lighten(80%)},
  table.header(
    [*Élément*], [*Exemple*], [*Rôle*],
  ),
  [RTL], [`full_adder_comb.sv`], [Description logique synthétisable],
  [Filelist], [`rtl.f`], [Ordre et chemins des sources],
  [Rapport], [`.sh` ou `.log`], [Rapport de sortie de la simulation (balises PASS ou FAIL)],
)],
caption: [Entrées sorties de la phase de simulation (#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]))]
)<tab_elements_simu>

\
On peut noter qu'il n'y a pas de sortie à proprement parler pour la simulation car la simulation ne produit pas de fichier, elle sert simplement à vérifier le bon fonctionnement de note module. Notre "sortie" est donc le verdict des scripts.

// -------------------  SOUS - SECTION ------------------- 
==  Niveau 1 : Commande Xcelium minimale
#columns(2, gutter: 2pt)[
  #rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Fichier* : dut/rtl/full_adder_comb.sv])

  #colbreak()

  #rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier d'execution* : flow/01_simulation/workdir])
]
Dans ce niveau, nous nous intéressons au module full_adder_comb.
Module très simple et purement combinatoire (sans clock). La première étape consiste à savoir ce qu'on veut que le module fasse. Cette étape passe souvent par écrire une *machine à état* ou une *table de vérité* pour être au clair sur les fonctions *précises* du module. 
=== Définition du contrat logique


Pour les entrées `a`, `b` et `c_in` :

- `sum = a XOR b XOR c_in`
- `c_out = ab + ac_in + bc_in`


#figure(
[#table(
  columns: (auto, auto, auto, auto, auto),
  inset: 5pt,
  align: center,
  fill : (x,y) => if y ==0 {silver},
  table.header(
    [*a*], [*b*], [*$c_{in}$*], [*sum*], [*$c_"out"$*],
  ),
  [0], [0], [0], [0], [0],
  [0], [0], [1], [1], [0],
  [0], [1], [0], [1], [0],
  [0], [1], [1], [0], [1],
  [1], [0], [0], [1], [0],
  [1], [0], [1], [0], [1],
  [1], [1], [0], [0], [1],
  [1], [1], [1], [1], [1],
)],
caption:[Table de vérité du full adder combinatoire]
)<tab_full_adder_comb>

=== RTL du full adder et de son testbench
*Deuxième étape* : on écrit le comportement du module en RTL (verilog, systemverilog ou vhdl). Ici, cela donne :
#codly(footer: [*full_adder_comb.sv*], breakable: false)
#deixis-attach(
```sv
aaaar4bbbb`timescale 1ns/1psaaaar5bbbb

// Additionneur complet combinatoire sur un bit.
//
// Les equations sont ecrites explicitement afin que le lien entre la table
// de verite, le RTL et les portes obtenues apres synthese reste visible.
aaaar0bbbbmodule full_adder_comb (
    input  logic a_i,
    input  logic b_i,
    input  logic cin_i,
    output logic sum_o,
    output logic cout_o
);                       aaaar1bbbb

    aaaar2bbbbassign sum_o  = a_i ^ b_i ^ cin_i;
    assign cout_o = (a_i & b_i) | (a_i & cin_i) | (b_i & cin_i);aaaar3bbbb

endmodule
```)

#deixis-inset-note(
  pins: ("r0", "r1"),
  marker: none,
  stroke: (rest: red, link: stroke(paint: red, thickness: 1pt, dash: "dashed")),
  fill: red.transparentize(95%),
  link: "curve",
  link-ports: (mark: right, body: left),
  link-marks: "body",
  dx: 4em,
  dy: -1em,
)[
  #text(size: 10pt, [Déclaration du module avec *nom* + *Entrées/sorties*])
]

#deixis-inset-note(
  pins: ("r2", "r3"),
  marker: none,
  stroke: (rest: green, link: stroke(paint: green, thickness: 1pt, dash: "dashed")),
  fill: green.transparentize(95%),
  link: "curve",
  link-ports: (mark: right, body: left),
  link-marks: "body",
  dx: 2em,
  dy: -1em,
)[
  #text(size: 10pt, [Ce que fait le module])
]

#deixis-inset-note(
  pins: ("r4", "r5"),
  marker: none,
  stroke: (rest: blue, link: stroke(paint: blue, thickness: 1pt, dash: "dashed")),
  fill: blue.transparentize(95%),
  link: "curve",
  link-ports: (mark: right, body: left),
  link-marks: "body",
  dx: 4em,
  dy: 0em,
)[
  #text(size: 10pt, "Définition d'un pas de simulation*")
]

\* Les deux valeurs correspondent à:
- 1ns  = unité de temps (si on met un délais de "#10" dans le module cela signifiera alors 10 *x 1ns*)
- 1ps  = précision temporelle / pas du simulateur (le simulateur peut distinguer les événements avec une résolution de 1 ps)


*Note* : Le DUT ne contient aucun délai, bloc `initial` ou appel système car c'est un bloc asynchrone (#underline("ie.") purement combinatoire).

// -------------------  SOUS - SECTION -------------------
=== Testbench du full adder comb
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Fichier* : dut/rtl/tb_full_adder_comb.sv])

De la même manière que un module, un testbench est aussi un module RTL qui comprend le module a tester ainsi que les entrée sorties commandées permettant de faire le test (exactement comme en analogique). Le rôle du testbench est également de faire ressortir des *marqueurs* (#text(fill: green,weight: "bold" ,[PASS]) ou #rouge[FAIL]) pour vérifier le bon fonctionnement comportemental de note module / DUT. 


#showybox(
  title: "Note : Retrouver les codes sources",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Pour des raisons de lisibilité, les codes abordés dans ce tutoriel se situent en annexe de ce document.
]



=== La simulation - Niveau 1 : commande minimale 
Une fois le RTL du full adder et de son testbench écrits (et qu'on a donc une description comportementale de nos modules), il faut effectuer la simulation. Pour ce faire on execute (après avoir chargé Cadence et les outils) *depuis le dossier "01_simulation_minimal" de la simulation*:


#codly(stroke: 1pt + red)
```bash
xrun -64bit -sv -timescale 1ns/1ps \
   ../../../dut/rtl/full_adder_comb.sv  \
   ../../../dut/rtl/tbfull_adder_comb.sv  \
   -top tb_full_adder_comb
```
#codly(stroke: 1pt + gray)

\
* Explication de la commande* : 
- *`-64bit`* : Utilise l'exécutable 64 bits.
- *`-sv`* : Active SystemVerilog (normalement on peut s'en passer car Xcellium est sensé reconnaître l'extension .sv mais cf note plus bas).
- *`-timescale`* : Fixe l'unité et la précision par défaut si un module n'a rien de spécifié (sinon utilisation du timescale du module).
- *`*.sv`* : Module ou sous module a simuler.
- *`-top`* : Choisit le top élaboré (#underline("ie.") le module le plus haut dans la hiérarchie).

\
#showybox(
  title: "Note : Spécifications de commandes",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  En règle générale, il vaut mieux éviter de penser que "l'outil va comprendre tout seul". Effectivement, certaines choses sont prisent en compte automatiquement et on a vite fait de se dire qu'on ne va pas rajouter l'option "x" car ça alourdi inutilement. C'est #rouge[une erreur]. Plus on spécifie de chose, plus on est certain que ça fait ce qu'on veut. Cette approche évite de chercher (longtemps) une erreur bête alors que c'est simplement un problème d'appel mal compris pas l'outil (valable pour tous les outils du flow).
]


On s'attend a voir dans la sortie quelque chose comme:
```sh
xcelium> run
TEST_PASS: full_adder_comb
```

\ *Super, notre module est fonctionnel !* 

On peut voir en tapant *`"ls"`* que trois choses sont apparues :
- *Dossier xcelium.d* :	Base de compilation et d'élaboration de Xcelium. Elle contient notamment le snapshot simulable et les données internes utilisées par Xrun.
- *xrun.log*	: Journal texte de la compilation, de l'élaboration et de la simulation.
- *xrun.history* :	Historique interne des invocations Xrun, utilisé par les fonctions d'historique et de rejeu de commandes.

Dans notre cas nous n'en avons plus besoin on peut donc les supprimer: 
```bash
rm -rf x*
```
$->$ Le full adder purement combinatoire fonctionne. On va pouvoir l'utiliser dans notre module de full adder pipeliné! Passons au niveau 2.


#showybox(
  title: "Note : Architecture de fichier",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il est important de bien avoir en tête d'où on lance le script et donc d'où partent les chemins relatifs!!! Chaque designer a son architecture de fichier et ses habitudes. La méthode ici consiste à toujours lancer la commande depuis la *racine du projet* et a adapter les chemins relatif à ce point de départ plutôt que l'inverse.
]

// -------------------  SOUS - SECTION ------------------- 
== Niveau 2 : Utiliser les filelists
Pour ce niveau et #rouge("dans toute la suite du tutoriel"), nous nous intéresserons au module ripple_carry_4. Autrement dit, a partir de maintenant nous laissons de côté la sous-brique full_adder_comb pour ne s'intéresser qu'au ripple_carry_4.

=== Contrat logique du ripple carry 
Dans un premier temps, il est important de comprendre ce que fait notre module:

#v(0.5cm)
#figure(
  image("Img/04_ripple_carry_contrat_logique.png", width: 100%),
  caption: [Contrat logique du ripple_carry_4 [généré pas ChatGPT]],
)<fig-04_ripple_carry_contrat_logique>#v(0.5cm)

=== Les filelists

Comme nous pouvons le voir sur la @fig-04_ripple_carry_contrat_logique, le module ripple_carry_4 contient le sous-module full_adder_comb (en plusieurs instances). Pour la simulation, on peut executer xrun individuellement pour chaque DUT et chaque testbench (comme avec le niveau 1) mais une bonne pratique si on a beaucoup de fichiers RTL est d'utiliser une filelist (extension en $#rect(fill: colors.code-bg, [.f])$) pour définir *dans quel ordre* procéder à l'élaboration et qu'on ai pas de problèmes de dépendances non résolues à cause d'un mauvais ordre. Par ailleurs, ces filelists seront #rouge("nécessaires pour les étapes suivantes") donc autant les implémenter dès maintenant.

#showybox(
  title: "Note : Utilisation des filelists",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  L'utilisation des filelists n'est pas *un passage obligatoire*. Certaines personnes utilisent des scripts ou il appellent chaque module séparément comme dans le niveau 1.
]

#showybox(
title: [#text(weight: "bold", fill: black, [À retenir : Séparer les rtl des tb] )],
frame: (
  border-color: red,
  title-color: red.lighten(30%),
  body-color: red.lighten(95%),
  footer-color: red.lighten(80%)
),
)[
  Il est #rouge("primordial") de séparer les .f des modules DUT (dans le dossier *rtl*) et des testbench en deux fichiers distincts. En effet, les filelists rtl.f seront *réutilisées* par la suite dans les phases de synthèse et de pnr et ne servent pas seulement pour la simulation.
]

\
C'est le moment de parler d'une notion importante : Dans la suite du tutoriel tous les chemins seront indiqués #rouge[relativement à la racine du tutoriel]. Pour ce faire on va définir une variable d'environnement qui va nous permettre de spécifier le chemin *absolu* de la racine du tutoriel : 

#codly(stroke: 1pt + red)
```bash
export DESIGN_PATH=/chemin/vers/la/racine/du/dossier
```
#codly(stroke: 1pt + gray)

Maintenant, a chaque fois qu'on va appeler \$DESIGN_PATH le code va pourvoir retrouver le chemin depuis n'importe quel répertoire d'execution (car chemin absolu).


Voici, par exemple, ce que contient la filelist rtl.f : 

#codly(footer: [*rtl.f*], breakable: false)
```txt
$DESIGN_PATH/dut/rtl/full_adder_comb.sv
$DESIGN_PATH/dut/rtl/ripple_carry_4.sv
```
C'est simplement une liste de tous les modules à élaborer et simuler.
Une fois les filelists écrites on peut lancer (toujours depuis le dossier "01_simulation_minimal"):

#codly(stroke: 1pt + red)
```bash
xrun -64bit \
  -sv  \
  -access +rwc \
  -gui \
  -timescale 1ns/1ps \
  -f $DESIGN_PATH/dut/filelists/rtl.f \
  -f $DESIGN_PATH/dut/filelists/tb.f \
  -top tb_ripple_carry_4
  -mess
```
#codly(stroke: 1pt + gray)

* Explication de la commande* :
- *`-access +rwc`* : Donne les droits de prober tous les signaux dans la hiérarchie du design.
- *`-gui`* : Ouvre la vue graphique
- *`-f`* : Lit une filelist.
- *`-mess`* : Affiche tous les messages en détail


=== Utilisr la vue graphique
Cette fois, avec l'option *`-gui`*, la vue graphique s'ouvre et on peut visualiser les résultats de simulation:

#v(0.5cm)
#figure(
  image("Img/05_xcelium_1.png", width: 60%),
  caption: [Simvision fenêtre 1],
)<fig-05_xcelium_1>#v(0.5cm)

 Après ouverture de la waveform cette fenêtre apparait:

#v(0.5cm)
#figure(
  image("Img/05_xcelium_2.png", width: 90%),
  caption: [Simvision fenêtre 1],
)<fig-05_xcelium_2>#v(0.5cm)

Si d'aventure nous avions des problèmes de simulation, cette vue graphique est un outils essentiel pour comprendre pourquoi tel ou tel signaux n'est pas dans l'état attendu.

\
#showybox(
  title: "Note : Utilisation de l'interface graphique",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Dans l'idée, on évite d'utiliser l'interface graphique et on ne l'ouvre *que pour du debuggage* si le testbench revoie #rouge[FAILED].
]

=== Ouverture de simulations précédentes
On peut remarquer que cette fois, en plus de ce que xcellium à généré au niveau 1, on a un dossier *`waves.shm`* qui s'est créé. Ce dossier contient toutes les wavesformes (les signaux temporels) qui ont été créés. C'est en réalité ces signaux qu'on a affichés en @fig-05_xcelium_2 et il est possible de les visualiser après coup en tappant : 
```bash
simvision waves.shm
```
Une fenêtre va s'ouvrir et il est alors possible de consulter les signaux. Une autre chose intéressante à consulter est la *netlist générée*. La consulter permet de vérifier que ce que nous avions en tête est bien conforme à ce qui va être synthétisé par la suite. Pour l'ouvrir :  

#v(0.5cm)
#figure(
  image("Img/06_1_simvision_setup.png", width: 40%),
  caption: [Simvision : ouverture de la netlist],
)<fig-06_1_simvision_setup>#v(0.5cm)

Puis une fenêtre s'ouvre et en double-clickant sur les modules on peut rentrer dedans. On peut alors visionner nos différents modules : 
#v(0.5cm)
#figure(
  image("Img/06_2_simvision_tb.png", width: 100%),
  caption: [Simvision : Module du tesbench],
)<fig-06_2_simvision_tb>#v(0.5cm)

La @fig-06_2_simvision_tb illustre bien le fait que notre testbench est un module qui *encapsule le dut* et qui comprend d'autres modules pour gérer les entrées et sorties attendues. On peut rentrer dans le dut et cela donne : 
#v(0.5cm)
#figure(
  image("Img/06_3_simvision_ripple_carry.png", width: 100%),
  caption: [Simvision : Module ripple_carry],
)<fig-06_3_simvision_ripple_carry>#v(0.5cm)

Sur la @fig-06_3_simvision_ripple_carry on voit bien les full adder combinatoires (en #rouge[rouge]) dont les entrées/sorties sont clockées par des bascules D (en #text(fill: purple, weight: "bold", "violet")).
Enfin, on peut également visualiser l'intérieur de nos full adder composés de portes logiques: 
#v(0.5cm)
#figure(
  image("Img/06_4_simvision_adder.png", width: 100%),
  caption: [Simvision : Module full adder],
)<fig-06_4_simvision_adder>#v(0.5cm)
\
De la même manière, Xcelium va mettre ses fichiers dans le répertoire d'execution, si il n'y a pas d'erreurs, nous n'en avons plus besoin: 
```bash
rm -rf x* waves.shm
```



== Niveau 3 : Wrapper réutilisable
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/01_simulation/02_simulation_gate_level])


Comme déjà mensionné précédemment, en pratique, on ne va pas lancer les commandes à la main à chaque fois car:
1. Ça peut être source d'erreur.
2. Il nous faut avoir un flow répétable et qu'on puisse facilement relancer. 

C'est pourquoi on va privilégier l'utilisation d'un wrapper qui va tout automatiser pour nous. 

\
La encore, il y a autant de façon de faire que de designer mais nous allons ici voir la méthode la plus couramment utilisée : le makefile.

Nous n'allons pas revenir ici sur ce qu'est un makefile ni comment l'utiliser mais ce qu'il fait comprendre c'est qu'il permet de lancer une suite d'instruction en utilisant la balise associée. Ici par exemple, on peut lancer la simulation avec environnement graphique en faisant :
```bash
make run_sim
```

#rouge("Attention :") Il faut bien avoir en tête qu'il le makefile utilisé est relativement simple et qu'il faut bien veiller à exporter les PATH corrects et pointer vers les bons fichiers RTL #rouge[dans le bon ordre] pour que ça fonctionne.

\
Ensuite, une fois la simulation finie et analysée, nous pouvons nettoyer le répertoire de run avec :
```bash
make clean
```

et relancer en vue non graphique avec :
```bash
make run_sim_no_gui
```



\
#showybox(
  title: "Note : Utilisation de script shell (.sh)",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Une autre méthode couramment utilisée pour automatiser la simulation est l'utilisation de scripts shell plus ou moins complexes permettant de mettre à jours les dut facilement, ranger des résultats dans des dossiers séparés, Vérifer si tous les tesbench sont fonctionnels ect..
  
  Ici, nous préférons utiliser le makefile car beaucoup plus simple a prendre en main et beaucoup plus proche de l'utilisation de la commande directe. 
]


#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : Export dans un script] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Si on fait "`export PATH_CUSTOM=/le/chemin`" dans un programme shell (ex: run_sim.sh) et qu'on l'exectute avec la commande *bash* la variable PATH_CUSTOM sera détruite à la fin de l'execution du programme. Pour éviter le l'exporter à chaque fois il vaut mieux faire l'export dans le terminale directement plutôt que dans le script.
]

\
Nous allons revenir sur la simulation gate level dans la @sec_simu_gate_level.

\
Maintenant que nous avons simulés notre DUT, nous pouvons passer à synthèse.

// ******************** SECTION ******************** 
// *************************************************
= Etape 2 : Synthèse logique - Outil Genus
La deuxième étape de ce parcours du combatant est donc la synthèse. C'est à cette étape que le lien avec la technologie cible va s'effectuer. Cette étape est plus complexe que la précédente car il va falloir correctement établir le lien avec le pdk et qu'il y a davantage de paramètres à prendre en compte.

\
En pratique, Genus transforme un *RTL* en une *netlist composée de cellules de la bibliothèque cible*.
Il optimise la logique sous les contraintes de :
- Timing
- Aire
- Transition
- Fanout
- Charge

\
Comme pour la simulation, l'outil Genus va réaliser plusieurs étapes d'un seul coup parmis elles ont peut citer les plus importantes :

#figure(
[#table(
  columns: (auto, auto),
  inset: 5pt,
  align: left,
  fill: (x, y) => if y == 0 {silver},
  table.header(
    [*Etape*], [*Description*],
  ),
  [1], [Lire le RTL, l'élaborer et comprendre le SDC],
  [2], [Exécuter *`syn_generic`* : transforme le RTL en logique générique et simplifie les expressions],
  [3], [Exécuter *`syn_map`* : choisit des cellules disponibles dans la Liberty],
  [4], [Exécuter *`syn_opt`* : améliore timing, aire et règles électriques selon l'effort demandé],
  [5], [Générer les rapports et les deux fichiers nécessaires à Innovus],
)],
caption: [Etapes clés réalisées lors de la synthèse]
)<tab_etapes_syn>

== Entrées et sorties
Dans un premier temps il est primordial de comprendre ce dont on a besoin pour lancer la synthèse et quels sont les fichiers en sortie de synthèse :


#figure(
[#table(
  columns: (auto, auto, auto),
  inset: 5pt,
  align: center,
  fill: (x, y) => if y == 0 {silver}
  else if y < 6 {green.lighten(80%)}
  else if y >= 6 {orange.lighten(80%)},
  table.header(
    [*Élément*], [*Exemple*], [*Rôle*],
  ),
  [RTL], [`ripple_carry_4.sv`], [Description logique synthétisable],
  [Filelist], [`rtl.f`], [Ordre et chemins des sources],
  [Contraintes], [`constraints.sdc`], [Clocks, délais d'E/S et exceptions],
  [Liberty], [`stdcells_tc.lib`], [Fonctions, arcs, délais et puissance],
  [Environnement], [`conf_ihp130.env`], [Chemin absolu des fichiers ],
  [Netlist mappée], [`ripple_carry_4_netlist.v`], [Netlist avec cellules du PDK],
  [SDC exporté], [`ripple_carry_4_sdc.sdc`], [Contraintes de timing mappées],
  [Fichiers SDF], [`ripple_carry_4_delay.sdf`], [Extraction de parasites],
  [Rapports], [`report_timing.rpt`, `report_area.rpt`, `report_qor.rpt`], [Preuves à examiner],
)],
caption: [#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]) de la minimales de la synthèse logique]
)<tab_elements_synthese>

\ 
#showybox(
  title: [#text(weight: "bold", fill: black, [Note importante : Il n'y a QUE des cas particuliers] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Les entrées sorties présentées ici permettent d'aller au bout du flow mais il en existe d'autres! Il est donc possible de rajouter des entrées/sorties supplémentaires comme les lef en entrée, mmmc en sortie ect. dépendamment du type de flow, du pdk, de l'outil etc...

  \
  Il y a autant de manière de faire que de designer / outil / pdk etc.. Ici, ce qui est donc important c'est de #rouge[comprendre la philosophie], les briques élémentaires qu'on retrouve dans tous les types de flow.
]

\
On ne va pas revenir sur ce que sont les fichiers `.sv` et `.f` mais voici une rapide description des autres entrées :

\
- *Fichiers .env (variables d'environnement)* : C'est un fichier de définition de variables que l'on va utiliser dans les différents scripts pour la synthèse et le PnR. Ces fichiers permettent d'écrire des scripts génériques utilisant des variables comme _\$FICHIER_SDC_ qu'on va définir une bonne fois pour toute dans les *.env* plutôt que d'écrire le PATH à la main dans chaque fichier et devoir tout changer partout au moindre changement de techo ou de dut.

\
- *Fichier SDC (Synopsys Design Constraint):* Le fichier qui va définir les contraintes de timing à respecter pour notre design. Genus a besoin du SDC pour savoir quelle fréquence il doit viser pendant la synthèse. 

#TODO("Si il voit que le timing n'est pas respecté, il se passe quoi?")

#showybox(
  title: [*Note* : Pourquoi un fichier .sdc en entrée et un autre en sortie ?],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Le fichier .sdc en *entrée* indique Le budget disponible pour un chemin entrée-vers-sortie est approximativement : [*période - délai d'entrée - délai de sortie - marges internes*]. Il correspond à un objectif théorique mais n'est pas lié à la techno ciblé ni aux cellules utilisées. Il est uniquement dépedant du *cahier des charges*.
 
  \
  Le fichier .sdc de sortie donne le budget de temps *en utilisant les cellules du pdk*. Il va définir très précisément quelle est la deadline pour que telle ou tellle cellule reçoive ou envoie son signal. C'est un fichier à fournir à Innovus pour le PnR afin qu'il sache après placement routage si le timing est toujours respecté.
]

\
- *Fichiers .lib (liberty)* : Ce sont les fichiers du PDK qui définissent les caractéristiques des cellules de la technologie cible. Ces fichiers répertorient les temps de passage dans chaque cellule. Il existe 3 types de liberty:
 
 -- tc ou tt pour typical (#underline("ie.") le temps moyen de passage dans la cellule)
 
 -- wc ou ss pour worst case / slow slow (temps le plus lent) 

 -- bc ou ff pour best case / fast fast (temps le plus rapide) 

\
- *Fichier SDF (Standard Delay Format) * : [optionnel mais fortement recommandé] - Fichier nécessaire à Innovus pour l'extraction de parasytes dans la phase de PnR. 

#TODO("on peut aussi donner à Xcellium non? Autres explications")
 

== Niveau 0 : L'appel direct $->$ mauvaise idée

Comme il y a beaucoup d'étapes à effectuer lors de la synthèse, un appel direct à l'outil n'est pas recommandé car genus prend énormément de paramètres. Un exemple d'appel direct à genus pourrait être : 

```bash
genus -no_gui \
     -execute "read_hdl -sv chemin/vers/ripple_carry_4.sv" \
     -execute "elaborate ripple_carry_4" \
     -execute "read_sdc chemin/vers/ripple_carry_4.sdc" \
     -execute "syn_generic" \
     -execute "syn_map" \
     -execute "syn_opt" \
     -execute "write_hdl -hier > chemin/vers/ripple_carry_4.mapped.v" \
     -execute "write_sdc > chemin/vers/ripple_carry_4.mapped.sdc" \
     -log genus.log
```
*Note* : Ce code est donné à tire d'exemple. L'appel direct à genus ne fonctionne pas en l'état (mauvais chemin etc.)

\
*Explications de la commande :*

On retrouve les grandes étapes répertoriées dans la @tab_elements_synthese :
1. *`read_hdl`* : compile les sources
2. *`elaborate`* : construit la hiérarchie et résout les paramètres
3. *`read_sdc`* : applique l'intention de timing
4. *`syn_generic`* : transforme le RTL en logique générique et simplifie les expressions
5. *`syn_map`* : choisit des cellules disponibles dans la Liberty
6. *`syn_opt`* : améliore timing, aire et règles électriques selon l'effort demandé
7. *Rapports* : qualifient le résultat
8. *Exports* : alimentent Innovus

\
*Inconvénients de procéder ainsi:*
- Chemins relatifs en dur $->$ peu portable, source d'erreur.
- Pas de gestion d'erreur (si une étape échoue, Genus continue).
- Pas de rapports (pas de report_timing.rpt, etc.)
- Pas de répertoire de travail avec des sorties bien rangées.
- Et sourtout #rouge("incomplet !"). Il manque beaucoup de choses et de paramètres pour que la synthèse aboutisse.

\
*Conclusion* : C'est une #rouge("mauvaise méthode"). 

\
#showybox(
  title: [*Note importante* : Etapes de la synthèse],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  On peut voir sur l'appel direct les #rouge("étapes clés indispensables") pour réaliser la synthèse. Evidemment, beaucoup de paramètres supplémentaires sont à ajouter pour affiner la synthèse mais l'essentiel est là. 

  \
  Ici, nous avons un DUT simple et donc nous pouvons *regrouper* les étapes de la synthèse en un seul fichier. Cependant, il est courant de *séparer* les différentes étapes de la synthèse (syn_generic, syn_map, syn_opt ect.) en *plusieurs fichiers* pour vérifier qu'ils marchent et les optimiser un par un.
]

== Niveau 1 : Commande et Tcl minimale
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/02_synthesis/01_syn_minimal/])

On vient de le voir, contrairement à la simulation, Genus nécessite d'être configuré pour correctement fonctionner. En effet, il y a davantage d'étapes : le lien avec le PDK, les différents fichiers `.f`, `.sdc` etc. et tout ceci nésessite des scripts pour être fait correctement et dans le bon ordre. 

\
*1ère étape :* se mettre dans le dossier de travail et exporter le DESIGN_PATH: 
```bash
cd flow/02_synthesis_genus/01_syn_minimal/workdir/
export DESIGN_PATH=/chemin/vers/la/racine/du/dossier
```

\
Le language de script qui va nous permettre de configurer genus est le *`.tcl`*. C'est dans ce fichier qu'on va renseigner ce que genus dois faire et dans quel ordre. Pour lancer genus en utilisant le fichier `.tcl` de configuration la commande minimale est :

\
```bash
genus -legacy_ui \
-file ../syn_minimal.tcl \
-log ./logs/genus
```

* Explication de la commande* : 
- *`-legacy_ui`* : Ouvre Genus en mode *legacy* (il reconnait alors les commandes utilisées dans le script).
- *`-file`* : Permet de dire quel fichier de script utiliser.
- *`-log`* : Permet de spécifier ou ranger ses fichiers de log et quel nom leurs donner (non essentiel dans l'absolu mais recommandé).


\
#showybox(
  title: [*Note* :],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Si la variable DESGN_PATH n'a pas été exportée, on devrait avoir une sortie proche de : 
  ```sh
  can't read "::env(DESIGN_PATH)": no such element in array
  Encountered problems processing file: flow/02_synthesis/01_syn_minimal/syn_minimal.tcl
  ```
]

=== Comment le script fonctionne
Le script de la synthèse effectue 2 opérations principales : 
1. Aller chercher les variables spécifiques au projet et au pdk
2. Executer ligne par ligne les étapes de la synthèse.

\
Voici un petit schema des imbrications d'appels:

\
#figure(
[#showybox(
title: [#text(fill: black, "Terminal")], 
frame: (
    border-color: gray,
    title-color: gray.lighten(20%),
    body-color: gray.lighten(80%),
    footer-color: gray.lighten(80%)
  ),
[Terminal d'ou est lancé la commande genus. Les outils cadence sont sourcées (les commandes *xrun, genus, innovus* par exemple sont accessibles) ainsi que la variable *\$DESIGN_PATH* définie par la commande $#rect(radius: 5pt, fill: white, "export DESIGN_PATH=/chemin/vers/la/racine/du/dossier")$


#showybox(
title-style: (boxed-style: (:)),
frame: (
  title-color: green.lighten(50%),
  border-color: green,
  body-color: green.lighten(95%)
  ),
title: [#text(fill: black, "genus")],
[ Genus execute *ligne par ligne* les commandes du script. Il commence par charger les variables d'environnement utilisés pour la simulation (ex : *\$GENUS_SDC*) qui sont définies dans les deux fichiers *.env*:
1. Le fichier qui défini toutes les variables liées à la techno utilisée : \$env(DESIGN_PATH)/config/conf_ihp130.lib. On y retrouve par exemple :
$#rect(radius: 5pt, fill: white, "set GENUS_LIBERTY_TC chemin/vers/le/typical.lib
set GENUS_LIBERTY_BC chemin/vers/le/best_case.lib
. . . ")$
2. Le fichiers de variables propre au dut t: \$env(DESIGN_PATH)/dut/design.lib. On y retrouve par exemple :
$#rect(radius: 5pt, fill: white, "set GENUS_FILELIST chemin/vers/le/rtl.f             # spécifique au projet
set GENUS_SDC chemin/vers/le/constraint.sdc        # spécifique au projet
. . . ")$

\
Ainsi, quand on veut changer de dut, il nous suffit simplement de pointer vers un autre  design.env. De même pour changer de pdk on peut simplement changer de config.env.

\
Ensuite, il déroule le flow de synthèse ligne par ligne et s'arrête en cas d'erreur.
]
)],

)
],
caption: [Imbrication des appels des fonctions de la synthèse]
)


\
#showybox(
  title: [#text(weight: "bold", fill: black, [Comprendre le script tcl] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Nous n'allons pas nous attarder énormément ici sur le contenu du script tcl car c'est une discipline à part entière, avec toutes ses complexités. Chaque version de Genus à ses propres commandes, ses subtilités et surtout *chaque design* va nécesiter la mise en place de paramètres très spécifiques.

  La version minimale du script donne vraiment les commandes *obligatoires* et laisse l'outil en automatique. Dans la pratique ça n'est pas aussi simple ; tout le travail réside dans la subtilité.
]

\
#showybox(
  title: [*Note * : Utilisation de Genus ligne par ligne],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Plutôt que de lancer Genus avec un script on aurait tout aussi bien pu le lancer avec la commande $#rect(radius: 5pt, fill: white, "genus -legacy_ui")$ et *executer les lignes du script* les unes à la suite des autres.
]


#showybox(
  title: [*Méthode* : Repérer les erreurs],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Lorsque l'on lance des gros scripts, une erreur peut vite se glisser, se perdre et devenir irrepérable (car non bloquant pour Genus par exemple). Pour prévenir ce problème il y a une règle de bonne pratique toute simple : *On découpe le flow en sous-étapes*.
]

#showybox(
  title: [*Note* : Execution de Genus],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il faut bien avoir en tête que le fichier .tcl n'est pas executé en tant que tel, c'est genus qui est executé et qui lance les commandes lignes par lignes. Ainsi, le script ne peut pas charger des variables d'environnement *globale* et une fois sorti de genus (avec la commande *`exit`*) les variables comme *\$GENUS_SDC* ne seront plus définies. 
]


\
Une fois le script terminé, on peut ouvrir la vue graphique (normalement pas nécessaire à cette étape mais intéressant de voir ce qu'il a généré). Pour ce faire, dans genus : 

```bash
legacy_genus:/> gui_show
```

Puis selectionner la vue _Schematic_ :

#v(0.5cm)
#figure(
  image("Img/08_genus_ouvrir_netlist.png", width: 60%),
  caption: [Genus : comment ouvrir la vue netlist],
)<fig-08_genus_ouvrir_netlist>#v(0.5cm)

On peut alors observer la nouvelle netlist générée par genus avec cette fois-ci les noms des composants du pdk:

#v(0.5cm)
#figure(
  image("Img/08_netlist_synthese.png", width: 100%),
  caption: [Netlist générée par Genus],
)<fig-08_netlist_synthese>#v(0.5cm)


Une fois qu'on en a terminé avec Genus, on peut le fermer : 
```bash
legacy_genus:/> exit
```

== Comprendre les rapports
Maintenant qu'on a fait la première synthèse, on peut regarder les résultats dans le répertoire d'ou on a lancé Genus en tappant la commande : 
```bash
tree
#ou 
ls
```


On y trouve  une arborescence de ce type : 
#set list(marker: ([•], [#sym.arrow.r.curve]))
- *fv\/* (pour la vérification formelle, pas utilisé ici)
 - ripple_carry_4/
 - fv_map.fv.json
 - fv_map.map.do
 - fv_map.singlebit.original_name.alias.json.gz
 - fv_map.user_hier.json
 - fv_map.v.gz
 - read_libs.tcl
 - rtl_to_fv_map.do

 \
- *logs\/* 
 - genus.cmd : la commande appelée
 - genus.log : le log de Genus

 \
- *outputs\/* (les sorties utilisées par la suite dans le PnR)
 - ripple_carry_4_delays.sdf
 - ripple_carry_4_netlist.v
 - ripple_carry_4_sdc.sdc

\
- *reports\/*
 - report_area.rpt
 - report_power.rpt
 - report_qor.rpt
 - report_timing.rpt

\
*Alors, qu'est ce qu'il faut regarder ?*

La procédure typique est : 
- Si on a une erreur -->  on regarde le log (ici *genus.log*) pour comprendre d'ou vient l'erreur et la corriger.
- Si non, on regarde les *rapports* pour vérifier que le circuit correspond aux attentes (et, si oui, c'est terminé pour cette étape et on peux fournir les *outputs* à innovus pour le PnR).

#showybox(
  title: [*Note* : Erreur de synthèse types],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Une erreur avant _elaborate_ concerne souvent les fichiers ou la syntaxe. Une _référence non résolue_ après élaboration concerne la hiérarchie. Un _timing mauvais_ après mapping concerne plutôt contraintes, architecture ou choix de cellules.

]

\
Mais alors comment lire les rapports et a quoi correspondent ils ?

#TODO("stylus, reagarder les rpt nécessaire?")

==== Fichier : report_timing.rpt - le timing
Comme son nom l'indique c'est dans ce fichier qu'on retrouve les informations relatives au timing. C'est ici que l'on voit si le timing respecte les contraintes définies dans le sdc. 

Concept essentiel à comprendre à cette étape : la *slack*. Elle est définie comme suit : $#rect(stroke: red,[ slack = t_requis - t_arrivee])$

Une slack *négative* indique qu'on est en retard $->$ #rouge("violation des contraintes"). 

Pour vérifier, on peut parcourir le fichier à la main ou lancer une commande du type : 
```bash
grep -i "slack" reports/report_timing.rpt 
```

#TODO("Pourquoi j'ai que un slack? J'ai que un seul chemin possible car mon dut est trop simple?")

\
Autres vérifications à effectuer : 
- *WNS* (Worst Negative Slack) = pire slack
- *TNS* (Total Negative Slack) = somme des slacks négatifs
- Les clocks et les unités sont celles attendues
- Aucun chemin important n'est non contraint
- Les ports reçoivent bien délais, transitions et charges
- Les exceptions ciblent les objets voulus
- Les violations de transition, capacitance et fanout sont *séparées* des violations de timing

#showybox(
  title: [*Note* : La slack],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Le corner le plus intéressant à regarder pour la slack est le WC car c'est ce corner qui menera au temps de setup le plus lent.

]


#showybox(
  title: [#text(weight: "bold", fill: black, [GENUS PASS $!=$ Design fonctionnel] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Le code retour de l'outil, l'élaboration, les contraintes, le timing, les design rules et les exports sont des *contrôles distincts*, Ils permettent de savoir ou le flow à éventuellement planté. Un code de retour : #text(fill: green, [GENUS_STATUS=PASS]) signifie *uniquement* que toutes les commandes ont été exécutées et les fichiers attendus ont été générés. Cela ne signifie #rouge("pas") nécessairement que :
  - le slack est positif
  - On a une absence de warnings dans check_design
  - On a une absence de warnings dans check_timing_intent
  - Une bonne fermeture setup/hold
  - On a un résultat signoff

  Les #rouge("rapports doivent donc toujours être examinés"), même lorsque la commande s'est terminée normalement.

  On peut faire cette vérification à la main ou l'intégrer dans un script (cf. niveaux suivants).
]

==== Fichier : report_power.rpt
Indique la consommation hesitimée du circuit. Il faut bien avaoir en tête que la consommation finale et fiable du circuit sera donnée à la suite du PnR.

==== Fichier : report_area.rpt et report_qor.rpt - Aire du design
Rapport de la surface prise par notre circuit. Il faut notamment vérifier :
- *Aire totale* : nombre de cellules + répartition combinatoire/séquentielle
- *Cellules non mappées* : doit être à 0

#showybox(
  title: [*Note* :],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Une aire plus petite *n'est pas automatiquement meilleure* si elle dégrade le timing ou la robustesse électrique. Si, toutefois, on souhaite optimiser l'aire au détriment par exemple du timing on peut le spécifier à genus avec des commande du type : 
  ```tcl
  set_db syn_goal {area 1.0 timing 0.8}  # effort 100% aire, 80% timing
  set_db syn_timing_slack_margin 0.05   # Marge de 50ps sur le slack
  ```
Genus essayera de réduire l'aire, mais ne sacrifiera pas le timing au-delà de la marge définie par syn_timing_slack_margin.

]




== Niveau 2 : script plus élaboré
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/02_synthesis/02_sim_advanced/])

#TODO("TODO")

Le script du niveau 1 est fonctionnel sur le papier mais en pratique il est *incomplet*. Notre circuit étant très simple, Genus à réussi à faire un synthèse fonctionnelle (qui respecte les timmings de contraints.sdc) tout seul. En règle générale, ça n'est pas le cas et le métier des designer numérique est justement de venir jouer sur les paramètres de genus pour orienter son travail et aboutir à une synthèse fonctionnelle. Ce travail est en général très spécifique à un projet (chaque projet ayant ses propres contraintes) et il n'y a pas une manière de faire. Ici, aller plus en détail n'a pas beaucoup d'intérêt car pour spécifier davanatge de choses à Genus il faudrait savoir *précisément ou on veut aller et ce qui ne va pas*. 

#showybox(
  title: [*Note* : 03_sim_gate_level],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  On garde ce répertoire pour la fin du tutoriel.
]


= Etape 3 : Implémentation physique - Innovus 

Pour cette phase, qu'on appelle indifféremment implémentation physique ou placement routage (place and route (PnR) en anglais), nous allons utiliser l'outil Innovus. Comme pour les autres logiciels, Innovus possède plusieurs version ayant chacune leur syntaxe. Nous allons utiliser Innovus avec la syntaxes *stylus* grâce à la commande :
```bash
innovus -stylus 
```

#showybox(
  title: [*Note* : Stylus],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
   Stylus est un outils développé dans les dernières versions des outils par Cadence dans le but *d'unifier les phases de synthèse et de PnR*. L'objectif affiché est de permettre d'utiliser ce seul outil pour dérouler tout le flow. Ici, nous allons utiliser Innovus avec la syntaxe stylus mais il est important de comprendre qu'on ne va effectuer que le PnR avec Innovus (la synthèse ayant été réalisée avec Genus)

]


\
Comme pour la synthèse, l'outil Innovus va réaliser plusieurs étapes d'un seul coup parmis elles ont peut citer les plus importantes :

#figure(
[#table(
  columns: (auto, auto),
  inset: 5pt,
  align: left,
  fill: (x, y) => if y == 0 {silver},
  table.header(
    [*Etape*], [*Description*],
  ),
  [1], [Lire le fichier MMMC avec *`read_mmmc`*],
  [2], [Lire les fichiers du pdk décrivant le layout des standard cell avec *`read_physical`*],
  [3], [Lire la netlist générée par Genus avec *`read_netlist`*],
  [4], [Initialiser sa database interne avec *`init_design`* et définir un certain nombre de paramètres avec *`set_db`* notamment],
  [5], [Générer le floorplan (#underline("ie.") quelle est la taille de la puce, ect.) avec *`create_floorplan`*],
  [6], [Générer les pin d'entrée/sorties (IO) avec *`assign_io_pins`*],
  [7], [Générer les éléments liées à l'alimentation (power ring, stripes)],
  [8], [Faire le placement (#underline("ie.") ou sont les cellules) avec *`place_design`*],
  [9], [Générer le clock tree (CTS) (#underline("ie.") comment est routé le signal de clock) avec *`ccopt_design`*],
  [10], [Router le design (#underline("ie.") routage des cellules entre elles) avec *`route_design`*],
  [11], [Effectuer des check avec par exemple *`check_connectivity`* ou *`check_drc`*],
  [12], [Faire l'extraction de parasites avec *`extract_rc`* et l'enregistrer avec *`write_sdf`*],
  [13], [Générer des rapports avec par exemple *`time_design`*],
  [14], [Exporter le design final avec *`write_db`*],
)],
caption: [Etapes clés réalisées lors de l'implémentation physique]
)<tab_etapes_pnr>

\
#rouge[Note]: Encore une fois, les étapes restent inchangées d'un flow à l'autre mais pas les commandes pour les réaliser! Entre, ces étapes, il est d'usage de générer des rapports et des saves de a database (qui permettent par la suite de reprendre à partir d'une save plutot que depuis le début)


== Entrées et sorties
Voici les entrées/sorties usuelle de cette phase de PnR :


#figure(
[#table(
  columns: (auto, auto, auto),
  inset: 5pt,
  align: center,
  fill: (x, y) => if y == 0 {silver}
  else if y < 7 {green.lighten(80%)}
  else if y >= 7 {orange.lighten(80%)},
  table.header(
    [*Élément*], [*Exemple*], [*Rôle*],
  ),
  [RTL synthetisé], [`ripple_carry_4_netlist.v`], [Sortie de Genus : RTL mappé avec le pdk],
  [Contraintes synthetisée], [`ripple_carry_4_sdc.sdc`], [Sortie de Genus : contraintes temporelle mappées],
  [Variables du pdk], [`PNR_ASPECT_RATIO` `PNR_BOTTTOM_LAYER`], [Spec. du pdk pour savoir quelle règles réspecter],
  [MMMC], [`constraints/mmmc.tcl`], [Pour les corner (voir plus loin)],
  [Liberty], [`typical.lib`], [Infos sur les stdcell pour le MMMC],
  [cds.lib], [`cds.lib`], [Entre autre pour les bases OA (voir plus loin)],
  [[optionnel] - Checkpoints], [`database format LEF ou OA`], [Pour pouvoir repartir d'une étape],
  [Fichiers SDF], [`ripple_carry_4_delay.sdf`], [Extraction de parasites poste route],
  [Rapports], [`report_timing.rpt`, `report_area.rpt`, `report_qor.rpt`], [Preuves à examiner],
  [design exporté], [`ripple_carry_4_OA`], [design routé sous un format LEF ou OA],
)],
caption: [#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]) de la minimales du placement routage]
)<tab-entree_sorties_pnr>


=== Les MMMC

#TODO("MMMC explication a revoir/edulcorer")

MMMC pour Multi Mode Multi Corner est l'analyse qui permet de savoir comment répond notre design avec des erreurs de fabrications, en température etc..

Avant de pouvoir envoyer un design en production, il faut d'abord s'assurer qu'il va fonctionner même si tel transistor est un peu plus lent, tel autre un peu plus rapide etc. C'est l'objectif du MMMC : faire des estimations de temps de passage dans les standard cell en fonction de chaque corner.

\
Les deux notions essentielles à comprendre à ce stade sont le setup et hold:

\
*Setup Time (Temps d'Établissement)*

- *Définition* : Temps minimum avant le front montant du clock pendant lequel la donnée doit être stable pour être correctement capturée par un registre.

- *Violation* : Si la donnée arrive trop tard ou pas assez en avance #sym.arrow Échec de capture (métastabilité).

- *Corner utilisé* : Worst-Case (WC) #sym.arrow Délais maximaux (pire cas pour le setup).

\
*Hold Time (Temps de Maintien)*

- *Définition* : Temps minimum après le front montant du clock pendant lequel la donnée doit rester stable pour éviter la métastabilité.

- *Violation* : Si la donnée change trop tôt #sym.arrow Échec de maintien (valeur instable).

- *Corner utilisé* : Best-Case (BC) #sym.arrow Délais minimaux (meilleur cas pour le hold).





=== Le format Open Access (OA) VS LEF
Par défaut, Innovus utilise un format LEF pour écrire et lire les données physiques (qu'on pourrait vulgariser par "vue layout"). C'est cette extension qui va décrire les tailles des cellules, ou sont les pistes métaliques, quelle largeur etc...

Pour faire l'implémentation physique on peut donc tout à fait donner à Innovus les vues .lef de la techno (qu'on peut retrouver dans le pdk). On entend ici un fichier qui va décrire le "layout" de chaque standard cell. Il va les comprendre et, à son tour, est capable de générer des .lef avec le floorplan complet, avec le design routé (ou son les cellules + comment elles sont reliées), avec le CTS (comment arrive le signal de clock #underline("ie.") sorte de routage spécifique à la clock car c'est l'élément le plus sensible) etc.

\
Mais il y a un gros point noir à cette méthode : les fichiers .lef ne sont pas directement lisibles par *virtuoso* (qui permet notamment de faire le LVS et de mettre le guardring (cf. plus loin)). 
Il est donc recommandé de passer par le format *open access*. Ce format est lisible par Innovus (bien qu'il fasse une conversion en interne vers un format .lef, cette opération est transparente pour les utilisateur) *et* par Virtuoso.


\
Pour qu'Innovus puisse fonctionner #rouge("il a besoin d'un fichier cds.lib") dans le dossier depuis lequel il est executé. Dans ce cds.lib (pour cadence library) on retrouve tous les chemins vers les librairies utilisées par cadence (que ça soit les librairies du pdk ou bien les librairies des projets/design). Dans ce cds.lib est donc défini à un endroit le dossier des standard cell du pdk par exemple : 

```lib
DEFINE ihp130_stdcell le/chemin/absolu/vers/le/pdk
```

Quand on va lire les librairies d'implementation physique avec Innovus on va alors non plus lui donner des lef mais directement le nom _ihp130_stdcell_ qu'il va pouvoir retrouver grâce au cds.lib (avec l'option -oa_ref_lib pour lui indiqué qu'on travaille avec des bases OA). 

\
Par la suite, on va enregistrer la base open access, non plus en format .lef mais, en format oa avec une commande du type : 
```tcl
write_db -oa_lib_cell_view "$oaLibDir $oaLibName imported"
```

Cette commande va créer dans le répertoire d'execution un dossier \$oaLibDir dans lequel on va retrouver une cellule (un design) \$oaLibName contenant une vue "imported" (cette vue peut être n'importe quoi mais il y a des noms usuels comme floorplan, placed, routed, pré_CTS, post_CTS etc.)

\
Si daventure, on voudrait repartir d'une database OA précédemment sauvegardée il suffit de tapper : 

```bash
  @innovus 1> read_db -oa_lib_cell_view "$oaLibDir $oaLibName placed"
  read_db -oa_lib_cell_view "RIPPLE_CARRY_4_OA ripple_carry placed"

```
#TODO("erreur lecture")


#showybox(
  title: [*Note* : OA *ou* LEF],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il est important de noter ici qu'il faut faire un choix entre travailler en format LEF ou en format OA. On ne peux pas faire les deux en même temps.
]


== Niveau 1 : script minimal
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/03_pnr/01_pnr_minimal/])

Comme pour ma synthèse, l'appel direct à l'outil n'est pas possible car il y a trop d'étapes et de paramètres. Le niveau 1 donne un script minimal de placement routage dans lequel on laisse travailler Innovus #rouge[en automatique] sur une grande partie des tâches. De même que pour la synthèse, ici c'est suffisant car notre circuit est très simple mais dans le cas de plus gros circuits ça ne suffit pas $->$ il faut donner davantage d'indications à Innovus (avec des commande du type *set_db* ou des paramètres dans les appels des fonctions)

\
Pour commencer on va se placer dans le dossier de travail. Depuis la racine :
```bash
cd flow/03_pnr/01_pnr_minimal/workdir
```

Pour lancer innovus avec le fichier : 

```bash
# comme pour genus 
innovus -stylus -files ../pnr_minimal.tcl -log logs/innovus
# Pour ouvrir la gui après coup
innovus -stylus &
```

#showybox(
  title: [#text(fill : black, [*Note importante* : Fonctionnement de Innovus ])],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Comme Genus, Innovus se lance grâce à la commande :
  ```bash
  innovus -stylus 
  ```

  Si on spécifie un fichier d'execution comme 
  ```bash
  innovus -stylus -file monfichier.tcl
  ```
  alors innovus va s'ouvrir en mode stylus puis executer *ligne par ligne* le script. On pourrait tout aussi bien ouvrir Innovus avec la première commande et copier coller les commandes dans l'interpréteur Innovus ligne par ligne (ou bloc d eligne par bloc de ligne) et ça en reviendrait au même.

  \
  Pour ouvir la vue graphique d'Innovus, il faut d'abord avoir initialisé la database d'innovus (#underline("ie.") avoir atteint la ligne "init_design" ou être reparti d'une sauvegarde OA) puis on peut simplement faire :
  ```bash
  @innovus 1> gui_show
  @innovus 1> gui_fit
  ```
]


#showybox(
  title: [*Note* : Niveaux de métal],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Souvent, les standard cell utilisent le premier niveau de métal pour le routage. Il est donc usuel d'indiquer à Innovus de commencer le routage avec le niveau de métal suivant. Il est par ailleurs courant de réserver le deuxième niveau de métal à l'arbre d'horloge. On va donc commencer le routage du reste au niveau 3.
]

#TODO("inclure pphoto vue layout et abstract
Notion de skew")

#showybox(
  title: [*Note* : Vue Layout vs vue abstract],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Quand on ouvre le design dans virtuoso, on remarque que les standard cell sont en vue abstract et non en vue layout. La vue abstract est en fait une *vue layout simplifiée* ou apparaissent:
  1. Les connections
  2. Le niveau de métal 1
  3. Une zone ou il est interdit de passer au dessus.

  Cette vue permet d'effectuer une routage fonctionnel tout en restant plus légère à lire et en preservant la propriété intélectuelle. C'est d'ailleurs pour ce dernier point que certain pdk ne contiennent pas de vue layout sur leurs standard cell. 

  \
  Pour envoyer un circuit en fonderie il est #rouge[impératif] de fourinir la vue layout si elle est disponnible. Si elle ne l'ai pas, il faut bien stipuler au fondeur qu'il va devoir faire le changement lui même. 
]


#TODO("le LVS est réalise par la suite dans virtuoso ")

== Ouverture du design dans Virtuoso

Une fois qu'on a correctement exporté le design dans une base Open Access, on peut l'ouvrir pour la visualiser dans virtuoso.

\
Pour se faire, il faut démarrer virtuoso dans le répertoire habituel et bien penser a inclure dans le cds.lib de ce répertoire le lien vers le cds.lib dans lequel Innovus a mis le chemin vers sa base OA en rajoutant la ligne 
```lib
INCLUDE /chemin/vers/mon/cds.lib
```

De cette manière, virtuoso va immédiatement trouver la base OA dans son librairy manager comme on peut le voir @fig-09_virtuoso_select. 

#v(0.5cm)
#figure(
  image("Img/09_virtuoso_select.png", width: 60%),
  caption: [Virtuoso : ouverture base OA],
)<fig-09_virtuoso_select>#v(0.5cm)

On remarque alors que toutes les vues qu'on a enregsité y figurent et que leurs taille augmente petit à petit (normal car au fur et à mesure des étapes on rajoute des éléments). On peut par exemple ouvir la vue "routed" et on voit alors :

#v(0.5cm)
#figure(
  image("Img/10_virtuoso_chip_complete.png", width: 60%),
  caption: [Vue complete de la puce ripple_carry_4],
)<fig-10_virtuoso_chip_complete>#v(0.5cm)

Super! On a une puce "complete". En réalité, il y aurait plusieurs choses à rajouter ou modifier comme le filling (rajout de dummy cells entre les cellules "fonctionnelles" qu'on voit sur la @fig-10_virtuoso_chip_complete) ou bien les rails d'alim qui, ici, n'ai pas en top métal car le circuit aurait été trop petit en comparaison et qui est trop proche de la puce.

\
On remarque par ailleurs que les cellules apparaissent relativement vide par rapport à ce à quoi on pourrait s'attendre. C'est normal, en réalité, les cellules standard sont exportée en format "*abstract*" plus légé et pratique pour travailler en numérique. Si la vue layout est disponnible dans la techno cible on peut alors changer les cellules abstract en layout en faisant : *tool $->$ find/replace* puis :

#v(0.5cm)
#figure(
  image("Img/11_replace_abs_layout.png", width: 40%),
  caption: [Comment remplacer la vue abstract par layout],
)<fig-11_replace_abs_layout>#v(0.5cm)

On peut observer que les cellules se sont "remplie" et que les différentes couches de métaux qui les composent apparaissent (cf. @fig-12_diff_vues_layout).

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 15pt,    // space between columns
      image("Img/12_vue abstract.png", width: 100%),
      image("Img/13_vue_layout.png", width: 100%), 
      text("(a) Vue abstract"),
      text("(b) Vue layout"),
  ),
  caption: [Différence entre la vue abstract et la vue layout],
)<fig-12_diff_vues_layout>#v(0.5cm)

Ansi, notre puce "finale" ressemble à ceci :

#v(0.5cm)
#figure(
  image("Img/14_chip_complete_layout.png", width: 60%),
  caption: [Vue complete de la puce ripple_carry_4 après changement vers vue layout],
)<fig-14_chip_complete_layout>#v(0.5cm)




= Etape 4 : Simulation gate-level<sec_simu_gate_level>
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/01_simulation/03_sim_gate_level])


Une fois que le placement routage est terminé, il nous reste à vérifier que le design "final" est toujours fontionnel. Pour ce faire on va refaire un étape de simulation avec Xcellium mais avec deux changements majeurs : 
1. On utilise cette fois le fichier RTL donné par Innovus avec notre module contenant les cellules standard. Pour que xrun puisse comprendre à quoi font référence les modules de cellules standard que Innovus à mis, il faut également lui indiquer les modèles comportementaux de ces cellules (il faut par exemple que quelque part xrun comprenne que le module OR3JILTX1 effectue une fonction "OU"). Pour ce faire, on va également renter en option les fichiers du PDK ou le comportement des cellules standard est décrit (facile à trouver c'est un fichier du stype stdcell.v).

\
2. On donne égalament à xrun le fichier .sdf généré par Innovus. Ce fichier spécifie point par point les retards dans les signaux à cause des ralentissment causé par le chemin de la clock (clock tree) ou bien par les parasites.

\
Dans notre cas, la commande complète ressemble à :
```bash
xrun -64bit \
  -sv \
  -access +rwc \
  -gui \
  -timescale 1ns/1ps \
  /share/Pdk/IHP/SG13S/ixc013_stdcell/verilog/ixc013_stdcell.v \
  /share/Pdk/IHP/SG13S/ixc013_stdcell/verilog/ixc013_primitives.v \
  flow/03_pnr/01_pnr_minimal/workdir/outputs/ripple_carry_4.routed.v \
  dut/rtl/tb_ripple_carry_4.sv \
  -sdf_cmd_file flow/01_simulation/02_simulation_gate_level/sdf_cmd_file -mess
```

#TODO("inclure l'explication du #1 dans le testbench ")

#showybox(
  title: [*Note* : nomenclature],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  On appelle cette étape la simulation gate level et non "extract" comme on pourrait le faire en analogique car ce terme est réservé à virtuoso.
]

== Comment savoir si le fichier sdf est bien pris en compte dans la simulation ?
Pour savoir si on simule bien le rtl placé routé c'est simple : on ne pointe que vers ce fichier et non plus vers les .sv d'avant. Pour savoir si xrun prend bien en compte le fichier sdf pour les parasites c'est moins évident. Quand ouvre la waveform, il suffit d'observer un petit décalage entre la clock et un signal synchrone. Si les signaux sont légèrement désynchronisés c'est gagné! Par exemple, on peut voir sur la @fig-07_simu_gate_level que le SDF est correctement pris en compte car cout_o est sensé monter en même temps que la clock. 

#v(0.5cm)
#figure(
  image("Img/07_simu_gate_level.png", width: 50%),
  caption: [Simulation gate level avec SDF pris en compte],
)<fig-07_simu_gate_level>#v(0.5cm)


// ===================== ANNEXES =====================
#heading(numbering: none, outlined: true)[Annexes]

// Définir une autre façon de numéroter pour les annexes
#set heading(
  numbering: (..nums) => {
    return "A." + numbering("1 ", nums.pos().last())
  },supplement: [Annexe], outlined: false
)


// ----------------- SOUS-SECTION ------------------ 
== Nomenclature classique dans les PDK <ann-nomenclature>
Il peut être trsè compliqué de se retrouver dans un PDK quand on a pas l'habitude des acronymes. Voici donc quelques indications générales qui peuvent s'avérer utile

#figure(
[#table(
  columns: (auto, auto, auto),
  inset: 5pt,
  align: center,
  fill: (x, y) => if y == 0 {silver},
  table.header(
    [*Partie du nom*], [*Signification*], [*Exemple techno tsmc65n*],
  ),
  [tc], [Timing Corner (fichiers pour la synthèse/PnR)], [tcbn65lp_200a],
  [tef], [Timing Effective (variante pour l’analyse timing)], [tef65lp32x1s_i_200a],
  [tp], [Timing Pessimistic (corner lent, pour le worst-case)], [tpan65lpnv2od3_200a],
  [bn], [Bulk NMOS (type de transistor)], [tcbn65lp_200a],
  [65lp], [65nm Low Power (mais peut correspondre à un kit 130nm pour des raisons de compatibilité)], [Tous tes dossiers],
  [nv], [Non-Volatile (pour les mémoires)], [tpan65lpnv2od3_200a],
  [esd], [ElectroStatic Discharge (protection contre les décharges)], [tef65lpesd_p_200a],
  [200a / 140c / 141a], [Version du kit de design (200a = plus récent, 140c = plus ancien)], [Tous tes dossiers],
  [_i_], [Input (fichiers pour les entrées)], [tef65lp32x1s_i_200a],
  [32x1s], [Variante spécifique (ex: 32 bits, 1 supply voltage)], [tef65lp32x1s_i_200a],
)],
caption: [Signification des noms de fichiers]
)<tab_noms_fichiers>

Pour les modèles de modélisation dans les pdk on peut retrouver deux types : 

#figure(
[#table(
  columns: (auto, auto, auto, auto, auto),
  inset: 5pt,
  align: center,
  fill: (x, y) => if y == 0 {silver},
  table.header(
    [*Modèle*], [*Signification*], [*Type*], [*Précision*], [*Complexité*],
  ),
  [ECSM], [Effective Current Source Model], [Modèle basé sur les courants], [Très élevée], [Élevée],
  [NLDM], [Non-Linear Delay Model], [Modèle basé sur les tables de lookup], [Élevée], [Modérée],
)],
caption: [Comparaison de deux modèles de parasites courants]
)<tab_modeles>


