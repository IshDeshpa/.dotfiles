{ config, pkgs, lib, ... }:

{
  home.username = "ishdeshpa";
  home.homeDirectory = "/home/ishdeshpa";
  
  home.packages = with pkgs; [
    bash
    zoxide
  ];

  programs.neovim = {
  	enable = true;
	  plugins = with pkgs.vimPlugins; [
	    catppuccin-nvim
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      copilot-lua
      copilot-cmp
      cmp-nvim-lsp    # Provides LSP-based completion source for nvim-cmp (e.g., clangd completions)
      nvim-cmp        # The main autocompletion engine/UI
      nvim-lspconfig  # Config helpers for LSP servers like clangd, lua_ls, etc.vim-lspconfig
      luasnip         # Snippet engine (used by cmp to expand snippets when selected)
      cmp_luasnip     # Completion source to feed LuaSnip snippets into nvim-cmp
  	];
	  vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  	extraConfig = lib.fileContents ../nvim/initvim;
  };

  programs.bash.enable = true;
  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    cd = "z";
    cdi = "zi";
  };

  programs.zoxide.enable = true;
  programs.zoxide.enableBashIntegration= true;

  home.stateVersion = "24.11"; # match your system
}


