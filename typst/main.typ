#import "lib.typ": *

#show: template_R.with(
  title: "LOGMIC V1",
  authors: (
    ("Romain DUCHADEAU", "IP2I / CNRS", "r.duchadeau@ip2i.in2p3.fr"),
    ("Edouard BECHETOILLE", "IP2I / CNRS", "e.bechetoille@ip2i.in2p3.fr"),
    ("Herve MATHEZ", "IP2I / CNRS", "h.mathez@ip2i.in2p3.fr"),
  ),
  logos: ("Img/logo_CNRS.jpg", "Img/logo_IP2I.png"), //ex : "Img/logo_CNRS.jpg"
  lang: "fr",
)

// ******************** SECTION ******************** 
// *************************************************
= Introduction
// ----------------- SOUS-SECTION ------------------ 
== Cadre du projet
Ce *projs de montée* : 200 ps
- *Durée du signal* : 2-5 ns
- *Capa détecteur* : 30 pF

\ // Line break
*NB* : Il faut noter que le signal n'ayant pas encore été correctement mesuré les caractéristiques ci-dessus sont estimées seront éventuellement à revoir.

\
Une première expérimentation a déjà permis de mesurer les signaux en sortie de 3 MCP (@03_PICMIC_signaux_reels) à l'aide d'un circuit monté autour d'un préampli du commerce @bib_ampli_LMH6702MF et une conversion courant-tension dans une résistance de 50 $Omega$ (@04_ampli_christophe).

#v(0.5cm)
#figure(
  image("Img/04_ampli_christophe.png", width: 80%),
  caption: [Circuit de préamplification du premier setup expérimental],
)<04_ampli_christophe>#v(0.5cm)

*Note* : la capa C1 de 10 nF sur la @04_ampli_christophe  a été enlevée et la résistance de 100 $Omega$ a été reet s'inscrit dans le cadre plus général de la R&T _PICMIC_ qui vise à utiliser des MCP pour détecter des rayons gamma avec une très bonne résolution temporelle. L'idée est d'empiler les MCP pour augmenter la probabilité de conversion d'un rayon gamma dans le dispositif. Une conversion dans un MCP engendrera une avalanche d'électrons qui va se propager d'un MCP au suivant en s'amplifiant de manière exponentielle. 

\
Plus précisément, l'objectif de la puce _LOGMIC_ est de récupérer et lire le courant sortant du détecteur composé d'une pile de MCP (cf. @01_PICMIC_detector) tout en conservant un maximum de précision temporelle et ce, sur toute la w dynamique.

#v(0.5cm)
#figure(
  image("Img/01_PICMIC_detector.png", width: 80%),
  caption: [Schéma d'un côté du détecteur ],
)<01_PICMIC_detector>#v(0.5cm)

Cette puce a été développée de *octobre 2025 à mai 2026* dans le cadre de la prématuration du projet *TOF_PET_MCP* visant à utiliser les MCP comme détecteur de rayon gamma permettant de remplacer la technologie actuellement en place dans les PET-scan. Ce projet permettrait ainsi de réduire le coût de la machine ainsi que la dose d'atome radioactif à introduire dans le corps humain pour effectuer le scanner.

// ----------------- SOUS-SECTION ------------------ 
== Signal d'entrée
Le signal attendu en sortie du détecteur (en entrée de LOGMIC) est un signal en courant *négatif* (#underline("ie.") un pulse d'électrons) qui possède les caractéristiques suivantes:
- *Amplitude* : [10 µA - 1A]
- *Temps de montée* : 200 ps
- *Durée du signal* : 2-5 ns
- *Capa détecteur* : 30 pF

\ // Line break
*NB* : Il faut noter que le signal n'ayant pas encore été correctement mesuré les caractéristiques ci-dessus sont estimées seront éventuellement à revoir.

\
Une première expérimentation a déjà permis de mesurer les signaux en sortie de 3 MCP (@03_PICMIC_signaux_reels) à l'aide d'un circuit monté autour d'un préampli du commerce @bib_ampli_LMH6702MF et une conversion courant-tension dans une résistance de 50 $Omega$ (@04_ampli_christophe).

#v(0.5cm)
#figure(
  image("Img/04_ampli_christophe.png", width: 80%),
  caption: [Circuit de préamplification du premier setup expérimental],
)<04_ampli_christophe>#v(0.5cm)

*Note* : la capa C1 de 10 nF sur la @04_ampli_christophe  a été enlevée et la résistance de 100 $Omega$ a été remplacée par une résistance du même ordre de grandeur (difficile à mesurer) donc le gain de l'ampli n'est pas certain.

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/03_PICMIC_signaux_reels_persistant.jpg", width: 100%),
      image("Img/03_PICMIC_signaux_reels.png", width: 100%), 
      text("(a) Vue persistante"),
      text("(b) Courbes extraites"),
  ),
  caption: [Exemple de signaux acquis avec 3 MCP avec le premier setup expérimental],
)<03_PICMIC_signaux_reels>#v(0.5cm)

On constate qu'avec le premier setup expérimental la tension maximale obtenue est de 1.8V (valeur absolue). Une partie du signal est perdue dans la capa détecteur et une autre perte est liée aux rebonds, ainsi, la tension qu'on pourrait obtenir avec un meilleur front-end dans avec 3MCP est certainement plus grande.

