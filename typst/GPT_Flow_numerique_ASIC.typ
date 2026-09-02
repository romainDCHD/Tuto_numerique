#import "lib.typ": *

#show: template_R.with(
  title: "Prise en main du flow numérique ASIC",
  authors: (
    ("Romain DUCHADEAU", "IP2I / CNRS", "r.duchadeau@ip2i.in2p3.fr"),
    // ("Sabra KARIM", "IP2I / CNRS", "k.sabra@ip2i.in2p3.fr"),
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

Pour illustrer les notions vues dans ce tutoriel, nous allons passer ensemble le flow numérique complet (du rtl jusqu'au layout) sur un bloc d'additionneur pipeliné appelé "adder_pipeline" 

== Pourquoi l'exemple _adder_pipeline_
Un des blocs les plus simples en microélectronique numérique est le full adder. Il possède huit combinaisons et aucune horloge (on parle alors de bloc purement *combinatoire*) ce qui en fait un bon candidate pour commencer. Cependant, comme il ne possède pas d'horloge, nous passerions à côté de beaucoup de notions importantes (le timing et l'horloge étant souvent le point critique d'un circuit numérique). C'est pourquoi nous allons plutôt dérouler le flow sur un bloc d'additionneur pipeliné qui ajoute des registres, une clock, un reset et un signal de validité. Il permet, sans rajouter beaucoup de complexité, d'étudier des problématiques temporelles comme la latence, setup, hold, MMMC, CTS etc...


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
[Racine principale du git contenant le pdf et README. #rouge("Toujours lancer les scripts depuis ce dossier")],
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
[Contient les fichiers de config liés au pdk / Cadence. Sert à faire le lien entre les scripts génériques et la config propre au labo.]
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
  Pour des raisons de répétabilité, les scripts ne seront jamais écrits avec des PATH relatifs mais seront toujours écrits en utilisant des PATH *absolus* chargés à partir de fichiers spécifiques. 

  \
  La logique ici est que tous les fichiers spécifiques au dut soient dans le dossier _dut_ tandis que les scripts dans _flow_ sont *génériques* et utilisent des PATH ou variables définies dans _confi_ et _dut_.
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
  [Rapport], [`.sh`], [Rapport de sortie de la simulation (balises PASS ou FAIL)],
)],
caption: [Entrées sorties de la phase de simulation (#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]))]
)<tab_elements_simu>

\
On peut noter qu'il n'y a pas de sortie à proprement parler pour la simulation car la simulation ne produit pas de fichier, elle sert simplement à vérifier le bon fonctionnement de note module. Notre "sortie" est donc le verdict des scripts.

// -------------------  SOUS - SECTION ------------------- 
==  Niveau 1 : Commande Xcelium minimale
Dans ce niveau, nous nous intéressons au module full_adder_comb.
Module très simple et purement combinatoire (sans clock). La première étape consiste à savoir ce qu'on veut que le module fasse. Cette étape passe souvent par écrire une machine à état ou une table de vérité pour être au clair sur les fonctions *précises* du module. 
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

\* Les deux valeurs correspondent à:
- 1ns  = unité de temps (si on met un délais de "#10" dans le module cela signifiera alors 10 *ns*)
- 1ps  = précision temporelle / pas du simulateur (le simulateur peut distinguer les événements avec une résolution de 1 ps)


*Note* : Le DUT ne contient aucun délai, bloc `initial` ou appel système car c'est un bloc asynchrone (#underline("ie.") purement combinatoire).

// -------------------  SOUS - SECTION -------------------
=== Testbench du full adder comb
De la même manière que un module, un testbench est aussi un module RTL qui comprend le module a tester ainsi que les entrée sorties commandées permettant de faire le test (exactement comme en analogique). Le rôle du testbench est également de faire ressortir des #rouge("marqueurs") pour vérifier le bon fonctionnement comportemental de note module / DUT. 


#showybox(
  title: "Note : Retrouver les codes sources",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Pour des raisons de lisibilité, les codes abordés dans ce tuto se situent en annexe de ce document.
]

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
  Un exemple de code de retour peut être :
  ```sv
  $fatal(1,
    "\033[31m[ERREUR]\033[0m : Echec vecteur %03b : obtenu cout,sum=%b%b, attendu=%b%b",
    {a_i, b_i, cin_i}, cout_o, sum_o,
    cout_attendue, sum_attendue);
    ```

  On notera la balise `\033[31m[ERREUR]\033[0m ` qui permet d'écrire en rouge dans le terminal pour des questions de lisibilité et la balise `\033[32m[TEST_PASS]\033[0m` qui permet d'écrire en vert.
]


