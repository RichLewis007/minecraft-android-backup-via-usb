#!/usr/bin/env bash
# minecraft-android-backup-via-usb.sh
#
# Version: 1.1
# Author: Rich Lewis - GitHub @RichLewis007
#
# Minecraft Bedrock Android Backup Tool via USB (using ADB)
# =========================================================
#
# DESCRIPTION:
#   Easily backup your complete Minecraft Bedrock Edition worlds from an Android
#   device to your computer using an interactive Text User Interface (TUI).
#   The connection is made via USB cable using ADB (Android Debug Bridge), which
#   provides the elevated system permissions needed to access protected app data
#   directories on Android devices.
#
#   Why ADB and USB?
#   - Android Scoped Storage protects app data directories (including Minecraft worlds)
#   - These directories cannot be accessed through normal file browsing or MTP
#   - ADB provides system-level access to read protected directories
#   - USB connection ensures reliable, fast data transfer for large world files
#   - ADB over USB is the standard method for accessing Android app data
#
#   The script discovers all Minecraft worlds on your device, displays them with
#   their actual names (read from levelname.txt), and allows you to backup them
#   individually or all at once as full folders or as .mcworld files.
#
# FEATURES:
#   Interactive Menu System:
#     - Auto-detects available menu tools (fzf > gum > basic select)
#     - fzf: Fuzzy finder with search-as-you-type (best experience)
#     - gum: Modern terminal UI library (good experience)
#     - Basic select: Built-in bash select (works everywhere)
#
#   World Discovery & Display:
#     - Automatically finds all Minecraft worlds on your Android device
#     - Reads world names from levelname.txt files (shows actual names, not folder IDs)
#     - Retrieves access times to sort worlds by most recently played
#     - Caches world list for 5 minutes to speed up subsequent operations
#
#   Backup Options:
#     - Individual backups: Select specific worlds one at a time
#     - Bulk backups: Backup all worlds at once
#     - Two backup formats:
#       * World Folders: Complete directory structure preserved
#         - Format: <world-name>__<world-id>/
#         - Includes all world files (level.dat, levelname.txt, chunks, etc.)
#         - Useful for manual inspection, editing, or advanced use cases
#         - Preserves exact directory structure from device
#       * .mcworld Files: Zipped archives ready for Minecraft import
#         - Format: <world-name>.mcworld
#         - Standard Minecraft world archive format
#         - Can be double-clicked to import directly into Minecraft
#         - Portable single-file format
#
#   Technical Features:
#     - Automatic path detection: Tries primary Android storage path, falls back
#       to alternative paths automatically
#     - Progress indicators: Spinner animations during long operations
#     - Organized backup structure: Timestamps and descriptive folder names
#     - Cache management: Automatic expiration and manual clearing
#     - Error handling: Graceful fallbacks and clear error messages
#     - macOS integration: Automatically opens Finder to backup location
#
# REQUIREMENTS:
#   Required:
#     - ADB (Android Debug Bridge) - Install via:
#       * Homebrew: brew install android-platform-tools
#       * MacPorts: sudo port install android-platform-tools
#     - zip command (for .mcworld export) - Install via:
#       * Homebrew: brew install zip
#       * MacPorts: sudo port install zip
#     - Android device connected via USB cable
#     - USB Debugging enabled on Android device
#       (Settings > Developer Options > USB Debugging)
#
#   Optional (for enhanced menu experience):
#     - fzf: Fuzzy finder (recommended) - brew install fzf
#     - gum: Modern terminal UI - brew install gum
#     - If neither is installed, script uses basic bash select menu
#
# USAGE:
#   ./minecraft-android-backup-via-usb.sh
#
#   The script will:
#   1. Check if ADB is installed and accessible
#   2. Verify an Android device is connected via USB
#   3. Display an interactive main menu
#   4. Allow you to browse, select, and backup your Minecraft worlds
#
# CONFIGURATION:
#   These variables can be modified in the script (see Configuration section):
#
#   MINECRAFT_WORLDS_PATH:
#     Primary path to Minecraft worlds on Android device
#     Default: /storage/emulated/0/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds
#
#   MINECRAFT_WORLDS_ALT_PATH:
#     Alternative path used if primary path is not accessible
#     Default: /sdcard/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds
#
#   BACKUP_BASE_DIR:
#     Base directory where backups are saved on your computer
#     Default: ~/Downloads/Minecraft-Worlds-Backups
#
#   WORLD_LIST_CACHE_FILE:
#     Location of the cached world list file
#     Default: ${TMPDIR:-/tmp}/minecraft-worlds-cache.txt
#     Cache expires automatically after 5 minutes
#
# BACKUP DIRECTORY STRUCTURE:
#   Backups are organized by format and timestamp:
#
#   ~/Downloads/Minecraft-Worlds-Backups/
#   ├── world-folders/
#   │   └── <world-name>__<timestamp>/
#   │       └── <world-name>__<world-id>/
#   │           ├── levelname.txt
#   │           ├── level.dat
#   │           ├── world_icon.jpeg
#   │           └── ... (all world files)
#   └── mcworld-files/
#       └── <world-name>__<timestamp>/
#           ├── <world-name>.mcworld
#           └── world_icon.jpeg
#
#   Example:
#   ~/Downloads/Minecraft-Worlds-Backups/
#   ├── world-folders/
#   │   └── My-Survival-World__2024-01-15__02-30-45-PM/
#   │       └── My-Survival-World__ABC123DEF456/
#   │           └── (world files)
#   └── mcworld-files/
#       └── My-Creative-World__2024-01-15__02-30-45-PM/
#           └── My-Creative-World.mcworld
#
# HOW IT WORKS:
#   1. Path Detection:
#      - Attempts to access primary Minecraft worlds path
#      - If primary path fails, automatically tries alternative path
#      - Handles different Android storage configurations
#
#   2. World Discovery:
#      - Lists all directories in Minecraft worlds folder via ADB
#      - For each directory, reads levelname.txt to get actual world name
#      - Retrieves file access time (atime) for sorting
#      - Builds array of worlds with IDs, names, and access times
#      - Sorts worlds by access time (most recently played first)
#
#   3. Caching:
#      - World list is cached to temporary file for 5 minutes
#      - Subsequent operations use cached data if available and fresh
#      - Cache automatically expires after 5 minutes
#      - Cache can be manually cleared via menu option
#      - Cache includes world IDs and names (not file contents)
#
#   4. Backup Process:
#      World Folders:
#      - Creates timestamped directory for this backup session
#      - Sanitizes world name (replaces special chars with dashes)
#      - Uses ADB pull to copy entire world directory structure
#      - Copies world icon to backup directory if available
#
#      .mcworld Files:
#      - Pulls world to temporary directory via ADB
#      - Creates zip archive in .mcworld format
#      - Removes temporary directory after zip creation
#      - Copies world icon to backup directory if available
#
#   5. Menu Navigation:
#      - Uses pick_option() function to display menus
#      - Automatically detects best available menu tool
#      - fzf/gum: Arrow keys to navigate, type to filter
#      - Basic select: Number keys to select
#
# NOTES & BEST PRACTICES:
#   - Close Minecraft app before backing up for best consistency
#     (Prevents file locks and ensures complete backups)
#   - Keep device connected via USB during entire backup process
#   - USB Debugging must remain enabled throughout
#   - World names are sanitized for filesystem compatibility
#     (Spaces and special characters become dashes)
#   - Access time sorting may vary depending on Android version
#     (Some Android versions don't update access times reliably)
#   - Cache is per-user (stored in user's temp directory)
#   - Backups preserve exact file structure from device
#   - .mcworld files are standard Minecraft format and can be shared
#
# TECHNICAL DETAILS:
#   - Uses bash strict mode (set -euo pipefail)
#   - All ADB commands are prefixed with proper path handling
#   - Spinner implementation shows progress during long operations
#   - Error handling includes graceful fallbacks at each step
#   - File operations use safe path handling and temporary files
#   - Menu system supports both interactive and non-interactive environments
#
# TROUBLESHOOTING:
#   See README.md for comprehensive troubleshooting guide covering:
#   - ADB connection issues
#   - Device not found errors
#   - World discovery problems
#   - Cache issues
#   - Path detection failures
#   - Backup failures
#
# LICENSE:
#   MIT License - See LICENSE file or README.md for full license text
#
# CREDITS:
#   - Based on UI components from bash-ui.sh (https://github.com/RichLewis007/utils)
#   - Uses fzf/gum for enhanced menu experience (with basic fallback)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/minecraft-android-backup-via-usb.sh"

