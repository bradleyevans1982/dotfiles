# Hyprland Config 

───────────────────────────────────────────────  
 °˖* ૮( • ᴗ ｡)っ🍸 shheersh - Dionysus vers. 1.0   
 ───────────────────────────────────────────────  
 
## Custom **hyprland** config
Tuned for EWW integration, CAVA visualizer, and Waybar  
![Hyprland Demo](../../assets/demo-hypr.gif)  
---

##  Features
  - Dynamic waybar depending on active/inactive windows.
  - Firefox preload for smooth quick access. 
  - ASUS keyboard fix scripts – brightness, breathing, and profile cycling

![Hyprland Demo 2](../../assets/demo-hypr-2.gif)

``` 
hyprland/
├── hyprland.conf
├── scripts/
│   ├── waybar_watcher.sh
│   └── asus-kbd/
│       ├── kbd-brightness.sh
│       ├── kbd-breathing.sh
│       └── cycle-profile.sh
└── demo.gif  
```

## Requirements
  - **Hyprland** (Wayland compositor & WM)
  - **Hyprpaper** (wallpaper daemon for Hyprland)
  - **eww** (Elkowar’s Wacky Widgets)
  - **cava** (audio visualizer)
  - **rofi** (application launcher)
  - **alacritty** (terminal emulator)
  - **thunar** (file manager)
  - **firefox** (browser, with custom profile support)
  - **grim** (Wayland screenshot tool)
  - **slurp** (Wayland region selector)
  - **wl-clipboard** (for `wl-copy`)
  - **wpctl** (PipeWire volume control)
  - **playerctl** (media player control)
  - **brightnessctl** (backlight control)
  - **curl** (network requests in scripts)
  - **lm-sensors** (for temps, fans, voltages)

This config ties into your other dotfiles:

## Usage

- **Waybar/Eww** → via [`waybar_watcher.sh`](https://github.com/pewdiepie-archdaemon/dionysus/blob/dionysus/dotfiles/hypr/scripts/waybar_watcher.sh)  
  Keeps Waybar and EWW and hyprpaper running reliably under Hyprland.
- **CAVA Visualizer** → launched on login, outputs ASCII to `/tmp/cava.raw`  
  Integrated with EWW via [`audio_visualizer.py`][`audio_visualizer.py`](https://github.com/pewdiepie-archdaemon/dionysus/blob/dionysus/dotfiles/eww/).
- **ASUS Keyboard** → custom scripts for backlight and performance profiles in  
  [`asus-kbd`](https://github.com/pewdiepie-archdaemon/dionysus/tree/dionysus/dotfiles/hypr/scripts/asus-kbd)   
  Includes brightness, breathing effects, and cycle-profile utilities.

