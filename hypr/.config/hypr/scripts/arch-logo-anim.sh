#!/bin/bash
# Arch logo animation - runs inside alacritty

arch_logo() {
    cat << "LOGO"
                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `/
LOGO
}

# Gruvbox colors
colors=(
    "\033[38;2;251;73;52m"
    "\033[38;2;250;189;47m"
    "\033[38;2;184;187;38m"
    "\033[38;2;131;165;152m"
    "\033[38;2;211;134;155m"
    "\033[38;2;254;128;25m"
)
arch_blue="\033[38;2;23;147;209m"
reset="\033[0m"

tput civis
trap "tput cnorm; exit 0" INT TERM EXIT

rows=$(tput lines)
cols=$(tput cols)
logo_height=19
logo_width=42
start_row=$(( (rows - logo_height) / 2 ))
start_col=$(( (cols - logo_width) / 2 ))

color_index=0
frame=0

while true; do
    if read -t 0.08 -rsn1 2>/dev/null; then
        break
    fi

    clear

    if (( frame % 40 < 20 )); then
        current_color="$arch_blue"
    else
        current_color="${colors[$color_index]}"
    fi

    line_num=0
    while IFS= read -r line; do
        tput cup $((start_row + line_num)) $start_col
        echo -e "${current_color}${line}${reset}"
        ((line_num++))
    done <<< "$(arch_logo)"

    text_row=$((start_row + logo_height + 2))
    text="A R C H   L I N U X"
    text_col=$(( (cols - ${#text}) / 2 ))
    tput cup $text_row $text_col
    echo -e "${current_color}${text}${reset}"

    ((frame++))
    if (( frame % 80 == 0 )); then
        color_index=$(( (color_index + 1) % ${#colors[@]} ))
    fi
done
