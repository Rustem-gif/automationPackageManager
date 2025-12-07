#!/usr/bin/env bash

# ───────────────────────── Colors ─────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ───────────────────── Repo configuration ─────────────────
# Format: "FolderName|GitURL"
REPOS=(
  "NewTR|https://github.com/Rustem-gif/NewTR.git"
  "KB_Regression|https://github.com/RUSTEMATOR/KB_Regression.git"
  "depositModalMonitor|https://github.com/RUSTEMATOR/depositModalMonitor.git"
  "Unpublish|https://github.com/RUSTEMATOR/Unpublish.git"
)

# Default base directory (user can change from menu)
BASE_DIR="${HOME}/Desktop/automation"

# ───────────────────────── Helpers ────────────────────────

banner() {
    clear
    echo -e "${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${CYAN}┃${MAGENTA}   📦 KB PACKAGE MANAGER · REPO INSTALLER CLI        ${CYAN}┃${NC}"
    echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo
    echo -e "${YELLOW}Base install directory:${NC} ${CYAN}${BASE_DIR}${NC}"
    echo
}

ensure_base_dir() {
    if [ ! -d "$BASE_DIR" ]; then
        mkdir -p "$BASE_DIR" || {
            echo -e "${RED}Failed to create base directory '${BASE_DIR}'.${NC}"
            return 1
        }
    fi
}

# Clone if missing, otherwise git pull
clone_or_update_repo() {
    local name="$1"
    local url="$2"
    local target="${BASE_DIR}/${name}"

    ensure_base_dir || return 1

    if [ -d "$target/.git" ]; then
        echo -e "${YELLOW}→ Updating existing repo ${CYAN}${name}${YELLOW} in ${CYAN}${target}${YELLOW}...${NC}"
        (cd "$target" && git pull --ff-only)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ Updated ${name}${NC}"
        else
            echo -e "${RED}✖ Failed to update ${name}${NC}"
        fi
    elif [ -d "$target" ]; then
        echo -e "${RED}✖ Directory '${target}' exists but is not a git repo. Skipping.${NC}"
    else
        echo -e "${YELLOW}→ Cloning ${CYAN}${name}${YELLOW} into ${CYAN}${target}${YELLOW}...${NC}"
        git clone "$url" "$target"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ Successfully cloned ${name}${NC}"
        else
            echo -e "${RED}✖ Failed to clone ${name}${NC}"
        fi
    fi
}

# Detect and install dependencies inside a repo folder
install_deps_for_repo() {
    local name="$1"
    local repo_dir="${BASE_DIR}/${name}"

    if [ ! -d "$repo_dir" ]; then
        echo -e "${RED}✖ Repo '${name}' is not installed in '${BASE_DIR}'.${NC}"
        return 1
    fi

    echo -e "${YELLOW}→ Installing dependencies for ${CYAN}${name}${YELLOW}...${NC}"

    # Node / JS projects
    if [ -f "${repo_dir}/package.json" ]; then
        local pm=""
        if [ -f "${repo_dir}/pnpm-lock.yaml" ]; then
            pm="pnpm"
        elif [ -f "${repo_dir}/yarn.lock" ]; then
            pm="yarn"
        else
            pm="npm"
        fi

        echo -e "${BLUE}  Detected Node project. Using '${pm} install'.${NC}"
        (cd "$repo_dir" && "$pm" install)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ Dependencies installed for ${name}${NC}"
        else
            echo -e "${RED}✖ Failed to install dependencies for ${name}${NC}"
        fi
        return
    fi

    # Python (optional, in case you add such repos later)
    if [ -f "${repo_dir}/requirements.txt" ]; then
        echo -e "${BLUE}  Detected Python project (requirements.txt). Using 'pip install -r'.${NC}"
        (cd "$repo_dir" && pip install -r requirements.txt)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ Python dependencies installed for ${name}${NC}"
        else
            echo -e "${RED}✖ Failed to install Python dependencies for ${name}${NC}"
        fi
        return
    fi

    echo -e "${YELLOW}⚠ No known dependency configuration found for ${name}.${NC}"
    echo -e "${YELLOW}  (No package.json or requirements.txt detected.)${NC}"
}

list_installed() {
    ensure_base_dir || return 1

    echo -e "${CYAN}Installed status in ${BASE_DIR}:${NC}"
    echo

    for entry in "${REPOS[@]}"; do
        IFS='|' read -r name url <<< "$entry"
        local dir="${BASE_DIR}/${name}"
        if [ -d "$dir/.git" ]; then
            echo -e "  ${GREEN}[✔]${NC} ${name}  ${BLUE}(${dir})${NC}"
        elif [ -d "$dir" ]; then
            echo -e "  ${YELLOW}[~]${NC} ${name}  (directory exists, but not a git repo)"
        else
            echo -e "  ${RED}[ ]${NC} ${name}  (not installed)"
        fi
    done
    echo
}

change_base_dir() {
    echo -e "${YELLOW}Current base directory:${NC} ${CYAN}${BASE_DIR}${NC}"
    read -rp "Enter new base directory path: " newdir
    if [ -z "$newdir" ]; then
        echo -e "${RED}No directory entered. Keeping current base directory.${NC}"
        return
    fi

    # Expand leading ~
    newdir="${newdir/#\~/$HOME}"
    BASE_DIR="$newdir"
    ensure_base_dir || return 1
    echo -e "${GREEN}✔ Base directory updated to:${NC} ${CYAN}${BASE_DIR}${NC}"
}

