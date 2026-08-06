#import "lib.typ": *

#show: template_R.with(
  title: "Prise en main du flow numérique ASIC",
  authors: (
    ("Romain DUCHADEAU", "IP2I / CNRS", "r.duchadeau@ip2i.in2p3.fr"),
    ("Sabra KARIM", "IP2I / CNRS", "k.sabra@ip2i.in2p3.fr"),
  ),
  logos: ("Img/logo_CNRS.jpg", "Img/logo_IP2I.png"), //ex : "Img/logo_CNRS.jpg"
  lang: "fr",
)

// ******************** SECTION ******************** 
// *************************************************
= Introduction

Ce tutoriel s'adresse a un public initié et/ou motivé (étudiant ingénieur ou ingénieur en microélectronique analogique). Il permet une prise en main *concrête* et *rapide* du flow numérique. Ce tutoriel n'a pas pour ambition d'être un guide ultime pour tout comprendre, pour plus de détails il existe une très bonne série de vidéo réalisée par Adi Teman dont vous pouvez retrouver le lien #link("https://www.youtube.com/watch?v=GIPhBfenqMc&list=PLZU5hLL_713x0_AV_rVbay0pWmED7992G", "ici") ou le github #link("https://github.com/enics-labs/rtl2gds-demo", "ici").

\
*Note :* Dans ce parcours les encadrés en $#rect(stroke: blue, [#text(fill: blue, [bleu])])$ sont généralement des notes ou des conseils alors que les encadrés en $#rect(stroke: red, [#text(fill: red, [rouge])])$ font référence à des points importants et jalons de progression a ne pas manquer.


\
Le flow numérique (et  a fortiori ce tutoriel) se découpe en trois grandes étapes dont chacune est prise en charge par un outil spécifique \*:

#figure(
  caption: [Méthodologie du flow numérique],
  [#showybox(
  title: [#text(weight: "bold", fill: black, [Etape 1 : Simulation RTL  (cf. @sec-simu_rtl)] )],
  title-style: (align: center),
  body-style: (align: center),
  footer-style: (align: center),
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
  footer: "Outil : Xcellium  |  Fichiers .rtl et .f"
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
  footer: "Outil : Genus  |  Fichiers .rtl, .f, .env, .lib et .sdc"
)[
  A cette étape, on prend le rtl (déjà simulé) et on fait le lien avec la technologie cible pour y introduire des aspects de timing (équivalent des simulations pré-layout). La synthèse va fair le lien entre les portes logiques et le temps de passages dans les gates, les délais etc. propres à la techno. 
]

$arrow.b$

#showybox(
  title: [#text(weight: "bold", fill: black, [Etape 3 : Place and route] )],
  title-style: (align: center),
  body-style: (align: center),
  footer-style: (align: center),
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
  footer: "Outil : Innovus  |  Fichiers .rtl, .env,  .f et .sdc"
)[
  Comme son nom l'indique, placement, routage et simu post-layout. *Innovus* importe la netlist et les vues physiques, construit le floorplan, place les cellules, traite l'horloge si elle existe, route les nets et extrait les parasites. 
]

])<fig-methodologie>

\


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
*\** Il existe d'autres outils que ceux cités mais ils ne seront pas évoqués dans ce tutoriel. La démarche restant exactement la même d'un outil à l'autre il faudra simplement réadapter les scripts en cas de changement d'outil.


== Pourquoi deux exemples
Le full adder est un bloc très simple : il possède huit combinaisons et aucune horloge. Il permet d'apprendre le RTL, le testbench, les filelists, une contrainte combinatoire, la synthèse et un premier placement sans mélanger les notions et avoir des problèmes d'horloge.

\
L'additionneur pipeliné ajoute des registres, une clock, un reset et un signal de validité. Il permet, dans un second temps d'étudier des problématiques temporelles (la ou les vrais problèmes commencent) comme la latence, setup, hold, MMMC, CTS etc...

\
Il vous appartient de terminer le flow complet avec le full_adder_comb puis, dans un deuxième temps, repasser le flow avec le adder_pipeline ou bien de dérouler chaque étape du flow avec les deux exemples l'un après l'autre pour voir les différences.

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
  Quand on fait quelque chose de nouveau (surtout en microélectronique numérique) la règle d'or est toujours de commencer simple et petit. Commencer petit permet de distinguer une erreur de *méthode* en s'affranchissant des difficultés réelles du design.
]


== Arborescence du dossier du tutoriel

#showybox(
title: "Racine du dossier", 
[Racine principale du git. Toujours lancer les scripts depuis ce dossier],
frame: (
    border-color: black,
    title-color: black.lighten(30%),
    body-color: black.lighten(95%),
    footer-color: black.lighten(80%)
  ),
columns(3)[
#showybox(
title-style: (boxed-style: (:)),
title: "exemples",
[Dossier contenant les #rouge("fichiers spécifiques") des deux exemples full adder combinatoire (01) et pipeline (02)],
columns(2)[
#showybox(

title: [#text(12pt,[Ex 01])],
[
- rtl
- tb
- sim
- syn
- pnr
]
)

#colbreak()
#showybox(
title: [#text(12pt,[Ex 02])],
[
- rtl
- tb
- sim
- syn
- pnr
]
)
]
)

#colbreak()

#showybox(
title-style: (boxed-style: (:)),
title: "./",
[A la racine du dossier on retrouve ce présent pdf, des fichiers de licences et le README]
)

#showybox(
title-style: (boxed-style: (:)),
title: "config",
[Contient les fichiers de config liés au pdk / Cadence. Sert à faire le lien entre les scripts génériques et la config propre au labo]
)



#colbreak()
#showybox(
title-style: (boxed-style: (:)),
title: "scripts",
[ On retrouve les wrapper `.sh` permettants de lancer les $!=$ parties du flow
#showybox(
title-style: (boxed-style: (:)),
title: "genus",
[Scripts spécifiques à l'utilisation de genus]
)

#colbreak()
#showybox(
title-style: (boxed-style: (:)),
title: "innovus",
[Scripts spécifiques à l'utilisation d'Innovus]
)
]
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
  Pour des raisons de répétabilité, les scripts ne seront jamais écrits avec des _PATH_ relatifs mais seront toujours écrits en utilisant des PATH absolu ou chargé à partir de variables (elles même chargées à partir d'un fichier qui "comprend" les chemins relatifs). Plus de détails plus loin.
]

