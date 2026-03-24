# SimDock

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/github/license/techinpark/SimDock" alt="License">
  <img src="https://img.shields.io/github/v/release/techinpark/SimDock" alt="Release">
</p>

<p align="center">
  <a href="README_ko.md">한국어</a>
</p>

A lightweight macOS menu bar utility that lets you quickly launch and manage iOS simulators.

## Features

- **Launch from Menu Bar** — Browse your simulators and boot them with a single click
- **Grouped by Runtime** — Simulators organized by runtime (iOS 26, iOS 18, etc.)
- **Status Indicator** — Visual status for each simulator (Running / Shutdown)
- **Installed Apps** — View installed apps per simulator with app icons
- **UserDefaults Browser** — Hover over an app to browse its UserDefaults plist files
- **Browse Data Directory** — Hover over a simulator to explore its internal folders
- **Open in Finder** — Click any folder in the submenu to reveal it in Finder
- **Launch at Login** — Auto-start SimDock when you log in

## Installation

### Homebrew (Recommended)

```bash
brew tap techinpark/tap
brew install --cask simdock
```

### GitHub Releases

Download the latest `.dmg` from the [Releases](https://github.com/techinpark/SimDock/releases) page.

1. Download `SimDock.dmg`
2. Open the DMG file
3. Drag `SimDock.app` to `/Applications`

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Build from Source

```bash
git clone https://github.com/techinpark/SimDock.git
cd SimDock
xcodegen generate
xcodebuild -scheme SimDock -configuration Release build
```

Or open the project directly in Xcode:

```bash
open SimDock.xcodeproj
```

## Contributing

Contributions are welcome! Feel free to open issues for bug reports, feature requests, or submit pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