Si on considère que le préampli a un gain de 2 (dépendamment de la résistance mise dans le montage) on obtient le courant maximal détecté suivant: 
$ lr({ mat(delim: #none, U_("conv"), R_("conv") I ; U_("oscillo"), U_("conv") * "Gain")) => I = frac(U_("oscillo"), R_("conv") * "Gain") => I_(m a x)= frac({1,8}, 50 * 2) tilde.eq frac(1, 5 0) = #rect[20 mA] )$
En ce qui concerne le courant minimal détectable on peut constater qu'on est dans le bruit à -300 mV ce qui correspond à $#rect[$I_("min")$ = 3 mA]$ . 

On constate donc qu'avec ce premier setup expérimental on est loin des spécifications données pour le signal d'entrée car, d'une part, la gamme de lecture est très limitée avec ce setup et, d'autre part, seulement 3 MCP sont empilés la ou dans l'avenir nous pourrions peut être en mettre 10. 

// ----------------- SOUS-SECTION ------------------ 
== Objectifs de _LOGMIC_ 
L'objectif de la puce _LOGMIC_ est donc double :
1. Permettre l'*acquisition du signal* avec le *moins de perte* dans le détecteur possible, la *meilleure résolution temporelle* possible et le *moins de bruit* possible.
2. Différencier les différents seuils permettants de remonter au MCP dans lequel la conversion a eu lieu comme illustré @02_tri_courbes_mcp.  

#v(0.5cm)
#figure(
  image("Img/02_tri_courbes_mcp.png", width: 100%),
  caption: [Simulation de courbes attendues en sortie des MCP ainsi que du travail de discrétisation à effectuer ],
)<02_tri_courbes_mcp>#v(0.5cm)

Dans la première version de _LOGMIC_ appelée _LOGMIC_V1_ l'objectif est principalement de tester le circuit front-end de lecture des signaux ainsi que de pouvoir mieux estimer les spécifications du signal à mesurer et les gammes de sensibilité désirées. Une deuxième version de _LOGMIC_ appelée _LOGMIC_V2_ est prévue dans un second temps afin d'affiner la mesure. 

== Livrables <Livrables>
Ce rapport technique s'accompagne de l'ensemble de livrables suivants :
1. Le travail de documentation (ressources bibliographiques) est disponible dans le dossier ```sh ./LOGMIC_ressources_zotero``` sous forme d'un dossier Zotero @bib_zotero.
2. L'ensemble des diapositives de réunion d'avancement de projet (weekly) sous forme pdf dans le dossier #block(```sh ./LOGMIC_Reunion_avancement_Weekly```)
3. Les fichiers cadence dans un dossier ```sh LOGMIC_V1``` sur un ordinateur de calcul ```sh ccomme01``` du centre de calcul *CCIN2P3*. Le dossier est pensé pour être indépendant de toutes librairies externe (hors cadence basics, la techno et analoglib). Cette librairie s'organise en 3 sous-dossiers :

#list(indent: 1cm, 
[*Layout :* Tous les circuits et sous-circuits utilisés dans le layout final. Le layout a été découpé en plusieurs circuits pour faciliter le passage des règles LVS et DRC au moment de la conception. Les fichiers les plus importants sont : _LOGMIC_TOP_ (la chip complète finale _LOGMIC_V1_), _chip_miroir_ et _chip_suiveur_ (les deux puces distinctes à l'intérieur de _LOGMIC_V1_). Cf. la @Sec_layout pour plus de détails sur les fichiers en question.], 
[*Simulation :* L'ensemble des Schematics permettant de simuler les circuits mentionnés ci-dessus. Une version _Flatten_ existe pour chacune des deux _chip_miroir_ et _chip_suiveur_. C'est une recopie exacte des deux puces mais sans les niveaux d'abstractions rajoutés par le découpage en différents blocs de layout (#underline("ie.") on voit tous les composants directement). Le seul inconvénient de la vie _Flatten_ est qu'elle ne permet pas d'effectuer des simulation post extraction de parasites.],
[*Filler :* Les cellules de remplissage permettant de former la vue layout _LOGMIC_filler_.])


4. Le présent document.

// ******************** SECTION ******************** 
// *************************************************
= Choix de conception de _LOGMIC_V1_

La puce _LOGMIC_V1_ (cf. @05_LOGMIC_layout) est conçue pour fonctionner en tandem avec une diode BAT42W @bib_BAT42 externe en amont. Le principe est le suivant : la diode en amont ne peut s'activer que si la chute de tension à ses bornes (#underline("ie.") le courant détecteur) est suffisamment grande pour dépasser la tension de seuil de la diode. Ainsi, *les petits courants rentrerons dans _LOGMIC_* qui présente une très faible impédance d'entrée (cf. @37_principe_LOGMIC).  

Les gros courants seront, quand à eux, suffisants pour *activer la diode* qui présentera alors une plus faible impédance que _LOGMIC_ (qui aura alors cessé de fonctionner). On observera alors une conversion courant-tension dans la diode en externe et on pourra mesurer la chute de tension via une batterie de comparateurs.

\
Le choix de la diode c'est porté sur la  BAT42W car c'est une diode facilement accessible et couramment utilisée en conception de circuit. Les résultats de simulations et la caractérisation de la diode BAT42W dans le contexte de notre détecteur peuvent se retrouver en @ajout_BAT42W.


#v(0.5cm)
#figure(
  image("Img/37_principe_LOGMIC.png", width: 80%),
  caption: [Principe de fonctionnement de la puce de _LOGMIC_ ],
)<37_principe_LOGMIC>#v(0.5cm)


\
Dans cette section nous motiverons les choix de design qui ont été faits afin de permettre de futures modifications potentielles de la puce pour une V2. Nous commenceront par présenter une vue générale de la puce en revenant rapidement sur le travail exploratoire qui nous à mené vers l'architecture choisie ; puis nous allons détailler élément par élément les choix de design qui ont étés effectués afin de pouvoir reprendre certains éléments par la suite. 

// ----------------- SOUS-SECTION ------------------ 
== Vue générale 

_LOGMIC_V1_ est composée de 2 puces séparées: 
- L'une (_chip\_miroir_) permet une sortie directement en courant pour pouvoir effectuer une conversion courant $arrow$ tension dans un élément à *l'extérieur* de la puce (comme montré sur le schéma de principe @37_principe_LOGMIC) #footnote("En toute rigueur, la conversion courant tension se fait dans le maitre du miroir.")
- L'autre (_chip\_suiveur_) repose sur le même front-end mais permet d'effectuer une conversion courant $arrow$ tension en interne. Nous justifierons de son utilité et des choix de design qui la concerne dans la @chip2.

#v(0.5cm)
#figure(
  image("Img/05_LOGMIC_layout.png", width: 60%),
  caption: [Layout complet de la puce de _LOGMIC_V1_ ],
)<05_LOGMIC_layout>#v(0.5cm)

La technologie utilisée pour concevoir cette puce est la *IHP130 nm*. Ce choix est motivé par deux arguments : 
1. C'est une techno BICMOS proposée dans le catalogue d'Europractice @bib_europractice avec qui nous traitons pour faire faire fabriquer nos puces. 
2. Il nous était possible de se greffer à un run avec Caen (ce qui ne s'est pas fait au finale, les ingénieurs de Caen ayant préférés prendre le run d'après).

=== Essais préliminaires <Essais_préliminaires>
La difficulté principale de la tâche est de récupérer le courant détecteur sur une grande gamme dynamique et ce très rapidement (le signal montant et repartant très vite ). Si on suppose la capacité détecteur à 30 pF et une signal montant en 200 ps le calcul de l'impédance équivalente au détecteur donne : 
$
  Z_(det) = frac(1, j C_d omega) -> R_(det) = frac(1, 2 pi f C_d) "avec" f = frac(0.35, t_("montée")) 
#linebreak()
  "AN : "R_(det) = frac(1,2*3.14*frac(0.35, 200*10^(-12))*30.10^(-12)) approx #rect[$3 space Omega$]
$

Autrement dit, si #text(fill: red)[l'impédance d'entrée de notre front-end est supérieure à $3 space Omega$ nous allons perdre du signal dans la capa détecteur].

\
Une première solution envisagée était une conversion courant $arrow$ tension dans une première diode (en PMOS) puis de venir rajouter successivement des diodes si la tension chutait trop (cf. @06_essai_switching).

#v(0.5cm)
#figure(
  image("Img/06_essai_switching.png", width: 70%),
  caption: [Essai diodes switchées],
)<06_essai_switching>#v(0.5cm)

La difficulté de ce genre d'architecture est le dimensionnement de la première diode :
- Petite alors $Z_("in")$ très *grand* et on avale pas le courant; par ailleurs on aura une chute très rapide de tension (U=RI) pour des gros courants, il faut donc switcher *très vite * (en quelques pico secondes) les diodes suivantes (impossible à faire si vite dans la pratique).
- Grosse ($Z_("in")$ petit) et on avale correctement le courant mais la conversion courant $->$ tension donne des tout petites tensions pour des faibles courant d'entrée. On ne peut alors pas lire les petits courants.

\ 
On peut déduire deux choses de ce premier essai : 
1. Les systèmes switchés ne sont *pas adaptés* à notre problématique (d'autres essais ont étés menés sans plus de succès) car *trop lents*.
2. La conversion courant $->$ tension ne peut pas être la même pour toute la gamme dynamique. Il faut réussir à séparer les signaux fort des signaux faibles.

\

Par la suite, nous avons essayés de séparer dans différentes branches les petits et les grands signaux mais sans succès (les petits signaux comme les grands empruntant systématiquement le même chemin). L'utilisation d'un préampli de charge (CSA) sur le même noeud qu'une diode a été également étudié mais l'impulsion étant très rapide, il a fallu mettre une très grosse bande passante sur l'ampli ce qui limitait donc le gain (le produit gain-bande ne pouvant pas être augmenté à l'infini). Ainsi, il était très difficile de capter les petits courants (car petit I $->$ petite capa de contre réaction $C_f$ $->$ Gros gain pour conserver une impédence d'entrée suffisamment basse).

\ 

Finalement, nous avons explorés la piste des convoyeur de courant (cf. @07_essai_convoyeur_courant .a). L'idée est de prendre le montage d'une grille commune mais d'utiliser un ampli en contre réaction pour diminuer l'impédance d'entrée et mieux récupérer le courant détecteur (cf. @07_essai_convoyeur_courant .b).

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/07_essai_convoyeur_courant.png", width: 100%),
      image("Img/07_essai_convoyeur_courant_Zin.png", width: 100%), 
      text("(a) Schéma du convoyeur"),
      text("(b) Calcul de l'impédance d'entrée"),
  ),
  caption: [Montage convoyeur de courant],
)<07_essai_convoyeur_courant>#v(0.5cm)

Le problème rencontré était alors au niveau de la contre réaction. Le signal étant très rapide, il faut une grosse bande passante pour réagir assez vite $->$ on est donc limité dans le gain pour conserver un système stable. Il fallait choisir entre performance et stabilité et nous avons donc abandonnés cette piste. Avec des signaux aussi rapides les* systèmes bouclés ne sont pas adaptés*.

Finalement, la solution retenue fût d'utiliser un montage grille commune sans contre réaction.

\
*Note: *Des solutions hybrides [CSA + grille commune] fonctionnant sur le même noeud mais dans différentes gammes ont étés explorés mais la encore sans grand succès car, le grille commune ayant une impédance d'entrée plus basse, fonctionnait mieux et le CSA ne faisait que gêner.

=== Architecture choisie <Architecture_choisie>
#rect(stroke: colors.primary)[#text(fill: red, weight: "bold")[Attention :] Les notations utilisées pour décrire les signaux sont différentes dépendamment du schéma utilisé. Ainsi, le même signal pourrait avoir deux noms différents dans ce document. Attention donc à bien faire attention à quel schéma se réfère l'explication.]

\
Les précédents essais (cf. @Essais_préliminaires) nous ont donc menés vers une architecture en grille commune pour capter le courant avec une très basse impédance d'entrée et sans rebouclage afin de garantir la stabilité malgré la grande vitesse des signaux. 
Afin d'encore augmenter la rapidité et baisser l'impédance d'entrée de notre circuit, nous avons mis un *transistor bipolaire* en entrée (meilleur gm et plus grande $f_t$).

