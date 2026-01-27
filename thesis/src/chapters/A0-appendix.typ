#import "../lib.typ": abbr, autoOutline

// Do not number the appendix chapters
#set heading(numbering: none)

#[
  // Make the Appendix heading invisible so that it only appears in the outline
  #show heading: none
  #pagebreak(to: "odd", weak: true)
  = Appendix
]

// Nest all following headers under the Appendix heading
#set heading(offset: 1)
// Include lists generated with outline in the main outline. Nest them under the appendix
#show outline: set heading(outlined: true)

#abbr.list()

#autoOutline([List of Figures], figure.where(kind: image))

#autoOutline([List of Tables], figure.where(kind: table))

#autoOutline([List of Source Code], figure.where(kind: raw))

// == List of Algorithms
// #pagebreak(to: "odd")

#bibliography("../thesis.bib", style: "ieee", title: [References])