== Approche pédagogique : méthode en 2 niveaux d'abstraction

Chaque chapitre montre d'abord:
1. L'appel direct à l'outil avec une *commande minimale*. C'est le coeur de l'utilisation de l'outil et c'est ce qui sera appelé par les scripts dans la suite donc il est très important de bien maîtriser cette étape.
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




// ******************** SECTION ******************** 
// *************************************************
= Etape 1 : Simulation RTL du full adder au testbench réutilisable - outil Xcelium <sec-simu_rtl>
// ----------------- SOUS-SECTION ------------------ 

//  Pour exemple d'un code highlighté avec codly
// 
// #codly(highlights: (
//   (line: 4, start: 2, end: none, fill: red),
//   (line: 5, start: 13, end: 19, fill: green, tag: "(a)"),
//   (line: 5, start: 26, fill: blue, tag: "(b)"),
// ))
// #codly(footer: [*11 e*]){
// ```py
// def fib(n):
//   if n <= 1:
//     return n
//   else:
//     return fib(n - 1) + fib(n - 2)
// print(fib(25))
// ```}




Cette première étape du flow se décompose elle même en trois phases (cf. @fig-methodologie):
1. *Compilation* : Lecture du SystemVerilog et contrôle de syntaxe.
2. *Élaboration* : Construction de la hiérarchie et résolution des modules, paramètres et ports.
3. *Simulation* : Exécution des blocs temporels et production du verdict du testbench.

\
Dans la pratique, ces trois phases seront effectuées en *même temps* pas Xcellium. Voyons comment:

