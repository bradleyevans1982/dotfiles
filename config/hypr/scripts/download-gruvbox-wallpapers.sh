#!/bin/bash
# Download Gruvbox wallpapers - Nature, Space, Abstract, Cozy aesthetic
# Source: https://github.com/AngelJumbo/gruvbox-wallpapers
# Avoids anime (mostly)

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
BASE_URL="https://raw.githubusercontent.com/AngelJumbo/gruvbox-wallpapers/main/wallpapers"
# Workaround for DNS issues (e.g., Tailscale MagicDNS not forwarding)
RESOLVE_OPT="--resolve raw.githubusercontent.com:443:185.199.108.133"

mkdir -p "$WALLPAPER_DIR"
cd "$WALLPAPER_DIR" || exit 1

echo "Downloading Gruvbox wallpapers to $WALLPAPER_DIR..."
echo ""

# Minimalistic - Space, Abstract, Nature
MINIMALISTIC=(
    "gruvbox_astro.jpg"
    "gruvbox_minimal_space.png"
    "gruvbox_spac.jpg"
    "solar-system-minimal.png"
    "solar-system.jpg"
    "starry-sky.png"
    "orbit.png"
    "red-moon.png"
    "moon.png"
    "space.png"
    "space-shuttle.png"
    "war-in-space.png"
    "nasa.png"
    "nasa-2.png"
    "nasa-3.png"
    "rocket.png"
    "gruvb_solarsys.png"
    "burning-earth.png"
    "gruv-kanji.png"
    "great-wave-of-kanagawa-gruvbox.png"
    "dragon.png"
    "atoms.png"
    "chaos.png"
    "elegant.png"
    "triangle.png"
    "gruv-abstract-maze.png"
    "door.png"
    "dark-bench.png"
    "fox.png"
    "husky.png"
    "skull.png"
    "skull-2.png"
    "coding.png"
    "coding-2.png"
    "coding-3.png"
    "gruv-dev-minimal.png"
    "gruv-commit.png"
    "gruv-focus.png"
    "gruv-limits.png"
    "gruv-mistakes.png"
    "gruv-understand.png"
    "gruv-estimate.png"
    "gruvbox-linux.png"
    "gruvbox_tux.png"
    "vim.png"
    "fingerprint.png"
    "rubiks-cube.png"
    "sunset.png"
    "looking-for.png"
    "philosophy.png"
    "kiddae.jpg"
    "gruv.jpg"
)

# Mix - Landscapes, Abstract, Architecture
MIX=(
    "black-hole.png"
    "galaxy.png"
    "astronaut.jpg"
    "satellite.jpg"
    "spaceship_maze.jpg"
    "abstract.jpg"
    "abstract-2.jpg"
    "abstract-3.jpg"
    "abstract-4.png"
    "abstract-darkhole.png"
    "alien_landscape.png"
    "chinatown.png"
    "gruv-sushi-streets.jpg"
    "night_moon.png"
    "future-town.jpg"
    "futurism.jpg"
    "houses.png"
    "mountain.jpg"
    "forest_castle.png"
    "warm_forest.png"
    "landscape0.png"
    "ruins-2.png"
    "ruines.jpg"
    "greek.png"
    "desk-gruvbox-material.jpg"
    "gruv-material.png"
    "gruvbox15.png"
    "gruvb99810.png"
    "gruvy.jpg"
    "gruvy-night.jpg"
    "dead-robot.jpg"
    "artificial-brain.jpg"
    "flower.jpg"
    "animal-skull.jpg"
    "skull.jpg"
    "wolf.jpg"
    "wall.jpg"
    "random.jpg"
    "platform.jpg"
    "free.jpg"
    "1.jpg"
    "FreshCake_forestWallpaper.jpg"
    "xavier-cuenca-w4-3.jpg"
    "wallhaven-vmk698.jpg"
    "wallhaven-z85eoy.jpg"
    "titlwinzbst81.jpg"
    "qcqKfdZ.png"
    "nord-shards.png"
)

# Pixel Art - Cityscapes, Nature, Cozy
PIXELART=(
    "dock.png"
    "chinatown.png"
    "brown_city_planet_w.jpg"
    "urban_architecture.jpg"
    "secluded-grove-pixel.png"
    "house-garden.png"
    "leaves-hard-pixelated.png"
    "gruvbox_image11.png"
    "gruvbox_image31.png"
    "gruvbox_image40.png"
    "gruvbox_image44.png"
    "gruvbox_image46.png"
    "gruvbox_image55.png"
    "gruvbox-pacman-full.png"
    "gruvbox-pacman-ghosts.png"
    "image16.png"
    "image21.png"
    "wall_secondary.png"
    "wallpaper.png"
)

