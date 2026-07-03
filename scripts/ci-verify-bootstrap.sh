#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_repo="$tmp_dir/dotfiles-src"
home_dir="$tmp_dir/home"
dotfiles_dir="$home_dir/Code/my-dotfiles"
branch="feat/chezmoi-non-nix-migration"

mkdir -p "$fixture_repo"
git init "$fixture_repo" >/dev/null
git -C "$fixture_repo" config user.name "CI"
git -C "$fixture_repo" config user.email "ci@example.com"
echo "fixture" > "$fixture_repo/README.md"
git -C "$fixture_repo" add README.md
git -C "$fixture_repo" commit -m "fixture" >/dev/null
git -C "$fixture_repo" branch -M "$branch"

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

test -d "$dotfiles_dir/.git"
test "$(git -C "$dotfiles_dir" rev-parse --abbrev-ref HEAD)" = "$branch"
test -f "$dotfiles_dir/README.md"