#showybox(
  title: "Note : les erreurs courantes",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Une *erreur de syntaxe* appartient généralement à la *compilation*. Un *top inconnu* ou un port impossible appartient à l'*élaboration*. Un `$fatal`, un timeout ou une comparaison incorrecte appartient à la *simulation*.
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
  [Rapport], [`.sh`], [Rapport de sortie de la simulation (balises PASS ou FAIL)],
)],
caption: [Entrées sorties de la phase de simulation (#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]))]
)<tab_elements_simu>

// -------------------  SOUS - SECTION ------------------- 
==  Exemple 1 : Full adder combinatoire
Module très simple et purement combinatoire (sans clock). La première étape consiste à savoir ce qu'on veut que le module fasse. Cette étape passe souvent par écrire une machine à état ou une table de vérité pour être au clair sur les fonction *précises* du module. 
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
Deuxième étape : on écrit le comportement du module en RTL (verilog, systemverilog ou vhdl). Ici, cela donne :
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
#TODO("faire la liaison pour le timescale")
\* Voir plus loin pour davantage de détails

*Note* : Le DUT ne contient aucun délai, bloc `initial` ou appel système car c'est un bloc asynchrone.

// -------------------  SOUS - SECTION -------------------
=== Testbench du full adder comb
De la même manière que un module, un testbench est aussi un module RTL qui comprend le module a tester ainsi que les entrée sorties commandées permettant de faire le test (exactement comme en analogique). Le rôle du testbench est également de faire ressortir des #rouge("marqueurs") pour vérifier le bon fonctionnement comportemental de note module / DUT. Ici, cela donne :
#codly(footer: [*tb_full_adder_comb.sv*], breakable: true)
```sv
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
            =10;

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

#showybox(
  title: [#text(weight: "bold", fill: black, [À retenir :] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Un testbench automatisable doit terminer avec `$fatal` en cas d'erreur et imprimer un marqueur final exact uniquement lorsque tous les tests passent. Il ne #rouge("suffit pas") de print PASS ou FAIL pour que ça fonctionne, il faut un réel #rouge("marqueur") `$fatal` pour être certain que le code *plante* et fasse ressortir une erreur nous empêchant de continuer si il y a une erreur dans le fonctionnement.
]


=== La simulation - niveau 1 : commande minimale
Une fois le RTL du full adder et de son testbench écrits (et qu'on a donc une description comportementale de nos modules), il faut effectuer la simulation. Pour ce faire on execute (après avoir chargé Cadence et les outils) :


```bash
xrun -64bit -timescale 1ns/1ps \
   examples/01_full_adder_comb/rtl/full_adder_comb.sv \
   examples/01_full_adder_comb/tb/tb_full_adder_comb.sv \
   -top tb_full_adder_comb
```

#TODO("On peut tout mettre dans le même .f") cf $arrow.b$

```c
// files to be compiled
dkm.sv
dkm_test.sv
// command line options
-gui
-access rwc
-linedebug
-timescale 1ns/1ns
```

#TODO("code coverage p 67 de RTLtoGDSII cadence course")

\
* Explication de la commande* : 
- `-64bit` utilise l'exécutable 64 bits.
- `-sv` active SystemVerilog.
- `-timescale` fixe l'unité et la précision par défaut.
- `-f` lit une filelist.
- `-top` choisit le top élaboré.

\
On s'attend a voir dans la sortie:
```sh
xcelium> run
TEST_PASS: full_adder_comb
```

#showybox(
  title: "Note :",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il est important de bien avoir en tête d'où on lance le script et donc d'où partent les chemins relatifs!!! Une méthode sûre consiste à toujours lancer la commande depuis la racine du projet et a adapter les chemins relatif à ce point de départ plutôt que l'inverse.
]

==== Filelists 
On peut executer xrun individuellement pour chaque DUT et chaque testbench (comme ) mais une bonne pratique si on a beaucoup de fichiers RTL est d'utiliser une filelist (extension en $#rect(fill: colors.code-bg, [.f])$) pour définir *dans quel ordre* procéder à l'élaborartion et qu'on ai pas de problèmes de dépendances non résolues à cause d'un mauvais ordre.
même si ça n'a pas beaucoup d'intéret car on a très peu de fichiers)


#showybox(
  title: "Bonne pratique :",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il est recommandé de séparer les .f des modules DUT et des testbench en deux fichiers distincts (ce qui est fait ici).
]
 


#codly(footer: [*rtl.f*], breakable: true)
```txt
examples/01_full_adder_comb/rtl/full_adder_comb.sv
```
Pour le testbench: 

#codly(footer: [*tb.f*], breakable: false)
```txt
examples/01_full_adder_comb/tb/tb_full_adder_comb.sv
```

Une fois les filelists écrites on peut lancer (depuis la racine du dossier toujours):

#codly(stroke: 1pt + red)
```bash
xrun -64bit -sv -timescale 1ns/1ps \
  -f examples/01_full_adder_comb/sim/rtl.f \
  -f examples/01_full_adder_comb/sim/tb.f \
  -top tb_full_adder_comb \
```
#codly(stroke: 1pt + gray)
\
* Explication de la commande* : Ajout de `-f` pour lui dire de lire une filelist et pas un fichier .sv


La sortie devrait être identique qu'avec la commande minimale précédente.
Evidemment, passer par des filelist quand on a un seul fichier de tb et de RTL n'est pas très pertinent mais c'est une bonne pratique à avoir en tête.

\
#showybox(
  title: [Note : ],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Si on veut élaborer dans un dossier particulier on peut défnir une worklib 

```bash
xrun -64bit -timescale 1ns/1ps \
   -f examples/01_full_adder_comb/sim/rtl.f \
   -f examples/01_full_adder_comb/sim/tb.f \
   -top tb_full_adder_comb \
   -work worklib
```
Pour dans un second temps reload avec l'option -R : 
```bash
xrun -64bit -R worklib tb_full_adder_comb
```

\
On peut également procéder sans filelist  et pointer directement vers les fichiers .sv mais ce n'est pas une bonne pratique (risque d'oubli, de path mauvais, pas modulable si on veut enlever un module par exemple): 
```bash
xrun -64bit -timescale 1ns/1ps \
   examples/01_full_adder_comb/rtl/full_adder.sv \
   examples/01_full_adder_comb/tb/tb_full_adder_comb.sv \
   -top tb_full_adder_comb
```
]
Note : 
#TODO("Rajoute précision sur le timescale, mettre commande sans fileliste")

==== La simulation - niveau 2 : Wrapper réutilisable
Comme nous en avons déjà discutés, en pratique, on ne va pas lancer cette commande à la main car on ne sait pas vraiment ou Xcellium stocke ses fichiers de simu, les logs, les résulats etc... Dans un flow numérique tout peut être une source d'erreur et stipuler explicitement ou vont chaque fichier peut faire gagner enormément de temps. C'est pourquoi on va privilégier l'utilisation d'un wrapper qui va tout automatsqer pour nous


#TODO("A eclaircir ...")
Pour une petite simulation, la visibilité complète peut être activée avec `-access +rwc`. Un fichier Tcl Xcelium peut créer une base SHM :

```tcl
database -open waves -into waves.shm -default
probe -create tb_full_adder_comb -all -depth all
run
exit
```

Puis :

```sh
xrun ... -input waves.tcl
simvision waves.shm
```
#TODO("FIn A eclaircir ...")


Le wrapper suivant crée un dossier de résultat unique, isole la bibliothèque Xcelium, conserve le code retour et vérifie le marqueur final.
#codly(footer: [*run_sim.sh*], breakable: true, )
```sh
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
```

Pour lancer le script : 

#codly(stroke: 1pt + red)
```bash
bash scripts/run_sim.sh full_adder_comb 
```
#codly(stroke: 1pt + gray)


#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : source $!=$ bash - 1/2] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Dans la logique les commande source et bash (ou ./) servent toutes à executer un processus mais la commande source est prévue pour mettre à jours des variables d'environnement (comme on en reparle plus loin). Pour cette raison, quand on execute un script il ne faut #rouge("jamais executer avec source") et toujours privilégier bash ou ./
]

// -------------------  SOUS - SECTION ------------------- 
== Exemple 2 : Full adder pipeliné

=== Additionneur pipeliné
Un second exemple ajoute une clock, un reset synchrone, des registres et un protocole `valid`. Une transaction acceptée avec `valid_i=1` produit un résultat valide un cycle plus tard.
Le scoreboard doit décaler la référence d'un cycle. Les stimuli sont de préférence appliqués au front descendant afin d'éviter une course avec la capture au front montant.

#codly(footer: [*adder_pipeline.sv*], breakable: true, )
```systemverilog
module adder_pipeline =(
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
Les étapes de simualtions de ce deuxième exemple sont très similaires à l'exemple précédent. Il suffit simplement de réadapter les chemins pour pointer vers les bons fichiers.

\
Maintenant que nous avons simulés notre DUT, nous pouvons passer à synthèse.

// ******************** SECTION ******************** 
// *************************************************
= Etape 2 : Synthèse logique avec Genus
La deuxième étape de ce parcours est donc la synthèse. C'est à cette étape que le lein avec la technologie cible va s'effectuer. Cette étape est plus compliquées que la précédente car il faut pouvoir correctement faire le lien avec le PDK cible.

*Ce que produit la concrêtement la synthèse*: Genus transforme un *RTL élaboré* en une *netlist composée de cellules de la bibliothèque cible*.
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
  [1], [Lire le full adder, l'élaborer et comprendre le SDC],
  [2], [Exécuter *`syn_generic`* : transforme le RTL en logique générique et simplifie les expressions],
  [3], [Exécuter *`syn_map`* : choisit des cellules disponibles dans la Liberty],
  [4], [Exécuter *`syn_opt`* : améliore timing, aire et règles électriques selon l'effort demandé],
  [5], [Générer les rapports et les deux fichiers nécessaires à Innovus],
)],
caption: [Etapes clés réalisées lors de la synthèse]
)<tab_etapes_syn>

== Entrées et sorties
Dans un premier temps il est primordial de comprendre ce dont on a besoin pour lancer la synthèse et quels sont les fichiers en sortie de synthèse


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
  [RTL], [`full_adder_comb.sv`], [Description logique synthétisable],
  [Filelist], [`rtl.f`], [Ordre et chemins des sources],
  [Contraintes], [`constraints.sdc`], [Clocks, délais d'E/S et exceptions],
  [Liberty], [`stdcells_tc.lib`], [Fonctions, arcs, délais et puissance],
  [Environnement], [`02_adder_pipeline.env`], [Chemin absolu des fichiers ],
  [Netlist mappée], [`full_adder_comb.mapped.v`], [Cellules choisies],
  [SDC exporté], [`mapped.sdc`], [Contraintes transmises],
  [Rapports], [`report_timing.rpt`, `report_area.rpt`, `report_qor.rpt`], [Preuves à examiner],
)],
caption: [#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]) de la minimales de la synthèse logique]
)<tab_elements_synthese>

