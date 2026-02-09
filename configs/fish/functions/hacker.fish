function hacker
    set -l config ~/.config/ghostty/config

    if grep -q 'theme = HaX0R Gr33N' $config
        sed -i '' 's/^theme = .*/theme = Aura/' $config
        killall -USR2 ghostty
        echo "Hacker mode deactivated."
        return
    end

    # Activate theme first so animation renders in green
    sed -i '' 's/^theme = .*/theme = HaX0R Gr33N/' $config
    killall -USR2 ghostty
    sleep 0.3

    set -l cols $COLUMNS
    set -l rows $LINES

    # Hide cursor
    printf '\033[?25l'
    clear

    # Matrix cascade — fill screen with random hex/symbol chars
    set -l charset '0-9a-f@#$%&*=~<>{}|'
    for i in (seq 1 $rows)
        printf '\033[1;32m%s\033[0m\n' (LC_ALL=C tr -dc $charset < /dev/urandom | head -c $cols)
        sleep 0.01
    end

    # Flash effect — rapid reverse-video flickers
    for i in (seq 1 3)
        printf '\033[?5h'
        sleep 0.05
        printf '\033[?5l'
        sleep 0.05
    end

    # ASCII art overlay — centered on the matrix background
    set -l art_lines \
        '██  ██    ██  █████  ██  ██ ████  ██████' \
        '██  ██ █████ ██     █████  ██    ██   ██' \
        '██████    ██ ██     ██ ██  ████  ██████' \
        '██  ██    ██  █████ ██  ██ ██    ██   ██' \
        '' \
        '██    ██  ████  █████  ████' \
        '███  ███ ██  ██ ██  ██ ██' \
        '██ ██ ██ ██  ██ ██  ██ ████' \
        '██    ██  ████  █████  ████'

    set -l art_height (count $art_lines)
    set -l start_row (math "floor(($rows - $art_height) / 2)")

    printf '\033[1;32m'
    for i in (seq 1 (count $art_lines))
        set -l line $art_lines[$i]
        set -l line_len (string length -- "$line")
        set -l col (math "floor(($cols - $line_len) / 2) + 1")
        set -l row (math "$start_row + $i")
        if test -n "$line"
            printf '\033[%d;%dH%s' $row $col "$line"
        end
    end

    # Hold
    sleep 1.5

    # Clear + show cursor
    printf '\033[0m'
    printf '\033[?25h'
    clear
    echo "Welcome, h4ck3r."
end