=== La simulation - Niveau 1 : commande minimale 
Une fois le RTL du full adder et de son testbench écrits (et qu'on a donc une description comportementale de nos modules), il faut effectuer la simulation. Pour ce faire on execute (après avoir chargé Cadence et les outils) :


```bash
xrun -64bit -timescale 1ns/1ps \
   dut/rtl/full_adder_comb.sv \
   dut/tb/tb_full_adder_comb.sv \
   -top tb_full_adder_comb
```

\
* Explication de la commande* : 
- `-64bit` utilise l'exécutable 64 bits.
- `-sv` active SystemVerilog.
- `-timescale` fixe l'unité et la précision par défaut si un module n'a rien de spécifié (sinon utilisation du timescale du module).
- `-f` lit une filelist.
- `-top` choisit le top élaboré.

*Autres options utiles* :
- `-access +rwc` donne les droits de prober tous les signaux dans la hiérarchie du design.
- `-gui` ouvre la vue graphique

\
On s'attend a voir dans la sortie:
```sh
xcelium> run
TEST_PASS: full_adder_comb
```

On peut voir en tapant `ls` que trois choses sont apparues :
- *Dossier xcelium.d* :	Base de compilation et d'élaboration de Xcelium. Elle contient notamment le snapshot simulable et les données internes utilisées par Xrun.
- *xrun.log*	: Journal texte de la compilation, de l'élaboration et de la simulation.
- *xrun.history* :	Historique interne des invocations Xrun, utilisé par les fonctions d'historique et de rejeu de commandes.

Dans notre cas nous n'en avons plus besoin on peut donc les supprimer: 
```bash
rm -rf x*
```
$->$ Le full adder purement combinatoire fonctionne. On va pouvoir l'utiliser dans notre module de full adder pipeliné! Passons au niveau 2.


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

// -------------------  SOUS - SECTION ------------------- 
== Niveau 2 : Utiliser les filelists
Pour ce niveau et #rouge("dans toute la suite du tutoriel"), nous nous intéresserons au module adder_pipeline. Autrement dit, a partir de maintenant nous laissons de côté la sous-brique full_adder_comb pour ne s'intéresser qu'à l'adder_pipeline


Le module adder_pipeline contient le sous-module full_adder_comb. Pour la simulation on peut executer xrun individuellement pour chaque DUT et chaque testbench (comme avec le niveau 1) mais une bonne pratique si on a beaucoup de fichiers RTL est d'utiliser une filelist (extension en $#rect(fill: colors.code-bg, [.f])$) pour définir *dans quel ordre* procéder à l'élaboration et qu'on ai pas de problèmes de dépendances non résolues à cause d'un mauvais ordre. Par ailleurs, ces filelists seront #rouge("nécessaires pour les étapes suivantes") donc autant les implémenter dès maintenant.


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

Voici ce que contient la filelist rtl.f : 

#codly(footer: [*rtl.f*], breakable: false)
```txt
dut/rtl/full_adder_comb.sv
dut/rtl/adder_pipeline.sv
```
Pour le testbench: 

#codly(footer: [*tb.f*], breakable: false)
```txt
dut/tb/tb_adder_pipeline.sv
```

Une fois les filelists écrites on peut lancer (depuis la racine du dossier toujours):

#codly(stroke: 1pt + red)
```bash
xrun -64bit -sv -timescale 1ns/1ps \
  -f dut/filelists/rtl.f \
  -f dut/filelists/tb.f \
  -top tb_adder_pipeline \
```
#codly(stroke: 1pt + gray)
\
* Explication de la commande* : Ajout de `-f` pour lui dire de lire une filelist et pas un fichier .sv

\
La sortie devrait être identique qu'avec la commande minimale précédente.

De la même manière, Xcelium va mettre ses fichiers dans le répertoire d'execution, si il n'y a pas d'erreurs, nous n'en avons plus besoin: 
```bash
rm -rf x*
```

== Niveau 3 : Wrapper réutilisable
Comme déjà mensionné auparavent, en pratique, on ne va pas lancer cette commande à la main car on ne sait pas vraiment ou Xcelium stocke ses fichiers de simu, les logs, les résulats etc... Dans un flow numérique tout peut être une source d'erreur et stipuler explicitement ou vont chaque fichier peut faire gagner enormément de temps et permet d'être correctement organisé. C'est pourquoi on va privilégier l'utilisation d'un wrapper qui va tout automatiser pour nous.


Le wrapper suivant crée un dossier de résultat unique, isole la bibliothèque Xcelium, conserve le code retour et vérifie le marqueur final.

#TODO("mettre le script en annexe")

Pour lancer le script : 

#codly(stroke: 1pt + red)
```bash
bash flow/01_simulation/run_sim.sh adder_pipeline 
```
#codly(stroke: 1pt + gray)

Avec l'interface graphique : 

```bash
bash flow/01_simulation/run_sim.sh adder_pipeline --gui
```

\
*Fonctionnalités clés du script :*
- Utilise l'argument pour savoir quel module simuler (ici l'adder_pipeline). Si on veut simuler un autre module il suffira de l'intégrer au code _run_sim.sh_ de la même manière que l'adder_pipeline. Procéder ainsi permet d'éviter de s'emmêler entre les paths, d'avoir des arguments à ralonge ect... Donc, on rajoute les bons paths dans le code et on appelle simplement le bon module avec un mot clé.
- Crée un répertoire de run propre dans : rundir/01_simulation/adder_pipeline/
- Si existant, supprime le contenu du run précédent afin d'éviter l'utilisation d'anciens résultats par exemple.
- Crée une base de formes d'onde SHM consultables par SimVision dans: waves.shm/ et y enregistre les signaux du testbench et des sous-modules.
- Redirige les fichiers générés par Xcelium vers le répertoire du run.
- Récupère le code de retour de Xrun pour détecter si c'est une erreur de compilation, d'élaboration ou de simulation.