#TODO("On peut générer des databases et des mmmc (peut être à mettre plus loin")

.mmmc (qui peut être un argument en + pour innovus)--> C'est une sortie de Genus (synthèse), PAS du PDK. Genus génère ce fichier automatiquement quand tu synthetises. Il peut s'appeler :

    .mmmc (format Cadence standard)
    .view (variante ou ancien format)
    Un .tcl custom que tu écris toi-même

\
On ne va pas revenir sur ce que sont les fichiers `.sv` et `.f` mais voici une rapide description des autres entrées :

=== Fichier SDC (Synopsys Design Constraint)
Le fichier qui va définir les contraintes de timing à respecter pour notre design. 
Voici par exemple le fichier de contraintes de l'exemple 02 -  _adder_pipeline_ :

#codly(footer: [*constraints.sdc*], breakable: true, )
```tcl
set PERIOD_NS 2.000
create_clock -name VCLK -period $PERIOD_NS

set_input_delay  0.200 -clock VCLK [get_ports {a_i b_i cin_i}]
set_output_delay 0.200 -clock VCLK [get_ports {sum_o cout_o}]

set_input_transition 0.050 [get_ports {a_i b_i cin_i}]
set_load 0.010 [get_ports {sum_o cout_o}]
```
#showybox(
  title: [*À retenir* :],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Le budget disponible pour un chemin entrée-vers-sortie est approximativement : [*période - délai d'entrée - délai de sortie - marges internes*].
  Les valeurs doivent correspondre au *contrat réel du bloc*, pas à un nombre choisi uniquement pour obtenir un rapport positif...
]

=== Fichiers .lib (liberty)
Ce sont les fichiers du PDK qui définissent les caractéristiques des cellules de la technologie cible. Il existe 
- tc ou tt pour typical
- wc ou ss pour lent 
- bc ou ff pour rapide 
#TODO("A améliorer")

== Niveau 1 : Commande et Tcl minimal
#TODO("A unifier ave la partie 1")
Comme il y a beaucoup d'étapes à effectuer lors de la synthèse, un appel direct à l'outil n'est pas recommandé. Un exemple d'appel direct à genus pourrait être : 

```bash
genus -no_gui \
     -execute "read_hdl -sv chemin/vers/adder_pipeline.sv" \
     -execute "elaborate adder_pipeline" \
     -execute "read_sdc chemin/vers/adder_pipeline.sdc" \
     -execute "syn_generic" \
     -execute "syn_map" \
     -execute "syn_opt" \
     -execute "write_hdl -hier > chemin/vers/adder_pipeline.mapped.v" \
     -execute "write_sdc > chemin/vers/adder_pipeline.mapped.sdc" \
     -log genus.log
```
\* Note : L'appel direct à genus ne fonctionne pas en l'état (mauvais chemin etc.)

\
*Explications de la commande :*

On retrouve les grandes étapes répertoriées dans la @tab_elements_synthese :
1. *`read_hdl`* : compile les sources
2. *`elaborate`* : construit la hiérarchie et résout les paramètres
3. *`read_sdc`* : applique l'intention de timing
4. *Checks* : détectent les références non résolues et contraintes incomplètes *avant l'optimisation*
5. *`syn_generic`* : transforme le RTL en logique générique et simplifie les expressions
6. *`syn_map`* : choisit des cellules disponibles dans la Liberty
7. *`syn_opt`* : améliore timing, aire et règles électriques selon l'effort demandé
8. *Rapports* : qualifient le résultat
9. *Exports* : alimentent Innovus

\
*Inconvénients de procéder ainsi:*
- Chemins relatifs en dur $->$ peu portable, source d'erreur.
- Pas de gestion d'erreur (si une étape échoue, Genus continue).
- Pas de rapports (pas de report_timing.rpt, etc.)
- Pas de répoertoire de travail avec des sorties bien rangées.

\
*Conclusion* : C'est une #rouge("mauvaise méthode"). 
#align(center, [$arrow.b $])

\
Contrairement à la simulation, la synthèse nécessite un peu plus de scripts. En effet, il y a davantage d'étapes : le lien avec le PDK, les différents fichiers `.f`, `.sdc` etc. et tout ceci nésessite des scripts pour être fait correctement. 

Le language de script qui va nous permettre d'échanger avec genus est le `.tcl`. On va donc écrire un fichier permettant de configurer genus : 

#showybox(
  title: [*Note* :],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il faut bien avoir en tête que le fichier tcl n'est pas executé en tant que tel, c'est genus qui est executée et qui l'utilise comme fichier de configuration. Ainsi, le script ne peut pas charger des variables d'environnement globale et des chemins configurables. Il est alors d'usage, pour des question de répétabilité de charger ces chemins *en amont* dans un script `.sh`. Et les utiliser dans le script par la suite (ce qui est fait dans le niveau 2)
]

Le soucis c'est que le tcl ne peut pas charger des variables d'envirronnement globale. Afin de corretement faire le lien entre tous les fichiers d'entrée on défini un fichier d'environnement (.env) qui va nous permettre de dire ou est ou d'un coup.

Première étape donc : sourcer le fichier :

```bash
source fichier.env
```

#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : source $!=$ bash - 2/2] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Si on fait `export PATH_CUSTOM=/le/chemin` dans un programme shell et qu'on l'exectute avec la commande *bash* la variable PATH_CUSTOM sera détruite à la fin de l'execution du programme. Si on veut pouvoir s'en servir par la suite il faut donc que ça reste et pour cela on utilise la commande *source*
]

#showybox(
  title: [*Note* :],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il y a d'autres façon de faire que cette architecture
]

== Niveau 2 : script réutilisable "simple"

Même si le script du niveau 2 est relativement simple il comporte des appels à plusieurs fichier et leurs rôle doit être correctement compris. Voici donc l'architecture des appels imbriqués à cette étape.

