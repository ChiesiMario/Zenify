# Zenify.

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

> 一款专为 Subsonic 兼容服务器打造的美观、高性能桌面端音乐播放器，为您带来极致流畅的聆听体验。

![Version](https://img.shields.io/badge/version-1.0.0-black?style=flat-square&labelColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-black?style=flat-square&labelColor=white)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square&labelColor=white)

<br>
<p align="center">
  <img src="assets/icon/app_icon.png" alt="Zenify Screenshot" width="800">
</p>
<br>

## 产品特色

- **极致视觉**：结合毛玻璃特效与极简主义，基于 Shadcn UI 美学打造的现代化界面。
- **Subsonic 生态**：完美兼容 Navidrome、Airsonic 等各类支持 Subsonic API 的服务器。
- **离线播放**：支持一键下载您最爱的歌曲与专辑，无网络也能随时享受音乐。
- **极致性能**：底层采用 Isar 数据库进行缓存，轻松应对海量音乐库的快速分页与加载。
- **系统深度整合**：支持 Windows 原生媒体控制 (SMTC)、系统托盘常驻，以及防多开的单一实例窗口管理。
- **强大音频引擎**：由 MediaKit 提供动力，支持无缝播放、丰富的音频格式与极高的播放稳定性。
- **多语言支持**：内置完整的繁体中文、简体中文与英文界面。

## 技术栈

- **框架**: Flutter / Dart
- **状态管理**: Riverpod
- **本地数据库**: Isar Database
- **音频引擎**: media_kit & just_audio
- **UI 组件库**: Shadcn UI

## 安装指南

### 下载预编译版本 (Windows)

1. 前往 [Releases](https://github.com/ChiesiMario/Zenify/releases) 页面。
2. 下载最新的安装程序 `Zenify-Setup-vX.X.X.exe`。
3. 运行安装程序并按照屏幕指示完成安装。

### 从源码编译

请确认您的系统已安装 Flutter SDK (>=3.12.2)。

```bash
git clone https://github.com/ChiesiMario/Zenify.git
cd Zenify
flutter pub get
flutter build windows
```

## 系统架构

Zenify 采用清晰的模块化架构，将 UI 展示层、业务逻辑与数据层彻底分离：

- `providers/`: Riverpod 状态管理与核心业务逻辑。
- `screens/` & `views/`: 界面布局、路由导航与页面组合。
- `components/`: 严格遵循自定义设计规范的可重用 UI 组件。
- `api/` & `services/`: 负责与 Subsonic 通信、文件下载与本地缓存机制。
- `models/`: Isar 数据库结构与 API 返回数据模型。

## 许可协议

本项目采用 MIT 许可协议。
