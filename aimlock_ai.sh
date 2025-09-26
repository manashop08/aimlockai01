#!/usr/bin/env bash
# AIMLOCK AI 
# DEV: MANA SHOP

yellow="\033[1;33m"
reset="\033[0m"

LOGO="${yellow}
 ________  ___  _____ ______   ___       ________  ________  ___  __            ________  ___     
|\   __  \|\  \|\   _ \  _   \|\  \     |\   __  \|\   ____\|\  \|\  \         |\   __  \|\  \    
\ \  \|\  \ \  \ \  \\\__\ \  \ \  \    \ \  \|\  \ \  \___|\ \  \/  /|_       \ \  \|\  \ \  \   
 \ \   __  \ \  \ \  \\|__| \  \ \  \    \ \  \\\  \ \  \    \ \   ___  \       \ \   __  \ \  \  
  \ \  \ \  \ \  \ \  \    \ \  \ \  \____\ \  \\\  \ \  \____\ \  \\ \  \       \ \  \ \  \ \  \ 
   \ \__\ \__\ \__\ \__\    \ \__\ \_______\ \_______\ \_______\ \__\\ \__\       \ \__\ \__\ \__\
    \|__|\|__|\|__|\|__|     \|__|\|_______|\|_______|\|_______|\|__| \|__|        \|__|\|__|\|__|
                                                                                                  
                                                                                                  
                                                                                                  
                                                                                                                                                                                                                                   

${reset}"

X_START=500; Y_START=2000
X_END=500;   Y_END=500
STEPS=8
DEV=""
STREAM_PID=""
SOUND_DIR="./sounds"

# Loading animation
loading_animation() {
    clear
    echo -ne "$LOGO"
    echo
    echo "Initializing AIMLOCK AI..."
    for i in $(seq 1 10); do
        printf "[%-10s] %d%%\r" "$(printf '#%.0s' $(seq 1 $i))" "$((i*10))"
        sleep 0.1
    done
    echo
    sleep 0.3
}

# Play sound function
play_sound() {
    local file="$1"
    [ -f "$file" ] && aplay "$file" >/dev/null 2>&1 &
}

# Detect touchscreen device
find_dev() {
    local d
    d=$(getevent -p 2>/dev/null | awk '/add device/ {dev=$3} /ABS_MT_POSITION_X/ {if(dev) print dev; dev="";}' | head -n1)
    [ -z "$d" ] && d="/dev/input/event2"
    echo "$d"
}

# Smooth swipe
perform_swipe() {
    local dev="$1" xs=$2 ys=$3 xe=$4 ye=$5
    [ -z "$dev" ] && return 1
    play_sound "$SOUND_DIR/swipe.wav"   
    sendevent "$dev" 3 57 0
    sendevent "$dev" 3 53 "$xs"
    sendevent "$dev" 3 54 "$ys"
    sendevent "$dev" 3 58 50
    sendevent "$dev" 0 0 0
    for i in $(seq 1 $STEPS); do
        fx=$(( xs + (xe - xs) * i / STEPS ))
        fy=$(( ys + (ye - ys) * i / STEPS ))
        sendevent "$dev" 3 53 "$fx"
        sendevent "$dev" 3 54 "$fy"
        sendevent "$dev" 0 0 0
        sleep 0.02
    done
    sendevent "$dev" 3 57 -1
    sendevent "$dev" 0 0 0
    echo "Swipe executed!"
}

# Stream Mode / Anti-Capture
stream_mode_start() {
    if [ -n "$STREAM_PID" ] && kill -0 "$STREAM_PID" 2>/dev/null; then
        return
    fi
    (
        while true; do
            pkill -f screenrecord 2>/dev/null
            pkill -f scrcpy 2>/dev/null
            sleep 1
        done
    ) &
    STREAM_PID=$!
    echo "Stream Mode ENABLED"
}

stream_mode_stop() {
    if [ -n "$STREAM_PID" ]; then
        kill "$STREAM_PID" 2>/dev/null
        STREAM_PID=""
        echo "Stream Mode DISABLED"
    fi
}

# Draw UI menu
draw_ui() {
    clear
    echo -ne "$LOGO"
    now=$(date +"%Y-%m-%d %H:%M:%S")
    echo "============================================"
    echo " CURRENT TIME: $now"
    echo "============================================"
    echo "[1] Swipe (AIMLOCK)"
    echo "[2] Set Coordinates (X/Y)"
    echo "[3] Detect Touch Device"
    echo "[4] Enable Stream Mode"
    echo "[5] Disable Stream Mode"
    echo "[6] Exit"
    echo "============================================"
    echo " DEV: MANA SHOP"
    echo "============================================"
    printf "Select an option: "
}

main_loop() {
    DEV=$(find_dev)
    while true; do
        draw_ui
        read choice
        case "$choice" in
            1) perform_swipe "$DEV" "$X_START" "$Y_START" "$X_END" "$Y_END" ;;
            2) echo "Start X (current $X_START): "; read sx
               echo "Start Y (current $Y_START): "; read sy
               echo "End X (current $X_END): "; read ex
               echo "End Y (current $Y_END): "; read ey
               [ -n "$sx" ] && X_START="$sx"
               [ -n "$sy" ] && Y_START="$sy"
               [ -n "$ex" ] && X_END="$ex"
               [ -n "$ey" ] && Y_END="$ey"
               ;;
            3) DEV=$(find_dev); echo "Detected device: $DEV"; sleep 1 ;;
            4) stream_mode_start; sleep 0.5 ;;
            5) stream_mode_stop; sleep 0.5 ;;
            6) stream_mode_stop; clear; exit 0 ;;
        esac
    done
}

if [ "$(id -u)" != "0" ]; then
    echo "Please run as root (su or tsu)"
    exit 1
fi

loading_animation
main_loop