#figure(
[#showybox(
title: "Terminal", 
[Terminal d'ou est lancé la commande genus. Les outils cadence sont sourcée (*xrun, genus, innovus* par exemple sont accessibles).],
frame: (
    border-color: black,
    title-color: black.lighten(30%),
    body-color: black.lighten(95%),
    footer-color: black.lighten(80%)
  ),
columns(1)[

#showybox(
title-style: (boxed-style: (:)),
title: "run_sym.sh",
[ Le script charge les variables d'environnement utilisés pour la simulation (ex : *\$GENUS_SDC*) et lance une ou plusieurs exectution de genus. Les variables sont accessibles depuis n'importe quel programme dans le script.
#showybox(
title-style: (boxed-style: (:)),
frame: (
  title-color: green.lighten(50%),
  border-color: green,
  body-color: green.lighten(95%)
  ),
title: [#text(fill: black, "Execute genus")],
[Genus utilise le fichier de configuration genus_etape2.tcl 

#colbreak()
#showybox(
title-style: (boxed-style: (:)),
frame: (
  title-color: blue.lighten(50%),
  border-color: blue,
  body-color: blue.lighten(95%)
  ),
title: [#text(fill: black, "genus_etape2.tcl")],
[Scripts générique, réutilisable qui utilise les variables d'envirronnement. Appelle helper.tcl
#colbreak()
#showybox(
title-style: (boxed-style: (:)),
title: "helper.tcl",
[Scripts générique qui défini des fonctions utilitaires pour les scripts tcl]
)
]
)
]
)
]
)
]
)
],
caption: [Imbrication des appels des fonctions du niveau 2 de la synthèse]
)<fig-architecture_etape_2_syn>

\
Détaillons le rôle précis de chaque fichier : 

=== Helper.tcl
Dans le flow numérique, un certain nombre d'opérations seront executées dans *chacun des scripts tcl* comme le renvoie d'erreur, la vérification de l'envirronnement etc. Afin d'éviter de réécrire systématiquement ces fonctions, nous pouvons les définir dans un fichier spécifique qui sera appelé à chaque fois (ici : helper.tcl).

\
Le fichier helpers.tcl regroupe donc les utilitaires du flow. Ce fichier contient des procédures TCL pour gérer les erreurs, les logs, et les rapports. Il vérifie que toutes les variables d'environnement obligatoires sont définies avant de lancer le flow.Cela évite les erreurs cryptiques (ex: `Library not found` à cause d'une variable manquante).

#codly(footer: [*helper.tcl*])
```tcl
# Utilitaires communs au flow Genus du tutoriel.
#
# Les statuts PASS enregistrés ici signifient uniquement que la commande de
# l'étape s'est terminée sans erreur Tcl. Ils ne constituent jamais une preuve
# de fermeture temporelle, de DRC/LVS ou de signoff.


### Vérification que l'enrionnement Cadence est bien chargé ###
proc tutorial_require_env {name} {
    if {![info exists ::env($name)] || [string trim $::env($name)] eq ""} {
        error "variable d'environnement obligatoire absente: $name"
    }
    return $::env($name)
}

### SPECIFIQUE AU FLOW ###
# Convertit une variable d'environnement (ex: GENUS_LIBERTY_TC="lib1:lib2") en une liste TCL utilisable ({lib1 lib2}).
# Gère les espaces et les éléments vides.
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

### Horodatage précis pour les logs (ex: 2026-08-03T14:30:00Z) ###
proc tutorial_now_utc {} {
    return [clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]
}

### Nettoie les chaînes de caractères (ex: messages d'erreur avec des sauts de ligne) pour les rendre lisibles en une seule ligne. ###
proc tutorial_one_line {value} {
    regsub -all {[\r\n\t]+} $value { } value
    return [string trim $value]
}

### Enregistre chaque étape du flow dans un fichier TSV (pour le suivi et le débogage) ###
proc tutorial_record_stage {stage status {detail ""}} {
    set status_file [tutorial_require_env GENUS_STAGE_STATUS]
    set fh [open $status_file a]
    puts $fh "[tutorial_one_line $stage]\t[tutorial_one_line $status]\t[tutorial_now_utc]\t[tutorial_one_line $detail]"
    close $fh
}


### Encapsule une étape du flow avec :
# Gestion d'erreur automatique.
# Logging automatique (via tutorial_record_stage)

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

### Génère automatiquement un rapport (ex: report_timing.rpt) et gère les erreurs

proc tutorial_report {path command} {
    file mkdir [file dirname $path]
    # Genus Ã©tend Tcl avec la redirection Â« commande > fichier Â».
    if {[catch {uplevel #0 "$command > [list $path]"} result]} {
        set fh [open $path w]
        puts $fh "REPORT_STATUS=FAILED"
        puts $fh "COMMAND=[tutorial_one_line $command]"
        puts $fh "ERROR=[tutorial_one_line $result]"
        close $fh
        error "Ã©chec du rapport '$command': $result"
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

```
#TODO("A voir comment on l'intègre")

#codly(footer: [*genus_cadence.tcl*], breakable: true)
```tcl
set_db init_lib_search_path ../lib/
set_db init_hdl_search_path ../rtl/
read_libs slow_vdd1v0_basicCells.lib

read_hdl counter.v
elaborate
read_sdc ../constraints/constraints_top.sdc

set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

syn_generic
syn_map
syn_opt

#reports
report_timing > reports/report_timing.rpt
report_power  > reports/report_power.rpt
report_area   > reports/report_area.rpt
report_qor    > reports/report_qor.rpt



#Outputs
write_hdl > outputs/counter_netlist.v
write_sdc > outputs/counter_sdc.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge  -setuphold split > outputs/delays.sdf

```


=== Script tcl minimal 

#TODO("changer le nom")

#TODO("Une action = une erreur en cas d'echec (sinon on se perd) ")

C'est le fichier de configuration renseigné à genus. Il utilise des fonctions définies dans helper.tcl pour réaliser chacune des étapes du flow. Afin de garantir que le flow est réutilisable dans d'autres contexte, les chemins spécifiques sont passés en paramètre dans des variables d'environnement.