\
Une fois le courant capté l'objectif est ensuite de faire une conversion courant $->$ tension. Nous avons pensés à la faire directement après le bipolaire dans une diode (cf. @chip2) mais la chute de tension que la conversion engendre modifie alors le point de fonctionnement du transistor d'entrée. Nous avons donc opté pour recopier le courant dans un miroir de courant pour faire la conversion sur un noeud en sortie (noeuds _out2_m_ et _out3_m_ sur la @08_LOGMIC_chip_miroir).

\
Enfin, une source de courant réglable a été placé sur le noeud _out2_m_ pour compenser le courant DC de la première source $I_("b1")$ (qui est recopié dans le miroir). Ainsi, le noeud _out2_m_ est un noeud de sortie *en courant* avec $I_("OUT2") = I_("det") + I_("b1") - I_("b2")$  ( avec $I_("b2") approx I_("b1")$)

\
Une deuxième recopie est effectuée avec, cette fois-ci, un *gain de 4* :\ $I_("OUT3") = 4 * (I_("det") + I_("b1")) - I_("b3")$  ( avec $I_("b3") approx I_("b1")$).

\
L'objectif initial d'avoir une recopie avec du gain était de venir amplifier directement le signal avant de le convertir. Dans les fait, comme discuté dans la @sec_sources_courant_miroir, il est difficile de soustraire la totalité du courant DC, et d'autant plus qu'il est amplifié x4. Ainsi, la plage de lecture en tension après conversion s'en trouve réduite. Il était tout de même intéressant de voir l'impact du gain sur le bruit, notamment pour la lecture des petits signaux $->$ lors des tests il faudra bien caractériser cette branche et éventuellement ne pas mettre de gain pour une prochaine version de _LOGMIC_

\
L'avantage de recopier le courant est aussi que cela permet de faire une conversion courant-tension *adaptée à chaque signal qu'on veut mesurer* : par exemple une grosse résistance en _out3_m_  permettra la lecture des petits signaux mais pas des gros tandis qu'en _out2_m_ on pourra mettre une petite résistance pour pouvoir lire les plus gros signaux par exemple. On peut également imaginer d'avoir d'autres miroirs pour d'autres gammes.

\
Finalement, voici le schema complet de la _chip\_miroir_ en @08_LOGMIC_chip_miroir: 

#v(0.5cm)
#figure(
  image("Img/08_LOGMIC_chip_miroir.png", width: 100%),
  caption: [Schema de la _chip_miroir_],
)<08_LOGMIC_chip_miroir>#v(0.5cm)

*Note:* Le schéma de la @08_LOGMIC_chip_miroir est tiré du fichier _Chip_miroir_flatten_simu_ (cf. #ref(<Livrables>) pour davantage de détails sur les livrables). Pour rappel, cette vue reprend les éléments constitutifs de la _puce_miroir_ en les mettant à plats afin d'avoir une meilleure visibilité. #text(fill: red)[L'ensemble des courbes de simulations (hors extraction de parasites) sont tirées de ces vues "flatten" mais elles ne constituent pas réellement la puce LOGMIC] (qui elle est découpée en sous-blocs permettant de segmenter le layout).

==== Avantages de l'architecture
- Conversion courant-tension en externe $arrow$ permet de tester différentes idées/régimes de fonctionnement/plage de mesure.
- Possibilité de recopier le courant (avec un gain ou non) pour avoir plusieurs plages de mesures (conversion courant-tension adaptée à chaque gamme de fonctionnement).
- $Z_("in") alpha space I_E "avec" I_E = I_("IN") + I_("REF1") arrow $ plus $I_("IN")$ augmente (en valeur absolue), plus l'impédance baisse et mieux ça marche (cf. @eq_Zin pour davantage de détail sur le calcul de l'impédance).


==== Limitations 
- Perte de signal due aux plots d'accès sur les sorties en courant (capa, inductance).
- Courant max limité par les miroirs (il faudrait que les transistors soient plus grand mais ils seraient alors trop lents).
- Courant min limité par le bruit (cf. @sec_bruit).

Nous allons dans la suite revenir sur les choix de design de chacune des partie constituant la _chip\_miroir_.

// ----------------- SOUS-SECTION ------------------ 
== Étage d'entrée

=== Transistor bipolaire
Element central de l'architecture, le transistor d'entrée (Q0 sur la @10_bipolaire_schematic) a pour rôle de présenter une très basse impédance d'entrée et de convoyer le courant détecteur jusqu'aux miroirs. Comme mentionné dans la @Architecture_choisie, le choix du transistor d'entrée s'est porté sur un transistor bipolaire pour deux raisons : le meilleur gm et la plus grande $f_t$.

Ce choix s'accompagne de contraintes supplémentaires : pour fonctionner correctement le transistor d'entrée à besoin de $#rect($V_C > V_B > V_E$)$ et la tension de claquage est donné à $#rect(stroke: red)[$V_("CE")$ < 1.6 V]$ . Par ailleurs, comme Q0 est un bipolaire, le courant détecteur peut passer par la base du transistor. Ainsi, on ne va pas récupérer 100% du signal dans le collecteur (limitant pour la lecture petits courants).

$arrow$ Si d'aventure le courant détecteur s'avère moins rapide que prévu ou bien si la capa détecteur est plus faible que prévu, il pourrait être pertinent de revenir sur un transistor d'entrée en CMOS.

#v(0.5cm)
#figure(
  image("Img/10_bipolaire_schematic$.png", width: 30%),
  caption: [Schematic de l'étage d'entrée],
)<10_bipolaire_schematic>#v(0.5cm)

Contrairement aux CMOS, paralléliser les bipolaire sans changer le courant de polarisation n'a aucun effet sur l'impédance d'entrée. Pour la diviser par deux il faudrait non seulement doubler le nombre de transistor mais doubler aussi le courant de polarisation (autrement on se retrouverait avec deux transistors deux fois moins bons...). Or, nous recopions ensuite le courant $I_E = I_("IN") + I_("REF1")$ (notations de la @10_bipolaire_schematic). Augmenter le courant $I_("REF1")$ obligerait à en soustraire davantage après les miroirs ce qui mettrait les sources de courants sur les noeuds de sortie encore plus en difficulté (cf. @sec_sources_courant_miroir pour davantage de détail). Nous avons donc fait le choix de ne mettre qu'*un seul transistor*. Nous le voulions le plus gros possible pour avoir le meilleur gm possible. Nous avons donc pris le plus gros de la techno (cf. @11_bipolaire_techno).

#v(0.5cm)
#figure(
  image("Img/11_bipolaire_techno.png", width: 90%),
  caption: [Spec du bipolaire utilisé (tirée du pdk)],
)<11_bipolaire_techno>#v(0.5cm)

*Remarque : * Si $I_("IN")$ est trop grand (en valeur absolue) alors $V_C$ va diminuer et passer en dessous de $V_B$ ce qui fera changer le bipolaire de régime. 

=== Maitre du miroir (P1 sur la @10_bipolaire_schematic) <sec_maitre_miroir>

Deuxième élément critique de l'architecture, le transistor P1 monté en diode permet de faire une conversion courant-tension. Si il est trop gros alors les capacités parasites ralentissent le signal. Ceci a pour conséquence une perte d'amplitude sur le signal de sortie car comme illustré @22_chip_miroir_influence_gros_miroir le signal détecteur étant bref, la sortie n'a pas le temps de monter que le signal est déjà parti.

A l'inverse si P1 est trop petit on ne va pas pouvoir correctement lire les gros signaux car le miroir ne suit plus.


#v(0.5cm)
#figure(
  image("Img/22_chip_miroir_influence_gros_miroir.png", width: 80%),
  caption: [Comparaison de courants pour différentes largeurs pour P0=P1],
)<22_chip_miroir_influence_gros_miroir>#v(0.5cm)

On peut voir sur la @22_chip_miroir_influence_gros_miroir que le signal convoyé par le bipolaire est légèrement meilleur avec le gros P1 car, étant plus gros, son impédance est plus faible et il fait moins "bouchon". En revanche, le signal que l'on récupère avec la recopie x1 est bien meilleur sur la chaîne avec les transistors de 10 µm. Cela est du au fait, qu'étant beaucoup plus petits, ils sont davantage réactifs et le signal à le temps de passer avant de partir.

\
On notera que les transistors choisis sont des CMOS car il n'existait pas de bipolaire PNP dans la techno choisie. On notera également qu'un #text(fill: red)[raffinement de la taille des transistors P0 et P1] peut être effectué afin d'obtenir des meilleures performances. Ce raffinement n'a pas été effectué pour la puce _LOGMIC_V1_ par manque de temps mais aussi parce que ce raffinement sera d'autant plus bon et utile que le cahier des charges sera correctement définis et que l'on sait sur quelle gamme on veut être sensible.

=== Source de courant et Vb