\
Une fois la simulation terminée, on va pouvoir retrouver les coubes simulées à l'aide de la commande:

```bash
simvision waves.shm
```


\
#showybox(
  title: "Note : Modularité et simplicité",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Le script est pensé pour être modulable et réutilisable dans d'autres contextes avec d'autres DUT. Le script est volontairement gardé simple pour des raisons de lisibilité mais on peut bien entendu l'améliorer. Voici quelques points d'amélioration possible :
  #rect(fill: white, radius: 5pt,[
    - Seul le design adder_pipeline est accepté.
  - Le run précédent est supprimé à chaque lancement.
  - Le script ne conserve pas encore plusieurs simulations datées.
  - Les options Xrun sont fixées dans le script.
  - Il n'exécute pas encore une liste de tests ou une régression complète.
  ])  
]

#showybox(
  title: "Note : Interface graphique",
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  La philosophie c'est sans interface sauf si bug.
]

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
\
Maintenant que nous avons simulés notre DUT, nous pouvons passer à synthèse.

// ******************** SECTION ******************** 
// *************************************************
= Etape 2 : Synthèse logique - Outil Genus
La deuxième étape de ce parcours est donc la synthèse. C'est à cette étape que le lien avec la technologie cible va s'effectuer. Cette étape est plus complexe que la précédente car il va falloir correctement établir le lien avec le pdk et qu'il y a davantage de paramètres à prendre en compte.

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
  [RTL], [`adder_pipeline.sv`], [Description logique synthétisable],
  [Filelist], [`rtl.f`], [Ordre et chemins des sources],
  [Contraintes], [`constraints.sdc`], [Clocks, délais d'E/S et exceptions],
  [Liberty], [`stdcells_tc.lib`], [Fonctions, arcs, délais et puissance],
  [Environnement], [`conf_ihp130.env`], [Chemin absolu des fichiers ],
  [Netlist mappée], [`adder_pipeline.mapped.v`], [Cellules choisies],
  [SDC exporté], [`adder_pipeline.mapped.sdc`], [Contraintes transmises],
  [Rapports], [`report_timing.rpt`, `report_area.rpt`, `report_qor.rpt`], [Preuves à examiner],
)],
caption: [#text(fill: green, [*entrées*]),  #text(fill: orange, [*sorties*]) de la minimales de la synthèse logique]
)<tab_elements_synthese>

*Note :* En plus de ces sorties, la synthèse peut également générerun fichier _.mmmc_ (nécessaire par la suite pour le PnR).
\
On ne va pas revenir sur ce que sont les fichiers `.sv` et `.f` mais voici une rapide description des autres entrées :

