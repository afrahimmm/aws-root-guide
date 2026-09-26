#!/bin/bash

# ============================================================
# AWS VPS SETUP PANEL v2
# roote.sh
# ============================================================

set -u

# ---------- COLORS ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_CYAN='\033[1;36m'
BOLD_MAGENTA='\033[1;35m'

# ---------- LOW-LEVEL HELPERS ----------

success() {
    echo -e "  ${BOLD_GREEN}[OK]${NC} $1"
}

error() {
    echo -e "  ${BOLD_RED}[X]${NC} $1"
}

warning() {
    echo -e "  ${BOLD_YELLOW}[!]${NC} $1"
}

info() {
    echo -e "  ${BOLD_CYAN}[i]${NC} $1"
}

step() {
    echo -e "  ${MAGENTA}[>]${NC} $1"
}

separator() {
    printf "${GRAY}%.0s-" {1..44}
    echo -e "${NC}"
}

pause_screen() {
    echo
    safe_read "$(echo -e "  ${DIM}Press ENTER to continue...${NC}")" _UNUSED
}

# Reads from the real controlling terminal, not stdin.
# Fixes the infinite "Invalid option" loop that happens when this
# script's stdin is a pipe (e.g. curl ... | bash) instead of a TTY.
safe_read() {
    local prompt_text="$1"
    local __resultvar="$2"
    local input=""

    if [ ! -e /dev/tty ]; then
        echo
        error "No interactive terminal available for input."
        error "This script needs to be run directly, not piped (e.g. avoid 'curl ... | bash')."
        exit 1
    fi

    if ! read -rp "$prompt_text" input < /dev/tty; then
        echo
        error "Input stream closed unexpectedly (no terminal attached)."
        exit 1
    fi

    printf -v "$__resultvar" '%s' "$input"
}

box_top() {
    echo -e "${CYAN}+==========================================+${NC}"
}

box_bottom() {
    echo -e "${CYAN}+==========================================+${NC}"
}

