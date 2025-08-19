{ config, pkgs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      # 建議：除非你確定需要，請不要長期開 allowBroken
      # allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays =
      # 只保留你自己 overlays 目錄的自家 overlays；不要再手動抓 emacs-overlay
      let
        path = ../../overlays;
      in
      with builtins;
      map (n: import (path + ("/" + n)))
        (filter (n:
          match ".*\\.nix" n != null
          || pathExists (path + ("/" + n + "/default.nix")))
          (attrNames (readDir path)));
  };
}