# Photography - Nature, Forests, Cozy
PHOTOGRAPHY=(
    "forest.jpg"
    "forest-2.jpg"
    "forest-3.jpg"
    "forest-4.jpg"
    "forest-5.jpg"
    "forest-6.jpg"
    "forest-7.jpg"
    "forest-cabin.jpg"
    "forest-river.jpg"
    "forest-foggy-misty-cloudy.png"
    "forest-moss.png"
    "forest-mountain-cloudy-valley.png"
    "gruvbox-forest.jpg"
    "cabin.png"
    "hut.jpg"
    "hut-2.jpg"
    "house.jpg"
    "houseonthesideofalake.jpg"
    "comfy-room.jpg"
    "beach.jpg"
    "beach.png"
    "lake.png"
    "mountain.jpg"
    "canyon.jpg"
    "bridge.jpg"
    "castle.jpg"
    "cat.jpg"
    "cat-2.jpg"
    "leaves-2.jpg"
    "leaves-3.jpg"
    "ferns-green.jpg"
    "grass.jpg"
    "gray_trees.jpg"
    "bush.png"
    "cactus.png"
    "flower-1.jpg"
    "flowers.jpg"
    "flowers-2.jpg"
    "berries.jpg"
    "coffee-cup.jpg"
    "coffee-green.jpg"
    "books.jpg"
    "camera.png"
    "camera-2.jpg"
    "keyboard.jpg"
    "keyboards.jpg"
    "bulbs.jpg"
    "lantern.jpg"
    "jars.jpg"
    "beer.jpg"
    "cinnamon-rolls.jpg"
    "board.png"
    "herb-notebook.png"
    "golden-statue.png"
    "Pages.png"
    "Colors.png"
    "White-Mountain.jpg"
)

# Renders - 3D Abstract
RENDERS=(
    "3d_gruvbox.png"
    "1.jpg"
    "2.jpg"
    "3.jpg"
    "4.jpg"
    "5.jpg"
    "8.jpg"
    "9.jpg"
    "22.jpg"
    "orthvrq3xgb91.jpg"
)

# Painting - Classic Art
PAINTING=(
    "A_Herefordshire_Lane.png"
    "Cat_at_Play.png"
    "Driving_Home_The_Flock.png"
    "The_Artists_Garden_at_Eragny.png"
    "The_Backwater.png"
    "View_of_Vent_in_the_Ventertal.jpg"
)

download_category() {
    local category="$1"
    shift
    local files=("$@")

    echo "=== Downloading $category ==="
    local count=0
    for file in "${files[@]}"; do
        # Create unique filename by prefixing category for duplicates
        local target="$file"
        if [[ "$category" == "renders" && "$file" =~ ^[0-9]+\.jpg$ ]]; then
            target="render-$file"
        fi
        if [[ "$category" == "pixelart" && "$file" == "chinatown.png" ]]; then
            target="pixel-chinatown.png"
        fi
        if [[ "$category" == "pixelart" && "$file" == "wallpaper.png" ]]; then
            target="pixel-wallpaper.png"
        fi
        if [[ "$category" == "photography" && "$file" == "mountain.jpg" ]]; then
            target="photo-mountain.jpg"
        fi

        if [[ -f "$target" ]]; then
            echo "  [SKIP] $target"
        else
            echo "  [GET]  $target"
            if curl $RESOLVE_OPT -sfL -o "$target" "$BASE_URL/$category/$file"; then
                ((count++))
            else
                echo "  [FAIL] $target"
                rm -f "$target"
            fi
        fi
    done
    echo "  Downloaded: $count new files"
    echo ""
}

download_category "minimalistic" "${MINIMALISTIC[@]}"
download_category "mix" "${MIX[@]}"
download_category "pixelart" "${PIXELART[@]}"
download_category "photography" "${PHOTOGRAPHY[@]}"
download_category "renders" "${RENDERS[@]}"
download_category "painting" "${PAINTING[@]}"

echo "=== Download Complete ==="
echo ""
echo "Total wallpapers: $(ls -1 "$WALLPAPER_DIR"/*.{png,jpg,jpeg} 2>/dev/null | wc -l)"
echo ""
echo "Preview random wallpaper with: ~/.config/hypr/scripts/random-wallpaper.sh"