\
- *Fichier SDC (Synopsys Design Constraint):* Le fichier qui va définir les contraintes de timing à respecter pour notre design. 

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

- *Fichiers .lib (liberty)* : Ce sont les fichiers du PDK qui définissent les caractéristiques des cellules de la technologie cible. Ces fichiers répertorient les temps de passage dans chaque cellule. Il existe 3 types de liberty:
 
 -- tc ou tt pour typical (#underline("ie.") le temps moyen de passage dans la cellule)
 
 -- wc ou ss pour worst case / slow slow (temps le plus lent) 

 -- bc ou ff pour best case / fast fast (temps le plus rapide) 

== Niveau 1 : Commande et Tcl minimal
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/02_synthesis/01_typical_minimal/])

=== L'appel direct $->$ mauvaise idée
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
\ *Note* : Ce code est donné à tire d'exemple. L'appel direct à genus ne fonctionne pas en l'état (mauvais chemin etc.)

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
  On peut voir sur l'appel direct les #rouge("étapes clés indispensables") pour réaliser la synthèse. Evidemment, beaucoup de paramètres supplémentaires peut être ajoutés pour affiner la synthèse mais l'essentiel est là. 

  \
  Ici, nous avons un DUT simple et donc nous pouvons *regrouper* les étapes de la synthèse en un seul fichier. Cependant, il est courant de *séparer* les différentes étapes de la synthèse (syn_generic, syn_map, syn_opt) en trois fichiers pour les optimiser un par un.
]

=== Script synthèse minimal


Contrairement à la simulation, la synthèse nécessite un peu plus de scripts car genus a besoin d'être configuré pour conrrectement fonctionner. En effet, il y a davantage d'étapes : le lien avec le PDK, les différents fichiers `.f`, `.sdc` etc. et tout ceci nésessite des scripts pour être fait correctement et dans le bon ordre. 

Le language de script qui va nous permettre de configurer genus est le `.tcl`. C'est dans ce fichier qu'on va renseigner ce que genus dois faire et dans quel ordre. Pour lancer genus en utilisant le fichier `.tcl` de configuration la commande minimale est :

```bash
genus -file flow/02_synthesis/01_typical_minimal/genus_minimal.tcl
```

On devrait avoir une sortie proche de : 
```sh
can't read "::env(TUTORIAL_ROOT)": no such element in array
Encountered problems processing file: flow/02_synthesis/01_typical_minimal/genus_minimal.tcl
```

*Patatra* ! Genus ne reconnais pas les chemin des fichiers. C'est #text(fill: green, [*normal*]). Quand on regarde le script *run_syn_minimal.sh* on peut voir que l'appel a genus utilise des PATH avec des variables d'environnement : 
#codly(highlights: (
  (line: 2, start: 14, end: 27, fill:red),))
```bash
genus -no_gui \
     -files "$TUTORIAL_ROOT/flow/02_synthesis/01_typical_minimal/genus_minimal.tcl" \
     -log "$GENUS_RUN_DIR/genus"
```

Nous aurions pu définir les chemins en dur dans les scripts mais pour des raisons de répétabilité et modularité des scripts il est préférable d'utiliser des variables d'environnement génériques que l'on vient charger en fonction du DUT dont on veut faire la synthèse. Dans cet exemple, à la place de devoir remettre à jours le nom du DUT (source d'erreur et pénible à faire) à chaque fois qu'on change de dut on va utiliser un fichier externe : design.env (dans le répertoire dut car spécifique) qui va definir quelles variables et fichiers utiliser. Ainsi, quand on veut changer de dut, il nous suffit simplement de changer de design.env!

La procédure typique est donc : 

