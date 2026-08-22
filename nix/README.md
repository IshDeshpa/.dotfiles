# NixOS bootstrap

This directory is a first-pass NixOS translation of the Arch installation in
the parent directory. The `arch-fw` configuration reuses the checked-out
desktop, shell, editor, wallpaper, and user-service files through Home Manager.

## Build and test

On a machine with Nix enabled:

```sh
cd nix
nix flake check
nix build .#nixosConfigurations.arch-fw.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#arch-fw
```

The repository also contains the user-level `nix.conf`. To manage it like the
other dotfiles, link the entire directory:

```sh
mkdir -p ~/.config
ln -sfn ~/.dotfiles/nix ~/.config/nix
```

For a disposable QEMU guest, use the dedicated `vm` configuration. It does not
use the physical machine's disk declarations and is safe to rebuild or delete:

```sh
nix build .#nixosConfigurations.arch-fw.config.system.build.vm
nix build .#nixosConfigurations.vm.config.system.build.vm
./result/bin/run-nix-vm
```

The generated runner uses a 4-core, 4 GiB VM with a 16 GiB virtual disk. It
uses a graphical QEMU display so the Ly/Niri session can be exercised. KVM is
used automatically when available; if it is unavailable, edit the generated
runner invocation to use TCG acceleration.

To test only evaluation and activation without opening a graphical window:

```sh
nix build .#nixosConfigurations.vm.config.system.build.toplevel
```

## Known non-equivalences

The package lists contain Arch and AUR names. Most base packages are mapped in
`configuration.nix`; AUR-only/proprietary entries such as `niri-git`,
`ly-git`, `saleae-logic2`, `visual-studio-code-bin`, `slack-electron`,
`zoom`, and `yay` require explicit nixpkgs overlays, flakes, or manual binary
installation. The physical machine's exact disk UUIDs and GPU/input details
must also be generated with `nixos-generate-config` before replacing Arch.

Existing configs contain a few absolute paths and references to scripts not
present in this repository (for example `volume.sh` and Niri's workspace
helper); those are preserved rather than silently rewritten.
