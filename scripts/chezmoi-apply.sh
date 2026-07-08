#!/usr/bin/env bash
set -euo pipefail

CHEZMOI_BIN="${CHEZMOI_BIN:-chezmoi}"
CHEZMOI_PATH_PREFIX="${CHEZMOI_PATH_PREFIX:-}"

if [ -n "$CHEZMOI_PATH_PREFIX" ]; then
  export PATH="$CHEZMOI_PATH_PREFIX:$PATH"
fi

if ! command -v "$CHEZMOI_BIN" >/dev/null 2>&1; then
  echo "chezmoi is not installed or not executable: $CHEZMOI_BIN" >&2
  exit 1
fi

CHEZMOI_CFG="${CHEZMOI_CFG:-$HOME/.config/chezmoi/chezmoi.toml}"
CHEZMOI_SRC="${CHEZMOI_SRC:-$HOME/Code/my-dotfiles}"
CHEZMOI_RUN_SCRIPTS="${CHEZMOI_RUN_SCRIPTS:-true}"

ensure_source_dir() {
  if [ ! -f "$CHEZMOI_CFG" ]; then
    return 0
  fi

  if grep -Eq '^[[:space:]]*sourceDir[[:space:]]*=' "$CHEZMOI_CFG"; then
    return 0
  fi

  local tmp_cfg
  tmp_cfg="$(mktemp)"
  {
    printf 'sourceDir = "%s"\n\n' "$CHEZMOI_SRC"
    cat "$CHEZMOI_CFG"
  } > "$tmp_cfg"
  mv "$tmp_cfg" "$CHEZMOI_CFG"
}

if [ ! -d "$CHEZMOI_SRC" ] && [ ! -f "$CHEZMOI_CFG" ]; then
  echo "chezmoi source directory not found: $CHEZMOI_SRC" >&2
  echo "Run the bootstrap step before switching, or set CHEZMOI_SRC." >&2
  exit 1
fi

if [ -d "$CHEZMOI_SRC" ]; then
  mkdir -p "$(dirname "$CHEZMOI_CFG")"
  if [ ! -f "$CHEZMOI_CFG" ]; then
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
  else
    ensure_source_dir
  fi
fi

if [ -f "$CHEZMOI_CFG" ]; then
  DRY_RUN_CMD="${DRY_RUN_CMD:-}"
  apply_args=(apply --no-tty)

  case "$CHEZMOI_RUN_SCRIPTS" in
    false|False|FALSE|0|no|No|NO)
      apply_args+=(--exclude scripts)
      ;;
  esac

  if [ -n "$DRY_RUN_CMD" ]; then
    # shellcheck disable=SC2086
    $DRY_RUN_CMD "$CHEZMOI_BIN" "${apply_args[@]}"
  else
    echo "Running $CHEZMOI_BIN ${apply_args[*]} with sourceDir=$CHEZMOI_SRC" >&2
    "$CHEZMOI_BIN" "${apply_args[@]}"
  fi
fi
