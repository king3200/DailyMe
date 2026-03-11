# DailyMe

<p align="center">
    <img src="DailyMe/Assets.xcassets/AppIcon.appiconset/appicon.png" width="128" height="128" />
</p>

<p align="center">
    macOS 菜单栏应用 - 每天自动为您拍摄一张照片
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

## 功能特性

- **自动拍照** - 每次打开 Mac 电脑时自动拍摄一张照片
- **手动拍照** - 支持随时手动触发拍照
- **自定义保存路径** - 可自由选择照片保存目录
- **每日仅拍一张** - 每天只会拍摄一张照片，避免重复
- **倒计时提醒** - 拍照前 4 秒倒计时，带音效提示
- **菜单栏应用** - 运行于 macOS 菜单栏，不占用 Dock 图标
- **开机自启动** - 支持设置开机自动启动

## 截图

<p align="center">
    <img src="screenshots/screenshot.png" width="300" alt="DailyMe 界面" />
</p>

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- 支持 FaceTime 高清摄像头（内置或外接）

## 安装

### 方法一：从 Release 下载

1. 前往 [Releases](https://github.com/yourusername/DailyMe/releases) 页面
2. 下载最新的 `DailyMe-x.x.x.dmg` 文件
3. 打开 dmg 文件，将 DailyMe 拖入应用程序文件夹
4. 首次运行后，在「系统设置 > 隐私与安全性 > 相机」中授权访问

### 方法二：从源码编译

```bash
# 克隆仓库
git clone https://github.com/yourusername/DailyMe.git
cd DailyMe

# 使用 Xcode 打开
open DailyMe.xcodeproj

# 在 Xcode 中选择 Product > Build (⌘B) 进行编译
# 编译产物位于 build/Debug/DailyMe.app
```

## 使用说明

### 首次设置

1. 首次运行时，点击菜单栏相机图标
2. 点击「选择目录」按钮，选择照片保存位置
3. 授权相机访问权限（系统会提示）

### 自动拍照

- 应用会在每次 Mac 唤醒/解锁时自动拍摄一张照片
- 每天只拍摄第一张照片，后续唤醒不会重复拍摄
- 拍照前有 4 秒倒计时和音效提示

### 手动拍照

- 点击菜单栏图标，在弹出窗口中点击「立即拍照」按钮
- 可随时强制拍照，不受每日一张限制

### 删除今日照片

- 点击删除按钮可删除当天拍摄的照片
- 删除后当天可再次自动拍照

## 项目结构

```
DailyMe/
├── App.swift                 # SwiftUI 应用入口
├── AppDelegate.swift        # 应用生命周期、状态栏管理
├── CameraManager.swift       # 相机管理、拍照逻辑
├── StatusBarView.swift      # 菜单栏弹出窗口 UI
├── ContentView.swift        # 备用内容视图
├── IconGenerator.swift      # 应用图标生成
├── Info.plist               # 应用配置信息
├── DailyMe.entitlements     # Sandbox 权限配置
└── Assets.xcassets/         # 应用资源（图标、颜色等）
```

## 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit
- **相机**: AVFoundation
- **目标平台**: macOS 13.0+

## 依赖

无外部依赖，仅使用 Apple 原生框架。

## 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

感谢使用 DailyMe！
