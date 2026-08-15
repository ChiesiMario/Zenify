# Zenify.

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

> A beautiful, high-performance desktop client for Subsonic-compatible music servers, crafted for a seamless listening experience.

![Version](https://img.shields.io/badge/version-1.0.0-black?style=flat-square&labelColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-black?style=flat-square&labelColor=white)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square&labelColor=white)

<br>
<p align="center">
  <!-- TODO: Update screenshot path if available -->
  <img src="assets/icon/app_icon.png" alt="Zenify Screenshot" width="800">
</p>
<br>

## FEATURES

- **Stunning UI**: A modern, glassmorphic and minimalist interface built with Shadcn UI aesthetics.
- **Subsonic Ecosystem**: Fully compatible with Navidrome, Airsonic, and other Subsonic API servers.
- **Offline Playback**: Download your favorite tracks and albums for offline listening.
- **High Performance**: Built on top of Isar database for lightning-fast caching and pagination of massive libraries.
- **System Integration**: Native Windows media controls (SMTC), system tray support, and single-instance window management.
- **Robust Audio**: Powered by MediaKit for gapless, format-rich, and stable audio playback.
- **Internationalization**: Full support for multiple languages (English, Traditional Chinese, Simplified Chinese).

## TECH STACK

- **Framework**: Flutter / Dart
- **State Management**: Riverpod
- **Local Database**: Isar Database
- **Audio Engine**: media_kit & just_audio
- **UI Components**: Shadcn UI

## INSTALLATION

### Pre-built Binaries (Windows)

1. Navigate to the [Releases](https://github.com/ChiesiMario/Zenify/releases) page.
2. Download the latest `Zenify-Setup-vX.X.X.exe`.
3. Run the installer and follow the instructions.

### Build from Source

Ensure you have the Flutter SDK (>=3.12.2) installed on your system.

```bash
git clone https://github.com/ChiesiMario/Zenify.git
cd Zenify
flutter pub get
flutter build windows
```

## ARCHITECTURE

Zenify follows a clean, modular architecture separating concerns across presentation, domain, and data layers:

- `providers/`: Riverpod state management and business logic.
- `screens/` & `views/`: UI layouts, navigation, and page compositions.
- `components/`: Reusable UI elements strictly adhering to our custom design standards.
- `api/` & `services/`: Subsonic communication, downloading, and local caching logic.
- `models/`: Data models for Isar database and API responses.

## LICENSE

This project is licensed under the MIT License.
