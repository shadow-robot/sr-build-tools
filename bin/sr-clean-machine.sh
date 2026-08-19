#!/bin/bash
# Copyright 2024 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

set -e
set -u

# Set the script to run in auto mode
AUTO_RUN=false

# Define color escape codes
GREEN='\e[0;32m'
RED='\e[0;31m'
RESET='\e[0m'
YELLOW='\e[1;33m'

# Print green text function
print_green() {
    echo -e "${GREEN}$1${RESET}"
}

# Print red text function
print_red() {
    echo -e "${RED}$1${RESET}"
}

# Print yellow text function
print_yellow() {
    echo -e "${YELLOW}$1${RESET}"
}

# Check for sudo
check_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        print_red "sudo is required but not installed. Exiting."
        exit 1
    fi
}

# Argument parsing
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  -h, --help          Show this help message and exit"
            echo "  -a, --auto          Run the script in automatic mode without prompts"
            echo ""
            echo "Warning: Running in automatic mode will execute all cleaning operations without confirmation prompts. This may delete important directories and files!"
            exit 0
            ;;
        -a|--auto)
            AUTO_RUN=true
            ;;
    esac
done

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-[y/N]} " response
    case "$response" in
    [yY][eE][sS] | [yY])
        echo "y"
        return 0
        ;;
    *)
        echo "n"
        return 1
        ;;
    esac
}

clean_aws() {
    # Double check its okay to remove AWS creds
    if $AUTO_RUN || confirm "Remove AWS Creds (y/N) "; then
        if [ -f "$HOME/.aws/credentials" ]; then
            rm "$HOME/.aws/credentials"
            print_green "----------AWS creds removed----------"
        else
            print_yellow "----------AWS Creds not found---------"
        fi
    else
        print_red "----------AWS Skipped----------"
    fi
}

clean_chrome() {
    # Double check its okay to remove contents of chrome
    if $AUTO_RUN || confirm "Remove chrome logins, history and cookies, this will kill the chrome process (y/N) "; then
        if [ -d "$HOME/.cache/google-chrome/" ]; then
            rm -rf "$HOME/.cache/google-chrome/*"
        else
            print_yellow "----------Chrome Cache not found skipping----------"
        fi
        if [ -d "$HOME/.config/google-chrome/Default" ]; then
            rm -rf "$HOME/.config/google-chrome/Default"
        else
            print_yellow "----------Chrome Config not found skipping----------"
        fi
        print_green "----------Chrome data Cleared----------"
    else
        print_red "----------Chrome Skipped----------"
    fi
}

clean_firefox() {
    # Double check its okay to remove contents of firefox
    if $AUTO_RUN || confirm "Remove firefox logins, history and cookies, this will kill the firefox process (y/N) "; then
        if [ -d "$HOME/.mozilla/firefox" ]; then
            rm -rf "$HOME/.mozilla/firefox"
            print_green "----------Firefox data Cleared----------"
        else
            print_yellow "----------Firefox not found skipping----------"
        fi
    else
        print_red "----------Firefox Skipped----------"
    fi
}

clean_downloads() {
    # Double check its okay to remove contents of downloads
    if $AUTO_RUN || confirm "Remove contents of downloads folder (y/N) "; then
        if [ -d "$HOME/Downloads/" ]; then
            rm -rf "$HOME/Downloads/*"
            print_green "----------Downloads Cleared----------"
        else
            print_yellow "----------Downloads not found skipping----------"
        fi
    else
        print_red "----------Downloads Skipped----------"
    fi
}

clean_git(){
    if $AUTO_RUN || confirm "Clear GitHub creds (y/N) "; then
        git credential-cache exit
        git credential-cache --timeout=1 exit
        if [ -f ~/.git-credentials ]; then
            rm ~/.git-credentials
            echo "Removed ~/.git-credentials"
        fi
        echo "----------GitHub Creds Cleared---------"
    fi
}

clean_ssh() {
    # Double check its okay to remove all ssh keys
    if $AUTO_RUN || confirm "Remove all ssh keys from $HOME/.ssh (y/N) "; then
        if [ -d "$HOME/.ssh/" ]; then
            rm -rf "$HOME/.ssh/"
            print_green "----------SSH Keys Cleared----------"
        else
            print_yellow "----------ssh not found skipping----------"
        fi
    else
        print_red "----------SSH Skipped----------"
    fi
}

clean_cache() {
    check_sudo
    if $AUTO_RUN || confirm "Would you like to remove the system cache? /tmp /var/tmp /var/lib/apt/lists/ $HOME/.cache (y/N) "; then
        sudo apt clean
        sudo rm -rf /tmp/*
        sudo rm -rf /var/tmp/*
        if [ -n "$HOME" ]; then
            rm -rf "$HOME/.cache/*"
        else
            print_red "HOME variable is not set. Skipping user cache clean."
        fi
        print_green "-----------Cleared Cache-----------"
    else
        print_red "-----------Cache Skipped----------"
    fi
}

clean_history() {
    # Double check its okay to remove bash history
    if $AUTO_RUN || confirm "Clear Bash History (y/N) "; then
        history -c
        history -w
        if [ -f "$HOME/.bash_history" ]; then
            rm "$HOME/.bash_history"
        fi
        print_green "----------Bash History Cleared----------"
    else
        print_red "----------Bash History Skipped----------"
    fi
}

main() {
    print_yellow "Step 1/8"
    clean_chrome
    print_yellow "Step 2/8"
    clean_firefox
    print_yellow "Step 3/8"
    clean_downloads
    print_yellow "Step 4/8"
    clean_cache
    print_yellow "Step 5/8"
    clean_git
    print_yellow "Step 6/8"
    clean_ssh
    print_yellow "Step 7/8"
    clean_aws
    print_yellow "Step 8/8"
    clean_history
    print_green "----------Cleaning Complete----------"
}

# Prompt for script to run and check for automode
print_green "----------Delivery Cleaner----------"
if $AUTO_RUN; then
    print_green "Running in auto mode"
    if confirm "Is this correct? (y/N)"; then
        main
    else
        print_red "----------Program Terminated----------"
        exit 1
    fi
else
    if confirm "This script will clean the machine. It will remove the AWS CLI and creds, the bash history, any logged-in GitHub accounts, and perform apt autoremove.\nAre you sure you would like to continue (y/N) "; then
        main
    else
        print_red "----------Program Terminated----------"
        exit 1
    fi
fi
