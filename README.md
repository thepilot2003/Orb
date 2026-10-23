<p align="center">
  <img src="logo.png" alt="Orb Logo" width="180" style="border-radius: 24px;" />
</p>

<h1 align="center">Orb</h1>

<p align="center">
  <strong>A fluid, liquid-glass Dynamic Island designed natively for your MacBook notch.</strong>
</p>

<p align="center">
  <a href="https://github.com"><img src="https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square&logo=apple&logoColor=white" alt="macOS 13.0+" /></a>
  <a href="https://developer.apple.com/swift/"><img src="https://img.shields.io/badge/Swift-5.10-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.10" /></a>
  <a href="https://developer.apple.com/metal/"><img src="https://img.shields.io/badge/Renderer-Metal%20%2B%20SwiftUI-007AFF?style=flat-square" alt="Metal + SwiftUI" /></a>
  <a href="https://github.com"><img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%26%20Intel-green?style=flat-square" alt="Universal" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-teal?style=flat-square" alt="MIT License" /></a>
</p>

---

## 🌟 Highlights

Orb transforms the static black camera notch on your MacBook Pro or MacBook Air into an elegant, interactive **Dynamic Island** with Apple Music synchronized karaoke lyrics, native calendar integration, floating lock screen media widgets, and optical liquid glass refraction.

<p align="center">
  <a href="dist/Orb-v2.0.0.dmg">
    <img src="https://img.shields.io/badge/Download-Orb%20v2.0.0%20(DMG)-22c55e?style=for-the-badge&logo=apple&logoColor=white" alt="Download Orb DMG" />
  </a>
</p>

---

## ✨ Features

### 🏝️ Fluid Dynamic Island
- **Seamless Notch Wrapping**: Hugs your MacBook's physical notch and expands smoothly with organic spring physics on hover or track changes.
- **Physical Notch Calibration**: Sub-pixel width and height offset adjustments to perfectly align with any MacBook display geometry.
- **Dynamic Glass Optical Refraction**: Native optical shader refraction and progressive multi-stage blurs that blend album artwork into macOS menu bars.

### 🎵 Real-Time Synced Karaoke Lyrics
- **Sneak Peek Below Notch**: Stream synchronized karaoke lyrics in real time directly below the notch in compact mode.
- **Apple Music Alphabet Glow Sweep**: Character-level illumination and syllable reveals in the expanded island with vocal synchronization.
- **Intro & Instrumental Pulsing Dots**: No awkward blank holes—musical pulsing indicators (`• • •`) preview upcoming lyrics during intros and solos.
- **Live Sync Offset Tuning**: Adjustable synchronization offset (-3.0s to +3.0s) in Settings with a single-click reset.

### 🎛️ Symmetrical Centered Playback Controls
- **Dead-Center Controls**: `[Previous]`, `[Play/Pause]`, and `[Next]` are locked directly in the center of the expanded notch.
- **Utility Flanking**: Quick-favorite star on the left, interactive queue drawer on the right.
- **Universal Player Detection**: Seamlessly detects Apple Music, Spotify, and system Now Playing audio.

### 📅 Interactive Week Calendar
- **Clickable Week Strip**: Click any day of the week to inspect scheduled events with illuminated accent glows.
- **One-Click Event Launch**: Clicking an event opens Apple Calendar directly to that exact meeting (`calshow:`).
- **Live Countdown Badges**: Real-time status tags (`"Now"`, `"in 15m"`, `"Tomorrow 10:00 AM"`).
- **Quick Launch**: Header shortcut to jump straight into Calendar.app.

### 🪟 Desktop & Lock Screen Media Widget
- **Lock Screen Support**: Uses SkyLight window server levels to render a translucent glass player directly on the macOS Lock Screen.
- **Floating Multi-Space Mode**: Float above all full-screen applications or stay anchored to your desktop wallpaper.
- **Draggable & Persisted**: Position anywhere on your display; coordinates are saved across restarts.

### ⚙️ Redesigned Native Settings
- **5 Clean Categorized Tabs**: Appearance, Island, Media & Lyrics, Calendar, and Advanced.
- **Zero Horizontal Distortion**: Built with responsive SwiftUI layouts and fluid button grids.
- **Haptic Feedback**: Custom haptic pulses on hover, open, track changes, and scrubber interaction.

### ⚡ Ultra-Low Battery & CPU Footprint
- Native **SwiftUI & Metal** CoreAnimation rendering.
- Asynchronous **EventKit** background event indexing.
- Idle CPU consumption **< 0.2%** to preserve all-day battery life.

---

## 🚀 Installation

### Option 1: Download Pre-Built DMG (Recommended)
1. Download **[`Orb-v2.0.0.dmg`](dist/Orb-v2.0.0.dmg)** or grab the latest release from the [Releases](https://github.com) page.
2. Open the DMG and drag **Orb.app** into your **Applications** folder.
3. Launch Orb. Click the menu bar icon (`Orb`) and select **Settings...** (`⌘,`) to customize your preferences.

> **Note on macOS Gatekeeper**: Because this is an open-source build, right-click `Orb.app` and select **Open** the first time, or grant permission in *System Settings > Privacy & Security*.

---

### Option 2: Build From Source

#### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Command Line Tools installed (`xcode-select --install`)

#### One-Line Build Script
Clone the repository and run the automated release builder:

```bash
git clone https://github.com/yourusername/Orb.git
cd Orb
chmod +x build_release.sh
./build_release.sh
```

The script compiles the application, ad-hoc codesigns it, and generates:
- `dist/Orb.app` (Ready to run)
- `dist/Orb-v2.0.0.dmg` (Installer disk image)
- `dist/Orb-v2.0.0-macOS.zip` (Zip archive)

#### Build via Xcode GUI
1. Open `Orb.xcodeproj` in Xcode.
2. Select the `Orb` scheme and destination **My Mac**.
3. Press `⌘R` to build and run, or `Product > Archive` to create an optimized release.

---

## 🔒 Permissions & Privacy

Orb is privacy-first and open source. All processing happens 100% locally on your Mac:

| Permission | Purpose |
| :--- | :--- |
| **Automation (Apple Events)** | Communicates locally with Apple Music and Spotify to display song title, artist, playback progress, and controls. |
| **Calendars (EventKit)** | Reads upcoming local calendar entries to display meeting countdowns in the idle island. No calendar data is ever uploaded. |
| **Screen Capture (Optional)** | Orb includes a privacy toggle to automatically hide itself from screen recordings and screenshots. |

---

## 🛠️ Architecture & Technologies

- **SwiftUI & AppKit**: Hybrid architecture providing high-performance NSPanel window management and reactive SwiftUI state.
- **SkyLight Framework**: Interacts with the macOS window server for lock screen persistence.
- **MediaRemote Private API**: Real-time system-wide Now Playing audio session bridge.
- **EventKit**: High-efficiency event store monitoring with debounce filters.
- **LRCLIB Client**: Real-time synchronized lyrics fetcher with intelligent memory caching.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

<p align="center">
  <sub>Crafted with ❤️ for the Mac community.</sub>
</p>