#codly(footer: [*genus_minimal.tcl*])
```tcl
# Synthèe Genus minimale en vue typique.
# Le wrapper fournit les chemins par variables d'environnement.

### récupération et chargement de helper.tcl dans le même répertoire ###
set flow_dir [file dirname [file normalize [info script]]]
source [file join $flow_dir helpers.tcl]

proc tutorial_minimal_main {} {

    # Initialisation des variables d'environnement a l'aide de la fonction définie dans le helper.tcl
    set root       [tutorial_require_env TUTORIAL_ROOT]
    set run_dir    [tutorial_require_env GENUS_RUN_DIR]
    set top        [tutorial_require_env GENUS_TOP_MODULE]
    set filelist   [tutorial_require_env GENUS_FILELIST]
    set sdc        [tutorial_require_env GENUS_SDC]
    set report_dir [file join $run_dir reports]
    set output_dir [file join $run_dir outputs]

    file mkdir $report_dir
    file mkdir $output_dir

    ###### Configuration de Genus ######
    # Utilisation de SystemVerilog
    set_db hdl_language sv
    # Définit les librairies à utiliser pour la synthèse
    set_db library [tutorial_env_list GENUS_LIBERTY_TC]
    # Ajoute $root (défini plus haut) au chemin de recherche des fichiers HDL
    set_db init_hdl_search_path [list $root]
    cd $root

    ###### Etapes du flow ######
    # Note : Chaque étape est encapsulée dans tutorial_run_stage pour :
    # - Gérer les erreurs.
    # - Enregistrer le statut (RUNNING/PASS/FAIL).
    # - Générer des rapports.

    # Lecture des fichiers RTL depuis $filelist
    tutorial_run_stage read_rtl {
        read_hdl -sv -f $filelist
    }

    #Élaboration
    tutorial_run_stage elaborate {
        elaborate $top
    }

    # Charge le fichier SDC
    tutorial_run_stage read_constraints {
        read_sdc $sdc
    }

    #Vérifie la structure du design (pas de latches, pas de boucles combinatoires) et les contraintes SDC
    tutorial_run_stage checks {
        tutorial_report [file join $report_dir check_design.rpt] \
            {check_design -all}
        tutorial_report [file join $report_dir check_timing_intent.rpt] \
            {check_timing_intent -verbose}
    }

    # Synthèse logique : RTL vers Netlist (optimisation incluse).
    tutorial_run_stage synthesis {
        syn_generic
        syn_map
        syn_opt
    }
    
    # Génère des rapports de timing, d'aire, et de qualité des résultats (QOR).
    tutorial_run_stage reports {
        tutorial_report [file join $report_dir report_timing.rpt] \
            {report_timing -max_paths 20}
        tutorial_report [file join $report_dir report_area.rpt] \
            {report_area}
        tutorial_report [file join $report_dir report_qor.rpt] \
            {report_qor}
    }


    #### Export final des Résultats #####
    set mapped_v   [file join $output_dir ${top}.mapped.v]
    set mapped_sdc [file join $output_dir ${top}.mapped.sdc]
    tutorial_run_stage export {
        write_hdl > $mapped_v
        write_sdc > $mapped_sdc
        tutorial_assert_nonempty $mapped_v
        tutorial_assert_nonempty $mapped_sdc
    }

    tutorial_write_final_status PASS \
        "niveau basic terminÃ©; netlist et SDC disponibles"
    tutorial_record_stage final_status PASS
}

set rc [catch {tutorial_minimal_main} message options]
if {$rc != 0} {
    catch {tutorial_write_final_status FAIL [tutorial_one_line $message]}
    puts stderr "GENUS_TUTORIAL_ERROR: $message"
    if {[dict exists $options -errorinfo]} {
        puts stderr [dict get $options -errorinfo]
    }
    exit 20
}

puts "GENUS_TUTORIAL_STATUS: BASIC_FLOW_COMPLETED"
exit 0
```


== Comprendre les rapports

Une erreur avant elaborate concerne souvent les fichiers ou la syntaxe. Une référence non résolue après élaboration concerne la hiérarchie. Un timing mauvais après mapping concerne plutôt contraintes, architecture ou choix de cellules.

Normalement, si les scripts sont bien faits, il n'y a pas besoin de regarder dans le détails les rapports car la moindre erreur sera remontée dans le script. Il est tout de même essentiel de bien comprendre ce qui se passe donc voici les sorties classiques:

=== Fichier : final_status.rpt

C'est la première chose à regarder. C'est le verdic final de la synthèse. Si on a quelque chose de ce type c'est que tout devrait être bon : 

```sh
GENUS_STATUS=PASS
FLOW_EXECUTION_STATUS=FLOW_COMPLETED
ARTIFACT_STATUS=PASS
```
=== Fichier : report_timing.rpt - le timing
Comme son nom l'indique c'est dans ce fichier qu'on retrouve les informations relatives au timing. C'est ici que l'on voit si le timing respecte les contraintes définies dans le sdc. Concept essentiel à comprendre à cette étape : la *slack*. Elle est définie comme suit : $#rect(stroke: red,[ slack = t_requis - t_arrivee])$

Une slack *négative* indique qu'on est en retard $->$ #rouge("violation des contraintes")

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
  title: [#text(weight: "bold", fill: black, [Verdict correct] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Le code retour de l'outil, l'élaboration, les contraintes, le timing, les design rules et les exports sont des *contrôles distincts*, Il ne faut donc *pas* les résumer par un seul message « terminé ».
]

=== Fichier : report_area.rpt et report_qor.rpt - Aire du design
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
Genus essayera de réduire l'aire, mais ne sacrifiera pas le timing au-delà de la marge définie par syn_timing_slack_margin

]

== Wrapper réutilisable

*Fichier* : `run_genus.sh`

---
== Méthodologie avancée

=== Passer du TC au MMMC

1. Qu’est-ce que Setup et Hold ?
📌 Setup Time (Temps d’Établissement)

Définition : Temps minimum avant le front montant du clock pendant lequel la donnée doit être stable pour être correctement capturée par un registre.
Analogie : Comme un train qui doit arriver à la gare avant le départ (sinon, il rate le train).
Violation : Si la donnée arrive trop tard → Échec de capture (métastabilité).
Corner utilisé : Worst-Case (WC) → Délais maximaux (pire cas pour le setup).
Clock période = 10ns.
Setup time = 1ns.
La donnée doit être stable 1ns AVANT le front montant du clock



Hold Time (Temps de Maintien)

Définition : Temps minimum après le front montant du clock pendant lequel la donnée doit rester stable pour éviter la métastabilité.
Analogie : Comme un train qui doit rester à quai après le départ (sinon, il bloque le prochain train).
Violation : Si la donnée change trop tôt → Échec de maintien (valeur instable).
Corner utilisé : Best-Case (BC) → Délais minimaux (meilleur cas pour le hold).
Exemple :

Clock période = 10ns.
Hold time = 0.5ns.
La donnée doit rester stable 0.5ns APRÈS le front montant du clock.