update_script() {
    local script_path="${BASH_SOURCE[0]}"
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    local script_name="$(basename "$script_path")"
    
    echo -e "${YELLOW}→ Checking for script updates...${NC}"
    echo -e "${BLUE}Script location: ${script_dir}/${script_name}${NC}"
    
    # Check if we're in a git repository
    if ! git -C "$script_dir" rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}✖ This script is not in a git repository.${NC}"
        echo -e "${YELLOW}  Cannot auto-update. Please update manually.${NC}"
        return 1
    fi
    
    # Save current branch
    local current_branch=$(git -C "$script_dir" rev-parse --abbrev-ref HEAD)
    
    # Fetch latest changes
    echo -e "${YELLOW}→ Fetching latest changes...${NC}"
    git -C "$script_dir" fetch origin
    
    # Check if there are updates
    local local_commit=$(git -C "$script_dir" rev-parse HEAD)
    local remote_commit=$(git -C "$script_dir" rev-parse origin/$current_branch 2>/dev/null)
    
    if [ -z "$remote_commit" ]; then
        echo -e "${RED}✖ Could not find remote branch.${NC}"
        return 1
    fi
    
    if [ "$local_commit" = "$remote_commit" ]; then
        echo -e "${GREEN}✔ Script is already up to date!${NC}"
        return 0
    fi
    
    # Pull updates
    echo -e "${YELLOW}→ Updating script...${NC}"
    if git -C "$script_dir" pull --ff-only origin "$current_branch"; then
        echo -e "${GREEN}✔ Script successfully updated!${NC}"
        echo -e "${CYAN}  Please restart the script to use the new version.${NC}"
        read -rp "Restart now? [Y/n]: " restart
        if [[ "$restart" =~ ^[Yy]?$ ]]; then
            echo -e "${MAGENTA}Restarting script...${NC}"
            exec "$script_path"
        fi
    else
        echo -e "${RED}✖ Failed to update script.${NC}"
        echo -e "${YELLOW}  You may have local changes. Please update manually.${NC}"
        return 1
    fi
}

# ─────────────────────── Menu / UI ────────────────────────

show_menu() {
    banner
    echo -e "${GREEN}1)${NC} Clone / update NewTR"
    echo -e "${GREEN}2)${NC} Clone / update KB_Regression"
    echo -e "${GREEN}3)${NC} Clone / update depositModalMonitor"
    echo -e "${GREEN}4)${NC} Clone / update Unpublish"
    echo -e "${MAGENTA}5)${NC} Clone / update ALL repositories"
    echo -e "${GREEN}6)${NC} Install dependencies for a single repo"
    echo -e "${GREEN}7)${NC} Install dependencies for ALL installed repos"
    echo -e "${GREEN}8)${NC} List installed repositories"
    echo -e "${YELLOW}9)${NC} Change base install directory"
    echo -e "${BLUE}u)${NC} Update this script"
    echo -e "${RED}0)${NC} Exit"
    echo
    echo -n "Please choose an option [0-9/u]: "
}

choose_repo_interactive() {
    echo
    echo -e "${GREEN}Select a repo:${NC}"

    # Local array to map numeric choice -> repo name
    local -a REPO_NAMES=()
    local i=1

    for entry in "${REPOS[@]}"; do
        IFS='|' read -r name url <<< "$entry"
        echo -e "  ${GREEN}${i})${NC} ${name}"
        REPO_NAMES[$i]="$name"
        ((i++))
    done

    local max=$((i-1))
    echo -n "Enter choice [1-${max}]: "
    read -r idx

    # Basic numeric validation
    if [ -z "$idx" ]; then
        echo -e "${RED}No choice entered.${NC}"
        return 1
    fi
    # Is it a number?
    case "$idx" in
        *[!0-9]*)
            echo -e "${RED}Invalid input (not a number).${NC}"
            return 1
            ;;
    esac
    # Range check
    if [ "$idx" -lt 1 ] || [ "$idx" -gt "$max" ]; then
        echo -e "${RED}Invalid repo choice.${NC}"
        return 1
    fi

    # Export selection via a global variable
    SELECTED_NAME="${REPO_NAMES[$idx]}"
    return 0
}

# ─────────────────────── Main loop ────────────────────────

while true; do
    show_menu
    read -r choice

    case "$choice" in
        1)
            clone_or_update_repo "NewTR" "https://github.com/Rustem-gif/NewTR.git"
            ;;
        2)
            clone_or_update_repo "KB_Regression" "https://github.com/RUSTEMATOR/KB_Regression.git"
            ;;
        3)
            clone_or_update_repo "depositModalMonitor" "https://github.com/RUSTEMATOR/depositModalMonitor.git"
            ;;
        4)
            clone_or_update_repo "Unpublish" "https://github.com/RUSTEMATOR/Unpublish.git"
            ;;
        5)
            for entry in "${REPOS[@]}"; do
                IFS='|' read -r name url <<< "$entry"
                clone_or_update_repo "$name" "$url"
                echo
            done
            ;;
        6)
            choose_repo_interactive
            if [ $? -eq 0 ] && [ -n "$SELECTED_NAME" ]; then
                install_deps_for_repo "$SELECTED_NAME"
            else
                echo
                echo -e "${YELLOW}No repo selected. Returning to menu.${NC}"
            fi
            ;;

        7)
            for entry in "${REPOS[@]}"; do
                IFS='|' read -r name url <<< "$entry"
                install_deps_for_repo "$name"
                echo
            done
            ;;
        8)
            list_installed
            ;;
        9)
            change_base_dir
            ;;
        u|U)
            update_script
            ;;
        0)
            echo -e "${MAGENTA}Exiting package manager...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac

    echo
    read -rp "Press [Enter] to return to menu..." _
done

