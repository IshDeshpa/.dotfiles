# NixOS bootstrap

This directory is a self-contained NixOS translation of the desktop setup.
The `dotfiles/` subdirectory contains the configs, scripts, editor files,
plugins, and assets consumed by Home Manager. The parent Arch dotfiles are kept
separately as the current system source of truth.

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
./result/bin/run-nix-vm-vm
```

The generated runner uses a 4-core, 4 GiB VM with a 16 GiB virtual disk. It
uses a graphical QEMU display so the Ly/Niri session can be exercised. KVM is
used automatically when available; if it is unavailable, edit the generated
 runner invocation to use TCG acceleration.

The disposable VM credential is `ishdeshpa` / `nixos`. Fingerprint auth is
disabled in the VM so Ly exercises ordinary Unix password authentication.

On Arch, use the host-QEMU wrapper for graphics. The generated Nix QEMU binary
expects NixOS's `/run/opengl-driver` layout, while Arch provides Mesa under
`/usr`. For a VNC-backed accelerated display:

```sh
./run-vm-host-qemu.sh \
  -display egl-headless,rendernode=/dev/dri/renderD128 \
  -vnc :1
vncviewer 127.0.0.1:1
```

For a normal host window, try `./run-vm-host-qemu.sh -display sdl,gl=on`.

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
