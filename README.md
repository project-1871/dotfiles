# dotfiles

My personal dotfiles for Arch Linux with Hyprland (Omarchy).

## System
- OS: Arch Linux
- WM: Hyprland (via Omarchy)
- Shell: Bash / Zsh / Fish
- Terminal: Ghostty / Alacritty / Kitty
- Editor: Neovim

## Structure
```
.bashrc / .zshrc / .bash_profile / .profile   ← shell configs
config/
  hypr/       ← Hyprland window manager
  waybar/     ← status bar
  mako/       ← notifications
  walker/     ← app launcher
  alacritty/  ← terminal
  ghostty/    ← terminal
  kitty/      ← terminal
  nvim/       ← neovim
  btop/       ← system monitor
  fastfetch/  ← system info
  starship.toml ← shell prompt
  lazygit/    ← git TUI
  omarchy/    ← omarchy theme/config
  MangoHud/   ← GPU/FPS overlay
  fish/       ← fish shell
```

## Install
Clone and symlink or copy configs to `~/.config/`.