Une fois la taille du maitre du miroir (P1 sur @08_LOGMIC_chip_miroir) et celle du bipolaire fixés, on obtient un *point DC de 2.337 V sur _Vout1_* (sur la @10_bipolaire_schematic). Il faut ensuite dimensionner la source de courant et la tension de base du transistor. Pour ce faire il y a quatres contraintes à respecter: 
1. La tension $V_"CE"$ ne doit pas dépasser la tension de claquage de 1.6 V.
2. Le courant doit être suffisamment grand pour abaisser l'impédance d'entrée du circuit (on rappelle que pour un montage comme celui-ci $#rect(stroke: red)[$Z"in" alpha frac(1,"gm") = frac(U_T, I_C)$]$ avec $U_T = frac(k dot T, q)$)
3. Le courant DC sera recopié dans les miroirs puis soustrait *en partie* par les sources de courant (cf. @sec_sources_courant_miroir ), plus le courant à soustraire est élevé, plus il sera difficile de lire correctement la sortie impulsionnelle.
4. Il faut que le $beta = frac(I_C, I_B)$ soit le plus grand possible pour que le transistor soit dans le meilleur régime de fonctionnement possible.

\
Afin de polariser correctement le bipolaire il a fallu tracer ces caractéristiques et notamment son beta (cf. @12_beta_bipolaire). Nous pouvons tirer de cette courbe un jeu de donnée idéal pour maintenir le bipolaire dans un bon régime de fonctionnement à [$I_C = 4 "mA, ""Vb" = 1.7$ V] (droite verticale sur la @12_beta_bipolaire)

#v(0.5cm)
#figure(
  image("Img/12_beta_bipolaire.png", width: 35%),
  caption: [Beta du bipolaire en fonction de Vbe],
)<12_beta_bipolaire>#v(0.5cm)

La source de courant à 4 mA fixe un point DC à 873 mV sur _in_m_ (cf. @21_LOGMIC_miroir_DC_oppoints). Cette tension est assez élevée pour dimensionner une source de courant sans trop de difficulté. Par ailleurs, l'impédance d'entrée du bipolaire étant très basse, il n'y a pas non plus beaucoup de contraintes sur l'impédance de sortie de la source de courant. C'est pour ces raisons qu'une architecture en simple miroir de courant a été choisie. 
La résistance au niveau de l'entrée des miroir est une résistance de $100 space Omega$ qui a simplement pour objectif de protéger le miroir d'un courant trop élevé. Afin de fournir le bon courant $I_("b1")$ (@21_LOGMIC_miroir_DC_oppoints), il est important de prendre en compte cette résistance dans le calcul de la tension externe à appliquer.

\
On peut également observer sur la @12_beta_bipolaire que si le courant $I_e = I_"bias" + I_"detecteur"$ devient trop élevé (par exemple 30mA) alors le transistor bipolaire n'est plus dans son régime de fonctionnement optimal.

Par ailleurs, le courant détecteur étant négatif, la tension $"Vc"_"|Q0" = V_"out1_m"$ va baiser en fonction de l'amplitude du courant (cf. @23_out1_m_tran). Le transistor bipolaire en fonctionnant dans un régime normal que si Vcb > 0 il faut polariser Vb suffisamment haut pour garantir un bon $beta$ mais suffisamment bas pour permettre au transitor Q0 de fonctionner pour des courants élevés. La limite à été fixée à max(I_detecteur) = 10mA pour la puce car c'est à partir de ce courant que la diode en externe se met à fonctionner (cf. @ajout_BAT42W). Mais il faut également le polariser le plus bas possible pour donner de la marge à _out1_m_ et pouvoir lire les gros signaux.

\
Ainsi Vb à été fixé à 1.7V. et nous pouvons voir sur la @24_dout1_m que la limite de fonctionnement (dans un régime normal) est de max(I_detecteur) = 10.712 mA.

#v(0.5cm)
#figure(
  image("Img/24_dout1_m.png", width: 70%),
  caption: [Minimum du courant I_out1_m en fonction de l'amplitude max du courant détecteur],
)<24_dout1_m>#v(0.5cm)


#v(0.5cm)
#figure(
  image("Img/23_out1_m_tran.png", width: 70%),
  caption: [Courant I_out1_m en fonction de l'amplitude max du courant détecteur],
)<23_out1_m_tran>#v(0.5cm)

*Note:* On peut également remarquer sur la @23_out1_m_tran qu'au dessus des 10 mA on commence à observer des effets des inductances des plots qui introduisent du ringing. On peut également constater que comme _Vout1_m_ diminue en fonction de I_detecteur et que _Vin_m_ ne bouge pas, on ne risque pas de dépasser la tension de claquage sur Vce (sauf effets éventuels de ringing non désirés). 

\
#text(fill: red)[*Attention* : Si $I_("b1")$ est trop élevé, alors $V_("in_m") = V_E$ va trop baisser et $V_("CE")$ risque de dépasser la tension de claquage de 1.6 V ]

\
Finalement, la @21_LOGMIC_miroir_DC_oppoints présente les points DC ainsi que les points de fonctionnement de la _chip_miroir_ au complet.

#v(0.5cm)
#figure(
  image("Img/21_LOGMIC_miroir_DC_oppoints.png", width: 100%),
  caption: [DC operating points et node voltage _chip_miroir_],
)<21_LOGMIC_miroir_DC_oppoints>#v(0.5cm)

// ----------------- SOUS-SECTION ------------------ 
== Miroirs de courants et source de courant <sec_sources_courant_miroir>
L'étage de sortie (cf. @14_schematique_etage_miroir) permet une recopie du courant $"Ic"_"|G0"$ avec un *gain de 1* sur _out2_m_ et un *gain de 4* sur _out3_m_. L'idée est de venir sortir en courant pour effectuer une conversion courant-tension en externe adaptée au signal auquel on souhaite être sensible. Cette configuration s'accompagne néanmoins de limitations : les capacités et inductances des plots d'accès ralentissent le signal. 

$arrow$ Idéalement, il faudrait effectuer une conversion courant-tension en interne et sortir sur un buffer numérique. Ceci ne peut être réalisé que lorsque l'on a une idée précise de la gamme à mesurer et de la précision souhaitée et fera l'objet d'une version 2 de la puce.

Les points de polarisation $V_("out2_m")$ et $V_("out3_m")$ (cf. @21_LOGMIC_miroir_DC_oppoints) fixés assez haut pour permettre une chute de tension la plus élevée possible mais pas trop haut pour garder les esclaves des miroirs de courants dans des régimes de saturation. 

\
Afin de soustraire le courant DC $I_("b1")$ de l'étage précédent, une source de courant est rajouté sur les deux étages de sortie. Comme le point DC des sortie est assez haut nous pouvons nous permettre de mettre un *miroir cascodé*. L'avantage d'une telle structure est qu'elle permet d'avoir une très *grosse impédance de sortie* et donc de moins avaler le signal détecteur.


#v(0.5cm)
#figure(
  image("Img/14_schematique_etage_miroir.png", width: 70%),
  caption: [Schema de l'étage de sortie de la _chip\_miroir_],
)<14_schematique_etage_miroir>#v(0.5cm)

L'impédance de sortie d'un miroir de courant cascodé se calcul comme suit (si on prend les notation du miroir de gauche dans la @14_schematique_etage_miroir) $ Z_"in" = "gm"_"N3" dot "rds"_"N3" dot "rds"_"N8" $ AN pour Ib = 2.5 mA:
$ Z_"in" = 23m times 844 times 1.8k = 35 space k Omega $<eq_Zout_source_I>

Afin de correctement récupérer le courant détecteur il est important de s'assurer que l'impédance de sortie de la puce est largement inférieure à celle du miroir. La taille des miroirs a donc été optimisée pour pouvoir soustraire un co urant de l'ordre de 4 mA à 16 mA DC tout en ayant une impédance de sortie la plus grande possible. 

\
On peut voir sur la @25_iout2_influence_plots (a) que la part du courant qui rentre dans le miroir (courbe noire) est négligeable devant la part du courant que l'on récupère (en bleu). On peut également voir sur la @25_iout2_influence_plots (b) à quel point les plots d'accès risquent d'être limitants dans le courant détecteur qu'on va pouvoir mesurer (la courbe (b) étant obtenue dans les exactes même conditions que la @25_iout2_influence_plots(a) avec un plot d'accès en _out2_m_).

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/25_iout2_sans_plots.png", width: 100%),
      image("Img/25_iout2_avec_plots.png", width: 100%), 
      text("(a) Sans plot sur out2_m"),
      text("(b) Avec plot sur out2_m"),
  ),
  caption: [Influence du plot de sortie sur le courant],
)<25_iout2_influence_plots>#v(0.5cm)



