#import "lib.typ": setup, html, abbr, heading-level, lineSpacing

#abbr.load("acronyms.csv")

#show: setup

#metadata("Bachelorarbeit im Fach Informatik") <thesistype>

#set document(
  title: "A Full-Source Bootstrap for NixOS",
  author: "Wire Jansen",
  date: datetime(year: 2025, month: 10, day: 27),
)

#metadata("Prof. Dr.-Ing. Peter Ulbrich") <advisor>
#metadata("Alwin Berger, M.Sc.") <advisor>
#metadata("Arbeitsgruppe Systemsoftware (LS-12)") <chair>
#metadata("https://sys.cs.tu-dortmund.de") <chair-url>

#include "coverpage.typ"

#pagebreak(to: "odd", weak: true)
// Use latin numbers for everything before the first chapter
#show: it => if not html {
  set page(numbering: "i")
  it
} else {
  it
}

#include "chapters/00-abstract.typ"

#if not html [
  #set par(spacing: lineSpacing)
  #outline()
]

// Switch to arabic numerals and reset the page counter
#set heading(numbering: "1.1")
#show: it => if not html {
  set page(numbering: "1")
  it
} else {
  it
}
#heading-level.update(0)
#pagebreak(to: "odd") // The pagebreak has to happen _before_ the counter is reset
#counter(page).update(1)

#include "chapters/01-introduction.typ"

#include "chapters/02-background.typ"

#include "chapters/03-implementation.typ"

#include "chapters/04-results.typ"

#include "chapters/05-discussion.typ"

#include "chapters/06-related-work.typ"

#include "chapters/07-conclusion.typ"

#v(10em)

#include "chapters/A0-appendix.typ"