\
#align(center, [
  #rect(fill: green.lighten(95%), stroke: green, [1. Charger les variables d'environnement ```bash
  source design.env
  ```])

  $arrow.b$

  #rect(fill: blue.lighten(95%), stroke: blue, [2. Lancer genus avec le fichier de config .tcl : ```bash
  genus -file flow/02_synthese/01_minimal/genus_minimal.tcl
  ```])

  $arrow.b$

  #rect(width: 482pt, fill: red.lighten(95%), stroke: red, [3. Ranger les sorties dans un dossier uique labélisé par exemple avec la commande `mv`])
])
\
C'est exactement ce que fait le script run_minimal.sh. Pour l'executer :

```bash
bash flow/02_synthesis/01_typical_minimal/run_syn_minimal.sh
```

#showybox(
  title: [*Méthode* : Repérer les erreurs],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Lorsque l'on lance des gros scripts, une erreur peut vite se glisser, se perdre et devenir irrepérable. Pour prévenir ce problème il y a une règle de bonne pratique toute simple : 
  
  *Une action = une erreur en cas d'échec*.
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
  Il faut bien avoir en tête que le fichier tcl n'est pas executé en tant que tel, c'est genus qui est executée et qui l'utilise comme fichier de configuration. Ainsi, le script ne peut pas charger des variables d'environnement globale et des chemins configurables par lui même. C'est pourquoi il est nécessaire de les charger en amont dans un script `bash`.
]

#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : source $!=$ bash - 2/2] )],
  frame: (
    border-color: red,
    title-color: red.lighten(30%),
    body-color: red.lighten(95%),
    footer-color: red.lighten(80%)
  ),
)[
  Si on fait `export PATH_CUSTOM=/le/chemin` dans un programme shell et qu'on l'exectute avec la commande *bash* la variable PATH_CUSTOM sera détruite à la fin de l'execution du programme. Si on veut pouvoir s'en servir par la suite il faut donc que ça reste et pour cela on utilise la commande *source*.
]


=== Comprendre les rapports
Maintenant qu'on a fait la première synthèse, on peut regarder les résultats dans `rundir/02_synthese/nom_du_run`. On y trouve : 
#set list(marker: ([•], [#sym.arrow.r.curve]))
- *fv\/* (pour la vérification formelle, pas utilisé ici)
 - adder_pipeline/
 - fv_map.fv.json
 - fv_map.map.do
 - fv_map.singlebit.original_name.alias.json.gz
 - fv_map.user_hier.json
 - fv_map.v.gz
 - read_libs.tcl
 - rtl_to_fv_map.do
- *genus\/* 
 - genus.cmd : la commande appelée
 - genus.log : le log de Genus (#rouge("super utile"))
- *outputs\/* (les sorties utilisées par la suite dans le PnR)
 - adder_pipeline.mapped.sdc
 - adder_pipeline.mapped.v
- *reports\/*
 - report_area.rpt
 - report_qor.rpt
 - report_timing.rpt

\
Normalement, si les scripts sont bien faits, il n'y a pas besoin de regarder dans le détails les rapports car la moindre erreur sera remontée dans le script. Il est tout de même *essentiel* de bien comprendre ce qui se passe donc voici les sorties classiques:
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

Ainsi, 
- Si on a une erreur --> *genus.log*
- Si non, on regarde les *rapports* (et on pourra fournir les *outputs* à innovus pour le PnR) 


==== Fichier : report_timing.rpt - le timing
Comme son nom l'indique c'est dans ce fichier qu'on retrouve les informations relatives au timing. C'est ici que l'on voit si le timing respecte les contraintes définies dans le sdc. 

Concept essentiel à comprendre à cette étape : la *slack*. Elle est définie comme suit : $#rect(stroke: red,[ slack = t_requis - t_arrivee])$

Une slack *négative* indique qu'on est en retard $->$ #rouge("violation des contraintes"). 

Pour vérifier, on peut parcourir le fichier à la main ou lancer une commande du type : 
```bash
grep -i "slack" \
rundir/02_synthesis/adder_pipeline_20260825T152355Z/reports/report_timing.rpt 
```

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

  Les #rouge("rapports doivent donc toujours être examinés"), même lorsque le wrapper affiche #text(fill: green, [TEST_PASS]).

  On peut faire cette vérification à la main ou l'intégrer dans un script (cf. niveaux suivants).
]

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
Genus essayera de réduire l'aire, mais ne sacrifiera pas le timing au-delà de la marge définie par syn_timing_slack_margin

]




== Niveau 2 : script réutilisable "simple"
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/02_synthesis/02_typical_advanced/])

Le script du niveau 1 est fonctionnel sur le papier mais en pratique il est *incomplet*. Genus permet de donner beaucoup plus d'informations sur son fonctionnement et ces rapport sont très utiles afin de repérer une erreur éventuelle. Par ailleur, un certain nombre de *vérifications basiques* comme "est ce que les chemins existent ?", "est-ce que j'ai bien accès aux outils cadence ?", "est-ce que telle ou telle commande à réussi ?" etc.

\ 
Le niveau 2 permet donc, en plus de ce que fait le niveau 1, de :
1. Faire des vérifications basiques
2. Générer plus de rapports
3. Encapsuler les appels de fonctions pour localiser les erreurs

\
Même si le script du niveau 2 est relativement simple en soit, il comporte des appels à plusieurs fichiers et leurs rôle doit être correctement compris. Voici donc l'architecture des appels imbriqués à cette étape.

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
[ Le script charge les variables d'environnement utilisés pour la simulation (ex : *\$GENUS_SDC*) et lance une ou plusieurs exectution de genus. Les variables sont accessibles depuis n'importe quel programme dans le script. Le script lance notamment Genus avec comme fichier de configuration genus_advanced.tcl.
#showybox(
title-style: (boxed-style: (:)),
frame: (
  title-color: green.lighten(50%),
  border-color: green,
  body-color: green.lighten(95%)
  ),
title: [#text(fill: black, "genus_advanced.tcl")],
[Genus utilise le fichier de configuration genus_advanced.tcl pour savoir quoi faire, dans quel ordre etc... Ce fichier utilise lui même un fichier helper.tcl

#colbreak()
#showybox(
title-style: (boxed-style: (:)),
frame: (
  title-color: blue.lighten(50%),
  border-color: blue,
  body-color: blue.lighten(95%)
  ),
title: [#text(fill: black, "helper.tcl")],
[Scripts générique qui défini des fonctions utilitaires pour les scripts tcl.]
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
*Rôle de helper.tcl*:

Dans le flow numérique, un certain nombre d'opérations seront executées dans *chacun des scripts tcl* comme le renvoie d'erreur, la vérification de l'envirronnement etc. Afin d'éviter de réécrire systématiquement ces fonctions, nous pouvons les définir dans un script spécifique qui sera appelé à chaque fois (ici : helper.tcl).
Le fichier helpers.tcl regroupe donc les utilitaires du flow. Ce fichier contient des procédures TCL pour gérer les erreurs, les logs, et les rapports. Il vérifie que toutes les variables d'environnement obligatoires sont définies avant de lancer le flow. Cela évite les erreurs cryptiques (ex: `Library not found` à cause d'une variable manquante). L'utilisation des fonctions de helper permet, entre autre, ici de faire en sorte que chaque action ai son erreur associée.

=== Lancer le script 

Pour lancer le script de niveau 2 il faut tapper:
```bash
bash flow/02_synthesis/02_typical_advanced/run_syn.sh adder_pipeline
```

=== Lire les sorties
De la même manière, on va regarder ce qu'il y a dans le répertoire de sortie : 

`/rundir/02_synthesis/02_typical_advanced/nom_du_run`.

\
Cette fois-ci on a davantage de rapports : 
- *reports\/*
 - check_design.rpt
 - check_timing_intent.rpt
 - final_status.rpt
 - report_area.rpt
 - report_qor.rpt
 - report_timing.rpt
 - stage_status.tsv


 #showybox(
  title: [*Note* : Ouvrir la GUI],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Généralement, Genus ne s'ouvre pas en vue graphique mais, en cas de besoin, voici comment le faire : 
  ```bash
  genus -legacy_ui  # Ouvir Genus en mode legacy (davantage de paramètres que le mode normal)
  # Dans Genus:
  gui_show
  ```

]

==== Fichier : final_status.rpt
Répond à la question : *Est-ce que le flow complet s'est terminé ?*

C'est la première chose à regarder. C'est le verdic final de la synthèse. Si on a quelque chose de ce type c'est que tout devrait être bon : 

```sh
GENUS_STATUS=PASS
FLOW_EXECUTION_STATUS=FLOW_COMPLETED
ARTIFACT_STATUS=PASS
```

==== Fichier : stage_status.tsv 
Répond à : *Quelle étape a réussi ou échoué ?*

Permet de faire un listing en cas d'echec de qu'est ce qui n'a pas fontionné.

==== Fichier : check_design.rpt
Répond à : *Le design que je vais synthétiser est-il structurellement sain / cohérent ?*
Permet de vérifier les références non résolues, drivers multiples, connexions suspectes, cellules manquantes, latches éventuels.

C'est important parce qu'on pourrait très bien obtenir un report_area.rpt et un report_timing.rpt alors que le design contient un problème structurel passé sous forme de warning

==== Fichier : check_timing_intent.rpt
Répond à : *Est-ce que mes résultats timing ont réellement un sens ?*
Permet de vérifier si on a des chemins non contraints, clocks manquantes, entrées/sorties non temporisées, problèmes SDC.

Sans cette vérification, on ne pourrait pas savoir si les résultats de timing sont réellement exploitables.
 

== Niveau 3 : Script complet avec mmmc
#rect(fill: blue.lighten(90%) , stroke: blue, radius: 5pt, [*Dossier* : flow/02_synthesis/03_mmmc/])

La synthèse du niveau 2 se rapproche beaucoup de quelque chose de complet mais il manque une dernière chose avant de pouvoir continuer sur le PnR : les corners. Avant de pouvoir envoyer un design en production, il faut d'abord s'assurer qu'il va fonctionner même si tel transistor est un peu plus lent, tel autre un peu plus rapide etc. C'est l'objectif du MMMC.

\
Le script du niveau 3 permet, en plus du niveau 2 de :
1. Prendre en compte les MMMC.
2. Utiliser en plus des scipts précédents un troisième scipt "lecture_resultats.tcl"  permettant de demander à Genus de vérifier que les rapports sont bons et que les résultats sont cohérent. Il est plus robuste d'utiliser un script .tcl que de faire une vérification avec des _grep_ dans des rapports.

===  MMMQUOI ?

MMMC pour Multi Mode Multi Corner est l'analyse qui permet de savoir comment répond notre design avec des erreurs de fabrications, en température etc..

Les deux notions essentielles à comprendre à ce stade sont le setup et hold.


=== Setup Time (Temps d'Établissement)

*Définition* : Temps minimum avant le front montant du clock pendant lequel la donnée doit être stable pour être correctement capturée par un registre.

*Violation* : Si la donnée arrive trop tard ou pas assez en avance #sym.arrow Échec de capture (métastabilité).

*Corner utilisé* : Worst-Case (WC) #sym.arrow Délais maximaux (pire cas pour le setup).


=== Hold Time (Temps de Maintien)

*Définition* : Temps minimum après le front montant du clock pendant lequel la donnée doit rester stable pour éviter la métastabilité.

*Violation* : Si la donnée change trop tôt #sym.arrow Échec de maintien (valeur instable).

*Corner utilisé* : Best-Case (BC) #sym.arrow Délais minimaux (meilleur cas pour le hold).

\
Pour lancer le script du niveau 3 : 
```bash
bash flow/02_synthesis/03_mmmc/run_syn_mmmc.sh adder_pipeline
```

\
#showybox(
  title: [#text(weight: "bold", fill: black, [Attention : Ne pas mettre la charue avant les boeufs] )],
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

 #showybox(
  title: [*Note* : Paramétrage fin],
  frame: (
    border-color: blue,
    title-color: blue.lighten(30%),
    body-color: blue.lighten(95%),
    footer-color: blue.lighten(80%)
  ),
)[
  Il existes une multitude de paramètres supplémentaire pour guider les 3 étapes de la synthèse plus précisément et affiner le résultat. Ici, pour des raisons de lisibilité et parceque notre design n'est pas très exigeant, on se contente de quelques paramètres et le reste est laissé en automatique. 

  \
  Pour voir quels autres paramètres on peut rentrer :
  ```bash
  genus -legacy_ui  # Ouvir Genus en mode legacy (davantage de paramètres que le mode normal)
  # Dans Genus:
  man syn_generic # Ou man syn_map ou man syn_opt
  ``` 
]

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

avec ce fichier runPnR.tcl

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

== Niveau 2 : PnR complete
Le minimal faisait essentiellement :

Genus
  ↓
init_design
  ↓
floorplan
  ↓
placement
  ↓
routing
  ↓
DEF + netlist

Le niveau complet devient :

Genus
  ↓
MMMC BC / TC / WC
  ↓
floorplan
  ↓
power planning
  ↓
placement
  ↓
optimisation pre-CTS
  ↓
tie cells
  ↓
CTS / CCOpt
  ↓
analyse + optimisation post-CTS
  ↓
routing timing/SI/antenna aware
  ↓
extraction RC
  ↓
optimisation setup/hold post-route
  ↓
fillers
  ↓
vérifications physiques
  ↓
DEF + netlist + GDS
  ↓
timing signoff optionnel

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


