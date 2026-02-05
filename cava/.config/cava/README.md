# CAVA config

───────────────────────────────────────────────  
 °˖* ૮( • ᴗ ｡)っ🍸 shheersh - Dionysus vers. 1.0   
 ───────────────────────────────────────────────  

## Custom **CAVA** config
Outputs raw ASCII data for easy integration.
![Eww Demo Png](../../assets/demo-cava.png)
---

##  Features
Raw ASCII output → written to /tmp/cava.raw so it can be piped into:

    - EWW widgets
    - Waybar modules
    - custom ASCII scripts

## Usage
Run with `cava -p ~/.config/cava/config`
CAVA writes raw ASCII bars to `/tmp/cava.raw`

![Eww Demo Gif](../../assets/demo-cava.gif)

## Pipe into your visualizer
Can pair with: [audio_visualizer.py](../eww/scripts/audio/audio_visualizer.py) for Ascii style visualizer.

```
python3 dotfiles/eww/scripts/audio/audio_visualizer.py
```
or in terminal:

```
watch -n0.1 cat /tmp/visualizer.txt
```


