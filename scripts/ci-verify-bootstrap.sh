#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_repo="$tmp_dir/dotfiles-src"
home_dir="$tmp_dir/home"
dotfiles_dir="$home_dir/Code/my-dotfiles"
bin_dir="$tmp_dir/bin"
branch="feat/chezmoi-non-nix-migration"

mkdir -p "$fixture_repo"
mkdir -p "$bin_dir"
git init "$fixture_repo" >/dev/null
git -C "$fixture_repo" config user.name "CI"
git -C "$fixture_repo" config user.email "ci@example.com"
echo "fixture" > "$fixture_repo/README.md"
git -C "$fixture_repo" add README.md
git -C "$fixture_repo" commit -m "fixture" >/dev/null
git -C "$fixture_repo" branch -M "$branch"

cat > "$bin_dir/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${CHEZMOI_LOG:-/tmp/chezmoi.log}"
if [ "${1:-}" = "apply" ]; then
  touch "${CHEZMOI_APPLY_MARK:-/tmp/chezmoi-apply.marker}"
fi
EOF
chmod +x "$bin_dir/chezmoi"

for script in \
  "$repo_root/apps/x86_64-darwin/build-switch" \
  "$repo_root/apps/aarch64-darwin/build-switch" \
  "$repo_root/apps/x86_64-linux/build-switch"
do
  grep -q 'run .#bootstrap' "$script"
done

for script in \
  "$repo_root/apps/x86_64-darwin/bootstrap" \
  "$repo_root/apps/aarch64-darwin/bootstrap" \
  "$repo_root/apps/x86_64-linux/bootstrap"
do
  HOME="$home_dir" \
  DOTFILES_DIR="$dotfiles_dir" \
  DOTFILES_REPO_URL="$fixture_repo" \
  DOTFILES_REPO_BRANCH="$branch" \
  bash "$script" >/dev/null
done

grep -Fq 'home.activation.chezmoiApply' "$repo_root/modules/darwin/home-manager.nix"
grep -Fq 'home.activation.chezmoiApply' "$repo_root/modules/nixos/home-manager.nix"
grep -Fq '${chezmoiApply}/bin/chezmoi-apply' "$repo_root/modules/darwin/home-manager.nix"
grep -Fq '${chezmoiApply}/bin/chezmoi-apply' "$repo_root/modules/nixos/home-manager.nix"

test -d "$dotfiles_dir/.git"
test "$(git -C "$dotfiles_dir" rev-parse --abbrev-ref HEAD)" = "$branch"
test -f "$dotfiles_dir/README.md"

CHEZMOI_LOG="$tmp_dir/chezmoi.log"
CHEZMOI_APPLY_MARK="$tmp_dir/chezmoi-apply.marker"
PATH="$bin_dir:$PATH" \
HOME="$home_dir" \
CHEZMOI_SRC="$dotfiles_dir" \
CHEZMOI_LOG="$CHEZMOI_LOG" \
CHEZMOI_APPLY_MARK="$CHEZMOI_APPLY_MARK" \
  bash "$repo_root/scripts/chezmoi-apply.sh"

test -f "$home_dir/.config/chezmoi/chezmoi.toml"
grep -q "sourceDir = \"$dotfiles_dir\"" "$home_dir/.config/chezmoi/chezmoi.toml"
test -f "$CHEZMOI_APPLY_MARK"
grep -q '^apply --no-tty$' "$CHEZMOI_LOG"

existing_home_dir="$tmp_dir/existing-home"
existing_dotfiles_dir="$existing_home_dir/Code/my-dotfiles"
existing_cfg="$existing_home_dir/.config/chezmoi/chezmoi.toml"
existing_log="$tmp_dir/existing-chezmoi.log"
existing_apply_mark="$tmp_dir/existing-chezmoi-apply.marker"

mkdir -p "$(dirname "$existing_cfg")" "$existing_dotfiles_dir"
cat > "$existing_cfg" <<'EOF'
[data]
    name = "sunick2009"
    email = "sunick2009@gmail.com"
EOF

