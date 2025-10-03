{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  dockutil
  aria2
  pinentry_mac
  iina
  # Disk usage analyzer
  grandperspective
  # TUI File manager
  yazi

    # yazi related tools
    fd
    ripgrep
    fzf
    bat
    jq
    p7zip
    exiftool
    mediainfo
    poppler          # pdftotext/pdftoppm 等，PDF 預覽
    imagemagick
    ffmpegthumbnailer
    zoxide           # 跟 yazi 很搭的目錄跳轉
]
