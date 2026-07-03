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
grep -q '^apply --no-tty --exclude scripts$' "$CHEZMOI_LOG"
