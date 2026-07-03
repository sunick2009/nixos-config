## Layout
```
.
├── config             # Config files not written in Nix
├── default.nix        # Defines module, system-level config,
├── disk-config.nix    # Disks, partitions, and filesystems
├── files.nix          # Non-Nix, static configuration files (now immutable!)
├── home-manager.nix   # Defines user programs
├── packages.nix       # List of packages to install for NixOS
├── secrets.nix        # Age-encrypted secrets with agenix
```

## Dotfiles bootstrap

The NixOS `build-switch` flow mirrors the macOS flow:

1. `nix run .#build-switch` runs `bootstrap`
2. `bootstrap` clones `~/Code/my-dotfiles` from the public dotfiles repo if it is missing
3. Home Manager activation seeds `~/.config/chezmoi/chezmoi.toml` if needed
4. `chezmoi apply` runs automatically during activation

This removes the need for a manual `chezmoi init` in the normal migration path.
