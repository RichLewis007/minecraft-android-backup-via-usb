# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6] - 2026-01-09

### Added
- Added "Support This Project" section with links to GitHub repository, profile, and issues
- Enhanced documentation with Free Open Source Software attribution

### Changed
- Updated website and README to prominently feature FOSS status and attribution to Rich Lewis
- Improved documentation clarity and organization

## [1.5] - 2026-01-09

### Changed
- Version bump for documentation and website improvements

## [1.4] - 2026-01-09

### Changed
- Reorganized website images directory structure
- Version bump for continued development

## [1.2] - 2026-01-09

### Added
- **GitHub Pages website** - Comprehensive project website at `github-pages-website/`
  - Attractive landing page highlighting the importance of backing up Minecraft worlds
  - Feature showcase with compelling visuals
  - Step-by-step usage instructions
  - Call-to-action buttons for starring, following, and downloading
- **Enhanced README.md** - Comprehensive documentation
  - Centered heading image
  - Left and right-aligned images throughout
  - Detailed "How It Works" section explaining technical implementation
  - Backup formats explained (world folders vs .mcworld files)
  - Caching mechanism documentation
  - Path detection explanation
  - Troubleshooting section
- **Release preparation script** (`local/prepare-release.sh`)
  - Automated version bumping (X.Y format)
  - Updates version in script, README, and website
  - Creates release archives excluding development files
  - Tests release archives locally
  - Automatic git commit and tagging
  - Updates download button URL to specific release tag
  - Defaults all Y/N prompts to "Y" for streamlined workflow
- **GitHub Actions workflow** (`.github/workflows/deploy-pages.yml`)
  - Automated deployment of GitHub Pages website
  - Deploys on push to main branch
  - Uses latest GitHub Actions deployment methods
- **Documentation** (`local/github-pages-setup.md`)
  - Comprehensive guide for GitHub Pages setup
  - Explains different deployment methods
  - Documents GitHub Actions workflow approach

### Changed
- **Script renamed** from `minecraft-backup-via-adb.sh` to `minecraft-android-backup-via-usb.sh`
  - More descriptive name emphasizing USB connection method
  - Better reflects the tool's purpose and connection method
- Enhanced script header comments with comprehensive documentation
- Updated all documentation to use new script name

### Fixed
- Fixed image paths to support both website and README usage
- Improved cross-platform compatibility for release preparation script

## [1.1] - 2026-01-08

### Added
- Version numbering system implemented
- Version displayed in script header, README, and website

### Changed
- Updated project description to emphasize "Easily backup your complete Minecraft Bedrock Edition worlds..."
- Explicitly mentioned both backup formats (full folders and .mcworld files) in descriptions

## [1.0] - 2026-01-07

### Added
- **Initial release** - Minecraft Android Backup via USB tool
- **Core Features:**
  - Interactive menu system with auto-detection (fzf > gum > basic select)
  - Automatic world discovery from Android device via ADB
  - World name resolution from `levelname.txt` files
  - Sorting by most recently accessed worlds
  - Individual world backup support
  - Bulk backup all worlds option
  - Two backup formats:
    - **World Folders**: Complete directory structure with `<world-name>__<world-id>` naming
    - **.mcworld Files**: Standard Minecraft world archive format (ZIP)
  - Automatic path detection with fallback support
  - Progress indicators with spinner animations
  - Organized backup structure with timestamps
  - World list caching (5-minute expiration)
  - Manual cache clearing option
  - macOS Finder integration (auto-opens backup location)
- **Technical Implementation:**
  - ADB (Android Debug Bridge) integration over USB
  - Access to protected Android app data directories
  - Bypasses Android Scoped Storage restrictions
  - Handles both primary and alternative storage paths
  - Error handling with graceful fallbacks
  - Cross-platform compatibility considerations
- **Requirements:**
  - ADB (Android Debug Bridge) installation
  - zip command for .mcworld export
  - Android device with USB Debugging enabled
  - Optional: fzf or gum for enhanced menu experience

---

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
