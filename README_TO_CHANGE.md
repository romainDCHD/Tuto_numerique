# Digi Tuto — méthodologie ASIC numérique

Guide progressif pour apprendre un flow numérique avec Xcelium,
Genus et Innovus.

Le parcours commence par un full adder combinatoire, puis augmente la
complexité avec un additionneur 8 bits pipeliné. Pour chaque outil, le guide
présente d'abord la commande minimale, ensuite les fichiers séparés, puis le
script réutilisable et enfin la méthode avancée.

## Guides PDF

- [Méthodologie ASIC numérique complète](pdf/methodologie_asic_numerique.pdf)
- [Simulation RTL avec Xcelium](pdf/01_simulation_xcelium.pdf)
- [Synthèse logique avec Genus](pdf/02_synthese_genus.pdf)
- [Implémentation physique avec Innovus](pdf/03_implementation_innovus.pdf)

Les empreintes SHA-256 sont disponibles dans
[pdf/SHA256SUMS](pdf/SHA256SUMS).

## Contenu

```text
pdf/       quatre guides prêts à lire
examples/  RTL, testbenches, filelists, SDC et paramètres des designs
scripts/   lanceurs Xcelium, Genus et Innovus
flow/      Tcl minimal et avancé pour Genus et Innovus
config/    modèle de configuration technologique du laboratoire
```

## Démarrage

Simulation RTL :

```bash
bash scripts/run_sim.sh full_adder_comb
bash scripts/run_sim.sh adder_pipeline
```

Préparer ensuite un fichier privé à partir de
`config/technology.example.env`, puis définir son chemin :

```bash
export LAB_CONFIG=/chemin/prive/lab.env
```

Synthèse progressive :

```bash
bash scripts/run_syn.sh --design full_adder_comb
bash scripts/run_syn.sh --design adder_pipeline \
  --level advanced --view mmmc
```

Implémentation progressive :

```bash
bash scripts/run_pnr.sh run \
  DESIGN=full_adder_comb \
  SYN_RUN_DIR=/tmp/digi_tuto_runs/genus/full_adder_comb/<run> \
  LEVEL=basic

bash scripts/run_pnr.sh run \
  DESIGN=adder_pipeline \
  SYN_RUN_DIR=/tmp/digi_tuto_runs/genus/adder_pipeline/<run> \
  LEVEL=advanced VIEW=mmmc
```

Les résultats sont créés par défaut sous `/tmp/digi_tuto_runs`; aucun résultat
d'outil n'est placé dans le dossier du tutoriel.

Les collatéraux PDK et les licences Cadence ne sont pas fournis. Le GDS produit
par le niveau avancé reste un candidat d'implémentation, pas une preuve de
signoff.

## Licences

- Scripts et exemples : MIT.
- Guides : CC BY 4.0.