Dimensionner la source de courant de manière à avoir une grosse résistance de sortie n'est pas sans conséquence: la source est limitée dans le courant DC qu'elle peut envoyer. La @27_consigne_vs_source_courant représente le courant DC envoyé par la source en fonction de la consigne Ib. On peut voir que c'est une bonne source de courant (courbe linéaire) jusqu'à envirron 3 mA mais qu'au delà les transistors constituant la source ne sont plus en régime de saturation ce qui induit une erreur de recopie. Interprétation également visible sur la @26_Ib_limite_i_tran ou l'on voit qu'au dessus de $I_b approx 2.5 space "mA"$ (courbes rouges fléchées sur la @26_Ib_limite_i_tran) le courant détecteur est partiellement avallé par la source et non plus transmis en sortie. Ainsi, on voit qu'il nous est impossible avec cette architecture de soustraire complètement le courant DC de 4 mA de la source de l'étage d'entrée mais qu'il faut se contenter de soustraire 2.5 mA. 

#v(0.5cm)
#figure(
  image("Img/26_Ib_limite_i_tran.png", width: 80%),
  caption: [Courants (sans DC) déctecté (bas) et avalé par la source de courant (haut) en fonction de la consigne Ib pour un courant détecteur de 100 µA],
)<26_Ib_limite_i_tran>#v(0.5cm)

#v(0.5cm)
#figure(
  image("Img/27_consigne_vs_source_courant.png", width: 60%),
  caption: [Courant DC en sortie du miroir en fonction de la consigne Ib],
)<27_consigne_vs_source_courant>#v(0.5cm)

La sortie 3 avec une deuxième recopie avec un gain de 4 a été placée pour tester si il est préférable pour la détection de petits courants d'introduire un gain au niveau du miroir ou plutôt d'augmenter la résistance de conversion.
On comprend donc que le courant DC de 4 mA va également être recopié x4 sur out3. La source de courant étant la même que pour out2, on ne va pouvoir soustraire à ces 16 mA que 2.5mA ce qui à pour conséquence de limiter la taille de la résistance de convertion (car $U = R dot ["16mA" + I_"detecteur"]$)

En réalité, même sur la _chip_miroir_ le courant n'est pas vraiment recopié au sens stric du terme. Il est dans un premier temps convertis en tension dans le maitre du miroir ; tension qui viendra, dans un second temps, servir de commande pour faire passer le même courant dans l'esclave du miroir. Ainsi, la conversion courant-tension se fait dans tous les cas en interne d'ou l'idée de pouvoir directement lire cette tension grâce à la _chip_suiveur_. 

// ----------------- SOUS-SECTION ------------------ 
== Intérêt de la _chip\_suiveur_ <chip2>
 Afin de pouvoir correctement caractériser la conversion et maitriser les points de fonctionnement de l'étage d'entrée il nous fallait avoir directement accès à la valeur de la tension Vc après le bipolaire d'entrée (Q0 sur la @10_bipolaire_schematic). Ainsi, nous avions pensés à mettre un plots avant le maitre du miroir (P1 sur la @10_bipolaire_schematic) mais les capacités parasites du plots auraient dégradé notre signal et nous aurions  perdu de l'information. Nous avons donc conçu une seconde puce : la _chip\_suiveur_ (cf. @09_LOGMIC_chip_suiveur) qui est  *identique que la _chip\_miroir_ *du point de vue de l'étage d'entrée mais dans laquelle nous avons mis un suiveur de tension (transistor N27 sur la @09_LOGMIC_chip_suiveur) afin de décaler le plot d'accès en sortie du suiveur et ne pas venir perturber le noeud _VOUT1_ (comme illuestré @25_iout2_influence_plots). Ce choix s'accompagne de compromis : le suiveur ne permet de véhiculer que 88% environ de la tension.

#v(0.5cm)
#figure(
  image("Img/09_LOGMIC_chip_suiveur.png", width: 60%),
  caption: [Schema de  la _chip\_suiveur_],
)<09_LOGMIC_chip_suiveur>#v(0.5cm)

*Note : *La source de courant du bipolaire et du suiveur sont identiques pour simplifier le layout (et que la source de courant était aussi adaptée pour polariser le suiveur). 


// ----------------- SOUS-SECTION ------------------ 
== Layout <Sec_layout>
=== Packaging
Comme le run ihp130 était lancé par Europractice @bib_europractice, nous avons, par soucis de praticité, passer également par eux pour le packaging de _LOGMIC_V1_. Notre puce étant assez petite, il nous fallait trouver le package le plus petit possible. Les spécifications en ce qui concerne les placement de plots et les packages disponibles peuvent se trouver directement sur le site d'europractice section packaging @bib_europractice_package. Le package QFN 4x4 mm 12 aurait été idéal pour nous malheureusement il nous était impossible de trouver un bonding diagram qui corresponde aux règles de soudure. Nous somme donc parti sur le package QFN 4x4mm 28 plots (cf. @package_euro).

\
La @28_Bonding_diagram montre le bonding diagram de _LOGMIC_V1_ ainsi que les pin auxquels correspondent chaque plot. Les noms des signaux font référence à la cellule ```sh LOGMIV_TOP``` dans le dossier  ```sh LOGMIV_V1``` (cf. @Livrables).

#v(0.5cm)
#figure(
  image("Img/28_Bonding_diagram.png", width: 50%),
  caption: [Bonding diagral de la puce _LOGMIC_V1_],
)<28_Bonding_diagram>#v(0.5cm)

La puce a été placée sur un bord du packaging afin de minimiser la longueur des fils de bonding sur les entrées/sorties en courant.


=== Epaisseur de piste
Les @38_chip_miroir_layout et @39_chip_suiveur_layout montrent les layouts respectifs des _chip_miroir_ et _chip_suiveur_. On constate que les layouts des deux puces ont été pensés pour être assez compact malgré le fait que _LOGMIC_V1_ soit "pad limited" et que donc ça n'est pas la place qui manquait (comme on peut le voir sue le layout complet de la puce @05_LOGMIC_layout). Cette compacité permet d'une part de réduire les distances entre les sous-cellules (meilleure vitesse, moins de résistance etc.) mais également de prévoir de la place pour rajouter des composants dans le futur. Ceci étant dit, il est tout de même possible de gagner davantage de compacité si le besoin s'en faisait ressentir.

#v(0.5cm)
#figure(
  image("Img/38_chip_miroir_layout.png", width: 100%),
  caption: [Layout de la _chip_miroir_],
)<38_chip_miroir_layout>#v(0.5cm)

#v(0.5cm)
#figure(
  image("Img/39_chip_suiveur_layout.png", width: 70%),
  caption: [Layout de la _chip_suiveur_],
)<39_chip_suiveur_layout>#v(0.5cm)

Un autre point d'attention quand au layout des puce a été de bien respecter la largeur de piste permettant de passer du courant. En effet, la _LOGMIC_V1_ a été conçue pour fonctionner jusqu'à Iin = 10 mA crête-à-crête mais il se pourrait que davantage de courant rentre dans la puce. Il faut donc s'assurer que ce courant ne soit pas trop élevé et fasse griller la puce. C'est pourquoi nous avons choisis de mettre des *niveaux de métaux suppérieurs à 2* en entrée pour avoir une meilleure densité de courant (cf. le tableau @40_current_sensity_layout). Par ailleurs, nous nous sommes assurés de pouvoir faire passer jusqu'à 40 mA DC (valeur arbitraire mais qui nous semblais largement suffisante étant donné que le courant détecteur est impulsionnel). Pour ce faire une largeur de piste de 20 µm a été respecté pour IN mais aussi pour VB car du courant détecteur pourrait également passer par là.

#v(0.5cm)
#figure(
  image("Img/40_current_sensity_layout.png", width: 50%),
  caption: [Règles de densité de courant (tiré du pdk)],
)<40_current_sensity_layout>#v(0.5cm)

L'inconvénient de ces mesures de sécurité est que cela augmente l'impédance d'entrée du circuit $->$ il pourrait donc être judicieux dans une V2 de la puce de réadapter les longeurs et largeur des pistes.

=== Sealring
Point d'attention : le sealring est inclu dans une vue layout *séparée* dans la cellule ```sh LOGMIV_TOP```. Il est présent dans la puce envoyée en fonderie mais il a intentionnellement été mis de côté dans la cellule pour permettre de lancer le LVS et l'extraction de parasite correctement.

=== Plots et plan d'alimentation
Les plots ainsi que les plans d'alim ont étés designés par un laboratoire à Caen pour la techno ihp130n. Nous avons récupérés ces cellules et nous les avons intégrés à notre design en utilisant un script SKILL (cf. @ann_skill pour plus de détails). Les cellules permettant de faire le maillage d'alimentation sont également conçues pour pouvoir être automatiquement transformée en capacité reliant la masse au VDD et permettant, dans le cas ou il reste de la place (ce qui est notre cas) de lisser les parasites sur l'alimentation.




// ************************ SECTION ****************************************************
= Résultats de simulation et spécifications
Dans cette section nous allons spécifier les performances attentues de chacune des deux puces et détailler l'envirronnement de simulation associé à chacune d'elle. Pour finalement simuler la puce LOGMIC V1 dans son ensemble en post layout et donner les attentes de fonctionnement de la puce.


