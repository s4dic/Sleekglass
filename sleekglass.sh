#!/bin/bash
# Sleekglass - Client simple pour Looking Glass
# Version 0.2 corrigée
# dépendances: xrandr yad
ami=`whoami`
if [[ "$ami" == "root" ]]; then
    echo "root detected, please don't launch me with root. EXIT"
    exit 2
fi

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
ami=$(whoami)
me=$(basename "$0")
usr=$LOGNAME

# Récupérer les écrans disponibles
xrandr | grep " connected " | cut -f1 -d " " > /tmp/.sleekglass-screen.log

function settingsempty {
    yad --center --width=500 --height=100 --title="Sleek glass - Looking Glass Client" --form --columns=2 \
        --field="IP:" "127.0.0.1" --field="PORT:" "5900" \
        --item-separator="," --field="Output screen:":CB "$(paste -s -d"," < /tmp/.sleekglass-screen.log)" \
        --field="Fullscreen:CB" Yes,No \
        --field="Show FPS:CB" No,Yes \
        --field="Borderless:CB" Yes,No \
        --field="disable keyboard/mouse:CB" Yes,No \
        --field="show mouse above the L-G window:CB" Yes,No > /home/$usr/.config/sleekglass/config.ini

    settingsvalue=$(cat /home/$usr/.config/sleekglass/config.ini)
    > /home/$usr/.config/sleekglass/config.json

    for val in $(echo "$settingsvalue" | tr "|" "\n"); do
        echo "$val" >> /home/$usr/.config/sleekglass/config.json
    done

    if [[ "$settingsvalue" != "" ]]; then
        notify-send -i "$dir/icons/Logo.png" "Sleekglass" "All settings are saved for your future connections"
    fi
}

function about {
    zenity --info --title="Sleek glass - Looking Glass Client" --width=100 --height=100 --no-wrap --text="<big><b>Soft by Sleek:\n<span color=\"red\">for opensource community</span></b></big>\n\nSleekGlass est un outil pour simplifier la connexion Looking Glass.\n
    Discord: https://discord.gg/Kp6Z27n\nEnjoy :)"
}

function emptyornot {
    configfile="/home/$usr/.config/sleekglass/config.ini"
    echo "mon path: $configfile"

    if [ ! -f "$configfile" ]; then
        mkdir -p /home/$usr/.config/sleekglass/
        settingsempty
    fi

    while [[ ! -s "$configfile" ]]; do
        settingsempty
    done
}
emptyornot

function createconfig {
    > /home/$usr/.config/sleekglass/config.json
    settingsvalue=$(cat /home/$usr/.config/sleekglass/config.ini)
    for val in $(echo "$settingsvalue" | tr "|" "\n"); do echo "$val" >> /home/$usr/.config/sleekglass/config.json; done

    IP=$(awk 'NR==1' /home/$usr/.config/sleekglass/config.json)
    Port=$(awk 'NR==2' /home/$usr/.config/sleekglass/config.json)
    Screenopening=$(awk 'NR==3' /home/$usr/.config/sleekglass/config.json)
    Fullscreen=$(awk 'NR==4' /home/$usr/.config/sleekglass/config.json)
    Showfps=$(awk 'NR==5' /home/$usr/.config/sleekglass/config.json)
    Borderless=$(awk 'NR==6' /home/$usr/.config/sleekglass/config.json)
    mousekeyboard=$(awk 'NR==7' /home/$usr/.config/sleekglass/config.json)
    mouseaboseLGwindows=$(awk 'NR==8' /home/$usr/.config/sleekglass/config.json)

    xrandr --output "$Screenopening" --primary

    [[ "$Fullscreen" == "Yes" ]] && Fullscreen2="-F" || Fullscreen2=""
    [[ "$Showfps" == "Yes" ]] && Showfps2="-k" || Showfps2=""
    [[ "$Borderless" == "Yes" ]] && Borderless2="-d" || Borderless2=""
    [[ "$mousekeyboard" == "Yes" ]] && mousekeyboard2="-s" || mousekeyboard2=""
    [[ "$mouseaboseLGwindows" == "Yes" ]] && showCursor="-m" || showCursor=""

    ivshmemArg="/dev/shm/looking-glass"
}

function startstream {
    createconfig
    echo "Command: /usr/local/bin/looking-glass-client -c $IP -p $Port $Fullscreen2 $Showfps2 $Borderless2 $mousekeyboard2 $mouseaboseLGwindows2 $ivshmemArg"
    /usr/local/bin/looking-glass-client -c "$IP" -p "$Port" $Fullscreen2 $Showfps2 $Borderless2 $mousekeyboard2 -M "$ivshmemArg" $showCursor &
    pid=$!
}

function settings {
    md5check1=$(md5sum /home/$usr/.config/sleekglass/config.ini | awk '{print $1}')

    notempty=$(yad --center --width=500 --height=100 --title="Sleek glass - Looking Glass Client" --form --columns=2 \
        --field="IP:" "$IP" --field="PORT:" "$Port" \
        --item-separator="," --field="Output screen:":CB "$Screenopening,$(paste -s -d"," < /tmp/.sleekglass-screen.log)" \
        --field="Fullscreen:CB" "$Fullscreen,Yes,No" \
        --field="Show FPS:CB" "$Showfps,Yes,No" \
        --field="Borderless:CB" "$Borderless,Yes,No" \
        --field="disable keyboard/mouse:CB" "$mousekeyboard,Yes,No" \
        --field="show mouse above the L-G window:CB" "$mouseaboseLGwindows,Yes,No")

    if [[ "$notempty" != "" ]]; then
        echo "$notempty" > /home/$usr/.config/sleekglass/config.ini
        notify-send -i "$dir/icons/Logo.png" "Sleekglass" "All settings are saved for your future connections"
    fi
}

function pkid {
    sleep 1
    kill -9 $(cat /tmp/ppid 2>/dev/null) $(cat /tmp/ppid2 2>/dev/null) 2>/dev/null
    echo "$(pgrep -f looking-glass)" > /tmp/ppid
    echo "$(pgrep -f sleekglass.sh)" > /tmp/ppid2
}

function stopstream {
    kill -9 $pid 2>/dev/null
}

pkid &

# Interface graphique
while true; do
    yad --title="SLEEKGLASS : a simple client for Looking Glass" \
        --center --button="Start viewing $ami!$dir/icons/Start.png":1 \
        --button="Stop viewing!$dir/icons/Stop.png":2 \
        --button="settings!$dir/icons/Settings.png":3 \
        --button="About!$dir/icons/About.png":4 \
        --button="Close!$dir/icons/Close.png":5

    case $? in
        1) stopstream; startstream ;;
        2) stopstream ;;
        3) createconfig; settings ;;
        4) about ;;
        5) stopstream; kill -9 $$; exit 0 ;;
    esac
done