mmmc.tcl --> 
mais ici pour comparer on regarde toutes les vues : 
```tcl
  set_analysis_view \
      -setup {tutorial_wc_view tutorial_tc_view tutorial_bc_view} \
      -hold  {tutorial_wc_view tutorial_tc_view tutorial_bc_view}

  foreach view {tutorial_bc_view tutorial_tc_view tutorial_wc_view} {
      tutorial_report [file join $report_dir timing report_timing_${view}.rpt] \
          {report_timing -view $view -max_paths 20}
  }
```

Mais pour la production il faut générer juste ce qu'il faut : 
```tcl
  set_analysis_view \
    -setup tutorial_wc_view \  # WC pour le setup
    -hold  tutorial_bc_view      # BC pour le hold

```


Génère SEULEMENT les rapports pour les vues actives :


```tcl
  # Rapport pour WC (setup)
  tutorial_report [file join $report_dir timing report_timing_wc_setup.rpt] \
      {report_timing -view tutorial_wc_view -max_paths 20}

  # Rapport pour BC (hold)
  tutorial_report [file join $report_dir timing report_timing_bc_hold.rpt] \
      {report_timing -view tutorial_bc_view -max_paths 20 -analysis_type hold}

  # Rapport pour TC (optionnel, pour la vérification nominale)
  tutorial_report [file join $report_dir timing report_timing_tc.rpt] \
      {report_timing -view tutorial_tc_view -max_paths 20}
```

Mieux en pratique parceque trop de rapports = on comprend rien et c'est inutile d'avoir le tc pour le setup .... 


Une analyse *MMMC* sépare :
- Les *library sets* Liberty
- Les *corners RC*
- Les *delay corners* (associent timing et interconnexions)
- Les *modes de contraintes*
- Les *analysis views* pour setup et hold

*Structure MMMC simplifiée* :

```tcl
create_library_set -name LIB_BC -timing [list $LIBERTY_BC]
create_library_set -name LIB_TC -timing [list $LIBERTY_TC]
create_library_set -name LIB_WC -timing [list $LIBERTY_WC]

create_rc_corner -name RC_BC -qx_tech_file $QRC_BC
create_rc_corner -name RC_TC -qx_tech_file $QRC_TC
create_rc_corner -name RC_WC -qx_tech_file $QRC_WC

create_delay_corner -name DC_BC \
    -library_set LIB_BC -rc_corner RC_BC
create_delay_corner -name DC_TC \
    -library_set LIB_TC -rc_corner RC_TC
create_delay_corner -name DC_WC \
    -library_set LIB_WC -rc_corner RC_WC

create_constraint_mode -name FUNC -sdc_files [list $SDC]

create_analysis_view -name VIEW_BC \
    -constraint_mode FUNC -delay_corner DC_BC
create_analysis_view -name VIEW_TC \
    -constraint_mode FUNC -delay_corner DC_TC
create_analysis_view -name VIEW_WC \
    -constraint_mode FUNC -delay_corner DC_WC

set_analysis_view \
    -setup [list VIEW_TC VIEW_WC] \
    -hold  [list VIEW_TC VIEW_BC]
```

> *⚠️ Important*
> Le choix exact des vues *setup* et *hold* appartient à la méthodologie du PDK.
> *Ne pas déduire ce choix uniquement du nom « best » ou « worst »*.

=== Données physiques

Pour une synthèse *physical-aware* :

```tcl
read_mmmc flow_mmmc.tcl
read_physical -lef [list $TECH_LEF $STDCELL_LEF]
read_hdl -sv -f syn/rtl.f
elaborate $TOP
init_design
```

> Cette estimation améliore la corrélation avec Innovus, mais *ne remplace pas* :
> - Placement
> - CTS (Clock Tree Synthesis)
> - Routage
> - Extraction réelle

=== Design séquentiel

Pour un additionneur pipeliné, le SDC doit définir la *vraie clock* :

```tcl
create_clock -name CLK -period 2.000 [get_ports clk_i]
set_clock_uncertainty 0.100 [get_clocks CLK]
set_input_delay  0.200 -clock CLK \
    [remove_from_collection [all_inputs] [get_ports clk_i]]
set_output_delay 0.200 -clock CLK [all_outputs]
set_false_path -from [get_ports rst_ni]
```

> *À vérifier* :
> L'exception de reset doit correspondre à *l'architecture* et à la *politique du laboratoire*.
> Vérifier les objets ciblés avec les rapports de contraintes.

---

---
== Handoff vers Innovus

#TODO("Comprendre les histoires de db (vers p 130 ou p. 144)")

Le *package minimal* contient :

1. La *netlist mappée* (non vide)
2. Le *SDC exporté* (non vide)
3. Le *nom exact du top*
4. Les *mêmes familles Liberty* utilisées par la configuration Innovus
5. Les *rapports* de checks, timing et QoR
6. Une *liste explicite* des violations ou hypothèses restantes

> *❌ Diagnostic*
> 


#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : Pas la charue avant les boeufs] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  *Ne pas lancer Innovus* si :
  - La netlist contient des *références non résolues*
  - Le SDC n'a pas produit les *clocks et contraintes attendues*
  - Le choix des *corners est inconnu* (un timing positif au *seul corner typique* reste un résultat *typique*, pas une preuve MMMC)
]


#TODO("Une étape sans objet, comme le CTS du full adder, doit être marquée NOT_APPLICABLE.")

= Etape 3 : Implémentation - Innovus 

commade legacy vs stylus : lageacy est ce qui avait avant mais le nouiveau truc (plus homogène avec la synthese) est stylus qu'il vaut mieux utiliser

DEF : 
Le DEF généré lors de la synthèse Genus (floorplan.def) n'est pas un vrai DEF de PnR complet. C'est un DEF de synthèse qui contient :

    Les dimensions du die/core prédéfinies
    Peut-être un placement abstrait des cellules optimisé au niveau synthèse
    Des io_pin placés
    Pas de routage détaillé

C'est essentiellement un guide pour le PnR, pas le design complet

#TODO("Mettre en forme +  rajouter dans synthse .def")
From cadence 

