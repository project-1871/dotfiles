#!/bin/bash

set -e

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installing Glenn's Dotfiles"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Shell configs (root directory)
echo "Installing shell configs..."
ln -sf "$DOTFILES_DIR/.bashrc" ~/.bashrc
ln -sf "$DOTFILES_DIR/.bash_profile" ~/.bash_profile
ln -sf "$DOTFILES_DIR/.profile" ~/.profile
ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
echo "✓ Shell configs linked"

# Hyprland
echo "Installing Hyprland configs..."
mkdir -p "$CONFIG_DIR/hypr"
ln -sf "$DOTFILES_DIR/config/hypr/hyprland.conf" "$CONFIG_DIR/hypr/hyprland.conf"
ln -sf "$DOTFILES_DIR/config/hypr/autostart.conf" "$CONFIG_DIR/hypr/autostart.conf"
ln -sf "$DOTFILES_DIR/config/hypr/bindings.conf" "$CONFIG_DIR/hypr/bindings.conf"
echo "✓ Hyprland configs linked"

# Waybar
echo "Installing Waybar configs..."
mkdir -p "$CONFIG_DIR/waybar"
ln -sf "$DOTFILES_DIR/config/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
ln -sf "$DOTFILES_DIR/config/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
echo "✓ Waybar configs linked"

# Ghostty
echo "Installing Ghostty config..."
mkdir -p "$CONFIG_DIR/ghostty"
ln -sf "$DOTFILES_DIR/config/ghostty/config" "$CONFIG_DIR/ghostty/config"
echo "✓ Ghostty config linked"

# Neovim
echo "Installing Neovim config..."
mkdir -p "$CONFIG_DIR/nvim"
ln -sf "$DOTFILES_DIR/config/nvim/init.lua" "$CONFIG_DIR/nvim/init.lua"
echo "✓ Neovim config linked"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Reload shell: source ~/.bashrc"
echo "  2. Restart Hyprland: Super+Shift+Q then Super+R"
echo "  3. Check configs: hyprctl reload && waybar restart"
echo ""
