# System Clean Plugin

Deep cleaning utilities for macOS system maintenance.

## Features

- **Cache Cleaning**: Clear system and user caches
- **Log Cleanup**: Remove old log files
- **Downloads Folder**: Organize and clean downloads
- **Xcode Cleanup**: Remove derived data and archives
- **iOS Backups**: Clean old device backups
- **Mail Attachments**: Remove cached email attachments
- **Trash Management**: Empty trash securely
- **Language Files**: Remove unused language packs

## Installation

This plugin is included with Mac Power Tools by default.

## Usage

```bash
# Interactive cleaning menu
mac clean

# Clean specific categories
mac clean cache
mac clean logs
mac clean downloads
mac clean xcode
mac clean ios
mac clean mail
mac clean trash

# Dry run (preview what will be deleted)
mac clean --dry-run

# Force clean without confirmation
mac clean --force
```

## Space Savings

Typical space recovered:
- Xcode: 5-20 GB
- iOS Backups: 2-10 GB per device
- Caches: 1-5 GB
- Logs: 500 MB - 2 GB

## Safety

- Always prompts before deletion
- Skips system-critical files
- Creates list of deleted items
- Dry-run mode available

## License

MIT - Part of Mac Power Tools
