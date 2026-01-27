#import "@preview/abbr:0.2.3" as abbr-lib
#import "@preview/codly:1.3.0" as codly-lib
#import "@preview/codly-languages:0.1.8": codly-languages
#import "@preview/icu-datetime:0.1.2" as icu

#let html = sys.inputs.keys().contains("html") and sys.inputs.html == "true"

// Re-export
#let abbr = abbr-lib
#let acr = abbr.a
#let acrs = abbr.s
#let acrl = abbr.l
#let acrlo = abbr.lo
#let acrpl = abbr.pla
#let acrspl = abbr.pls
#let acrlpl = abbr.pll
#let acrlopl = abbr.pllo
#let codly = codly-lib
#let codly-local = codly-lib.local

#let lineSpacing = 0.55em
#let ruleStroke = 0.5pt
#let paragraphIndent = 1.8em

// The tracking has been calibrated to match how the fonts are rendered by LaTeX
#let fonts = (
  serif: (font: "Bitstream Charter", tracking: -0.025em),
  sans: (font: "Nimbus Sans L", tracking: -0.05pt), // What uwr-base35 uses for helvet
  mono: (font: "Copperflame Mono", tracking: 0pt, size: 1.05em),
  math: (font: "New Computer Modern Math", tracking: 0pt), // Math just doesn't feel scientific in any other font
)

// Font sizes as used by 10pt LaTeX (see size10.clo and latex.ltx)
#let textsize = (
  tiny: 5pt,
  scriptsize: 7pt,
  footnotesize: 8pt,
  small: 9pt,
  normalsize: 10pt,
  large: 12pt,
  Large: 14.4pt,
  LARGE: 17.28pt,
  huge: 20.74pt,
  Huge: 24.88pt,
)

#let hr() = {
  let lineExtension = .2em
  line(start: (-lineExtension / 2, 0pt), length: 100% + lineExtension, stroke: ruleStroke)
}

#let oddPage() = calc.rem(here().page(), 2) == 1

#let alignOuter(content) = {
  if oddPage() {
    h(1fr)
  }
  content
}

#let chapterNum(it) = text(it, fill: luma(40%))

#let heading-level = state("heading", 0)

