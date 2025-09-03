
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

### files.nix
Static configuration files management for macOS-specific settings.

### home-manager.nix
User-level configuration including:
- Homebrew setup and Mac App Store apps
- Home manager user configuration
- GPG agent configuration
- Dock entries management
- Application symlinks and dotfiles

### packages.nix
System-level packages installation for macOS, extending shared packages with macOS-specific tools.

### secrets.nix
Age-encrypted secrets configuration for secure credential management.
