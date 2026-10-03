// Copy this file for each homework and edit these fields.
#let course = "COURSE 101"
#let assignment = "Homework 1"
#let author = "Ishan Deshpande"
#let subtitle = "Course Name · Semester Year"
#let title = course + " · " + assignment

// Document layout and typography.
#let question(body) = block(above: 0pt, below: 5pt, sticky: true)[
  #text(size: 9pt, weight: "semibold", fill: rgb("354657"))[#body]
]
#set document(title: title, author: author)
#set page(
  paper: "us-letter",
  margin: (x: 0.72in, top: 0.72in, bottom: 0.7in),
  header: align(right, text(size: 8pt, fill: rgb("64748b"))[#title]),
  footer: context align(center, text(size: 8pt, fill: rgb("64748b"))[#counter(page).display("1")]),
)
#set text(font: "Libertinus Serif", size: 10pt, fill: rgb("202833"))
#set par(leading: 0.5em, spacing: 0.65em)
#set enum(numbering: "(a.i)", full: false, indent: 0pt, body-indent: 1.5em, spacing: 0.8em)
#set list(indent: 0pt, body-indent: 1.2em)
#set heading(numbering: none)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(above: 0pt, below: 14pt)[
    #text(font: "Libertinus Serif", size: 17pt, weight: "bold", fill: rgb("243e56"))[#it.body]
    #v(5pt)
    #line(length: 100%, stroke: 0.6pt + rgb("b8c6d1"))
  ]
}
#set table(inset: (x: 7pt, y: 3.5pt), stroke: 0.4pt + rgb("d1d9e0"), fill: (x, y) => if y == 0 { rgb("e6edf3") } else if calc.odd(y) { rgb("f7f9fb") })
#show table: set text(size: 9pt)
#show table: it => block(breakable: false, it)
#show raw: set text(font: "DejaVu Sans Mono", size: 8pt)
#show raw.where(block: true): it => block(
  width: 100%, inset: 9pt, fill: rgb("f4f6f8"),
  radius: 3pt, breakable: false,
)[
  #set par(leading: 0.4em, spacing: 0pt)
  #it
]
#show math.equation: set text(size: 9.5pt)
#show math.equation.where(block: true): set block(above: 0.65em, below: 0.65em)
#set figure(gap: 8pt)
#show figure.caption: set text(size: 9pt, fill: rgb("536273"))

#align(center)[
  #text(size: 23pt, weight: "bold", fill: rgb("243e56"))[#title]
  #v(6pt)
  #text(size: 12pt)[#author]
  #v(4pt)
  #text(size: 9pt, fill: rgb("64748b"))[#subtitle]
]

// The first problem stays on the title page.
#block(above: 18pt, below: 12pt)[
  #text(size: 17pt, weight: "bold", fill: rgb("243e56"))[Problem 1: Title]
]

+ #question[Insert the question for part (a).]

  Write your solution here.

+ #question[Insert the question for part (b).]

  Write your solution here.

// Level-one headings start subsequent problems on new pages.
= Problem 2: Title

#question[Insert the question.]

Write your solution here.

// Duplicate a problem section or add more enumerated parts as needed.
// Display equation: $ y = m x + b $
// Table:
// #table(
//   columns: 2,
//   table.header([*Quantity*], [*Value*]),
//   [Example], [0],
// )
// Figure (replace the path with your image):
// #figure(image("figure.png", width: 80%), caption: [Description.])
// Use triple backticks for a styled code block.
