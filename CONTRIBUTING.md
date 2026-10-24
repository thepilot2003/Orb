# Contributing to Orb

Thank you for your interest in contributing to Orb!

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/Orb.git
   cd Orb
   ```
3. Open `Orb.xcodeproj` in Xcode 16+.
4. Build and run the project using `Cmd+R`.

## Development Guidelines

- **Architecture**: Keep code organized in the respective subfolders (`Core`, `Models`, `Pet`, `Views`, `Settings`, `State`).
- **Performance**: Maintain 60fps / 120fps animations with minimal CPU and battery usage.
- **Style**: Adhere to idiomatic Swift conventions and clean SwiftUI code.

## Submitting Pull Requests

1. Create a feature branch (`git checkout -b feature/amazing-feature`).
2. Commit your changes with descriptive commit messages.
3. Push to your branch (`git push origin feature/amazing-feature`).
4. Open a Pull Request against `main`.
