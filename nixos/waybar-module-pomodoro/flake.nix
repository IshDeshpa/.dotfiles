{
  description = "Waybar pomodoro flake"
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    waybar-module-pomodoro = {
      type = "github";
      owner = "Andeskjerf";
      repo = "waybar-module-pomodoro";
      ref = "main";
      flake = false;
    };
  };

  outputs = {self, nixpkgs, flake-utils, waybar-module-pomodoro}:
}
