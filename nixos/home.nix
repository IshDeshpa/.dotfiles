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
  	];
	  vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = false;
  	extraConfig = lib.fileContents ../nvim/initvim;
  };

  home.stateVersion = "24.11"; # match your system
}


