{
  description = "Starter Configuration with secrets for MacOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-fuse = {
      url = "github:gromgit/homebrew-fuse";
      flake = false;
    };
    homebrew-angristan = {
      url = "github:angristan/homebrew-tap";
      flake = false;
    };
    steipete-tap = {
      url = "github:steipete/homebrew-tap";
      flake = false;
    };
    homebrew-orca = {
      url = "github:stablyai/homebrew-orca";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/sunick2009/susu-secret-nix.git";
      flake = false;
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, homebrew-fuse, homebrew-angristan, steipete-tap, homebrew-orca, home-manager, nixpkgs, disko, agenix, secrets } @inputs:
    let
      user = "susu";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "bootstrap" = mkApp "bootstrap" system;
        "install" = mkApp "bootstrap" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "bootstrap" = mkApp "bootstrap" system;
        "rollback" = mkApp "rollback" system;
      };
      mkNixosConfiguration = system: extraModules: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.${user} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ] ++ extraModules;
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            ({ config, ... }: {
              nix-homebrew = {
                inherit user;
                enable = true;
                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = true;
                # Homebrew cannot derive its version from nix-homebrew's synthetic Git repository.
                extraEnv.HOMEBREW_VERSION = config.nix-homebrew.package.version;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "gromgit/homebrew-fuse" = homebrew-fuse;
                  "angristan/homebrew-tap" = homebrew-angristan;
                  "steipete/homebrew-tap" = steipete-tap;
                  "stablyai/homebrew-orca" = homebrew-orca;
                };
                trust.casks = [ "stablyai/orca/orca" ];
                mutableTaps = false;
                autoMigrate = true;
              };
            })
            ./hosts/darwin
          ];
        }
      );

      nixosConfigurations =
        nixpkgs.lib.genAttrs linuxSystems (system: mkNixosConfiguration system [])
        // {
          ci-x86_64-linux = mkNixosConfiguration "x86_64-linux" [
            ({ lib, ... }: {
              networking = {
                hostName = lib.mkForce "ci";
                useDHCP = lib.mkForce true;
                interfaces = lib.mkForce {};
              };

              disko.devices.disk.vdb.device = lib.mkForce "/dev/vda";
            })
          ];
        };
  };
}
