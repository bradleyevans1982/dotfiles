# dotfiles

My Arch Linux + Hyprland configuration files.

## Structure

```
config/          # ~/.config/ files
  alacritty/     # Alacritty terminal
  btop/          # System monitor
  cava/          # Audio visualizer
  dunst/         # Notifications
  eww/           # Widgets
  hypr/          # Hyprland WM
  hyprpaper/     # Wallpaper
  kitty/         # Kitty terminal
  rofi/          # Application launcher
  starship.toml  # Shell prompt
  waybar/        # Status bar
  waypaper/      # Wallpaper manager
  wlogout/       # Logout screen
  wofi/          # Launcher
  yazi/          # File manager
  zathura/       # PDF viewer

shell/           # Shell configs
  .bashrc
  .zprofile
  .zshrc
```

## Installation

Symlink or copy configs to their respective locations:

```bash
# Example for hypr
ln -sf ~/dotfiles/config/hypr ~/.config/hypr
```

## Based on

[dionysus](https://github.com/pewdiepie-archdaemon/dionysus) by pewdiepie-archdaemon