Input Files Definitions and Uses
Gate level Netlist (.v) This file, which contains the logic connectivity of all the cells, is exported
from the synthesis tool.
Design constraints (.sdc) The .sdc file contains all the timing constraints that the tool must meet and
fix, if there are violations in the design.
Liberty (.lib) The .lib file is a timing library that contains logical information (setup time,
hold time, cell delay, etc.) of all the standard cells/macros.
Library exchange format (.lef) The LEF file is a physical library that contains physical information (cell/pin
name, cell/pin dimensions, blockages, etc.) of the standard cells/macros.
The LEF file is extracted from the abstract view of a cell.
Technology LEF file (.lef) The technology LEF file contains the metal layers, vias, and their name and
preferred directions for routing. It also has design rules for each metal
layers.
Extraction Technology File
(.qrctech)
The .qrctech file contains the values of capacitance and resistance per unit
length of each metal layer. These RC parasitics are used to calculate net
delays during extraction.


Pour lancer innovus avec le fichier : 

```bash
# comme pour genus 
innovus -files runPnR.tcl
# Pour ouvrir la gui après coup
innovus -stylus &
```

#TODO(".;log vs .logv v pour verbose")

commande innovis : 
 Pour lire du GDSII (binaire)read_stream mon_design.gds -layer_map gds_layer_map.txt
 Pour lire un DEF (texte)read_def mon_design.def

avec ce fichier 
#codly(footer: [*runPnR.tcl*], breakable: true)
```tcl
#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Thu Oct 22 09:51:30 2020                
#                                                     
#######################################################

#@(#)CDS: Innovus v20.10-p004_1 (64bit) 05/07/2020 20:02 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: NanoRoute 20.10-p004_1 NR200413-0234/20_10-UB (database version 18.20.505) {superthreading v1.69}
#@(#)CDS: AAE 20.10-p005 (64bit) 05/07/2020 (Linux 2.6.32-431.11.2.el6.x86_64)
#@(#)CDS: CTE 20.10-p005_1 () Apr 14 2020 09:14:28 ( )
#@(#)CDS: SYNTECH 20.10-b004_1 () Mar 12 2020 22:18:21 ( )
#@(#)CDS: CPE v20.10-p006
#@(#)CDS: IQuantus/TQuantus 19.1.3-s155 (64bit) Sun Nov 3 18:26:52 PST 2019 (Linux 2.6.32-431.11.2.el6.x86_64)

set_db init_netlist_files ../physical_design/counter_netlist.v
set_db init_lef_files {../lef/gsclib045_tech.lef ../lef/gsclib045_macro.lef}
set_db init_power_nets VDD
set_db init_ground_nets VSS
set_db init_mmmc_files  counter.view
read_mmmc counter.view
read_physical -lef {../lef/gsclib045_tech.lef ../lef/gsclib045_macro.lef}
read_netlist ../physical_design/counter_netlist.v -top counter
init_design


connect_global_net VDD -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS -type pg_pin -pin_base_name VSS -inst_base_name *

#Create Floorplan
create_floorplan -core_margins_by die -site CoreSite -core_density_size 1 0.7 2.5 2.5 2.5 2.5

#Pin Assignment
read_io_file pins.io

#Power Planning
set_db add_rings_skip_shared_inner_ring none ; set_db add_rings_avoid_short 1 ; set_db add_rings_ignore_rows 0 ; set_db add_rings_extend_over_row 0

#Add Rings
add_rings -type core_rings -jog_distance 0.6 -threshold 0.6 -nets {VDD VSS} -follow core -layer {bottom Metal11 top Metal11 right Metal10 left Metal10} -width 0.7 -spacing .4 -offset 0.6

#Add Stripes
add_stripes -block_ring_top_layer_limit Metal11 -max_same_layer_jog_length 0.44 -pad_core_ring_bottom_layer_limit Metal9 -set_to_set_distance 5 -pad_core_ring_top_layer_limit Metal11 -spacing 0.4 -merge_stripes_value 0.6 -layer Metal10 -block_ring_bottom_layer_limit Metal9 -width 0.3 -nets {VDD VSS} 

# Create Power Rails with Special Route
route_special -connect core_pin -layer_change_range { Metal1(1) Metal11(11) } -block_pin_target nearest_target -core_pin_target first_after_row_end -allow_jogging 1 -crossover_via_layer_range { Metal1(1) Metal11(11) } -nets { VDD VSS } -allow_layer_change 1 -target_via_layer_range { Metal1(1) Metal11(11) }
# Read the Scan DEF
read_def counter.scandef
set_db reorder_scan_comp_logic true
# Run Placement Optimization
place_opt_design
# Save the Database
write_db placeOpt 
# Create a Clock Tree Spec and run CTS
create_clock_tree_spec
clock_opt_design

# Save the database
write_db postCTSopt
# Run Detail Routing
set_db route_design_with_timing_driven 1
set_db route_design_with_si_driven 1
set_db design_top_routing_layer Metal11
set_db design_bottom_routing_layer Metal1
set_db route_design_detail_end_iteration 0
set_db route_design_with_timing_driven true
set_db route_design_with_si_driven true
route_design -global_detail
reset_parasitics
extract_rc
```

Explication claude : La database Innovus (fichier .db ou .inn) est un fichier binaire propriétaire qui stocke l'état complet de ton design : netlist, placement, routage, couches, connexions, etc. C'est le format interne d'Innovus.Elle n'est PAS créée lors de la synthèse
`init_design` : Ici, Innovus crée sa database en mémoire. Les write_db sauvegardent des checkpoints (.db) pour reprendre plus tard.


la version v2 utilise LEGACY et : Ton script actuel est un bon test pour vérifier que :

la netlist peut être importée ;
les LEF sont lisibles ;
un floorplan peut être construit ;
les cellules peuvent être placées ;
le routeur peut produire une géométrie.

Mais ce n’est pas encore un flow permettant d’obtenir une puce fonctionnelle, signoffée ou fabricable

Netlist
  ↓
Import
  ↓
Floorplan
  ↓
Placement
  ↓
Routage des signaux
  ↓
DEF


RTL vérifié
  ↓
Synthèse + DFT
  ↓
Équivalence logique
  ↓
Import MMMC
  ↓
Floorplan / IO / macros
  ↓
Réseau d’alimentation
  ↓
Placement et optimisation pré-CTS
  ↓
Clock Tree Synthesis
  ↓
Optimisation post-CTS
  ↓
Routage
  ↓
Extraction RC
  ↓
Optimisation post-route
  ↓
Finition physique
  ↓
STA / IR / EM / DRC / LVS / antenne
  ↓
GDS/OASIS
  ↓
Packaging et test

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


