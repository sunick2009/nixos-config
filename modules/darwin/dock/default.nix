{
  config,
  pkgs,
  lib,
  ...
}:

# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd

with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in
{
  options = {
    local.dock = {
      enable = mkOption {
        description = "Enable dock";
        default = stdenv.isDarwin;
        example = false;
      };

      entries = mkOption {
        description = "Entries on the Dock";
        type =
          with types;
          listOf (submodule {
            options = {
              path = lib.mkOption { type = str; };
              section = lib.mkOption {
                type = str;
                default = "apps";
              };
              options = lib.mkOption {
                type = str;
                default = "";
              };
            };
          });
        readOnly = true;
      };

      username = mkOption {
        description = "Username to apply the dock settings to";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable (
    let
      createEntries = concatMapStrings (
        entry:
        ''${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}
        ''
      ) cfg.entries;
    in
    {
      system.activationScripts.postActivation.text = ''
          echo >&2 "Setting up the Dock for ${cfg.username}..."
          su ${cfg.username} -s /bin/sh <<'USERBLOCK'
        ${dockutil}/bin/dockutil --remove all --no-restart
        ${createEntries}
        killall Dock || true
        USERBLOCK
      '';
    }
  );
}
