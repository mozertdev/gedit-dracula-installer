#!/usr/bin/env bash

################################################################################
#
# MIT License
#
# Copyright (c) 2025 - gedit-dracula-installer (gdt_installer) [mozertdev]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
################################################################################
#
# DISCLAIMER: This project is an independent installation utility and is
# NOT affiliated, endorsed, or sponsored by the official developers
# or maintainers of the main project.
#
# It is provided solely as a convenience tool to simplify the installation
# and setup process.
#
################################################################################
#
# --- Acknowledgments ---
#
# This script is a simple automation tool designed to install the beautiful
# Dracula theme for Gedit.
#
# The Dracula theme is an independent project created and maintained by
# Ricardo Madriz, Zeno Rocha, Ali Vakilzade, Benjamin Reynolds and the dedicated
# contributors of the Dracula community.
#
# PROJECT CREATORS: Ricardo Madriz, Zeno Rocha and the Dracula Theme
#                   Contributors.
#
# OFFICIAL LINKS:
#   GitHub Repository: https://github.com/dracula/gedit
#   Official Website:  https://draculatheme.com/gedit
#
# Thank you for creating this amazing theme!
#
################################################################################
#
# Gedit Dracula Theme Installer (gdt_installer)
#
# DESCRIPTION:
# This script automates the installation of the Dracula theme for the Gedit text
# editor. It performs connectivity checks, downloads the necessary theme files
# (for both legacy and modern versions of Gedit), and attempts to install them
# in **all standard user configuration directories** for
# **system-native installations** (old and new paths), **Flatpak**, and
# **Snap** installations.
#
# AUTHOR: Mozert M. Ramalho (mozertdev)
# DATE: 2025/10/28
# LICENSE: MIT (See LICENSE file for details)
#
# GITHUB REPOSITORY: https://github.com/mozertdev/gedit-dracula-installer
#
# Dependencies: curl, cp, mkdir, cat, rm, command, dirname, readlink
#
################################################################################
#
# --- How to Use ---
#
# Follow these steps to run the gdt_installer.sh script.
#
# 1. GRANT execution permission:
#    (This step allows the script to be executed)
#    $ chmod +x gdt_installer.sh
#
# 2. RUN the script:
#    (Execute the script with the './' prefix)
#    $ ./gdt_installer.sh
#
# The script will automatically check for connectivity, download the theme files
# and attempt to install the theme in all known Gedit configuration paths:
# (System/Native 'Legacy < v46 and Modern >= v46', Flatpak 'Modern >= v46',
# and Snap 'Modern >= v46').
#
################################################################################


# Set flags:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: Fail if any command in a pipeline fails.
set -euo pipefail

### --- Dependences ---

# curl check
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' command not found."
    echo "Please install 'curl' and run the script again."
    exit 1
fi

# dirname check
if ! command -v dirname &> /dev/null; then
    echo "Error: 'dirname' command not found."
    echo "Please install 'dirname' and run the script again."
    exit 1
fi

# readlink check
if ! command -v readlink &> /dev/null; then
    echo "Error: 'readlink' command not found."
    echo "Please install 'readlink' and run the script again."
    exit 1
fi

### --- Constants ---

