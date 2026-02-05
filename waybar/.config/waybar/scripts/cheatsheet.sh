#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Cheatsheet - Keybinds & CLI Commands
# Launch with rofi for quick reference
# ──────────────────────────────────────────────────────────────────────────

# Build the cheatsheet content
cheatsheet() {
cat << 'EOF'
───────────────────────────────────────
  HYPRLAND KEYBINDS
───────────────────────────────────────
SUPER + Enter         Terminal (alacritty)
SUPER + Space         App Launcher (rofi)
SUPER + W             Close Window
SUPER + L             Lock Screen
SUPER + Escape        Logout Menu (wlogout)
SUPER + F             Fullscreen
SUPER + T             Toggle Floating
SUPER + P             Pseudo Tile
SUPER + J             Toggle Split
SUPER + N             Toggle Night Light
SUPER + S             Special Workspace
SUPER + Tab           Next Workspace
SUPER + Shift + Tab   Previous Workspace
SUPER + 1-0           Switch to Workspace 1-10
SUPER + Shift + 1-0   Move Window to Workspace
SUPER + Arrows        Move Focus
SUPER + Shift + Arrows   Swap Windows
SUPER + Shift + R     Reload Hyprland
SUPER + K             This Cheatsheet
SUPER + O             Toggle Open WebUI
SUPER + G             Toggle Ollama Chat

───────────────────────────────────────
  APP SHORTCUTS
───────────────────────────────────────
SUPER + Shift + B     Firefox
SUPER + Shift + F     File Manager (thunar)
SUPER + Shift + T     btop (System Monitor)
SUPER + Shift + N     Neovim
SUPER + Shift + O     Obsidian
SUPER + Shift + G     Lazygit
SUPER + Shift + Space Package Browser
SUPER + Alt + Space   Power Menu

───────────────────────────────────────
  SCREENSHOTS (hyprshot)
───────────────────────────────────────
Print                 Region to Clipboard
Shift + Print         Region to ~/Pictures
SUPER + Print         Window to Clipboard
SUPER + Shift + Print Full Screen to ~/Pictures

───────────────────────────────────────
  MEDIA KEYS
───────────────────────────────────────
Vol Up/Down           Adjust Volume
Mute                  Toggle Mute
Brightness Up/Down    Adjust Brightness
Play/Pause            Toggle Playback
Next/Prev             Skip Track

───────────────────────────────────────
  MOUSE (hold SUPER)
───────────────────────────────────────
Left Click + Drag     Move Window
Right Click + Drag    Resize Window

═══════════════════════════════════════
  LINUX / ARCH CLI COMMANDS
═══════════════════════════════════════

───────────────────────────────────────
  PACMAN (Package Manager)
───────────────────────────────────────
pacman -Syu           Update System
pacman -S <pkg>       Install Package
pacman -Rs <pkg>      Remove Package + Deps
pacman -Ss <pkg>      Search Packages
pacman -Qs <pkg>      Search Installed
pacman -Qi <pkg>      Package Info
pacman -Qe            List Explicit Pkgs
pacman -Sc            Clean Cache
yay -S <pkg>          Install from AUR
yay -Syu              Update All (incl AUR)

───────────────────────────────────────
  FILE OPERATIONS
───────────────────────────────────────
ls -la                List All Files
cd <dir>              Change Directory
pwd                   Print Working Dir
cp <src> <dst>        Copy File
mv <src> <dst>        Move/Rename
rm <file>             Remove File
rm -rf <dir>          Remove Directory
mkdir -p <dir>        Create Directories
touch <file>          Create Empty File
cat <file>            Display File
less <file>           Paginate File
head -n <file>        First n Lines
tail -f <file>        Follow Log File
find . -name "*.txt"  Find Files
grep -r "text" .      Search in Files

───────────────────────────────────────
  SYSTEMD
───────────────────────────────────────
systemctl status <s>  Service Status
systemctl start <s>   Start Service
systemctl stop <s>    Stop Service
systemctl restart <s> Restart Service
systemctl enable <s>  Enable at Boot
systemctl disable <s> Disable at Boot
journalctl -xe        Recent Logs
journalctl -fu <s>    Follow Service Log

───────────────────────────────────────
  NETWORKING
───────────────────────────────────────
ip a                  Show IP Addresses
ip link               Show Interfaces
nmcli device wifi list   List WiFi
nmcli device wifi connect <SSID>   Connect
ping <host>           Test Connection
ss -tulpn             Open Ports
curl -I <url>         HTTP Headers
wget <url>            Download File

───────────────────────────────────────
  DISK & STORAGE
───────────────────────────────────────
df -h                 Disk Usage
du -sh <dir>          Directory Size
lsblk                 List Block Devices
mount                 Show Mounts
fdisk -l              List Partitions

───────────────────────────────────────
  PROCESSES
───────────────────────────────────────
ps aux                All Processes
htop / btop           Interactive Monitor
kill <pid>            Kill Process
killall <name>        Kill by Name
pkill <pattern>       Kill by Pattern
pgrep <pattern>       Find Process ID

───────────────────────────────────────
  GIT
───────────────────────────────────────
git status            Working Tree Status
git add .             Stage All Changes
git commit -m "msg"   Commit
git push              Push to Remote
git pull              Pull from Remote
git log --oneline     Compact History
git diff              Show Changes
git branch            List Branches
git checkout -b <br>  New Branch
git merge <branch>    Merge Branch
git stash             Stash Changes
git stash pop         Apply Stash

───────────────────────────────────────
  PERMISSIONS
───────────────────────────────────────
chmod +x <file>       Make Executable
chmod 755 <file>      rwxr-xr-x
chmod 644 <file>      rw-r--r--
chown user:grp <file> Change Owner
sudo <cmd>            Run as Root

───────────────────────────────────────
  COMPRESSION
───────────────────────────────────────
tar -czvf a.tar.gz dir   Create tarball
tar -xzvf a.tar.gz       Extract tarball
zip -r a.zip dir         Create zip
unzip a.zip              Extract zip

───────────────────────────────────────
  MISC
───────────────────────────────────────
man <cmd>             Manual Page
<cmd> --help          Quick Help
which <cmd>           Command Location
alias                 List Aliases
history               Command History
!!                    Repeat Last Cmd
!$                    Last Argument
ctrl+r                Search History
ctrl+c                Cancel Command
ctrl+z                Suspend Process
EOF
}

# Display in rofi with custom theme
cheatsheet | rofi -dmenu \
    -i \
    -p "Cheatsheet" \
    -theme-str 'window {width: 60%; height: 80%;}' \
    -theme-str 'listview {lines: 30; scrollbar: true;}' \
    -theme-str 'element {padding: 4px 8px;}' \
    -theme-str 'element-text {font: "monospace 11";}' \
    -theme-str 'inputbar {enabled: true;}' \
    -no-custom
