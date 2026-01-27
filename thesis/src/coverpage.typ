
#[
  #import "lib.typ": fonts, lineSpacing, textsize, fmt-date

  #set text(
    lang: "de", // The coverpage is in german and we want to get the correct formatting
    ..fonts.sans,
  )
  #set par(leading: lineSpacing * 1.25, spacing: lineSpacing)

  #let marginLeft = -1.5cm

  #v(-3cm)

  #h(marginLeft) #box(width: 12.5cm, context [
    #v(par.leading)
    #h(par.first-line-indent.amount) #box(width: 8cm, { image("/assets/tu-logo.jpg") })
  ])

  #v(4cm)

  #h(marginLeft - 0.2cm) #box(width: 9cm, [
    #set text(size: textsize.large)
    #align(center, [
      #text(size: textsize.Large, context query(<thesistype>).first().value)
      #v(1cm)
      #block(height: 1.75 * textsize.large + lineSpacing, [
        *#context document.title*
      ])
      #v(1cm)
      #context document.author.join(", ") \
      #context fmt-date(document.date)
    ])
  ])

  #v(5.5cm + 2.1cm)

  #h(marginLeft) #box(width: 8cm, [
    Gutachter: \
    #context query(<advisor>).map(it => it.value).flatten().join("\n")
  ])

  #v(2.5cm)

  #h(marginLeft) #box(width: 8cm, [
    Technische Universität Dortmund \
    Fakultät für Informatik \
    #context query(<chair>).first().value \
    #context link(query(<chair-url>).first().value)
  ])

  #pagebreak(to: "odd")
]
