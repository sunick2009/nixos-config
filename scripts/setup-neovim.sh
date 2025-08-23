#!/bin/bash

# Setup script for neovim with dotfiles integration
# This script helps setup neovim plugins and troubleshoot common issues

set -e

echo "🔧 Setting up Neovim with dotfiles integration..."

# Check if neovim is installed
if ! command -v nvim &> /dev/null; then
    echo "❌ Error: neovim is not installed. Please build and apply nixos-config first."
    exit 1
fi

# Check if git and curl are available (needed for vim-plug)
for cmd in git curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ Error: $cmd is not installed. Please ensure it's in your nixos-config packages."
        exit 1
    fi
done

echo "✅ Dependencies check passed"

# Check if dotfiles are linked correctly
DOTFILES_PATH="$HOME/Code/my-dotfiles"
if [[ ! -d "$DOTFILES_PATH/.config/nvim" ]]; then
    echo "❌ Error: Dotfiles not found at $DOTFILES_PATH"
    echo "Please ensure your dotfiles are cloned to $DOTFILES_PATH"
    exit 1
fi

if [[ ! -L "$HOME/.config/nvim" ]]; then
    echo "❌ Error: ~/.config/nvim is not a symlink to dotfiles"
    echo "Please rebuild your nixos-config to create the symlink"
    exit 1
fi

echo "✅ Dotfiles symlink check passed"

# Create necessary directories
mkdir -p ~/.vim/plugged
mkdir -p ~/.local/share/nvim/site/autoload

# Check if vim-plug is installed, if not install it
PLUG_VIM="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [[ ! -f "$PLUG_VIM" ]]; then
    echo "📦 Installing vim-plug..."
    curl -fLo "$PLUG_VIM" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "✅ vim-plug installed"
else
    echo "✅ vim-plug already installed"
fi

# Install plugins
echo "📦 Installing neovim plugins..."
nvim --headless +PlugInstall +qall

# Check if molokai theme was installed
if [[ -d "$HOME/.vim/plugged/molokai" ]]; then
    echo "✅ molokai theme installed successfully"
else
    echo "⚠️  Warning: molokai theme not found, trying alternative installation..."
    nvim --headless +'PlugInstall tomasr/molokai' +qall
fi

# Check if NERDTree was installed
if [[ -d "$HOME/.vim/plugged/nerdtree" ]]; then
    echo "✅ NERDTree installed successfully"
else
    echo "⚠️  Warning: NERDTree not found, trying alternative installation..."
    nvim --headless +'PlugInstall scrooloose/nerdtree' +qall
fi

echo "🎉 Setup complete! Try running 'nvim' to test the configuration."
echo ""
echo "If you still encounter issues, try:"
echo "1. Run 'nvim +PlugStatus' to check plugin status"
echo "2. Run 'nvim +PlugInstall' to reinstall plugins"
echo "3. Check ~/.config/nvim/init.vim for any syntax errors"