// ----------------- SOUS-SECTION ------------------ 
== Chip_miroir

=== Montage
Comme illustré sur la @15_Chip_miroir_simu_schematic, les puces sont dans un premier temps testées séparément en simulation dans un environnement le plus proche possible du cas d'usage. On retrouve :
- La modélisation du détecteur en lui même (à gauche sur la @15_Chip_miroir_simu_schematic) avec sa haute tension, une capa détecteur estimée à 30 pF, une source de courant impulsionnelle modélisant le signal détecteur et une capacité de découplage de 1 nF.
- On retrouve ensuite la diode externe BAT42W (cf. @ajout_BAT42W pour savoir comment ajouter le modèle SPICE à Cadence)
- Les plots d'accès (cf. @16_plot_simulation_model) ont étés ajoutés afin de simuler l'influence des capas et inductances parasites sur le signal de sortie. (la valeur des composants étant paramétrable sur maestro). 
- Enfin, on retrouve les résistances (ou diodes) de conversions externes. 

\
*Note : *les sources de courant et de tension sont considérées comme idéales.

#v(0.5cm)
#figure(
  image("/Img/15_Chip_miroir_simu_schematic.png", width: 100%),
  caption: [Schema de simulation de la _chip\_miroir_],
)<15_Chip_miroir_simu_schematic>#v(0.5cm)


#v(0.5cm)
#figure(
  image("Img/16_plot_simulation_model.png", width: 70%),
  caption: [Schema de simulation d'un plot],
)<16_plot_simulation_model>#v(0.5cm)

*Note:* Comme indiqué précédemment, les noms des signaux peuvent changer d'une simulation à l'autre dépendamment de quelle cellule a été utilisée pour la simulation.

== Nominal

Dans un premier temps, la  @31_100u_nominal simule le focntionnement de la puce pour un courant de 100 µA (en rouge sur la @31_100u_nominal). Il faut noter ici que les courants réels son *négatifs* e qu'ils ont étés redressés pour des questions de lisibilité!

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/30_chip_miroir_100u_nominal.png", width: 120%),
      image("Img/31_chip_suiveur_100u_nominal.png", width: 120%), 
      text("(a) chip_miroir"),
      text("(b) chip_suiveur"),
  ),
  caption: [Simulation des courants entrants et tensions de sortie pour un courant de 100µA en nominal],
)<31_100u_nominal>#v(0.5cm)

On constate qu'on eécupère bien une très large proportion du signal sur l'entrée de la puce et qu'une très faible proportion part dans la capa détecteur (et dans la diode externe BAT42W également même si ça n'est pas affiché ici). On constate également que notre signal est très rapide ce qui nous permet d'atteindre une très bonne résolution temporelle.

On peut également voir un exemple de signaux de sortie convertis, pour la _chip_miroir_ dans des résistances R2 = 500 $Omega$ et R3 = 100 $Omega$ .

== Parasitics

Dans cette section le simulations ont étés effectuée après extraction de parasites, ce qui permet d'obtenir quelque chose de plus fiable.

#v(0.5cm)
#figure(
  image("Img/32_Vout_chip_suiveur_parasitics.png", width: 70%),
  caption: [Simulation de la tension de sortie de la _chip_suiveur_ après extraction de parasites],
)<32_Vout_chip_suiveur_parasitics>#v(0.5cm)

#v(0.5cm)
#figure(
  image("Img/34_miroir_pareil_suiveur_parasitics_deux_Imax.png", width: 70%),
  caption: [Simulation des courants en entrée de la _chip_suiveur_ (identique que pour la _chip_miroir_) après extraction de parasites],
)<34_miroir_pareil_suiveur_parasitics_deux_Imax>#v(0.5cm)
#v(0.5cm)


#figure(
  image("Img/33_dVout_miroir_suiveur_parasitics.png", width: 100%),
  caption: [Simulation de l'élévation de la tension en sortie des deux _chip_suiveur_ et _chip_miroir_ après extraction de parasites],
)<33_dVout_miroir_suiveur_parasitics>#v(0.5cm)

On peut clairement voir sur la @33_dVout_miroir_suiveur_parasitics que les gammes de sensibilité sont dépendantes de la résistance de conversion.

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/35_Vout2_miroir_parasitics.png", width: 100%),
      image("Img/35_Vout3_miroir_parasitics.png", width: 100%), 
      text("(a) Sortie Vout2 de la _chip_miroir_"),
      text("(b) Avec plot sur out2_m"),
  ),
  caption: [Simulation des tensions de sorties de la _chip_miroir_ après extaction de parasites pour des résistances de conversion de $R_2 = 500 Omega "et" R_3 = 100 Omega$],
)<35_Vout_miroir_parasitics>#v(0.5cm)


On voit bien sur les @35_Vout_miroir_parasitics qu'à partir d'une certaine tension, le transistor escalave du miroir est étouffé et ne fonctionne plus correctement.


== Simulation en bruit <sec_bruit>

=== Chip_miroir
La @41_noise représente le bruit en tension généré par la _chip_miroir_ sur le noeud OUT2. Ce bruit comprend le 4KTR de la résistance de sortie de $100 space Omega$. 

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/41_noise_DSP.png", width: 100%),
      image("Img/41_noise_RMS.png", width: 100%), 
      text("(a) DSP de bruit "),
      text("(b) Bruit en tension (valeur RMS)"),
  ),
  caption: [Simulation du bruit en tension généré par _LOGMIC_V1_ sur le noeud OUT2 de la _chip_miroir_],
)<41_noise>#v(0.5cm)

On constate que le bruit RMS (calculé sur la gamme 10-100GHz) en tension sur OUT2 s'élève à $#rect(stroke: red)[536.9 µVrms]$ *pour une résistance de 500 $Omega$* (résistance de analoglib). D'après les courbes de la @42_dVout2_zoom_noisefloor on peut constater que on a $delta V_"out2" approx 5$ mV $approx 10 times "noise_rms"$ pour $#rect(stroke: red)[$I_"in" approx 15$ µA ]$ qu'on considère alors comme le *noise floor*.


#v(0.5cm)
#figure(
  image("Img/42_dVout2_zoom_noisefloor.png", width: 70%),
  caption: [Zoom du $delta V_"out2"$ petits courants pour la _chip_miroir_ (après extraction de parasites)],
)<42_dVout2_zoom_noisefloor>#v(0.5cm)
#v(0.5cm)


=== Chip suiveur

Les courbes de bruit généré par la _chip_suiveur_ se trouve @43_suiveur_noise. On peut remarquer que la chip suiveur génère beaucoup moins de bruit que la _chip_miroir_ du au fait qu'il n'y ai pas de miroir de courant.

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/43_suiveur_noise_DSP.png", width: 100%),
      image("Img/43_suiveur_noise_RMS.png", width: 100%), 
      text("(a) DSP de bruit "),
      text("(b) Bruit en tension (valeur RMS)"),
  ),
  caption: [Simulation du bruit en tension généré par _LOGMIC_V1_ sur le noeud de sortie de la _chip_suiveur_],
)<43_suiveur_noise>#v(0.5cm)

On voit que la _chip_suiveur_ génère un bruit en tension RMS sur la sortie total de $#rect(stroke: red)[231,47 µVrms]$. Si on zoom sur le $delta V_"out"$ de la _chip_suiveur_ (cf. @44_dVout_zoom_suiveur_noisefloor) on voit que la seuil de bruit (10 fois le bruit) se trouve à $#rect(stroke: red)[Iin $approx 37$ µA]$. On peut en conclure que bien que le bruit généré par la _chip_suiveur_ soit moins important en absolu que la _chip_miroir_, le noise floor est plus loin pour la _chip_miroir_. 

#v(0.5cm)
#figure(
  image("Img/44_dVout_zoom_suiveur_noisefloor.png", width: 70%),
  caption: [Zoom du $delta V_"out"$ petits courants pour la _chip_suiveur_ (après extraction de parasites)],
)<44_dVout_zoom_suiveur_noisefloor>#v(0.5cm)


== Spécifications

=== Tensions et courant de sortie
Comme dit précédemment, la tension attentue en sortie dépend de la résistance de conversion placée en sortie. La @36_dVout2_different_R quelques choix dans la résistance de conversion sur Vout2 pour la _chip_miroir_.

#v(0.5cm)
#figure(
  image("Img/36_dVout2_different_R.png", width: 100%),
  caption: [Simulation de Vout2 pour différentes résistances de conversion (R2) après extraction de parasites],
)<36_dVout2_different_R>#v(0.5cm)



=== Impédance d'entrée 
L'impédance d'entrée théorique de _LOGMIC_V1_ est celle du bipolaire d'entrée monté en grille commune: 
$ Z"in" alpha frac(1,"gm") = frac(U_T, I_C) $ avec $U_T = frac(k dot T, q)$, $space k approx 1,38 times 10^(-23) space J K^-$, $space q = 1.6*10^(-19)  C$ et $T approx 300 K$ 