#let setupPaged(body) = {
  set page("a4") // Needs to be set here so that the correct dimensions are available in the context

  context {
    // Page layout
    let contentWidth = 410pt
    let contentHeight = 598pt
    let horizontalMargin = (page.width - contentWidth) / 2
    let verticalMargin = (page.height - contentHeight) / 2
    set page(margin: (top: verticalMargin, bottom: verticalMargin, left: horizontalMargin, right: horizontalMargin))

    // Header
    set page(
      header-ascent: 20pt,
      header: context {
        let headings = query(heading.where().before(here())).filter(it => it.level <= calc.min(heading-level.get(), 2))
        if headings.len() > 0 {
          let parts = ()
          let h = headings.last()
          let num = {
            if h.numbering != none {
              numbering(h.numbering, ..counter(heading).at(h.location()))
            } else {}
          }
          parts.push(h.body)
          while h.level > 1 {
            h = headings.filter(it => it.level < h.level).last()
            parts.push(h.body)
          }
          let numtext = chapterNum(num)
          if not oddPage() {
            parts = parts.rev()
            alignOuter([*#numtext#sym.space.fig#parts.join([ -- ])*])
          } else {
            alignOuter([*#parts.join([ -- ])#sym.space.fig#numtext*])
          }
          hr()
        }
        // }
      },
    )

    // Footer
    set page(footer-descent: 22.5pt, footer: context {
      if page.numbering != none {
        let loc = here()
        alignOuter(numbering(loc.page-numbering(), ..counter(page).at(loc)))
      }
    })

    // Headings
    show heading: it => {
      heading-level.update(it.level - 1)
      set text(weight: "bold", size: textsize.normalsize)
      set block(above: 2em, below: 1em)

      let headingText = block[#chapterNum(counter(heading).display())#sym.space.fig#it.body]

      if it.depth == 1 {
        /// chapter
        if it.level == 1 {
          pagebreak(to: "odd", weak: true)
        } else {
          pagebreak(weak: true)
        }
        set text(size: textsize.huge, weight: "bold", tracking: .16em)
        block(below: 40pt, height: 4.2cm, {
          v(1fr)
          block(above: 0pt, below: 0pt, {
            box(upper(it.body))
            if it.numbering != none {
              h(1fr)
              box(text(fill: gray, size: 96pt, weight: "regular", counter(heading).display()))
            }
          })
          v(0.75 * lineSpacing)
          block(above: 0pt, below: 0pt, hr())
        })
      } else if it.depth == 2 {
        /// section
        set text(size: textsize.Large)
        set block(above: 2.25em, below: 1.2em)
        headingText
      } else if it.depth == 3 {
        /// subsection
        set text(size: textsize.large)
        headingText
      } else {
        headingText
      }
      heading-level.update(it.level)
    }

    body
  }
}

#let setup(body) = {
  // Regular text
  set par(leading: lineSpacing, spacing: 2 * lineSpacing, first-line-indent: 1em, justify: true)
  set text(
    size: textsize.normalsize,
    lang: "en",
    costs: (hyphenation: 80%, widow: 100%, orphan: 100%, runt: 100%),
    ..fonts.serif,
  )

  // Lists
  set list(indent: paragraphIndent, spacing: lineSpacing * 2.75)
  show list: it => {
    block(above: lineSpacing * 2.75, below: lineSpacing * 2.75, it)
  }
  set enum(numbering: "(1)")

  // Figures
  show figure: it => block(inset: (y: 2 * lineSpacing), it)

  // Code
  let codlyColor = luma(240)
  let codeBackground = codlyColor.lighten(50%)

  show: codly.codly-init.with()
  codly.codly(
    languages: codly-languages,
    radius: 0.64em,
    // lang-outset: (x: 0pt, y: 0.32em),
    lang-radius: 0.48em,
    lang-stroke: none,
    lang-fill: (lang) => none,
    number-format: n => text(codlyColor.darken(25%), str(n)),
    zebra-fill: codeBackground,
    // header-cell-args: (stroke: (bottom: stroke(paint: codlyColor, thickness: 1pt))),
    header-cell-args: (fill: codlyColor),
  )
  show raw: set text(..fonts.mono)
  show raw.where(block: true): set text(size: 8pt)

  // show raw.where(block: false): it => box(fill: codeBackground, outset: 1.5pt, radius: 1.5pt, it)

  // Outlines
  /// Main outline
  show outline.where(title: auto): it => {
    show outline.entry.where(level: 1): entry => {
      show repeat: none // Hide the fill

      [ \ ]
      text(weight: "bold", entry)
    }
    it
  }

  // Abbreviations
  abbr.config(style: it => underline(it, stroke: stroke(dash: "densely-dotted", paint: gray)))

  if not html {
    setupPaged(body)
  } else {
    body
  }
}

#let fmt-date(date) = context icu.fmt-date(date, locale: text.lang, length: "long")

#let autoOutline(title, target) = context {
  let results = query(target)
  if results.len() > 0 {
    outline(title: title, target: target)
  }
}

// #let cn() = text([*[cn]*], red, ..fonts.mono)
// #let todo(body) = text([TODO: #body], green.darken(33%), ..fonts.mono)
// #let fixme(body) = text([FIXME: #body], red, weight: "bold", ..fonts.mono)

// The IEEE citation style we are using does not shorten with "et al.".
// Because this hurts the readability of the text, we use APA for the author part and IEEE for the "[number]" reference
#let author-cite(label) = cite(label, form: "author", style: "apa")
#let prose-cite(label) = [#author-cite(label)#sym.space.punct#cite(label)]

#let fig-supplement = text.with(size: .75em)