PATH="$bin_dir:$PATH" \
HOME="$existing_home_dir" \
CHEZMOI_SRC="$existing_dotfiles_dir" \
CHEZMOI_LOG="$existing_log" \
CHEZMOI_APPLY_MARK="$existing_apply_mark" \
  bash "$repo_root/scripts/chezmoi-apply.sh"

grep -q "sourceDir = \"$existing_dotfiles_dir\"" "$existing_cfg"
grep -q '^\[data\]$' "$existing_cfg"
test -f "$existing_apply_mark"

skip_scripts_home_dir="$tmp_dir/skip-scripts-home"
skip_scripts_dotfiles_dir="$skip_scripts_home_dir/Code/my-dotfiles"
skip_scripts_log="$tmp_dir/skip-scripts-chezmoi.log"
skip_scripts_apply_mark="$tmp_dir/skip-scripts-chezmoi-apply.marker"

mkdir -p "$skip_scripts_dotfiles_dir"

PATH="$bin_dir:$PATH" \
HOME="$skip_scripts_home_dir" \
CHEZMOI_SRC="$skip_scripts_dotfiles_dir" \
CHEZMOI_RUN_SCRIPTS=false \
CHEZMOI_LOG="$skip_scripts_log" \
CHEZMOI_APPLY_MARK="$skip_scripts_apply_mark" \
  bash "$repo_root/scripts/chezmoi-apply.sh"

grep -q '^apply --no-tty --exclude scripts$' "$skip_scripts_log"
test -f "$skip_scripts_apply_mark"

explicit_bin_home_dir="$tmp_dir/explicit-bin-home"
explicit_bin_dotfiles_dir="$explicit_bin_home_dir/Code/my-dotfiles"
explicit_bin_log="$tmp_dir/explicit-bin-chezmoi.log"
explicit_bin_apply_mark="$tmp_dir/explicit-bin-chezmoi-apply.marker"

mkdir -p "$explicit_bin_dotfiles_dir"

PATH="/usr/bin:/bin" \
HOME="$explicit_bin_home_dir" \
CHEZMOI_BIN="$bin_dir/chezmoi" \
CHEZMOI_SRC="$explicit_bin_dotfiles_dir" \
CHEZMOI_LOG="$explicit_bin_log" \
CHEZMOI_APPLY_MARK="$explicit_bin_apply_mark" \
  bash "$repo_root/scripts/chezmoi-apply.sh"

grep -q '^apply --no-tty$' "$explicit_bin_log"
test -f "$explicit_bin_apply_mark"

path_prefix_home_dir="$tmp_dir/path-prefix-home"
path_prefix_dotfiles_dir="$path_prefix_home_dir/Code/my-dotfiles"
path_prefix_bin_dir="$tmp_dir/path-prefix-bin"
path_prefix_log="$tmp_dir/path-prefix-chezmoi.log"
path_prefix_apply_mark="$tmp_dir/path-prefix-chezmoi-apply.marker"

mkdir -p "$path_prefix_dotfiles_dir" "$path_prefix_bin_dir"
cp "$bin_dir/chezmoi" "$path_prefix_bin_dir/chezmoi"

PATH="/usr/bin:/bin" \
HOME="$path_prefix_home_dir" \
CHEZMOI_PATH_PREFIX="$path_prefix_bin_dir" \
CHEZMOI_SRC="$path_prefix_dotfiles_dir" \
CHEZMOI_LOG="$path_prefix_log" \
CHEZMOI_APPLY_MARK="$path_prefix_apply_mark" \
  bash "$repo_root/scripts/chezmoi-apply.sh"

grep -q '^apply --no-tty$' "$path_prefix_log"
test -f "$path_prefix_apply_mark"

missing_home_dir="$tmp_dir/missing-home"
missing_log="$tmp_dir/missing-chezmoi.log"

mkdir -p "$missing_home_dir"

if PATH="$bin_dir:$PATH" \
  HOME="$missing_home_dir" \
  CHEZMOI_SRC="$missing_home_dir/Code/my-dotfiles" \
  CHEZMOI_LOG="$missing_log" \
    bash "$repo_root/scripts/chezmoi-apply.sh"; then
  echo "expected chezmoi-apply.sh to fail when sourceDir is missing" >&2
  exit 1
fi
