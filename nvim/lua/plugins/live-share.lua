-- lazy.nvim
return {
  "azratul/live-share.nvim",
  config = function()
    require("live-share").setup({
      username = "ishdeshpa",
    })
  end,
};