$ "AN:" space Z"in" approx frac(1.38 *10^(-23) times 300, 1.6*10^(-19)) times frac(1, 4*10^(-3)) approx 6.5 space Omega $<eq_Zin>

Résultat obtenu si on néglique le courant détecteur (ce qui n'est pas le cas sur la fin de la gamme de fonctionnement)

_LOGMIC_V1_ va rentrer en concurence avec la diode BAT42W ainsi qu'avec la capacité détecteur. Ainsi, on s'attend à ce que l'impédance réelle obtenue soit légèrement supérieure au calcul de l'@eq_Zin.

Voici les résultats obtenus en simulation AC calculé @ 3ns (pic du courant entrant) pour un courant entrant de 100µA (négligeable devant le courant de polarisation, sans courant, les résultats sont très similaires).

#v(0.5cm)
#figure(
  image("Img/48_Zin_chip_miroir_3ns_nominal.png", width: 60%),
  caption: [Impédance calculée @ 3ns d'entrée de la _chip_miroir_ pour un courant détecteur de 100 µA en nominal],
)<48_Zin_chip_miroir_3ns_nominal>#v(0.5cm)


#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/49_Zin_diode_chip_miroir_3ns_nominal.png", width: 100%),
      image("Img/50_Zin_cd_chip_miroir_3ns_nominal.png", width: 100%), 
      text("(a) diode BAT42W "),
      text("(b) Capa détecteur"),
  ),
  caption: [Impédance calculée @ 3ns d'entrée de la capa détecteur et de la diode placée avant la _chip_miroir_ pour un courant détecteur de 100 µA en nominal],
)<50_Zin_cd_chip_miroir_3ns_nominal>#v(0.5cm)


On observe de ces trois courbes qu'effectivement, notamment sur les grandes fréquences, la capa de la diode vient se rajouter sur le noeud d'entrée ce qui la met en compétition avec _LOGMIC_V1_. On observe égalment que pour des fréquences de l'ordre du GHz les trois circuits ont des impédances d'entrée très similaires.

\
Une autre série de simulation a été menée après extaction de parasites pour estimer l'impact que cela a sur l'impédance d'entrée:

#v(0.5cm)
#figure(
  image("Img/47_Zin_chip_miroir_3ns.png", width: 60%),
  caption: [Impédance calculée @ 3ns d'entrée de la _chip_miroir_ pour un courant détecteur de 100 µA après extraction de parasites],
)<47_Zin_chip_miroir_3ns>#v(0.5cm)

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/45_Zin_diode_miroir_3ns.png", width: 100%),
      image("Img/46_Zin_cd_miroir_3ns.png", width: 100%), 
      text("(a) diode BAT42W "),
      text("(b) Capa détecteur"),
  ),
  caption: [Impédance calculée @ 3ns d'entrée de la capa détecteur et de la diode placée avant la _chip_miroir_ pour un courant détecteur de 100 µA après extraction de parasites],
)<50_Zin_cd_chip_miroir_3ns_nominal>#v(0.5cm)

== Résolution temporelle 

La formule pour calculer la ésoution temporelle est la suivante: 
$ R_t = frac("Noise_rms", frac(delta V, delta t)) $<equ_rt>

Par exemple, pour la _chip_suiveur_ si on se réfère à la @32_Vout_chip_suiveur_parasitics et si on prend le bruit de 231 µVrms calculé dans la @sec_bruit, pour un courant entrant de 230 µA, on obtient une résolution temporelle de 
$ R_"t suiveur" = frac(231 dot 10^(-6) times 2 dot 10^(-9),13.4 dot 10^(-3)) approx 35 "ps" $<equ_rt_suiveur>

De même, avec les données de la @35_Vout_miroir_parasitics(a) et les 536.9 µVrms calculé en @sec_bruit pour la _chip_miroir_, sur la sortie 2 pour un courant entrant de 94 µA, on obtient une résolution temporelle de : 
$ R_"t miroir" = frac(536.9 dot 10^(-6) times 2.55 dot 10^(-9),32.85 dot 10^(-3)) approx 42 "ps" $<equ_rt_miroir>

Les mêmes calculs ont étés effecués pour les vues extract des deux chip sur cadence 

#v(0.5cm)
#figure(
  grid(
      columns: 2,     // 2 means 2 auto-sized columns
      align: center,
      gutter: 0cm,    // space between columns
      image("Img/51_Rt_miroir.png", width: 120%),
      image("Img/51_Rt_suiveur.png", width: 120%), 
      text("(a) Chip_miroir "),
      text("(b) Chip_suiveur"),
  ),
  caption: [Résolution temporelle calculée en fonction du courant d'entrée],
)<51_Rt>#v(0.5cm)

// ******************** SECTION *********************************************************************
= PCB de test de LOGMIC

A venir . 
// ******************** SECTION *********************************************************************
= Conclusion et perspectives 
Cette première version de la puce permet de correctement lire le courant détecteur sur une plage de allant de la dizaine de µA à la dizaine de mA (gamme de $10^(6)$ #underline("ie.") 120 dB). Des sorties en courant et en tension ont étés placées afin de tester chacune des configurations possible. L'objectif est notamment de permettre de placer différentes résistances de conversion en externe pour venir tester chaque gamme de fonctionnement séparément. 

\
La difficulté ici est que la puce est designée pour une gamme de fonctionnement estimée et sur un détecteur dont la capacité parasite, la vitesse, l'amplitude sont également estimées. Cette première version va permettre de préciser un certain nombre de choses côté détecteur tout en caractérisant les forces et limitations de cette architecture hybride (lecture de gros signaux en externe et de petits signaux en intégré). 

\
Une fois les tests réalisés et la gamme de fonctionnement recherchée précisée. Il convient d'*améliorer l'existant* côté front-end pour une puce V2 mais également de travailler sur une meilleure solution de *conversion* courant-tension / lecture *en intégré*. 

\
Pour ce faire une deuxième verison de _LOGMIC_ est en préparation. Elle intègre le même front-end que _LOGMIC_V1_ mais avec un bloc numérique permettant de traiter les signaux en interne. L'intérêt ici d'ajouter un bloc numérique est qu'on peut alors *multiplier les miroirs de courants* pour effectuer des conversion courant-tension sur une plus grande gamme dynamique tout en s'affranchisant du problème du nombre de plots (qui était très limitant sur _LOGMIC_V1_ qui était *pad limited*). Ainsi la puce _LOGMIC_V2_ intégrera un module numérique chargé de récupérer les tensions en sorties de la puce et de les envoyer via comunication série vers l'extérieur.

Le deuxième rôle de ce bloc numérique sera de pouvoir commander tous les courants et tensions de référence directement en SPI à l'aide d'un seul plot d'entrée et ainsi obtenir une puce "core limited" et gagner de la surface.


// ******************** SECTION *********************************************************************
#bibliography("biblio.bib", title: "Références")



// ******************** SECTION *********************************************************************
#heading(outlined: false)[Annexes]

// Définir une autre façon de numéroter pour les annexes
#set heading(
  numbering: (..nums) => {
    return "A." + numbering("1 ", nums.pos().last())
  },supplement: [Annexe], outlined: false
)

// ----------------- SOUS-SECTION ------------------ 
== Caractérisation diode BAT42W  <ajout_BAT42W>
Dans un premier temps nous avons simulés la diode sur des simulateurs SPICE avant de l'intégrer à Candence.
Le modèle de la diode BAT42W a été trouvé sur le site _diodes.com_ @bib_diodes. Le modèle SPICE récupéré est le suivant:

#rect(fill: colors.code-bg)[
```cpp
*SRC=BAT42W;DI_BAT42W;Diodes;Si;  30.0V  0.200A  5.00ns   Diodes Inc Schottky Diode
.MODEL DI_BAT42W D  ( IS=87.5u RS=18.1m BV=30.0 IBV=500n
+ CJO=8.88p  M=0.333 N=3.51 TT=7.20n )
```]

La diode à étée simulée à l'aide du logiciel de simulation spice intégré à Kicad @bib_kicad (#text(fill: red, weight: "bold")[Attention:] Au moment de l'importation du modèle dans Kicad il peut arriver que le symbole de la diode se lie dans le *mauvais sens*) ainsi que sur le logiciel LTspice @bib_ltspice. La @18_BAT42W_ltspice_simu montre les résultats de simulation de la diode sur LTspice. On peut notamment observer que même pour un courant de 10 A la chute de tension observée ne dépasse pas les 1 V. On remarque également que la courbe $Delta V_d = f(|I_{"In max"}|)$ est prèsque linéaire à partir de 10 mA, ce qui implique une compression logarithmique dans la conversion courant-tension qui s'oppère dans la diode. On pourra tout de même émettre la réserve que le courant étant impulsionnel et très rapide les résultats de simulations SPICE obtenus peuvent s'avérer peu fiables. 