## Text
ASCII_TITLE=$(cat <<'END_OF_TITLE'
  __                                   
 /__  _   _| o _|_                     
 \_| (/_ (_| |  |_                     
                | \ ._ _.  _     |  _. 
            ___ |_/ | (_| (_ |_| | (_| 
             | |_   _  ._ _   _        
  ___       _| |_| (/_ | | | (/_ _     
   |  |\ | (_   |  /\  |  |  |_ |_)    
  _|_ | \| __)  | /--\ |_ |_ |_ | \    
                                       
END_OF_TITLE
)

DISCLAIMER=$(cat <<'EOF_DISCLAIMER'
================================================================================
  DISCLAIMER: This project is an independent installation utility and is
  NOT affiliated, endorsed, or sponsored by the official developers
  or maintainers of the main project.

  It is provided solely as a convenience tool to simplify the installation
  and setup process.
================================================================================
EOF_DISCLAIMER
)

## Theme file names and remote URL base
THEME_FILE_NAME="dracula.xml"
THEME_FILE_NAME_V46="dracula-46.xml"
THEME_URL_BASE="https://raw.githubusercontent.com/dracula/gedit/master"

## Installation directories
# Script directory
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

# Path for older Gedit versions (before ~46)
OLDER_GEDIT_DIR="$HOME/.local/share/gedit"
STYLE_DIR="$OLDER_GEDIT_DIR/styles"

# Path for modern Gedit versions (using libgedit-gtksourceview-300)
LIBGEDIT_DIR="$HOME/.local/share/libgedit-gtksourceview-300/styles"

# Path for Flatpak installation (modern versions using libgedit-gtksourceview-300)
FLATPAK_GEDIT_DIR="$HOME/.var/app/org.gnome.gedit"
FLATPAK_STYLE_DIR="$FLATPAK_GEDIT_DIR/data/libgedit-gtksourceview-300/styles"

# Path for Snap installation (modern versions using libgedit-gtksourceview-300)
SNAP_GEDIT_DIR="$HOME/snap/gedit/current"
SNAP_STYLE_DIR="$SNAP_GEDIT_DIR/libgedit-gtksourceview-300/styles"

### --- Functions ---

# check_connectivity()
#
# Verifies internet connectivity by attempting to reach an external website (GitHub) via curl.
# This check relies on HTTP/HTTPS access, which is required for theme file downloads.
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: HTTP connection established.
#   1 - Failure: Failed to connect to the internet.
check_connectivity() {
    local test_url="https://www.google.com/"
    local timeout=5
    
    echo "Checking internet connectivity..."
    
    if curl -s -o /dev/null --max-time "$timeout" "$test_url"; then
        echo "Internet connection established."
        return 0
    else
        echo "Error: Failed to connect to the internet."
        echo "Please check your network connection."
        return 1
    fi
}

# countdown()
#
# Displays a visible countdown to the user before continuing script execution.
# This is used to respect external rate limits (e.g., GitHub's API).
#
# Arguments:
#   $1 - seconds: The number of seconds to wait.
countdown() {
    local seconds="$1"
    
    echo -n "Waiting $seconds seconds to respect GitHub's rate limits: "
    
    for ((i = seconds; i > 0; i----)); do
        echo -ne " $i\r"
        sleep 1
    done
    echo -e "Wait complete.      "
}

# download_theme_file()
#
# Downloads a single Gedit theme file from a remote URL only if it does not
# already exist locally. This function relies on the global variables
# $THEME_URL_BASE and $SCRIPT_DIR being set in the script's environment.
# It attempts to handle common HTTP errors, particularly the 429 Rate Limit.
#
# Arguments:
#   $1 - theme_file_name: The name of the XML theme file (e.g., "dracula.xml").
#
# Returns:
#   0 - Success: File already exists, or was successfully downloaded (HTTP 200).
#   1 - Failure: Download failed due to a non-200 HTTP status (e.g., 404, 429).
download_theme_file() {
    local theme_file_name="$1"
    
    local theme_url="$THEME_URL_BASE/$theme_file_name"
    local local_path="$SCRIPT_DIR/$theme_file_name"
    local http_status="000"
    
    if [ -f "$local_path" ]; then
        return 0
    fi
    
    echo "Downloading theme file ($theme_file_name) from $THEME_URL_BASE..."
    
    http_status=$(
        curl -L -s -w "%{http_code}" -o "$local_path" "$theme_url"
    )
    
    if [ "$http_status" == "200" ]; then
        echo "Dracula theme ($theme_file_name) successfully downloaded at $SCRIPT_DIR."
        return 0
    elif [ "$http_status" == "429" ]; then
        echo "Rate Limit Exceeded (429) for $theme_file_name."
        rm -f "$local_path"
        return 1
    elif [ "$http_status" == "404" ]; then
        echo "Error: File not found (404) at $theme_url."
        rm -f "$local_path"
        return 1
    else
        echo "Error: Failed to download theme ($theme_file_name). URL returned status code $http_status."
        rm -f "$local_path"
        return 1
    fi
}

# check_theme_files()
#
# Ensures that both the modern and legacy Gedit theme files are available
# in the local script directory, downloading them if necessary.
#
# It relies on the global functions/variables:
#   - download_theme_file()
#   - THEME_FILE_NAME
#   - THEME_FILE_NAME_V46
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Both theme files are available.
#   1 - Failure: At least one theme file failed to download or is unavailable.
check_theme_files() {
    echo "Checking theme files..."
    
    if [[ -f "$SCRIPT_DIR/$THEME_FILE_NAME" && -f "$SCRIPT_DIR/$THEME_FILE_NAME_V46" ]]; then
        echo "Theme files ready."
        return 0
    fi
    
    if ! download_theme_file "$THEME_FILE_NAME"; then
        return 1
    fi
    
    countdown 10
    
    if ! download_theme_file "$THEME_FILE_NAME_V46"; then
        return 1
    fi
    
    echo "Theme files ready."
    return 0
}

# install_gdt_for_system_old_gedit()
#
# Attempts to install the Dracula theme for older, system/native Gedit versions
# (typically using GtkSourceView 2/3, before v46).
#
# It relies on the global variables: STYLE_DIR, THEME_FILE_NAME, and SCRIPT_DIR.
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Theme installed, or theme already exists.
#   1 - Failure: 'gedit' command is not found, or directory creation/file copy failed.
install_gdt_for_system_old_gedit() {
    if ! command -v gedit &> /dev/null; then
        return 1
    fi
    
    echo -e "\n::: System/Native - Legacy Gedit Dracula Theme Version '< v46' :::"
    echo "Trying installation in $STYLE_DIR (Legacy Gedit Version '< v46')..."

    if [ -f "$STYLE_DIR/$THEME_FILE_NAME" ]; then
        echo "It is already installed. Trying next option..."
        return 0
    fi

    mkdir -p "$STYLE_DIR" || { echo "Error creating directory $STYLE_DIR."; return 1; }

    if cp "$SCRIPT_DIR/$THEME_FILE_NAME" "$STYLE_DIR/$THEME_FILE_NAME"; then
        echo "SUCCESS: Dracula theme ($THEME_FILE_NAME) successfully installed at $STYLE_DIR."
        return 0
    else
        echo "Failed to install theme in $STYLE_DIR (Copy failed). Trying next option..."
        return 1
    fi
}

# install_gdt_for_system_modern_gedit()
#
# Attempts to install the Dracula theme for modern, system/native Gedit versions
# (typically Gedit v46 and above, using libgedit-gtksourceview-300).
#
# It relies on the global variables: LIBGEDIT_DIR, THEME_FILE_NAME_V46, and SCRIPT_DIR.
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Theme installed, or theme already exists.
#   1 - Failure: 'gedit' command is not found, or directory creation/file copy failed.
install_gdt_for_system_modern_gedit() {
    if ! command -v gedit &> /dev/null; then
        return 1
    fi
    
    echo -e "\n::: System/Native - Modern Gedit Dracula Theme Version - libgedit '>= v46' :::"
    echo "Trying installation in $LIBGEDIT_DIR (Modern Gedit Version - libgedit '>= v46')..."
    
    if [ -f "$LIBGEDIT_DIR/$THEME_FILE_NAME_V46" ]; then
        echo "It is already installed. Trying next option..."
        return 0
    fi

    mkdir -p "$LIBGEDIT_DIR" || { echo "Error creating directory $LIBGEDIT_DIR."; return 1; }

    if cp "$SCRIPT_DIR/$THEME_FILE_NAME_V46" "$LIBGEDIT_DIR/$THEME_FILE_NAME_V46"; then
        echo "SUCCESS: Dracula theme ($THEME_FILE_NAME_V46) successfully installed at $LIBGEDIT_DIR."
        return 0
    else
        echo "Failed to install theme in $LIBGEDIT_DIR (Copy failed). Trying next option..."
        return 1
    fi
}

# install_gdt_for_flatpak_modern_gedit()
#
# Attempts to install the Dracula theme for Gedit installed via Flatpak.
# This targets the modern Gedit version path specific to Flatpak environments.
#
# It relies on the global variables: FLATPAK_GEDIT_DIR, FLATPAK_STYLE_DIR, 
# THEME_FILE_NAME_V46, and SCRIPT_DIR.
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Theme installed, or theme already exists.
#   1 - Failure: Flatpak Gedit base directory is not found, or directory creation/file copy failed.
install_gdt_for_flatpak_modern_gedit() {
    if [ ! -d "$FLATPAK_GEDIT_DIR" ]; then
        return 1
    fi
    echo -e "\n::: Flatpak - Modern Gedit Dracula Theme Version - libgedit '>= v46' :::"
    echo "Trying Flatpak installation in $FLATPAK_STYLE_DIR (Modern Gedit Version - libgedit '>= v46')..."

    if [ -f "$FLATPAK_STYLE_DIR/$THEME_FILE_NAME_V46" ]; then
        echo "It is already installed. Trying next option..."
        return 0
    fi

    mkdir -p "$FLATPAK_STYLE_DIR" || { echo "Error creating directory $FLATPAK_STYLE_DIR."; return 1; }

    if cp "$SCRIPT_DIR/$THEME_FILE_NAME_V46" "$FLATPAK_STYLE_DIR/$THEME_FILE_NAME_V46"; then
        echo "SUCCESS: Dracula theme ($THEME_FILE_NAME_V46) successfully installed in $FLATPAK_STYLE_DIR."
        return 0
    else
        echo "Failed to install theme in $FLATPAK_STYLE_DIR. Trying next option..."
        return 1
    fi
}

# install_gdt_for_snap_modern_gedit()
#
# Attempts to install the Dracula theme for Gedit installed via **Snap**.
# This targets the modern Gedit version path (>= v46) specific to Snap
# environments, typically using libgedit-gtksourceview-300.
#
# NOTE: Due to the nature of Snap's sandboxing and updates, the theme may need
# to be reinstalled after a Gedit Snap update.
#
# It relies on the global variables: SNAP_GEDIT_DIR, SNAP_STYLE_DIR, 
# THEME_FILE_NAME_V46, and SCRIPT_DIR.
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Theme installed, or theme already exists.
#   1 - Failure: Snap Gedit base directory is not found, or directory creation/file copy failed.
install_gdt_for_snap_modern_gedit() {
    if [ ! -d "$SNAP_GEDIT_DIR" ]; then
        return 1
    fi
    echo -e "\n::: Snap - Modern Gedit Dracula Theme Version - libgedit '>= v46' :::"
    echo "Trying Snap installation in $SNAP_STYLE_DIR (Modern Gedit Version - libgedit '>= v46')..."

    if [ -f "$SNAP_STYLE_DIR/$THEME_FILE_NAME_V46" ]; then
        echo "It is already installed."
        return 0
    fi

    mkdir -p "$SNAP_STYLE_DIR" || { echo "Error creating directory $SNAP_STYLE_DIR."; return 1; }

    if cp "$SCRIPT_DIR/$THEME_FILE_NAME_V46" "$SNAP_STYLE_DIR/$THEME_FILE_NAME_V46"; then
        echo "SUCCESS: Dracula theme ($THEME_FILE_NAME_V46) successfully installed in $SNAP_STYLE_DIR."
        return 0
    else
        echo "Failed to install theme in $SNAP_STYLE_DIR."
        return 1
    fi
}

### --- Main Logic ---

# main()
#
# Main entry point for the installation utility.
# It performs pre-flight checks (connectivity and theme file readiness) and
# attempts theme installation in all known Gedit locations (Legacy, Modern Native, Flatpak).
#
# It relies on the global functions/variables:
#   - check_connectivity()
#   - check_theme_files()
#   - install_gdt_for_system_old_gedit()
#   - install_gdt_for_system_modern_gedit()
#   - install_gdt_for_flatpak_modern_gedit()
#   - ASCII_TITLE, DISCLAIMER, STYLE_DIR, LIBGEDIT_DIR, FLATPAK_STYLE_DIR
#
# Parameters:
#   None
#
# Returns:
#   0 - Success: Installation attempts completed (even if only one was successful).
#   1 - Failure: Required pre-flight checks (connectivity or file check) failed, halting installation.
main(){
    # Title
    echo "$ASCII_TITLE"
    echo "$DISCLAIMER"
    echo -e "\n--- Pre-flight Checks ---\n"

    # Connectivity check
    if ! check_connectivity; then
        exit 1
    fi

    # Theme files check
    if ! check_theme_files; then
        exit 1
    fi

    echo -e "\n--- Installation Attempts ---"
    INSTALLED=0
    
    # Installation for older Gedit versions (< 46, system/native install)
    if install_gdt_for_system_old_gedit; then
        INSTALLED=1
    fi

    # Installation for modern Gedit (>= 46, system/native install)
    if install_gdt_for_system_modern_gedit; then
        INSTALLED=1
    fi

    # Installation for Flatpak Gedit 'modern' (>= 46)
    if install_gdt_for_flatpak_modern_gedit; then
        INSTALLED=1
    fi

    # Installation for Snap Gedit 'modern' (>= 46)
    if install_gdt_for_snap_modern_gedit; then
        INSTALLED=1
    fi

# Final Result
    echo -e "\n--- Summary ---"
    if [ "$INSTALLED" -eq 1 ]; then
        cat << EOF

SUCCESS: Gedit Dracula Theme installation complete!

To activate the theme:
1 - Open Gedit;
2 - Click on the menu button (hamburger icon);
3 - Click on 'Preferences';
4 - Click on 'Fonts & Colors' tab;
5 - Select the 'Dracula' theme.

FOR SNAP GEDIT USERS:
    Due to Snap's sandboxing, the theme is deleted with every Gedit update.
    - To keep using Snap, simply re-run 'gtd_installer.sh' after every Gedit update.
    - ALTERNATIVE*: 
        To avoid reinstallation, switch to the Flatpak or native package manager version of Gedit.
        Uninstall the Snap version > install the alternative > run 'gtd_installer.sh' one final time.
EOF
    else
        cat << EOF

FAILED: Installation failed in all possible directories.

Please verify your Gedit installation path and try again.
If you are having difficulties downloading/installing the theme try install it manually:
- Download it directly from the official Github repository: https://github.com/dracula/gedit
- Or from official website: https://draculatheme.com/gedit
- Follow 'INSTALL.md' instructions of https://github.com/dracula/gedit or
  see 'README.md' Troubleshooting section of gdt_installer.

TIPS:

      If you installed Gedit (< v46) from your Linux distribution repository:
      Install '$THEME_FILE_NAME' in $STYLE_DIR

      If you installed Gedit (>= v46) from your Linux distribution repository:
      Install '$THEME_FILE_NAME_V46' in $LIBGEDIT_DIR

      If you installed Gedit (>= v46) from Flatpak:
      Install '$THEME_FILE_NAME_V46' in $FLATPAK_STYLE_DIR
      
      If you installed Gedit (>= v46) from Snap:
      Install '$THEME_FILE_NAME_V46' in $SNAP_STYLE_DIR
        Due to Snap's sandboxing, the theme is deleted with every Gedit update.
        - To keep using Snap, simply re-run 'gtd_installer.sh' after every Gedit update.
        - ALTERNATIVE*:
            To avoid reinstallation, switch to the Flatpak or native package manager version of Gedit.
            Uninstall the Snap version > install the alternative > run 'gtd_installer.sh' one final time.

      FOR ALL METHODS ACTIVATE THE DRACULA THEME IN GEDIT:
      Open Gedit > Navigate to 'Preferences' > Go to the 'Fonts & Colors' tab > Select 'Dracula' from the list.
EOF
    fi

    echo -e "\n---"
}

### --- Execute the main function ---
main
