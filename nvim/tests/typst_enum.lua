-- Run from the dotfiles root:
-- nvim --headless -n -u NONE -i NONE -l nvim/tests/typst_enum.lua
vim.opt.rtp:append(vim.fn.getcwd() .. "/nvim")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
local enum_text = require("plugins.markview").opts.typst.list_items.marker_plus.text
local buffer = vim.api.nvim_create_buf(false, true)
local function check(source, expected)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(source, "\n"))
  local actual = {}
  for row, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
    local indent = line:match("^(%s*)%+")
    if indent then
      actual[#actual + 1] = string.format(
        enum_text(buffer, {
          range = { row_start = row - 1, col_start = #indent },
        }),
        999
      )
    end
  end
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end

check(
  '#set enum(numbering: "1.a.I.i", full: true)\n= Title\n+ A\n  + B\n    + C\n      + D\n  + E\n+ F',
  { "1", "1.a", "1.a.I", "1.a.I.i", "1.b", "2" }
)
check('#set enum(numbering: "(1.a)")\n+ A\n  + B\n  + C\n+ D', { "(1)", "(a)", "(b)", "(2)" })
check('#set enum(numbering: "A)", start: 26)\n+ A\n+ B\n\n+ C\n\nParagraph\n\n+ D', { "Z)", "AA)", "AB)", "Z)" })
check('#set enum(numbering: "i.")\n4. Four\n+ Five\n+ Six', { "v.", "vi." })
check('#set enum(numbering: "1%")\n+ A', { "1%" })
check("#set enum(numbering: n => str(n))\n+ A", { "+" })
check('#set enum(numbering: "α)")\n+ A', { "+" })
check("#set enum(reversed: true)\n+ A", { "+" })
check('// #set enum(numbering: "a)")\n+ A\n#[\n#set enum(numbering: "I)")\n+ B\n]\n+ C', { "1.", "I)", "1." })
check('```typst\n#set enum(numbering: "a)")\n+ example\n```\n+ Real', { "+", "1." })
check('#set enum(\n numbering: "1.a",\n full: true,\n)\n+ A\n  + B', { "1", "1.a" })
-- Same buffer, same marker position: edits must invalidate cached labels.
check('#set enum(numbering: "a)")\n+ A', { "a)" })
check('#set enum(numbering: "I)")\n+ A', { "I)" })
check('#set enum(numbering: "1.", full: true)\n+ A\n  + B\n    + C', { "1.", "1.1.", "1.1.1." })
check('= One\n#set enum(numbering: "a)")\n+ A\n= Two\n+ B', { "a)", "a)" })
vim.api.nvim_buf_delete(buffer, { force = true })
print("Typst enum tests passed")
