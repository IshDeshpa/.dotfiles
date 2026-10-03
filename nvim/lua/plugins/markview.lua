-- Inline numbering for Markview's Typst '+' markers. This interprets literal
-- set rules, not arbitrary Typst code; use TypstPreview for evaluated output.
-- Supports 1/a/A/i/I patterns, full, and start in markup lists. Explicit 'n.'
-- markers contribute to counters but remain unchanged by Markview. Imports,
-- show rules, and generated content are not evaluated. Unsupported local
-- numbering expressions and reversed lists retain their source '+' marker.
local cache = {}

local function count(symbol, n)
  if symbol == "1" then
    return tostring(n)
  end
  if n < 1 then
    return nil
  end
  if symbol == "a" or symbol == "A" then
    local result = ""
    while n > 0 do
      n = n - 1
      result = string.char(65 + n % 26) .. result
      n = math.floor(n / 26)
    end
    return symbol == "a" and result:lower() or result
  end
  if n > 3999 then
    return nil
  end
  local result = ""
  for _, pair in ipairs({
    { 1000, "M" },
    { 900, "CM" },
    { 500, "D" },
    { 400, "CD" },
    { 100, "C" },
    { 90, "XC" },
    { 50, "L" },
    { 40, "XL" },
    { 10, "X" },
    { 9, "IX" },
    { 5, "V" },
    { 4, "IV" },
    { 1, "I" },
  }) do
    while n >= pair[1] do
      result, n = result .. pair[2], n - pair[1]
    end
  end
  return symbol == "i" and result:lower() or result
end

local function format(pattern, numbers, full)
  -- Restrict to supported symbols and ASCII punctuation. Unknown counting
  -- alphabets must not silently turn into literal prefixes.
  if not pattern or pattern:find("[^1aAiI%p%s]") then
    return nil
  end
  local parts, previous = {}, 1
  for position, symbol in pattern:gmatch("()([1aAiI])") do
    parts[#parts + 1] = { prefix = pattern:sub(previous, position - 1), symbol = symbol }
    previous = position + 1
  end
  if #parts == 0 or pattern:find("*", 1, true) then
    return nil
  end
  local result = ""
  for depth = full and 1 or #numbers, #numbers do
    local part = parts[math.min(depth, #parts)]
    local value = count(part.symbol, numbers[depth])
    if not value then
      return nil
    end
    -- With full:false Typst uses the first prefix and the depth's symbol.
    local prefix = not full and parts[1].prefix or part.prefix
    if full and depth > #parts and prefix == "" then
      prefix = pattern:sub(previous)
    end
    result = result .. prefix .. value
  end
  return result .. pattern:sub(previous)
end

local function labels(buffer)
  local parser = vim.treesitter.get_parser(buffer, "typst")
  local root = parser:parse()[1]:root()
  local result = {}
  local function text(node)
    return vim.treesitter.get_node_text(node, buffer)
  end

  local function set_rule(node, state)
    if node:type() ~= "code" then
      return
    end
    local rule = node:named_child(0)
    if not rule or rule:type() ~= "set" then
      return
    end
    local call = rule:named_child(0)
    if not call or call:type() ~= "call" or text(call:named_child(0)) ~= "enum" then
      return
    end
    -- Conditional set rules require evaluation.
    if rule:named_child_count() ~= 1 then
      state.unknown = true
      return
    end
    local group = call:named_child(1)
    if not group then
      return
    end
    for arg in group:iter_children() do
      if arg:named() then
        if arg:type() ~= "tagged" then
          state.unknown = true
        else
          local key, value = text(arg:named_child(0)), text(arg:named_child(1))
          if key == "numbering" then
            -- Escaped strings and expressions require Typst evaluation.
            state.pattern = value:match('^"([^"\\]*)"$') or false
          elseif key == "full" then
            state.full = value == "true"
            state.bad_full = value ~= "true" and value ~= "false"
          elseif key == "start" then
            state.start = value == "auto" and 1 or tonumber(value)
            state.bad_start = not state.start or state.start < 0 or state.start % 1 ~= 0
          elseif key == "reversed" then
            state.reversed = value ~= "false"
          end
        end
      end
    end
  end

  local walk
  walk = function(node, inherited, ancestors, shared)
    local state = shared and inherited or vim.tbl_extend("force", {}, inherited)
    local next_number
    for child in node:iter_children() do
      if child:named() then
        local kind = child:type()
        if kind == "item" then
          local source = text(child)
          local explicit = source:match("^(%d+)%.")
          local ordered = source:sub(1, 1) == "+" or explicit ~= nil
          if ordered then
            local n = tonumber(explicit) or next_number or state.start or 1
            next_number = n + 1
            local numbers = vim.list_extend(vim.deepcopy(ancestors), { n })
            local row, col = child:range()
            if not (state.unknown or state.bad_full or state.bad_start or state.reversed) then
              result[row .. ":" .. col] = format(state.pattern, numbers, state.full)
            end
            walk(child, state, numbers)
          else
            next_number = nil
            walk(child, state, ancestors)
          end
        elseif kind ~= "parbreak" and kind ~= "comment" then
          next_number = nil
          set_rule(child, state)
          -- Only traverse markup containers. Do not interpret examples in raw
          -- blocks, strings, or unevaluated function bodies as document lists.
          if kind == "section" or kind == "content" then
            walk(child, state, ancestors, kind == "section" or node:type() == "section")
          elseif kind == "code" then
            local content = child:named_child(0)
            if content and content:type() == "content" then
              walk(content, state, ancestors)
            end
          end
        end
      end
    end
  end
  walk(root, { pattern = "1.", full = false, start = 1 }, {})
  return result
end

local function enum_text(buffer, item)
  local tick = vim.api.nvim_buf_get_changedtick(buffer)
  if not cache[buffer] or cache[buffer].tick ~= tick then
    local ok, values = pcall(labels, buffer)
    cache[buffer] = { tick = tick, values = ok and values or {} }
  end
  local range = item.range
  local label = cache[buffer].values[range.row_start .. ":" .. range.col_start] or "+"
  -- Markview passes this result through string.format(label, item.number).
  return (label:gsub("%%", "%%%%"))
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("TypstEnumCache", { clear = true }),
  callback = function(event)
    cache[event.buf] = nil
  end,
})

return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  opts = {
    preview = {
      condition = function(buffer)
        -- Guest files have no local backing file, but can still be rendered.
        if vim.api.nvim_buf_get_name(buffer):match("^liveshare://") and vim.bo[buffer].filetype == "markdown" then
          return true
        end
        -- Use Markview's default filters for all other buffers.
        return nil
      end,
    },
    typst = {
      list_items = {
        marker_plus = {
          text = enum_text,
        },
      },
      math_blocks = { enable = false },
      math_spans = { enable = false },
      symbols = { enable = false },
    },
    latex = {
      enable = false,
      blocks = { enable = false },
      inlines = { enable = false },
    },
  },

  -- For blink.cmp's completion
  -- source
  -- dependencies = {
  --     "saghen/blink.cmp"
  -- },
}
