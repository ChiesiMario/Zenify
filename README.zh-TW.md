# Zenify.

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

> 一款專為 Subsonic 相容伺服器打造的美觀、高效能桌面端音樂播放器，為您帶來極致流暢的聆聽體驗。

![Version](https://img.shields.io/badge/version-1.0.0-black?style=flat-square&labelColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-black?style=flat-square&labelColor=white)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square&labelColor=white)

<br>
<p align="center">
  <img src="assets/icon/app_icon.png" alt="Zenify Screenshot" width="800">
</p>
<br>

## 產品特色

- **極致視覺**：結合毛玻璃特效與極簡主義，基於 Shadcn UI 美學打造的現代化介面。
- **Subsonic 生態**：完美相容 Navidrome、Airsonic 等各類支援 Subsonic API 的伺服器。
- **離線播放**：支援一鍵下載您最愛的歌曲與專輯，無網路也能隨時享受音樂。
- **極致效能**：底層採用 Isar 資料庫進行快取，輕鬆應對海量音樂庫的快速分頁與載入。
- **系統深度整合**：支援 Windows 原生媒體控制 (SMTC)、系統工作列常駐，以及防多開的單一實例視窗管理。
- **強大音訊引擎**：由 MediaKit 提供動力，支援無縫播放、豐富的音訊格式與極高的播放穩定性。
- **多語系支援**：內建完整的繁體中文、簡體中文與英文介面。

## 技術棧

- **框架**: Flutter / Dart
- **狀態管理**: Riverpod
- **本地資料庫**: Isar Database
- **音訊引擎**: media_kit & just_audio
- **UI 元件庫**: Shadcn UI

## 安裝指南

### 下載預編譯版本 (Windows)

1. 前往 [Releases](https://github.com/ChiesiMario/Zenify/releases) 頁面。
2. 下載最新的安裝檔 `Zenify-Setup-vX.X.X.exe`。
3. 執行安裝程式並按照畫面指示完成安裝。

### 從原始碼編譯

請確認您的系統已安裝 Flutter SDK (>=3.12.2)。

```bash
git clone https://github.com/ChiesiMario/Zenify.git
cd Zenify
flutter pub get
flutter build windows
```

## 系統架構

Zenify 採用清晰的模組化架構，將 UI 展示層、業務邏輯與資料層徹底分離：

- `providers/`: Riverpod 狀態管理與核心業務邏輯。
- `screens/` & `views/`: 畫面佈局、路由導覽與頁面組合。
- `components/`: 嚴格遵循自訂設計規範的可重複使用 UI 元件。
- `api/` & `services/`: 負責與 Subsonic 溝通、檔案下載與本地快取機制。
- `models/`: Isar 資料庫結構與 API 回傳資料模型。

## 授權條款

本專案採用 MIT 授權條款。