box_line() {
    local text="$1"
    local pad=$(( 44 - ${#text} ))
    (( pad < 0 )) && pad=0
    printf "${CYAN}|${NC} ${BOLD}%s${NC}%*s${CYAN}|${NC}\n" "$text" "$pad" ""
}

# Typewriter effect for headers, kept fast so it never feels sluggish
typewriter() {
    local text="$1"
    local delay="${2:-0.01}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# Spinner that runs while a background PID is alive
spinner() {
    local pid=$1
    local msg="$2"
    local frames='|/-\'
    local i=0

    tput civis 2>/dev/null

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r  ${CYAN}[%s]${NC} %s" "${frames:$i:1}" "$msg"
        sleep 0.1
    done

    wait "$pid" 2>/dev/null
    local rc=$?

    printf "\r%*s\r" "$(( ${#msg} + 10 ))" ""
    tput cnorm 2>/dev/null

    return $rc
}

# Runs a command with a spinner + label, returns the command's exit code
run_with_spinner() {
    local msg="$1"
    shift
    ( "$@" ) >/tmp/roote_spinner_out 2>&1 &
    local pid=$!
    spinner "$pid" "$msg"
    local rc=$?
    return $rc
}

# Animated progress bar over N steps, each with its own label
progress_bar() {
    local total=$1
    shift
    local labels=("$@")
    local width=32

    for (( n=1; n<=total; n++ )); do
        local filled=$(( n * width / total ))
        local empty=$(( width - filled ))
        local bar
        bar=$(printf "%${filled}s" "" | tr ' ' '#')
        bar+=$(printf "%${empty}s" "" | tr ' ' '.')
        local label="${labels[$((n-1))]:-Working...}"
        printf "\r  ${CYAN}[%s]${NC} %-28s" "$bar" "$label"
        sleep 0.18
    done
    echo
}

clear_line() {
    printf "\r%*s\r" "80" ""
}

# ---------- SPLASH ----------

splash_screen() {
    clear
    echo
    echo -e "${BOLD_CYAN}"
    cat <<'EOF'
   ___ __      _____   _____  ___ ___ ___
  |_  |  |    / __\ \ / /_  \|_  |_  | __|
   / /|  |__  \__ \\ V / / ){|/ /|/ / _|
  |___|____|  |___/ |_| |_/_|/_/ |_/___|
EOF
    echo -e "${NC}"
    typewriter "        AWS VPS SETUP PANEL  //  v2" 0.008
    echo
    progress_bar 5 \
        "Checking environment" \
        "Loading SSH state" \
        "Reading hostname" \
        "Preparing menu" \
        "Almost there"
    echo
}

# ---------- ROOT CHECK ----------

if [ "$EUID" -ne 0 ]; then
    clear
    echo
    error "This script must be run as root."
    echo
    echo -e "  ${DIM}Run:${NC}"
    echo -e "  ${BOLD_YELLOW}sudo bash roote.sh${NC}"
    echo
    exit 1
fi

# ---------- ROOT LOGIN ----------

enable_root() {

    clear
    box_top
    box_line "ROOT LOGIN CONFIGURATION"
    box_bottom
    echo

    step "Reading current SSH configuration..."
    sleep 0.3

    ROOT_LOGIN=$(sshd -T 2>/dev/null | awk '$1=="permitrootlogin" {print $2}')
    PASSWORD_LOGIN=$(sshd -T 2>/dev/null | awk '$1=="passwordauthentication" {print $2}')

    if [ "$ROOT_LOGIN" = "yes" ] && [ "$PASSWORD_LOGIN" = "yes" ]; then

        success "Root login is already enabled."
        success "Password authentication is already enabled."
        echo

        safe_read "$(echo -e "  ${YELLOW}Do you want to change the root password anyway? [y/N]:${NC} ")" CHANGE_PASS

        if [[ "$CHANGE_PASS" =~ ^[Yy]$ ]]; then
            passwd root
        else
            info "Root password was not changed."
        fi

        return

    fi

    echo
    info "Checking AWS SSH configuration..."
    sleep 0.3
    echo

    SSH_DIR="/etc/ssh/sshd_config.d"
    OVERRIDE="$SSH_DIR/99-root-login.conf"

    mkdir -p "$SSH_DIR"

    # Backup existing override if present
    if [ -f "$OVERRIDE" ]; then
        cp "$OVERRIDE" "$OVERRIDE.backup.$(date +%Y%m%d%H%M%S)"
        info "Existing root SSH configuration backed up."
    fi

    # Create override
    cat > "$OVERRIDE" <<'EOF'
PermitRootLogin yes
PasswordAuthentication yes
EOF

    success "Root SSH configuration created."

    # Fix AWS cloud-init setting
    CLOUD_CONFIG="$SSH_DIR/60-cloudimg-settings.conf"

    if [ -f "$CLOUD_CONFIG" ]; then

        if grep -qE '^PasswordAuthentication[[:space:]]+no' "$CLOUD_CONFIG"; then

            sed -i \
            's/^PasswordAuthentication[[:space:]]\+no/PasswordAuthentication yes/' \
            "$CLOUD_CONFIG"

            success "AWS cloud-init PasswordAuthentication setting fixed."

        else
            info "AWS cloud-init password authentication setting is already OK."
        fi
    fi

    echo
    step "Validating SSH configuration..."

    sleep 0.4

    if sshd -t 2>/tmp/roote_ssh_error; then

        success "SSH configuration is valid."

    else

        error "SSH configuration validation failed."

        echo
        cat /tmp/roote_ssh_error

        echo
        warning "Attempting automatic recovery..."

        rm -f "$OVERRIDE"

        if sshd -t 2>/dev/null; then
            success "Original SSH configuration restored."
        else
            error "SSH configuration is still invalid."
            error "DO NOT close your current SSH session."
            return 1
        fi

        return 1
    fi

    echo
    run_with_spinner "Restarting SSH service..." systemctl restart ssh
    RESTART_RC=$?

    if [ "$RESTART_RC" -eq 0 ]; then
        success "SSH service restarted."
    else
        error "Failed to restart SSH service."
        cat /tmp/roote_spinner_out 2>/dev/null
        return 1
    fi

    echo
    step "Checking final SSH settings..."
    sleep 0.3

    FINAL_ROOT=$(sshd -T 2>/dev/null | awk '$1=="permitrootlogin" {print $2}')
    FINAL_PASSWORD=$(sshd -T 2>/dev/null | awk '$1=="passwordauthentication" {print $2}')

    echo

    if [ "$FINAL_ROOT" = "yes" ]; then
        success "Root login: ENABLED"
    else
        error "Root login: NOT ENABLED"
    fi

    if [ "$FINAL_PASSWORD" = "yes" ]; then
        success "Password login: ENABLED"
    else
        error "Password login: NOT ENABLED"
    fi

    echo

    if [ "$FINAL_ROOT" = "yes" ] && [ "$FINAL_PASSWORD" = "yes" ]; then

        success "Root SSH login is fully configured."

        echo
        safe_read "$(echo -e "  ${YELLOW}Set/change the root password now? [Y/n]:${NC} ")" SET_PASS

        if [[ ! "$SET_PASS" =~ ^[Nn]$ ]]; then
            passwd root
        fi

    else
        error "Root SSH configuration could not be completed."
        return 1
    fi
}

# ---------- HOSTNAME ----------

change_hostname() {

    clear
    box_top
    box_line "HOSTNAME CONFIGURATION"
    box_bottom
    echo

    CURRENT_HOSTNAME=$(hostname)

    info "Current hostname: ${BOLD_CYAN}$CURRENT_HOSTNAME${NC}"
    echo

    safe_read "$(echo -e "  ${YELLOW}Enter new hostname:${NC} ")" NEW_HOSTNAME

    if [ -z "$NEW_HOSTNAME" ]; then
        error "Hostname cannot be empty."
        return 1
    fi

    # Hostname validation
    if ! [[ "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]]; then
        error "Invalid hostname."
        echo
        echo -e "  ${DIM}Allowed characters:${NC}"
        echo -e "  ${DIM}Letters, numbers, hyphen (-), and dot (.)${NC}"
        return 1
    fi

    if [ "$CURRENT_HOSTNAME" = "$NEW_HOSTNAME" ]; then
        success "Hostname is already '$NEW_HOSTNAME'."
        return 0
    fi

    echo
    progress_bar 3 \
        "Applying hostnamectl" \
        "Updating /etc/hostname" \
        "Updating /etc/hosts"
    echo

    if hostnamectl set-hostname "$NEW_HOSTNAME"; then
        success "Hostname changed."
    else
        error "hostnamectl failed."
        return 1
    fi

    # Ensure /etc/hostname is correct
    if echo "$NEW_HOSTNAME" > /etc/hostname; then
        success "/etc/hostname updated."
    else
        error "Failed to update /etc/hostname."
        return 1
    fi

    # Fix /etc/hosts
    if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts; then

        sed -i \
        "s/^127\.0\.1\.1[[:space:]].*/127.0.1.1    $NEW_HOSTNAME/" \
        /etc/hosts

    else

        echo "127.0.1.1    $NEW_HOSTNAME" >> /etc/hosts

    fi

    success "/etc/hosts updated."

    echo
    success "Hostname successfully changed."
    info "New hostname: ${BOLD_CYAN}$(hostname)${NC}"
}

# ---------- STATUS ----------

show_status() {

    clear
    box_top
    box_line "SYSTEM STATUS"
    box_bottom
    echo

    step "Gathering status..."
    sleep 0.3
    echo

    echo -e "  ${BOLD_MAGENTA}Hostname${NC}"
    echo -e "    $(hostname)"
    echo

    ROOT_STATUS=$(sshd -T 2>/dev/null | awk '$1=="permitrootlogin" {print $2}')
    PASSWORD_STATUS=$(sshd -T 2>/dev/null | awk '$1=="passwordauthentication" {print $2}')

    echo -e "  ${BOLD_MAGENTA}SSH${NC}"

    if [ "$ROOT_STATUS" = "yes" ]; then
        success "Root login: ENABLED"
    else
        error "Root login: DISABLED"
    fi

    if [ "$PASSWORD_STATUS" = "yes" ]; then
        success "Password login: ENABLED"
    else
        error "Password login: DISABLED"
    fi

    echo

    if systemctl is-active --quiet ssh; then
        success "SSH service: RUNNING"
    else
        error "SSH service: NOT RUNNING"
    fi

    echo
}

# ---------- MAIN MENU ----------

splash_screen

while true; do

    clear

    box_top
    box_line "AWS VPS SETUP PANEL"
    box_bottom
    echo
    echo -e "  ${DIM}Hostname:${NC} ${BOLD}$(hostname)${NC}"
    echo

    ROOT_STATUS=$(sshd -T 2>/dev/null | awk '$1=="permitrootlogin" {print $2}')
    PASSWORD_STATUS=$(sshd -T 2>/dev/null | awk '$1=="passwordauthentication" {print $2}')

    if [ "$ROOT_STATUS" = "yes" ] && [ "$PASSWORD_STATUS" = "yes" ]; then
        success "Root SSH Login: ENABLED"
    else
        warning "Root SSH Login: NOT FULLY ENABLED"
    fi

    echo
    separator
    echo
    echo -e "  ${BOLD_CYAN}1${NC}) Enable ROOT Login"
    echo -e "  ${BOLD_CYAN}2${NC}) Change HOSTNAME"
    echo -e "  ${BOLD_CYAN}3${NC}) ROOT Login + HOSTNAME"
    echo -e "  ${BOLD_CYAN}4${NC}) Show Status"
    echo -e "  ${BOLD_RED}0${NC}) Exit"
    echo
    separator
    echo

    safe_read "$(echo -e "  ${YELLOW}Select an option [0-4]:${NC} ")" OPTION

    case "$OPTION" in

        1)
            enable_root
            pause_screen
            ;;

        2)
            change_hostname
            pause_screen
            ;;

        3)
            enable_root
            echo
            change_hostname
            pause_screen
            ;;

        4)
            show_status
            pause_screen
            ;;

        0)
            clear
            progress_bar 3 "Cleaning up" "Closing SSH checks" "Goodbye"
            echo
            success "Exiting AWS VPS Setup Panel."
            echo
            exit 0
            ;;

        *)
            error "Invalid option."
            sleep 1.2
            ;;

    esac

done
