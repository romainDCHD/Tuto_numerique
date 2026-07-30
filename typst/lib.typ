#let colors = (
  primary: rgb("#00284b"),
  secondary: rgb("#3498DB"),
  accent: rgb("#2ECC71"),
  text: rgb("#2C3E50"),
  code-bg: rgb("#F4F6F6"),
  gold-code-bg: rgb("#f7f7d1"),
  proof-bg: rgb("#EBF5FB"),
)

// TODO en rouge 
#let TODO(montexte)= {
  v(0.5cm)
  box(width: 100%, inset: 4pt, stroke: red)[#text(fill: red, weight: "bold")[*TODO:* #montexte]]
  v(0.5cm)
}

#let rouge(montexte)= {
  text(fill: red, weight: "bold")[ #montexte]
}

// Configure codeblock
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

//Annotations
#import "@preview/deixis:0.1.1": *

//Box 
#import "@preview/showybox:2.0.4": showybox



// Main template
// Permet d'encapsuler les show et let en un seul endroit et changer facilement de template 
#let template_R(
  title: "",
  authors: (), // list of tuples: (name, affiliation, email)
  date: "2025-2027",
  logos: none,
  lang: "fr",
  heading-color: colors.primary,
  body,
) = {
  
  // Met à jour les variables du document
  let first-author = authors.at(0).at(0)  // Récupère le nom du premier auteur
  set document(title: title, author: first-author)

  // Met à jours les paramètres de chaque page 
  set page(
    paper: "a4",
    margin: 2cm,
    header: context {
      if counter(page).get().first() > 1 {
        grid(
          columns: (1fr, 1fr),
          align(left)[#smallcaps(title)],
          align(right)[#counter(page).display()],
        )
        line(length: 100%, stroke: 0.5pt + gray)
      }
      counter(footnote).update(0) //Permet de numéroter les footnote par page
    },
  )

  // Met à jour les règles pour les paragraphes
  set par(justify: true, leading: 1em, spacing: 1em)

  // Règle pour les headings
  set heading(numbering: "1.")

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(2em)
    text(size: 20pt, weight: "bold", fill: heading-color)[#it]
    v(1em)
    line(length: 100%, stroke: 1pt + heading-color)
    v(1em)
  }

  show heading.where(level: 2): it => {
    v(1.5em)
    text(size: 14pt, weight: "bold", fill: heading-color)[#it]
    v(0.75em)
  }

  show heading.where(level: 3): it => {
    v(1em)
    text(size: 12pt, weight: "bold", fill: heading-color.lighten(20%))[#it]
    v(0.5em)
  }

  show heading.where(level: 4): it => {
    v(1em)
    text(size: 12pt, weight: "bold", fill: heading-color.lighten(30%))[#it]
    v(0.5em)
  }
  // footnotes 
  show footnote.entry: set text(colors.primary)
  set footnote.entry(gap: 0.6em)
  show footnote.entry: it => {
  let loc = it.note.location()
  numbering(
    "1. ",
    ..counter(footnote).at(loc),
  )
  it.note.body
}

  // numéroter les équations 
  set math.equation(numbering: "(1)")
  
  // ref avec couleur 
  show ref: set text(weight: "bold", colors.primary)

  // figure caption underlined
  // 2 façons de faire : 
  // 
  // Ex: Si on veut custom plusieurs choses à la fois :
  // show figure.caption: it => [
  //   #underline(it.body)
  //  #context it.counter.display(it.numbering)
  // ] 
  // 
  // Si on veut custom qu'une chose 
  show figure.caption: underline

  //liens
  show link:  it => [
    #text(fill: colors.primary)[#underline(it)]
  ]

  // Biblio 
  show bibliography: set heading(numbering: "1.")

  // Codeblock
  show: codly-init.with()
  codly(stroke: 1pt + gray, fill: colors.code-bg, zebra-fill: colors.code-bg, footer-cell-args: (align: center, fill: silver))

  // Annotations
  show: deixis-setup-notes
  deixis-set-pin-pattern(
  prefix: "aaaa",
  postfix: "bbbb",
)
  /////// FIN REGLES GENERALES /////////

  /////// Title page ///////
  // Faire une variable pour la page de garde pour pouvoir la modifier plus rapidement
  let page-de-garde = [
    #align(center, [
      // Titre
       #v(2cm)
      #text(size: 40pt, weight: "bold", title)

      #v(1cm)
      // Logo (si présent)
      #if logos != none [
        
        // Cas 1 seul logo
        // #image(logos, width: 30%)

        // Si plusieurs logos
        #let nombre_logos = logos.len()
        
        #grid(
          columns: 15cm, 
          grid(
              columns: nombre_logos,     // 2 means 2 auto-sized columns
              align: center,
              gutter: 0.5cm,    // space between columns
              [#align(right)[#image(logos.at(0), width: 50%)]],
              [#align(left)[#image(logos.at(1), width: 50%)]], // ajouter manuellement les logos
          ),
        )      

        #v(2cm)
      ]
    
      // Liste des auteurs
      #for (nom, affiliation, email) in authors {
        [
          #nom #h(0.2cm) (#affiliation) 
          #if email != none [
            // #footnote(email)
            #h(0.2cm)#footnote(link("mailto:" + email, email)) \
          ]
        ]
      }

      // Date
      #v(2cm)
      // #text(size: 20pt, date)
      #text(size: 20pt, [Dernière modification:])

      #text(size: 20pt, [#datetime.today().display("[day]/[month]/[year]")])
      
    ])

  ]

  ////////////// A AFFICHER //////////////////// 
  [
    #page(
      margin: (x: 2cm, y: 3cm),
      page-de-garde, // Equivalent à un import title_page.tex
    )

    #pagebreak() 
    #outline( 
      title: "Table des matières"
       )
    #pagebreak()  // Saut de page avant le corps (optionnel)

    #body
  ]
}
