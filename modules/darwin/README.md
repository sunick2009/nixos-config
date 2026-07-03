
## Layout
```
.
├── dock               # MacOS dock configuration
├── audio-loopback.nix # Audio output device automatic switching service
├── casks.nix          # List of homebrew casks
├── files.nix          # Non-Nix, static configuration files (now immutable!)
├── home-manager.nix   # Defines user programs and dock configuration
├── packages.nix       # List of packages to install for MacOS
├── secrets.nix        # Age encrypted secrets configuration
└── README.md          # This documentation
```

## Modules Description

### audio-loopback.nix
Audio output device management module that automatically switches audio output to "Loopback Audio" device. Uses a launchd user agent to monitor and switch audio output devices with polling.

### casks.nix
Homebrew cask packages configuration for GUI applications installation on macOS.

### Homebrew taps (declarative)
When `nix-homebrew.mutableTaps = false`, `brew bundle` cannot auto-tap new
repositories. If a cask comes from a non-core tap (for example
`steipete/tap/codexbar`), `brew` will fail with a permission error under
`/opt/homebrew/Library/Taps`. Fix this by declaring the tap in the flake and
`nix-homebrew.taps`, then refresh the lock and switch:

1. Add a flake input for the tap (e.g. `github:steipete/homebrew-tap`,
	`flake = false`).
2. Add the tap to `nix-homebrew.taps` (e.g. `"steipete/homebrew-tap"`).
3. Update the lock and switch:
	- `nix flake update --update-input <tap-input>`
	- `nix run .#build-switch`

### files.nix
Static configuration files management for macOS-specific settings.

### home-manager.nix
User-level configuration including:
- Homebrew setup and Mac App Store apps
- Home manager user configuration
- GPG agent configuration
- Dock entries management
- Application symlinks and dotfiles

#### Dotfiles bootstrap
Use `nix run .#bootstrap` to clone the dotfiles repository into
`~/Code/my-dotfiles` when it is not present yet. If the repository URL is
not known locally, the command prompts for it and then performs a normal
`git clone`.

After that, run your normal `nix run .#build-switch`. On first activation,
if `~/Code/my-dotfiles` exists and `~/.config/chezmoi/chezmoi.toml` does
not, the activation hook seeds the chezmoi config automatically and then
runs `chezmoi apply`.

This means a manual `chezmoi init` is not required for the standard
migration path.

### packages.nix
System-level packages installation for macOS, extending shared packages with macOS-specific tools.

### secrets.nix
Age-encrypted secrets configuration for secure credential management.
