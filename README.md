<p align="center">
  <img src="assets/png/icon.png" width="120" alt="Rootify Logo">
</p>

<h1 align="center">Rootify</h1>

<p align="center">
  <strong>an Root All In One application for Tweaking, Tuning Performance, AI Management on Your Device, Monitor System Resources, and More</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-0078D4?style=flat-square&logo=android" alt="Platform">
  <img src="https://img.shields.io/badge/Framework-Flutter-02569B?style=flat-square&logo=flutter" alt="Framework">
  <img src="https://img.shields.io/badge/License-Apache_2.0-D22128?style=flat-square" alt="License">
</p>

---

Rootify is a high-performance system utility engineered to grant users complete control over their device's underlying architecture. Crafted with precision using Flutter, it offers a seamless blend of aesthetic excellence and raw technical power, designed specifically for power users and developers who demand the most from their hardware.

## Core Architecture & Features

### System Orchestration

- **Performance Tuning**: Real-time manipulation of system parameters for optimal throughput.
- **Resource Monitoring**: Granular tracking of CPU, Memory, and GPU utilization metrics.
- **Kernel Management**: Direct interaction with kernel-level settings to refine device behavior.

### Advanced Toolset

- **Logcat Diagnostics**: High-fidelity system log capturing with powerful filtering and export capabilities.
- **FPS Analysis**: Non-obtrusive, high-frequency frame rate monitoring via a precision-engineered overlay.
- **ZRAM Tweaking**: Sophisticated memory optimization algorithms to ensure persistent system fluidity.

### Visual Architecture

- **Glassmorphism Interface**: A state-of-the-art UI utilizing real-time blur and depth effects.
- **Dynamic Theming**: Intelligent theme switching logic that adapts to user preference and system states.
- **Modular Design**: Reusable component architecture ensuring rapid extensibility and stability.

## Getting Started

### Prerequisites

To ensure a seamless development experience, verify that your environment meets the following criteria:

- **Flutter SDK**: Latest Stable Channel (v3.27.0 or newer recommended).
- **Java Development Kit (JDK)**: Version 17 is strictly required for Gradle 8.x compatibility.
- **Android SDK**: Build Tools level 34.0.0 (Android 14) or higher installed via Android Studio SDK Manager.
- **Root Permissions**: Mandatory for system-level modifications and diagnostics on the target device.

### Setup Workflow

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/RootifyProject/Rootify.git
   cd Rootify
   ```

2. **Initialize Dependencies**:

   ```bash
   flutter pub get
   ```

3. **Environment Verification**:
   Run the following command to detect any configuration issues:
   ```bash
   flutter doctor -v
   ```

## Development and Deployment

### IDE Configuration

We recommend **Visual Studio Code** for the most efficient workflow:

- Install the official **Flutter** and **Dart** extensions.
- Use the **Flutter Intl** extension for managing localization (if applicable).
- Ensure your `java.home` in VS Code settings points to JDK 17.

### Execution Modes

- **Standard Debug (JIT)**:
  Best for UI development and hot reload.

  ```bash
  flutter run
  ```

- **Performance Profiling (AOT)**:
  Essential for analyzing shader compilation and frame rendering performance.
  ```bash
  flutter run --profile
  ```

### Production Release Pipeline

Rootify employs a context-aware build system orchestrated by Gradle. This ensures that every binary is correctly properly versioned and optimized for distribution.

#### Build Command

To generate a distinct production APK for each CPU architecture (ARM64, ARMv7, x86_64), use:

```bash
flutter build apk --release --split-per-abi -Pctx=[CONTEXT]
```

#### Build Contexts (`-Pctx`)

The `ctx` property determines the versioning strategy and build labeling:

| Context  | Badge       | Version Schema | Use Case                                  |
| :------- | :---------- | :------------- | :---------------------------------------- |
| `stable` | **Release** | `1.0.x`        | Public production deployment.             |
| `rc`     | **RC**      | `0.9.9.x`      | Final freeze before stable release.       |
| `beta`   | **Beta**    | `0.9.x`        | Verification of new features.             |
| `alpha`  | **Alpha**   | `0.0.x`        | Internal testing and experimental builds. |

> **Note**: The build system automatically handles version code incrementation to prevent conflicts on the Play Store or package managers.

## Credits and Inspirations

Rootify stands on the shoulders of giants in the Android optimization community. For questions or support, reach out to the core team:

- **Dizzy (Developer)**: [Dizzy](https://t.me/WzdDizzyFlasherr)
- **Laynsb (Laya Developer)**: [Laynsb](https://t.me/Laynsb)
- **Telegram Channel**: [Aby Rootify](https://t.me/AbyRootify)

### Inspirations

- **AZenith**: [Inspirational Architecture](https://github.com/Liliya2727/AZenith)
- **Project Raco**: [Performance Conceptualization](https://github.com/LoggingNewMemory/Project-Raco)

## Compliance and Legal

Rootify is committed to transparency and user privacy. Please refer to our official documentation for detailed information:

- **LICENSE**: [LICENSE](LICENSE) (Apache 2.0)
- **Rootify EULA**: [LICENSE-ROOTIFY.md](LICENSE-ROOTIFY.md) (End-User License Agreement)
- **Privacy Policy**: [LICENSE-PRIVACY.md](LICENSE-PRIVACY.md) (Data Handling Transparency)

---

Copyright (C) 2026 Rootify - Aby - FoxLabs
All Rights Reserved.
