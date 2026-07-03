#!/usr/bin/env bash
set -euo pipefail

if ! command -v chezmoi >/dev/null 2>&1; then
  exit 0
fi

CHEZMOI_CFG="${CHEZMOI_CFG:-$HOME/.config/chezmoi/chezmoi.toml}"
CHEZMOI_SRC="${CHEZMOI_SRC:-$HOME/Code/my-dotfiles}"

if [ ! -f "$CHEZMOI_CFG" ] && [ -d "$CHEZMOI_SRC" ]; then
  mkdir -p "$(dirname "$CHEZMOI_CFG")"
  cat > "$CHEZMOI_CFG" <<EOF
sourceDir = "$CHEZMOI_SRC"

[data]
    name = "sunick2009"
    email = "sunick2009@gmail.com"
    installOhMyZsh = true
    installFonts = true
    changeShell = true
    installNeovimPlugins = true
    installTmuxPlugins = true
EOF
fi

if [ -f "$CHEZMOI_CFG" ]; then
  DRY_RUN_CMD="${DRY_RUN_CMD:-}"
  if [ -n "$DRY_RUN_CMD" ]; then
    # shellcheck disable=SC2086
    $DRY_RUN_CMD chezmoi apply --no-tty --exclude scripts 2>/dev/null || true
  else
    chezmoi apply --no-tty --exclude scripts 2>/dev/null || true
  fi
fi
