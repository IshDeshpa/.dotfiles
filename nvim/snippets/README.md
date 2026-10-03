# Typst snippets

Blink loads `typst.json` automatically from this directory for `.typ` files.
Type a prefix, select its completion, and press Enter to expand. Use Tab and
Shift-Tab to move between placeholders (or Ctrl-y to accept a completion).

| Prefix | Expansion |
| --- | --- |
| `h1`, `h2`, `h3` | Headings |
| `bold`, `emph`, `link`, `code` | Text formatting and links |
| `mk`, `dm` | Inline and display math |
| `frac`, `sqrt`, `sum`, `int`, `mat`, `cases` | Expressions to insert inside math mode |
| `fig`, `table` | Figure and table |
| `doc`, `import`, `bib` | Document setup, imports, bibliography |

Use markup snippets without typing a leading `#`; their bodies include it where
needed. Math expression snippets are offered throughout Typst buffers, so use
them inside `$...$`. Literal math delimiters are escaped as `\\$` in JSON so
Neovim can distinguish them from snippet placeholders.

These local snippets use Blink's existing native snippet engine. The upstream
`abhinandh-s/typst-snippets` collection was evaluated, but its math snippets failed
Neovim's native snippet parser due to unescaped dollar signs.