# Version
SCRIPT_VERSION="1.1"

# Configuration
ADB_BIN="adb"
MINECRAFT_WORLDS_PATH="/storage/emulated/0/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds"
BACKUP_BASE_DIR="${HOME}/Downloads/Minecraft-Worlds-Backups"
MINECRAFT_WORLDS_ALT_PATH="/sdcard/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds"


# Global variables
declare -a WORLD_LIST
declare -a WORLD_NAMES
declare -a WORLD_ACCESS_TIMES
WORLD_LIST_CACHE_FILE="${TMPDIR:-/tmp}/minecraft-worlds-cache.txt"

# ============================================================
# UI Functions (self-contained, no external dependencies)
# ============================================================

# Logging functions with colors
log_info() {
  echo "ℹ  $*" >&2
}

log_error() {
  echo "✗ ERROR: $*" >&2
}

log_warn() {
  echo "⚠  WARNING: $*" >&2
}

log_ok() {
  echo "✓ $*" >&2
}

# Confirm function - prompts user for yes/no with optional default
# Usage: confirm "Prompt" [default]
# default can be "y" or "n" (defaults to "y" if not specified)
confirm() {
  local prompt="$1"
  local default="${2:-y}"  # Default to "y" if not specified
  local response
  local prompt_suffix
  
  # Set prompt suffix based on default
  if [[ "$default" == "y" ]] || [[ "$default" == "Y" ]]; then
    prompt_suffix="[Y/n]"
  else
    prompt_suffix="[y/N]"
  fi
  
  while true; do
    printf "%s %s: " "$prompt" "$prompt_suffix" >&2
    read -r response
    # If empty response, use default
    if [[ -z "$response" ]]; then
      response="$default"
    fi
    case "$response" in
      [yY]|[yY][eE][sS]) return 0 ;;
      [nN]|[nN][oO]) return 1 ;;
      *) echo "Please answer yes or no." >&2 ;;
    esac
  done
}

