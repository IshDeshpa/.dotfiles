{ config, pkgs, lib, ... }:

{
  home.username = "ishdeshpa";
  home.homeDirectory = "/home/ishdeshpa";

  programs.neovim = {
  	enable = true;
	  plugins = with pkgs.vimPlugins; [
	    catppuccin-nvim
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      copilot-lua
      copilot-lualine
  	];
	  vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  	extraConfig = lib.fileContents ../nvim/initvim;
  };

  programs.bash.shellAliases = {
    l = "ls -alh";
    ll = "ls -l";
    ls = "ls --color=tty";
    cd = "z";
    cdi = "zi";
  };


  home.stateVersion = "24.11"; # match your system
}