#v(0.5cm)
#figure(
  image("Img/18_BAT42W_ltspice_simu.png", width: 100%),
  caption: [Schema et simulation de la diode BAT42W dans le contexte de PICMIC sur LTspice],
)<18_BAT42W_ltspice_simu>#v(0.5cm)

Une simulation avec deux diodes en parallèle à également étée effectuée (cf @19_BAT42W_x2_ltspice_simu). On peut notamment observer une meilleure compression log (la courbe est davanatge droite) ainsi qu'une chute de tension un peu moins importante. 

#v(0.5cm)
#figure(
  image("Img/19_BAT42W_x2_ltspice_simu.png", width: 100%),
  caption: [Schema et simulation de deux diodes BAT42W mises en parallèle dans le contexte de PICMIC sur LTspice],
)<19_BAT42W_x2_ltspice_simu>#v(0.5cm)


\
La diode a été également simulée après importation sur cadence et les résultats de simulations sont très comparables à ceux obtenus grâce aux simulateurs SPICE (cf. @20_BAT42W_cadence_simu).


#v(0.5cm)
#figure(
  image("Img/20_BAT42W_cadence_simu.png", width: 100%),
  caption: [Schema et simulation de la diode BAT42W dans le contexte de PICMIC sur Cadence],
)<20_BAT42W_cadence_simu>#v(0.5cm)

*Aide :* Pour ajouter un modèle SPICE à Cadence et pouvoir simuler sa chip avec des modules extérieurs je recommande de suivre le tutoriel du site "Mis Circuitos" @bib_miscircuitos


// ----------------- SOUS-SECTION ------------------ 
== Package choisi chez Europractice <package_euro>

#v(0.5cm)
#figure(
  image("Img/29_package_europractice.png", width: 100%),
  caption: [Package QFN 'x'mm 28 plots choisi pour _LOGMIC_V1_],
)<29_package_europractice>#v(0.5cm)

== Script SKILL layout <ann_skill>

Voici un exemple de code (a réadaper) permettant de placer automatiquement les plots et le plan d'alim dans la techno ihp130n: 
#show raw.where(block: true): block.with(fill: luma(240), inset: 1em, radius: 0.5em, width: 100%)
#show raw.where(block: false): box.with(fill: luma(240), inset: (x: 3pt), outset: (y: 3pt), radius: 2pt)

```lisp 
; load("/share/Projets/IHP/ihp130/rduchadeau/cds_rev1.13.0/pad_2.il")
ineed('(geOpenOrRaisecv ))
cv = dbOpenCellViewByType( "design_rduchadeau" "L00_pad_2" "layout" "maskLayout" "w")

;; Define lib name and cellviews
libName="lpccaen_sg13s_pad"
vdd="lpccaen_sg13s_pad_vdd3v3_76u_76u"
vss="lpccaen_sg13s_pad_vss_76u_76u"
io="lpccaen_sg13s_pad_ana_0_76u_76u"
mesh="lpccaen_sg13s_mesh_subCell"
libName_sealring="SG13_dev"
sealring="sealring_complete"
win=geOpenOrRaisecv(cv)

cvdd=(dbOpenCellViewByType libName vdd "layout")
cvss=(dbOpenCellViewByType libName vss "layout")
cio=(dbOpenCellViewByType libName io "layout")
cmesh=(dbOpenCellViewByType libName mesh "layout")
cring=(dbOpenCellViewByType libName_sealring sealring "layout")

;; remove previous seletion 
oldSelect=geGetSelectedSet()
geDeselectAll(win)

;; MESH CREATION
imesh=dbCreateInst(cv cmesh nil 0:0 "R0")
mosaic=leConvertInstToMosaic(imesh)
instm=car(mosaic)
instm~>rows=39
instm~>columns=39
bBoxm=instm~>bBox
dbFlattenInst(instm 1 nil)

;; DELET CORNERS
; select the mesh grid corners
cx0=caar(bBoxm) 
cy0=nth(1 nth(0 bBoxm) )
cx1=nth(0 nth(1 bBoxm) )
cy1=nth(1 nth(1 bBoxm) )
geSingleSelectPoint(win nil cx0:cy0)
ss=geGetSelectedSet()  sss=setof(s ss s~>cellName==mesh) foreach(s sss dbDeleteObject(s))
geSingleSelectPoint(win nil cx0:cy1)
ss=geGetSelectedSet()  sss=setof(s ss s~>cellName==mesh) foreach(s sss dbDeleteObject(s))
geSingleSelectPoint(win nil cx1:cy0)
ss=geGetSelectedSet()  sss=setof(s ss s~>cellName==mesh) foreach(s sss dbDeleteObject(s))
geSingleSelectPoint(win nil cx1:cy1)
ss=geGetSelectedSet()  sss=setof(s ss s~>cellName==mesh) foreach(s sss dbDeleteObject(s))

; TODO for multiple selection a once
;geSelectPoint(win nil cx1:cy1)

;; ADD SEALRING
;isealring=dbCreateInst(cv cring nil -10:-10 "R0")
iseal=dbCreateParamInst(cv cring  nil -10:-10 "R0" 1 '(("w" "string"  "800u") ("l" "string" "800u")))
; A adapter et utiliser:
;iseal=dbCreateParamInstByMasterName(cv car(lc) sealRing "layout" nil back "R0" 1 propList)

;; ADD PLOTS
plots='()
x0=20 y0=20
grid_pitch=20
pas=6*grid_pitch


;;;; GAUCHE
iio=dbCreateInst(cv cvss nil    list(x0 y0) "R0")
iio1=dbCreateInst(cv cvss nil    list(x0 y0+pas+grid_pitch) "R0")
iio2=dbCreateInst(cv cio nil    list(x0 y0+pas*2+grid_pitch) "R0")
iio3=dbCreateInst(cv cio nil    list(x0 y0+pas*3+grid_pitch) "R0")
iio4=dbCreateInst(cv cio nil    list(x0 y0+pas*4+grid_pitch) "R0")
iio5=dbCreateInst(cv cvdd nil    list(x0 y0+pas*5+grid_pitch*2) "R0")

;;;; DROIT
;si rotate 180, ajout 100 (taille plot) en y et 100 en x
iio6=dbCreateInst(cv cvdd nil    list(x0+pas*5+140 y0+100) "R180")
iio7=dbCreateInst(cv cvdd nil    list(x0+pas*5+140 (y0+100)*2+grid_pitch) "R180")
iio8=dbCreateInst(cv cio nil    list(x0+pas*5+140 (y0+100)*3+grid_pitch) "R180")
iio9=dbCreateInst(cv cio nil    list(x0+pas*5+140 (y0+100)*4+grid_pitch) "R180")
iio10=dbCreateInst(cv cio nil    list(x0+pas*5+140 (y0+100)*5+grid_pitch) "R180")
iio11=dbCreateInst(cv cvss nil    list(x0+pas*5+140 (y0+100)*6+grid_pitch*2) "R180")

;;;; BAS
iio12=dbCreateInst(cv cio nil    list(x0+pas*2 y0) "R90")
iio13=dbCreateInst(cv cio nil    list(x0+pas*3 y0) "R90")
iio14=dbCreateInst(cv cio nil    list(x0+pas*4 y0) "R90")
iio15=dbCreateInst(cv cio nil    list(x0+pas*5 y0) "R90")

;;;; HAUT
iio16=dbCreateInst(cv cio nil    list(x0+pas*1+grid_pitch y0+pas*5+100+grid_pitch*2) "R270")
iio17=dbCreateInst(cv cio nil    list(x0+pas*2+grid_pitch y0+pas*5+100+grid_pitch*2) "R270")
iio18=dbCreateInst(cv cio nil    list(x0+pas*3+grid_pitch y0+pas*5+100+grid_pitch*2) "R270")
iio19=dbCreateInst(cv cio nil    list(x0+pas*4+grid_pitch y0+pas*5+100+grid_pitch*2) "R270")

;; REMOVE MESH BELOW THE PLOTS
plots=list(iio iio1 iio2 iio3 iio4 iio5 iio6 iio7 iio8 iio9 iio10 iio11 iio12 iio13 iio14 iio15 iio16 iio17 iio18 iio19)
bBox=iio~>bBox
foreach(mapcar i plots bBox=i~>bBox geSingleSelectBox(win nil bBox) ss=geGetSelectedSet()  sss=setof(s ss s~>cellName==mesh) foreach(s sss dbDeleteObject(s)) )


;; COMMENT FOR VISIBILITY
;leSetLayerVisible( '("TopMetal1" "drawing") nil);
;leSetLayerVisible( '("TopMetal2" "drawing") nil);
leSetLayerVisible( '("prBoundary" "drawing") nil);<= marche pas rendre invisible boundary ?
;pteSetVisible("prBoundary drawing" t "Layers")  ;<= fonctions à utiliser pour boundary
pteSetVisible("prBoundary drawing" nil "Layers")

```
