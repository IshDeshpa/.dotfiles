local copilot = require('copilot')
local ccmp = require("copilot_cmp")

copilot.setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})
ccmp.setup()
