{ config, pkgs, lib, home-manager, ... }:

let
  user = "susu";
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
  chezmoiApply = pkgs.writeShellScriptBin "chezmoi-apply" (builtins.readFile ../../scripts/chezmoi-apply.sh);
  chezmoiPath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
    pkgs.findutils
    pkgs.gawk
    pkgs.git
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
    pkgs.neovim
    pkgs.tmux
    pkgs.zsh
  ];
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    brews = [
      "gromgit/fuse/ntfs-3g-mac"
      # for mole cleanup tool
      "mole"
    ];
    onActivation = {
    # the following two options ensure that brew casks are updated when the system is also updated
    #autoUpdate = true;
    #upgrade = false;
    # cleanup = "uninstall";
  };
    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

    masApps = {
      # "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:{
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
        ];

        stateVersion = "23.11";
      };
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry_mac;
        enableSshSupport = true;
        defaultCacheTtl = 28800; # 8 hours
        maxCacheTtl = 86400;     # 24 hours
        extraConfig = ''
          allow-loopback-pinentry
        '';
      };

      home.activation.chezmoiApply = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CHEZMOI_BIN="${pkgs.chezmoi}/bin/chezmoi" \
        CHEZMOI_PATH_PREFIX="${chezmoiPath}" \
        CHEZMOI_SRC="${config.home.homeDirectory}/Code/my-dotfiles" \
          ${chezmoiApply}/bin/chezmoi-apply
      '';

      home.activation.atuinSyncEnvLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ln -sf /run/agenix/atuin-sync-env "${config.home.homeDirectory}/.atuin-sync.env"
      '';

      home.activation.atuinKeyLink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.home.homeDirectory}/.local/share/atuin"
        ln -sf /run/agenix/atuin-key "${config.home.homeDirectory}/.local/share/atuin/key"
      '';

      home.activation.neovideFileAssociations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "/Applications/Neovide.app" ]; then
          NEOVIDE_BUNDLE_ID=$(/usr/bin/defaults read /Applications/Neovide.app/Contents/Info.plist CFBundleIdentifier 2>/dev/null || true)
          if [ -n "$NEOVIDE_BUNDLE_ID" ]; then
            for UTI in \
              public.plain-text \
              public.source-code \
              public.script \
              public.shell-script \
              net.daringfireball.markdown \
              public.json \
              public.yaml; do
              ${pkgs.duti}/bin/duti -s "$NEOVIDE_BUNDLE_ID" "$UTI" all >/dev/null 2>&1 || true
            done
          fi
        fi
      '';

      # Marked broken Oct 20, 2022 check later to remove this
      ## https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/System/Applications/Launchpad.app/"; }
        { path = "/Applications/ForkLift.app/"; }
        { path = "/Applications/Obsidian.app/"; }
        { path = "/Applications/ChatGPT.app/"; }
        { path = "/Applications/Microsoft Outlook.app/"; }
        { path = "/Applications/Arc.app/"; }
        { path = "/Applications/LINE.app/"; }
        { path = "/Applications/Discord.app/"; }
        { path = "/Applications/Visual Studio Code.app"; }
        { path = "/Applications/Tabby.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
        { path = "/Applications/Loopback.app/"; }

        {
          path = "${config.users.users.${user}.home}/Downloads";
          section = "others";
          options = "--sort name --view grid --display stack";
        }
      ];
    };
  };
}