# Pick option - interactive menu selection with fzf/gum/basic fallback
# Based on original implementation from ~/utils/bash-ui.sh
pick_option() {
  local prompt="$1"
  shift
  local items=("$@")
  
  if [[ ${#items[@]} -eq 0 ]]; then
    return 1
  fi
  
  # Split into header and prompt_line on first newline (if present)
  local header prompt_line
  header="${prompt%%$'\n'*}"
  if [[ "$prompt" == *$'\n'* ]]; then
    prompt_line="${prompt#*$'\n'}"
  else
    prompt_line="$prompt"
  fi
  
  # Try fzf first (best experience) - matches original implementation
  if command -v fzf >/dev/null 2>&1; then
    local fzf_header="$header"
    local fzf_prompt="$prompt_line"
    if [[ -z "$fzf_prompt" ]]; then
      fzf_prompt="$fzf_header"
    fi
    
    printf '%s\n' "${items[@]}" | fzf \
      --header="$fzf_header" \
      --prompt="${fzf_prompt} " \
      --height=100% \
      --border \
      --reverse \
      --info=hidden
    return $?
  fi
  
  # Try gum second (modern alternative)
  if command -v gum >/dev/null 2>&1; then
    local combined_header
    if [[ -n "$prompt_line" && "$prompt_line" != "$header" ]]; then
      combined_header="${header}\n${prompt_line}"
    else
      combined_header="$header"
    fi
    gum choose --header "$combined_header" -- "${items[@]}"
    return $?
  fi
  
  # Fallback to basic select menu
  echo "$prompt" >&2
  echo "" >&2
  select choice in "${items[@]}"; do
    if [[ -n "$choice" ]]; then
      echo "$choice"
      return 0
    fi
  done
}

# Run command with spinner
run_with_spinner() {
  local message="$1"
  shift
  local cmd=("$@")
  
  # Simple spinner implementation
  local spinner_chars="|/-\\"
  local pid
  local spinner_pid
  
  # Start the command in background
  "${cmd[@]}" >/dev/null 2>&1 &
  pid=$!
  
  # Show spinner while command runs
  (
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
      printf "\r%s %s" "$message" "${spinner_chars:$i:1}" >&2
      sleep 0.1
      i=$(( (i + 1) % 4 ))
    done
    printf "\r%s done\n" "$message" >&2
  ) &
  spinner_pid=$!
  
  # Wait for command to complete
  wait "$pid"
  local exit_code=$?
  
  # Stop spinner
  kill "$spinner_pid" 2>/dev/null || true
  wait "$spinner_pid" 2>/dev/null || true
  
  return $exit_code
}

# UI run page - main menu loop
ui_run_page() {
  local title="$1"
  shift
  local menu_items=("$@")
  
  while true; do
    clear
    echo "========================================="
    echo "$title"
    echo "========================================="
    echo ""
    
    # Parse menu items (format: "Display Text::handler_function")
    local display_items=()
    local handlers=()
    
    for item in "${menu_items[@]}"; do
      if [[ "$item" == *"::"* ]]; then
        local display_text="${item%%::*}"
        local handler="${item##*::}"
        display_items+=("$display_text")
        handlers+=("$handler")
      else
        display_items+=("$item")
        handlers+=("$item")
      fi
    done
    
    # Show menu and get selection
    local choice
    choice=$(pick_option "Select an option:" "${display_items[@]}")
    local exit_code=$?
    
    # Handle selection
    if [[ $exit_code -ne 0 ]] || [[ -z "$choice" ]]; then
      # User cancelled or no selection
      return 0
    fi
    
    # Find the index of the selected item
    local selected_index=-1
    for i in "${!display_items[@]}"; do
      if [[ "${display_items[$i]}" == "$choice" ]]; then
        selected_index=$i
        break
      fi
    done
    
    if [[ $selected_index -eq -1 ]]; then
      continue
    fi
    
    local handler="${handlers[$selected_index]}"
    
    # Check if it's QUIT
    if [[ "$handler" == "QUIT" ]] || [[ "$handler" == "Quit" ]] || [[ "$handler" == "quit" ]]; then
      return 0
    fi
    
    # Call the handler function
    if declare -f "$handler" >/dev/null 2>&1; then
      "$handler"
    else
      log_error "Handler function '$handler' not found"
      echo ""
      echo "Press Enter to continue..."
      read -r
    fi
  done
}

# ============================================================
# Helper Functions
# ============================================================

check_device() {
  if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
    log_error "adb not found. Install with: brew install android-platform-tools (or: sudo port install android-platform-tools)"
    return 1
  fi

  device_count=$("$ADB_BIN" devices 2>/dev/null | awk 'NR>1 && $2=="device"{count++} END{print count+0}')
  if [[ "$device_count" -lt 1 ]]; then
    log_error "No ADB device found. Connect your phone and enable USB debugging."
    return 1
  fi
  return 0
}

get_world_list() {
  WORLD_LIST=()
  WORLD_NAMES=()
  WORLD_ACCESS_TIMES=()

  log_info "Fetching world list from Android device..."
  log_info "Trying path: ${MINECRAFT_WORLDS_PATH}"
  
  # Use a simple loop approach - list all items in directory and check if they're directories
  # Try primary path first
  local worlds_raw=""
  # Use spinner but capture command output to temp file to avoid mixing with spinner output
  local temp_output=$(mktemp)
  if run_with_spinner "Listing worlds..." bash -c "\"$ADB_BIN\" shell \"for item in '${MINECRAFT_WORLDS_PATH}'/*; do [ -d \\\"\\\$item\\\" ] && basename \\\"\\\$item\\\"; done 2>/dev/null\" 2>/dev/null | tr -d '\r' > \"$temp_output\""; then
    worlds_raw=$(cat "$temp_output" 2>/dev/null || true)
  fi
  rm -f "$temp_output"
  
  if [[ -z "$worlds_raw" ]]; then
    # Try alternative path (MINECRAFT_WORLDS_ALT_PATH)
    log_info "Primary path not found, trying alternative: ${MINECRAFT_WORLDS_ALT_PATH}"
    temp_output=$(mktemp)
    if run_with_spinner "Listing worlds (alternative path)..." bash -c "\"$ADB_BIN\" shell \"for item in '${MINECRAFT_WORLDS_ALT_PATH}'/*; do [ -d \\\"\\\$item\\\" ] && basename \\\"\\\$item\\\"; done 2>/dev/null\" 2>/dev/null | tr -d '\r' > \"$temp_output\""; then
      worlds_raw=$(cat "$temp_output" 2>/dev/null || true)
      if [[ -n "$worlds_raw" ]]; then
        MINECRAFT_WORLDS_PATH="$MINECRAFT_WORLDS_ALT_PATH"
      fi
    fi
    rm -f "$temp_output"
  fi
  
  if [[ -z "$worlds_raw" ]]; then
    log_error "No worlds found in: ${MINECRAFT_WORLDS_PATH}"
    log_error "Or alternative: ${MINECRAFT_WORLDS_ALT_PATH}"
    log_warn "Make sure Minecraft is installed and has worlds."
    return 1
  fi
  
  # Parse the output line by line - convert to array and process
  # Split by newlines and process each
  local count=0
  mapfile -t world_lines < <(printf '%s\n' "$worlds_raw")
  
  log_info "Reading world names (${#world_lines[@]} worlds)..."
  for wid in "${world_lines[@]}"; do
    # Skip empty lines
    [[ -z "$wid" ]] && continue
    # Remove any trailing/leading whitespace
    wid=$(echo "$wid" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$wid" ]] && continue
    
    # Skip if it looks like an error message
    [[ "$wid" == *"No such file"* ]] && continue
    [[ "$wid" == *"Permission denied"* ]] && continue
    
    # Try to get world name from levelname.txt (this is fast, no spinner needed)
    local world_name="$wid"
    local name_file="${MINECRAFT_WORLDS_PATH}/${wid}/levelname.txt"
    local name=""
    
    # Try to read levelname.txt
    name=$("$ADB_BIN" shell "cat '${name_file}' 2>/dev/null | head -1" 2>/dev/null | tr -d '\r\n' || true)
    if [[ -n "$name" ]]; then
      # Clean up the name
      name=$(echo "$name" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      [[ -n "$name" ]] && world_name="$name"
    fi
    
    # Get access time (atime) for the world directory
    local world_path="${MINECRAFT_WORLDS_PATH}/${wid}"
    local access_time="0"
    # Try to get access time using stat via ADB
    # stat format: %X for access time (atime) in seconds since epoch
    local stat_output
    stat_output=$("$ADB_BIN" shell "stat -c %X '${world_path}' 2>/dev/null || stat -f %a '${world_path}' 2>/dev/null || echo 0" 2>/dev/null | tr -d '\r\n' || echo "0")
    if [[ "$stat_output" =~ ^[0-9]+$ ]]; then
      access_time="$stat_output"
    fi
    
    WORLD_LIST+=("$wid")
    WORLD_NAMES+=("$world_name")
    WORLD_ACCESS_TIMES+=("$access_time")
    ((count++))
  done
  
  log_info "Parsed $count world(s) from output"
  
  # Sort worlds by access time (most recently accessed first)
  # Create array of indices, sort by access time, then reorder arrays
  if [[ ${#WORLD_LIST[@]} -gt 1 ]]; then
    local temp_array=()
    local i
    for i in "${!WORLD_ACCESS_TIMES[@]}"; do
      temp_array+=("${WORLD_ACCESS_TIMES[$i]}:$i")
    done
    
    # Sort by access time (descending) - most recent first
    local sorted_pairs=()
    mapfile -t sorted_pairs < <(printf '%s\n' "${temp_array[@]}" | sort -t: -k1 -rn)
    
    local sorted_world_list=()
    local sorted_world_names=()
    local sorted_access_times=()
    
    for pair in "${sorted_pairs[@]}"; do
      local idx="${pair##*:}"
      sorted_world_list+=("${WORLD_LIST[$idx]}")
      sorted_world_names+=("${WORLD_NAMES[$idx]}")
      sorted_access_times+=("${WORLD_ACCESS_TIMES[$idx]}")
    done
    
    WORLD_LIST=("${sorted_world_list[@]}")
    WORLD_NAMES=("${sorted_world_names[@]}")
    WORLD_ACCESS_TIMES=("${sorted_access_times[@]}")
  fi

  if [[ ${#WORLD_LIST[@]} -eq 0 ]]; then
    log_warn "No worlds found after parsing. Make sure Minecraft is installed and has worlds."
    return 1
  fi

  log_info "Found ${#WORLD_LIST[@]} world(s)"
  
  # Cache the world list to temp file
  {
    echo "${#WORLD_LIST[@]}"
    for i in "${!WORLD_LIST[@]}"; do
      echo "${WORLD_LIST[$i]}"
      echo "${WORLD_NAMES[$i]}"
    done
  } > "$WORLD_LIST_CACHE_FILE"
  
  return 0
}

# Load world list from cache file (only if cache is less than 5 minutes old)
load_world_list_from_cache() {
  WORLD_LIST=()
  WORLD_NAMES=()
  WORLD_ACCESS_TIMES=()
  
  if [[ ! -f "$WORLD_LIST_CACHE_FILE" ]]; then
    return 1
  fi
  
  # Check if cache file is older than 5 minutes (300 seconds)
  local cache_age=0
  local current_time
  current_time=$(date +%s) || current_time=0
  local cache_mtime="0"
  
  # Get modification time (try macOS stat first, then Linux stat)
  if command -v stat >/dev/null 2>&1; then
    cache_mtime=$(stat -f %m "$WORLD_LIST_CACHE_FILE" 2>/dev/null || stat -c %Y "$WORLD_LIST_CACHE_FILE" 2>/dev/null || echo "0")
  fi
  
  # Ensure cache_mtime is a number
  if [[ ! "$cache_mtime" =~ ^[0-9]+$ ]]; then
    cache_mtime="0"
  fi
  
  # If we can't determine the cache age, don't trust it - delete and return failure
  if [[ "$cache_mtime" == "0" ]] || [[ "$current_time" == "0" ]]; then
    log_warn "Cannot determine cache file age, deleting cache for safety"
    rm -f "$WORLD_LIST_CACHE_FILE"
    return 1
  fi
  
  cache_age=$((current_time - cache_mtime))
  
  # If cache is older than 5 minutes, delete it and return failure
  if [[ $cache_age -gt 300 ]]; then
    log_info "Cache is ${cache_age} seconds old (expired), deleting"
    rm -f "$WORLD_LIST_CACHE_FILE"
    return 1
  fi
  
  {
    read -r count
    local i=0
    while [[ $i -lt $count ]]; do
      read -r wid || break
      read -r wname || break
      WORLD_LIST+=("$wid")
      WORLD_NAMES+=("$wname")
      ((i++))
    done
  } < "$WORLD_LIST_CACHE_FILE"
  
  if [[ ${#WORLD_LIST[@]} -eq 0 ]]; then
    log_warn "Cache file is empty or corrupted, deleting"
    rm -f "$WORLD_LIST_CACHE_FILE"
    return 1
  fi
  
  log_info "Loaded ${#WORLD_LIST[@]} world(s) from cache (age: ${cache_age}s)"
  return 0
}

timestamp_now() {
  date +"%Y-%m-%d__%I-%M-%S-%p"
}

# ============================================================
# Backup Functions
# ============================================================

backup_world_as_is() {
  local world_id="$1"
  local world_name="$2"
  
  local ts=$(timestamp_now)
  # Sanitize world name: replace spaces and special characters with dashes
  local safe_name=$(echo "$world_name" | sed 's/[^A-Za-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
  local backup_dir="${BACKUP_BASE_DIR}/world-folders/${safe_name}__${ts}"
  
  local folder_name="${safe_name}__${world_id}"
  local dest_dir="${backup_dir}/${folder_name}"
  
  mkdir -p "$dest_dir"
  
  log_info "Backing up world: $world_name"
  log_info "Destination: $dest_dir"
  
  # Pull the world directory
  local world_path="${MINECRAFT_WORLDS_PATH}/${world_id}"
  if run_with_spinner "Pulling world files..." "$ADB_BIN" pull "$world_path" "$dest_dir" >/dev/null 2>&1; then
    # Copy world_icon.jpeg to the backup folder if it exists
    # adb pull creates a subdirectory with the source directory name, so check dest_dir/world_id/world_icon.jpeg
    local icon_source="${dest_dir}/${world_id}/world_icon.jpeg"
    if [[ ! -f "$icon_source" ]]; then
      # Also try direct location in case adb pull behavior differs
      icon_source="${dest_dir}/world_icon.jpeg"
    fi
    
    if [[ -f "$icon_source" ]]; then
      cp "$icon_source" "${backup_dir}/world_icon.jpeg" 2>/dev/null || true
      log_info "Copied world icon to backup folder"
    fi
    
    log_ok "World backed up successfully!"
    log_info "Location: $dest_dir"
    
    if [[ "$(uname)" == "Darwin" ]]; then
      if confirm "Open backup location in Finder?" "y"; then
        open "$backup_dir"
      fi
    fi
  else
    log_error "Failed to backup world"
    return 1
  fi
}

backup_world_as_mcworld() {
  local world_id="$1"
  local world_name="$2"
  
  local ts=$(timestamp_now)
  # Sanitize world name for filename: replace all non-alphanumeric with dashes
  local safe_name=$(echo "$world_name" | sed 's/[^A-Za-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
  local backup_dir="${BACKUP_BASE_DIR}/mcworld-files/${safe_name}__${ts}"
  mkdir -p "$backup_dir"
  
  local out_file="${backup_dir}/${safe_name}.mcworld"
  local temp_dir="${backup_dir}/.temp_${world_id}"
  
  log_info "Exporting world: $world_name"
  log_info "Destination: $out_file"
  
  # Pull world to temp directory
  mkdir -p "$temp_dir"
  local world_path="${MINECRAFT_WORLDS_PATH}/${world_id}"
  if ! run_with_spinner "Pulling world files..." "$ADB_BIN" pull "$world_path" "$temp_dir/${world_id}" >/dev/null 2>&1; then
    log_error "Failed to pull world files"
    rm -rf "$temp_dir"
    return 1
  fi
  
  # Copy world_icon.jpeg to the backup folder if it exists
  local icon_source="${temp_dir}/${world_id}/world_icon.jpeg"
  if [[ -f "$icon_source" ]]; then
    cp "$icon_source" "${backup_dir}/world_icon.jpeg" 2>/dev/null || true
  fi
  
  # Create zip file
  if command -v zip >/dev/null 2>&1; then
    if run_with_spinner "Creating .mcworld file..." bash -c "cd '$temp_dir/${world_id}' && zip -r -q '$out_file' ."; then
      rm -rf "$temp_dir"
      log_ok "World exported successfully!"
      log_info "File: $out_file"
      
      if [[ "$(uname)" == "Darwin" ]]; then
        if confirm "Open backup location in Finder?"; then
          open "$backup_dir"
        fi
      fi
    else
      log_error "Failed to create .mcworld file"
      rm -rf "$temp_dir"
      return 1
    fi
  else
    log_error "zip command not found. Install with: brew install zip (or: sudo port install zip)"
    rm -rf "$temp_dir"
    return 1
  fi
}

# ============================================================
# Menu Handlers
# ============================================================

handler_list_worlds() {
  if ! check_device; then
    echo
    printf "Press Enter to continue..."
    read -r
    return 0  # Return 0 to return to main menu
  fi
  
  # Try to load from cache first, otherwise fetch from device
  if ! load_world_list_from_cache; then
    if ! get_world_list; then
      echo
      printf "Press Enter to continue..."
      read -r
      return 0  # Return 0 to return to main menu (not 1, which would be an error)
    fi
  fi
  
  # Loop to show world list menu until user selects "Return to main menu"
  while true; do
    # Create display names with IDs, with "Return to main menu" at the top
    local display_items=("Return to main menu")
    local i
    for i in "${!WORLD_LIST[@]}"; do
      display_items+=("${WORLD_NAMES[$i]} (${WORLD_LIST[$i]})")
    done
    
    local choice
    choice=$(pick_option "Select a world to backup:" "${display_items[@]}") || return 0
    
    # Check if user selected "Return to main menu"
    if [[ "$choice" == "Return to main menu" ]]; then
      return 0
    fi
    
    # Extract world ID from choice (account for "Return to main menu" at index 0)
    local selected_world_id=""
    local selected_world_name=""
    for i in "${!WORLD_LIST[@]}"; do
      # display_items[0] is "Return to main menu", so worlds start at index 1
      local display_index=$((i + 1))
      if [[ "${display_items[$display_index]}" == "$choice" ]]; then
        selected_world_id="${WORLD_LIST[$i]}"
        selected_world_name="${WORLD_NAMES[$i]}"
        break
      fi
    done
    
    if [[ -z "$selected_world_id" ]]; then
      log_error "Could not find selected world"
      continue
    fi
    
    # Prompt for backup type
    local backup_type
    backup_type=$(pick_option "Backup type for: $selected_world_name" \
      "Backup as world folder (full directory)" \
      "Export as .mcworld file") || continue
    
    case "$backup_type" in
      "Backup as world folder (full directory)")
        backup_world_as_is "$selected_world_id" "$selected_world_name"
        ;;
      "Export as .mcworld file")
        backup_world_as_mcworld "$selected_world_id" "$selected_world_name"
        ;;
      *)
        log_error "Unknown backup type"
        continue
        ;;
    esac
    
    echo
    printf "Press Enter to continue..."
    read -r
    # After Enter, loop continues to show world list again (from cache)
  done
}

handler_backup_all() {
  if ! check_device; then
    echo
    printf "Press Enter to continue..."
    read -r
    return 0  # Return 0 to return to main menu
  fi
  
  if ! get_world_list; then
    echo
    printf "Press Enter to continue..."
    read -r
    return 0  # Return 0 to return to main menu
  fi
  
  log_info "Backing up all worlds..."
  
  local backup_type
  backup_type=$(pick_option "Backup all worlds as:" \
    "Backup as world folders (full directories)" \
    "Export as .mcworld files") || return 0
  
  local i
  for i in "${!WORLD_LIST[@]}"; do
    local world_id="${WORLD_LIST[$i]}"
    local world_name="${WORLD_NAMES[$i]}"
    
    echo
    log_info "Processing: $world_name"
    
    case "$backup_type" in
      "Backup as world folders (full directories)")
        backup_world_as_is "$world_id" "$world_name" || log_warn "Failed to backup $world_name"
        ;;
      "Export as .mcworld files")
        backup_world_as_mcworld "$world_id" "$world_name" || log_warn "Failed to export $world_name"
        ;;
    esac
  done
  
  log_ok "All worlds processed!"
  echo
  printf "Press Enter to continue..."
  read -r
}

handler_open_backup_folder() {
  if [[ "$(uname)" == "Darwin" ]]; then
    mkdir -p "$BACKUP_BASE_DIR"
    open "$BACKUP_BASE_DIR"
    log_ok "Opened backup folder in Finder"
  else
    log_info "Backup folder: $BACKUP_BASE_DIR"
  fi
  echo
  printf "Press Enter to continue..."
  read -r
}

handler_clear_cache() {
  if [[ ! -f "$WORLD_LIST_CACHE_FILE" ]]; then
    log_info "Cache file does not exist: $WORLD_LIST_CACHE_FILE"
    echo
    printf "Press Enter to continue..."
    read -r
    return 0
  fi
  
  # Get cache file modification time and age
  local cache_mtime="0"
  local current_time
  current_time=$(date +%s) || current_time=0
  
  # Get modification time (try macOS stat first, then Linux stat)
  if command -v stat >/dev/null 2>&1; then
    cache_mtime=$(stat -f %m "$WORLD_LIST_CACHE_FILE" 2>/dev/null || stat -c %Y "$WORLD_LIST_CACHE_FILE" 2>/dev/null || echo "0")
  fi
  
  # Ensure cache_mtime is a number
  if [[ ! "$cache_mtime" =~ ^[0-9]+$ ]]; then
    cache_mtime="0"
  fi
  
  # Display cache file info
  if [[ "$cache_mtime" != "0" ]] && [[ "$current_time" != "0" ]]; then
    local cache_age=$((current_time - cache_mtime))
    local cache_date
    cache_date=$(date -r "$cache_mtime" 2>/dev/null || date -d "@$cache_mtime" 2>/dev/null || echo "unknown")
    
    log_info "Cache file: $WORLD_LIST_CACHE_FILE"
    log_info "Last modified: $cache_date"
    
    # Calculate age in human-readable format
    if [[ $cache_age -lt 60 ]]; then
      log_info "Age: ${cache_age} second(s)"
    elif [[ $cache_age -lt 3600 ]]; then
      local minutes=$((cache_age / 60))
      log_info "Age: ${minutes} minute(s)"
    elif [[ $cache_age -lt 86400 ]]; then
      local hours=$((cache_age / 3600))
      log_info "Age: ${hours} hour(s)"
    else
      local days=$((cache_age / 86400))
      log_info "Age: ${days} day(s)"
    fi
    
    # Check if cache is expired (older than 5 minutes)
    if [[ $cache_age -gt 300 ]]; then
      log_warn "Cache is expired (older than 5 minutes)"
    fi
  else
    log_info "Cache file: $WORLD_LIST_CACHE_FILE"
    log_warn "Could not determine cache file age"
  fi
  
  # Delete the cache file
  rm -f "$WORLD_LIST_CACHE_FILE"
  log_ok "Cleared world list cache"
  echo
  printf "Press Enter to continue..."
  read -r
}

# ============================================================
# Main Menu
# ============================================================

main_menu() {
  ui_run_page "Minecraft Bedrock Backup Tool (v${SCRIPT_VERSION})" \
    "List Minecraft Worlds - Show all worlds and backup individually::handler_list_worlds" \
    "Backup All Worlds - Backup all worlds at once::handler_backup_all" \
    "Open Backup Folder - Open the backup folder in Finder::handler_open_backup_folder" \
    "Clear World List Cache - Delete cached world list::handler_clear_cache" \
    "Quit - Exit the program::QUIT"
}

# ============================================================
# Main Entry Point
# ============================================================

main() {
  # Check dependencies
  if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
    log_error "adb not found. Install with: brew install android-platform-tools (or: sudo port install android-platform-tools)"
    exit 1
  fi
  
  # Check device on startup
  if ! check_device; then
    log_error "Please connect your Android device and try again."
    exit 1
  fi
  
  # Ensure backup directory exists
  mkdir -p "$BACKUP_BASE_DIR"
  
  # Run main menu (ui_run_page handles the loop internally)
  main_menu
  
  log_info "Goodbye!"
}

main "$@"

