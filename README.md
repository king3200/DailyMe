# DailyMe

<p align="center">
    <img src="Assets.xcassets/AppIcon.appiconset/appicon.png" width="128" height="128" />
</p>

<p align="center">
    macOS Menu Bar App - Automatically captures a photo of you every day
    <br>
    <a href="README-ZH.md">中文版</a>
</p>

<p align="center">
    <a href="https://github.com/yourusername/DailyMe/releases/latest">
        <img src="https://img.shields.io/github/v/release/yourusername/DailyMe?color=blue&label=Release" />
    </a>
    <a href="https://github.com/yourusername/DailyMe/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/yourusername/DailyMe?color=green" />
    </a>
    <a href="https://github.com/yourusername/DailyMe/issues">
        <img src="https://img.shields.io/github/issues/yourusername/DailyMe?color=orange" />
    </a>
    <img src="https://img.shields.io/badge/macOS-13.0%2B-blue" />
</p>

---

## Features

- **Auto Capture** - Automatically takes a photo when you wake up/unlock your Mac
- **Manual Capture** - Trigger manual photo capture anytime
- **Custom Save Location** - Choose your preferred photo storage directory
- **One Photo Per Day** - Only captures one photo per day to avoid duplicates
- **Countdown Timer** - 4-second countdown with sound effect before capture
- **Menu Bar App** - Runs in macOS menu bar, no Dock icon占用
- **Launch at Login** - Supports automatic startup when Mac boots

## Screenshots

<p align="center">
    <img src="screenshots/screenshot.png" width="300" alt="DailyMe Interface" />
</p>

## Requirements

- macOS 13.0 (Ventura) or later
- FaceTime HD camera (built-in or external)

## Installation

### Option 1: Download from Releases

1. Go to [Releases](https://github.com/yourusername/DailyMe/releases) page
2. Download the latest `DailyMe-x.x.x.dmg` file
3. Open the dmg and drag DailyMe to your Applications folder
4. On first run, grant camera access in System Settings > Privacy & Security > Camera

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/DailyMe.git
cd DailyMe

# Open in Xcode
open DailyMe.xcodeproj

# Build with Product > Build (⌘B) in Xcode
# Built app is located at build/Debug/DailyMe.app
```

## Usage

### First Time Setup

1. On first launch, click the menu bar camera icon
2. Click "Select Directory" to choose your photo storage location
3. Grant camera access when prompted by the system

### Auto Capture

- App automatically captures a photo when Mac wakes up/unlocks
- Only the first wake-up triggers capture each day
- 4-second countdown with sound effect before capture

### Manual Capture

- Click the menu bar icon, then click "Capture Now" button
- Force capture anytime, not limited to once per day

### Delete Today's Photo

- Click the delete button to remove today's photo
- After deletion, auto capture can trigger again for the day

## Project Structure

```
DailyMe/
├── App.swift                 # SwiftUI app entry point
├── AppDelegate.swift        # App lifecycle, status bar management
├── CameraManager.swift       # Camera management, capture logic
├── StatusBarView.swift      # Menu bar popover UI
├── ContentView.swift        # Backup content view
├── IconGenerator.swift      # App icon generation
├── Info.plist               # App configuration
├── DailyMe.entitlements     # Sandbox entitlements
└── Assets.xcassets/         # App resources (icons, colors, etc.)
```

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI + AppKit
- **Camera**: AVFoundation
- **Target Platform**: macOS 13.0+

## Dependencies

No external dependencies - uses only native Apple frameworks.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Issues and Pull Requests are welcome!

## Acknowledgments

Thank you for using DailyMe!
