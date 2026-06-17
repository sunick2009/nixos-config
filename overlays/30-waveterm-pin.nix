final: prev:
let
  version = "0.14.5";
  selectSystem = attrs: attrs.${prev.stdenv.hostPlatform.system};
in
{
  # Temporary pin until nixpkgs updates waveterm past 0.13.1.
  waveterm = prev.waveterm.overrideAttrs (_old: {
    inherit version;

    src =
      let
        isDarwin = prev.stdenv.hostPlatform.isDarwin;
        arch = selectSystem {
          x86_64-linux = "amd64";
          aarch64-linux = "arm64";
          x86_64-darwin = "x64";
          aarch64-darwin = "arm64";
        };
        file =
          if isDarwin then
            "Wave-darwin-${arch}-${version}.zip"
          else
            "waveterm-linux-${arch}-${version}.deb";
      in
      final.fetchurl {
        url = "https://github.com/wavetermdev/waveterm/releases/download/v${version}/${file}";
        hash = selectSystem {
          x86_64-linux = "sha256-aRrOVi5mog2XJ7i+6vmP5kpEXfZVI7sf0R7TD1b9E3s=";
          aarch64-linux = "sha256-139jgwHkiQ3X/WTObXUyJwciiXg64PhAY/LRUeGGqlU=";
          x86_64-darwin = "sha256-nFA3sAEJ2aJrsx1xxhGbMw/UovKI2mFIVJHf11HzZMA=";
          aarch64-darwin = "sha256-84KU8LKKuEypdQhJCfxbII+w1qVhYBYmsQh9JGuxzA8=";
        };
      };
  });
}
