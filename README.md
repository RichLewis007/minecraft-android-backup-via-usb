# Minecraft Backup via ADB

**Author:** Rich Lewis - [GitHub @RichLewis007](https://github.com/RichLewis007)

Interactive TUI (Text User Interface) for backing up Minecraft Bedrock worlds from Android devices via ADB (Android Debug Bridge).

## Overview

This script provides a menu-driven interface for backing up Minecraft Bedrock worlds from your Android device. It allows you to selectively backup individual worlds or all worlds at once, in either directory format or as `.mcworld` files.

## Features

- **Interactive menu system** - Supports fzf, gum, or basic select menu (auto-detects what's available)
- **Lists all Minecraft worlds** - Automatically discovers worlds from your Android device
- **Displays world names** - Shows actual world names from `levelname.txt` files (not just folder IDs)
- **Sorted by most recently accessed** - Worlds are automatically sorted by access date
- **Individual or bulk backup** - Backup one world at a time or all worlds at once
- **Two backup formats:**
  - **World folders**: Full directory structure with descriptive names (`<world-name>_<world-id>`)
  - **.mcworld files**: Zipped world archives ready for import into Minecraft
- **Automatic path detection** - Tries primary path, falls back to alternative automatically
- **Progress indicators** - Spinners show progress during long operations
- **Organized backup structure** - Timestamps and organized folders for easy management
- **Cache management** - Caches world list (expires after 5 minutes) with manual clear option
- **Finder integration** - Automatically opens backup location in Finder (macOS)

## Requirements

### macOS Dependencies

**Using Homebrew:**
```bash
# Install ADB (Android Debug Bridge) - required
brew install android-platform-tools

# Install zip (for .mcworld export) - required
brew install zip

# Optional: Enhanced menu experience
brew install fzf        # or
brew install gum
```

**Using MacPorts:**
```bash
# Install ADB (Android Debug Bridge) - required
sudo port install android-platform-tools

# Install zip (for .mcworld export) - required
sudo port install zip

# Optional: Enhanced menu experience
sudo port install fzf        # or
sudo port install gum
```

### Android Setup

1. **Enable USB Debugging**:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
   - Connect device via USB
   - Accept the debugging prompt on your phone when connected

2. **Verify ADB Connection**:
   ```bash
   adb devices
   # Should show your device with "device" status
   ```

## Installation

1. **Clone or download** this repository
2. **Make the script executable**:
   ```bash
   chmod +x minecraft-backup-via-adb.sh
   ```

## Usage

```bash
./minecraft-backup-via-adb.sh
```

The script will:
1. Check for ADB installation
2. Verify Android device connection
3. Display an interactive menu with options

## Menu Options

### List Minecraft Worlds
- Shows all Minecraft worlds from your device
- Worlds are sorted by most recently accessed
- Select a world to backup individually
- Choose backup format (world folder or .mcworld file)
- Returns to world list after backup to backup more

### Backup All Worlds
- Backs up all worlds at once
- Choose format (world folders or .mcworld files)
- Shows progress for each world

### Open Backup Folder
- Opens the backup directory in Finder (macOS)
- Shows backup location path on other systems

### Clear World List Cache
- Deletes the cached world list
- Shows cache file age and location
- Forces fresh fetch from device on next run

### Quit
- Exits the program

## Backup Directory Structure

Backups are saved to: `~/Downloads/Minecraft-Worlds-Backups/`

```
Minecraft-Worlds-Backups/
├── world-folders/
│   └── <world-name>__<timestamp>/
│       └── <world-name>__<world-id>/
│           └── (world files)
└── mcworld-files/
    └── <world-name>__<timestamp>/
        └── <world-name>.mcworld
```

**Example:**
```
Minecraft-Worlds-Backups/
├── world-folders/
│   └── My-World__2024-01-15__02-30-45-PM/
│       └── My-World__ABC123DEF/
│           ├── levelname.txt
│           ├── level.dat
│           └── ...
└── mcworld-files/
    └── My-World__2024-01-15__02-30-45-PM/
        └── My-World.mcworld
```

## How It Works

### Path Detection

The script automatically detects the correct Minecraft worlds path:

1. **Primary path**: `/storage/emulated/0/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds`
2. **Alternative path**: `/sdcard/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds`

If the primary path doesn't exist, it automatically tries the alternative.

### World Discovery

1. Lists all directories in the Minecraft worlds folder
2. Reads `levelname.txt` from each world folder to get the actual world name
3. Gets access time for each world directory to sort by most recently accessed
4. Displays worlds sorted by access date (most recent first)

### Caching

- World list is cached for 5 minutes to speed up subsequent runs
- Cache is automatically refreshed if older than 5 minutes
- Cache location: `${TMPDIR:-/tmp}/minecraft-worlds-cache.txt`
- Manual cache clearing available in menu

### Backup Formats

#### World Folders
- Full directory structure
- Includes all world files
- Folder name format: `<world-name>__<world-id>`
- Useful for manual editing or inspection

#### .mcworld Files
- Zipped archive ready for import
- Single file per world
- File name format: `<world-name>.mcworld`
- Double-click to import into Minecraft

## Tips

- **Close Minecraft before backing up** - Ensures best consistency (worlds aren't locked)
- **USB Debugging must stay enabled** - Required for ADB to work
- **Keep device connected** - During the backup process
- **World names are sanitized** - Special characters are replaced with dashes for safe file names
- **Access times may vary** - Depending on Android system configuration

## Troubleshooting

### "No ADB device found"
- Verify USB Debugging is enabled
- Connect device via USB
- Accept the debugging prompt on your phone
- Run `adb devices` to verify connection

### "No worlds found"
- Make sure Minecraft is installed
- Verify you have at least one world created
- Check that the Minecraft app has been opened at least once

### "adb not found"
- Install Android Platform Tools:
  ```bash
  brew install android-platform-tools
  # or
  sudo port install android-platform-tools
  ```

### "zip command not found"
- Required for .mcworld export:
  ```bash
  brew install zip
  # or
  sudo port install zip
  ```

### Cache showing old worlds
- Use "Clear World List Cache" menu option
- Or manually delete: `rm /tmp/minecraft-worlds-cache.txt`
- Cache automatically expires after 5 minutes

### Worlds not sorting correctly
- Access time sorting depends on Android system settings
- Some Android versions may not update access times reliably
- Try clearing cache to force fresh discovery

## Understanding ADB

ADB (Android Debug Bridge) is used because it provides **elevated permissions** needed to access Minecraft world directories, which are located in:

```
/storage/emulated/0/Android/data/com.mojang.minecraftpe/files/games/com.mojang/minecraftWorlds
```

These directories are protected by **Android Scoped Storage** and cannot be accessed through normal file browsing or SSHFS. ADB bypasses these restrictions, allowing direct access to app data folders.

### Why ADB for Minecraft?

- **Elevated permissions**: ADB runs with system-level access
- **Access protected folders**: Can access `/Android/data/*` directories
- **Direct file operations**: Pull files directly without intermediate steps
- **Automated backups**: Perfect for scripting and batch operations

## License

MIT License

Copyright (c) 2024 Rich Lewis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

- Based on UI components from [bash-ui.sh](https://github.com/RichLewis007/utils)
- Uses fzf/gum for enhanced menu experience (with basic fallback)
