# Changelog

All notable changes to the Orb project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.04] - 2026-10-25

### Added
- **Beside Notch Companion Placement**: Relocated the pet from below the notch to sit cleanly **beside the notch** within the native macOS menu bar row, keeping the workspace, browser tabs, and application title bars underneath 100% unobstructed.
- **Left / Right / Both Sides Placement Picker**: Added intuitive side selection in Settings > Notch Pet:
  - *Right of Notch*: Perches to the right of the island, facing inward.
  - *Left of Notch*: Perches to the left of the notch, facing inward.
  - *Both Sides (Roaming)*: Strolls and switches sides across the menu bar.
- **Dynamic Spring Tracking**: The companion automatically glides outward when the Dynamic Island expands for Now Playing or Calendar views, and retracts flush beside the notch when compact.

## [1.03] - 2026-10-24

### Fixed
- **Sub-Pixel Notch Centering**: Fixed an AppKit `NSHostingView` leading-edge layout constraint that caused the Dynamic Island to render ~76–124pt to the left of the physical MacBook camera cutout. The island is now locked dead-center to `(auxiliaryTopLeftArea.maxX + auxiliaryTopRightArea.minX) / 2.0`.
- **Notch Height Calibration**: Calibrated hardware notch depth to 34pt, eliminating the 3.5pt black overhanging lip on M2/M3 MacBook Air screens.
- **Companion Grounding**: Anchored Notch Pet right at `notchBottom + 1`, preventing mid-air hovering and camera bezel clipping.
- **Spider Silk Physics**: Replaced coordinate position offsets with relative anchored geometry so the silk thread and anchor knot drop directly from the notch rim.
- **Settings Layout**: Widened Settings window to 680px with `.lineLimit(1)` on tabs, preventing hyphenated tab wrapping.

## [1.02] - 2026-10-24

### Added
- **Notch Pet Companion Expansion**:
  - Added new **Spider Companion (Webby)** with 8-legged crawl, shiny anime eyes, and silk bungee line.
  - Added **Wardrobe & Clothes System** featuring 11 hats (DJ Headphones, Sunglasses, Rain Hat, Winter Beanie, Santa Hat, Party Hat, Wizard Hat, Crown, Cowboy Hat, Flower) and 7 outfits (Raincoat, Cozy Sweater, Hero Cape, Bowtie, Mini Laptop, Pom-Poms).
  - Added **Feeding & Treats System** with favorite snacks (Fish for Cat, Bone for Dog, Bread for Duck, Fly for Spider, Star Candy for Orb).
  - Added **Mini DJ Headphones** automatically worn during music playback.
  - Added **Karaoke Singing Companion** synced with lyric vocal phrases.
  - Added **Adaptive Dance Routines** calibrated to track tempo.
  - Added **MagSafe Battery Snack** reaction when charging.
  - Added **Typing / Work Companion** cheering you on during rapid coding.
  - Added **Pomodoro Break & Hydration Reminders**.
  - Added **Weather Reactions** (Raincoat in rain, Beanie in cold, Sunglasses in sun).
  - Added dedicated **Notch Pet** tab in Settings.
- **Repository Architecture**:
  - Restructured codebase into clean, modular domain directories (`Core`, `Models`, `Pet`, `Views`, `Settings`, `State`).
  - Added GitHub Actions CI workflow, `CONTRIBUTING.md`, and `CODE_OF_CONDUCT.md`.

### Fixed
- Fixed pet vertical positioning and sizing so it is fully visible beneath the MacBook notch curve without clipping.

## [1.01] - 2026-10-24

### Added
- Animated Notch Pet Companion foundation with Cat, Dog, Duck, and Orb companions.
- Walking, idle, sleeping, and petting interactions.

### Removed
- Cleanly removed experimental desktop and lock screen widget.

## [1.0.0] - 2026-10-23

### Initial Release
- Hardware notch expansion with Apple Music & Spotify integration.
- Apple Music style karaoke lyrics with character glow wipe.
- Dynamic Island calendar integration.
- Liquid glass shader effects and native haptic feedback.
