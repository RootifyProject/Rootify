<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="Rootify Logo">
</p>

<h1 align="center">Rootify</h1>

<p align="center">
  <strong>An Root All In One application for Tweaking, Tuning Performance, AI Management on Your Device, Monitor System Resources, and More</strong>
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

## System Configuration & Prerequisites

To ensure a seamless development experience across different host operating systems, verify the core requirements and follow the OS-specific setup.

### Standard Requirements

- **Flutter SDK**: Latest Stable Channel (v3.27.0+).
- **JDK 17**: Strictly required for Gradle 8.x.
- **Android SDK**: API Level 34 (Android 14) platform and build tools.
- **Root Permissions**: Mandatory for system-level modifications on the target device.

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
   ```bash
   flutter doctor -v
   ```

### Operating System Specifics

#### Linux (Debian/Ubuntu)

1. **Install Dependencies**:
   ```bash
   sudo apt update
   sudo apt install openjdk-17-jdk clang cmake ninja-build pkg-config libgtk-3-dev git curl unzip -y
   ```
2. **Path Configuration**:
   Ensure `JAVA_HOME` is exported in your `.bashrc` or `.zshrc`:
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
   export PATH=$JAVA_HOME/bin:$PATH
   ```

#### Linux (Fedora/RHEL/CentOS)

1. **Install Dependencies**:
   ```bash
   sudo dnf install java-17-openjdk-devel git curl unzip clang cmake ninja-build pkg-config gtk3-devel
   ```

#### Linux (Arch/Manjaro)

1. **Install Dependencies**:
   ```bash
   sudo pacman -S jdk17-openjdk git curl unzip clang cmake ninja pkg-config gtk3
   ```

#### Windows (PowerShell/CMD)

1. **Install OpenJDK 17**: Recommended via `winget install Microsoft.OpenJDK.17` or manual installer.
2. **Environment Variables**:
   - Set `JAVA_HOME` to `C:\Program Files\Microsoft\jdk-17.x.x-hotspot`.
   - Update `Path` to include `%JAVA_HOME%\bin`.
3. **C++ Build Tools**: Install "Desktop development with C++" via Visual Studio Installer if targeting Windows desktop (optional for Android builds).

#### macOS (Intel/Apple Silicon)

1. **Install via Homebrew**:
   ```bash
   brew install --cask flutter
   brew install openjdk@17
   ```
2. **JDK Linking**:
   ```bash
   sudo ln -sfn /usr/local/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
   ```

## Command Execution & Build Orchestration

Rootify allows for flexible development workflows using either the provided `rify` wrapper or standard `flutter` commands.

### 1. The `rify` Utility Wrapper

Rootify includes a high-performance wrapper script (`rify.sh` for Linux/macOS, `rify.bat` for Windows) to orchestrate complex build contexts and execution modes.

#### Command Syntax

```bash
# Linux/macOS
./rify.sh [run|build] [-channel] [-mode] [extra-args]

# Windows
rify.bat [run|build] [-channel] [-mode] [extra-args]
```

#### Selection Matrix

| Flag      | Description    | Logic (Gradle Project Property)                      |
| :-------- | :------------- | :--------------------------------------------------- |
| `-stable` | Stable Context | `-Pstable` or `-Pctx=stable`                         |
| `-beta`   | Beta Context   | `-Pbeta` or `-Pctx=beta`                             |
| `-rc`     | RC Context     | `-Prc` or `-Pctx=rc`                                 |
| `-alpha`  | Alpha Context  | `-Palpha` or `-Pctx=alpha`                           |
| `-p`      | Profile Mode   | Executes with AOT and performance profiling enabled. |
| `-d`      | Debug Mode     | Executes with JIT and Hot Reload (Default).          |

---

### 2. Manual Command Execution

If you prefer using the standard Flutter CLI, you must manually pass the Gradle project properties (`-P`) to ensure the build system identifies the correct context.

#### Running the Application

```bash
# Standard Debug Run (Without ctx)
flutter run --debug
# or
flutter run -debug

# Standard Profile Run (Without ctx)
flutter run --profile
# or
flutter run -profile

# Running [ctx] in Profile Mode
flutter run --profile -P[ctx]
# or
flutter run -profile -Pctx=[ctx]

# Running [ctx] in Release Mode
flutter run -P[ctx]
# or
flutter run -Pctx=[ctx]
# or
flutter run --release -P[ctx]
# or
flutter run --release -Pctx=[ctx]

```

#### Building the APK

To ensure correct architecture splitting and version incrementing, use the following syntax:

```bash
# General Build Pattern
# Use --split-per-abi to generate ARM-specific APKs
flutter build apk --release --split-per-abi -P[context]
# or
flutter build apk --release --split-per-abi -Pctx=[ctx]

# Without --split-per-abi
flutter build apk --release -P[ctx]
# or
flutter build apk --release -Pctx=[ctx]

# Standard Build Pattern
# Release Build (Without ctx)
flutter build apk --release
# or
flutter build apk -release

# Debug Build (Without ctx)
flutter build apk --debug
# or
flutter build apk -debug

# Profile Build (Without ctx)
flutter build apk --profile
# or
flutter build apk -profile

```

> [!IMPORTANT]
> **Versioning Logic**: To prevent build number "bloat" during development, `android/app/version.properties` only increments when using the `build` command (Release tasks). Using `rify run` or `flutter run` will keep the current build count persistent.

### 3. Release Signing Configuration

Rootify uses a secure signing system that separates production credentials from the source code.

#### Key Setup

1.  **Template**: Copy `android/key.properties.example` to `android/key.properties`.
2.  **Configuration**: Fill in your keystore path, alias, and passwords in `key.properties`.
3.  **Security**: The `key.properties` file is gitignored to protect your credentials.

#### Logic & Fallbacks

- **Production builds**: If `key.properties` is present, `release` and `profile` builds will be cryptographically signed with your key.
- **Development builds**: If `key.properties` is missing, the build system gracefully falls back to the standard Android `debug` signing key. This ensures high portability for new contributors.

## Contributing to Rootify

Rootify is an open-community project that welcomes contributions from developers, system engineers, and security researchers. We are committed to a collaborative environment focused on improving application functionality, fixing bugs, implementing new features, and optimizing app performance.

### How to Contribute

#### 1. Reporting Issues

- Use the project's issue tracker to report bugs or suggest enhancements.
- Provide a clear, descriptive title and a detailed summary of the issue.
- For bug reports, include reproduction steps, expected behavior, and actual results.

#### 2. Development Workflow

- **Fork and Clone**: Create a personal fork and clone it to your local environment.
- **Branching Strategy**: Use descriptive branch names for your work (e.g., `fix/log-filtering` or `feat/cpu-governor-tweaks`).
- **Linter & Formatting**: Ensure your code passes all local linting and formatting checks before submission.

#### 3. Pull Request Protocol

- **Single Responsibility**: Each PR should address a single issue or implement a single feature.
- **Documentation**: Update relevant documentation and comments alongside code changes.
- **Commit Messages**: Use clear, concise, and technical English for all commit messages.
- **Code Review**: Prepare for a technical review process where maintainers may suggest refinements for performance or stability.

### Technical & Engineering Standards

1.  **Licensing**: All contributions are submitted under the **Apache License 2.0**. Every new file must include the project's official copyright header.
2.  **Linguistic Consistency**:
    - Use technical **English** for all source code, documentation, and commit messages.
    - Maintain a clear and precise tone across all technical communications.
3.  **Hierarchy of Comments**:
    - **Category/Main Blocks**: `// ---- Comment Here ----` (For major logic blocks or classes)
    - **Sub-sections**: `// --- Comment Here` (For specific logic groups)
    - **Explanations**: `// Comment Here` (For inline logic descriptions)
4.  **Architecture & Performance**:
    - Adhere to the existing project structure and modular design patterns.
    - Prioritize execution efficiency, memory safety, and system stability in all system-level implementations.

## Credits and Inspirations

Rootify stands on the shoulders of giants in the Android optimization community. For questions or support, reach out to the core team:

- **Dizzy (Developer)**: [Dizzy](https://t.me/WzdDizzyFlasherr)
- **Laynsb (Laya Developer)**: [Laynsb](https://t.me/Laynsb)
- **Telegram Support Group**: [Rootify](https://t.me/AbyRootify)

### Inspirations

- **AZenith**: [Inspirational Architecture](https://github.com/Liliya2727/AZenith)
- **Project Raco**: [Performance Conceptualization](https://github.com/LoggingNewMemory/Project-Raco)

## Compliance and Legal

Rootify is committed to transparency and user privacy. Please refer to our official documentation for detailed information:

- **LICENSE**: [LICENSE](LICENSE) (Apache 2.0)
- **Rootify EULA**: [LICENSE-ROOTIFY](LICENSE-ROOTIFY.md) (End-User License Agreement)
- **Privacy Policy**: [LICENSE-PRIVACY](LICENSE-PRIVACY.md) (Data Handling Transparency)

---

Copyright (C) 2026 Rootify - Aby - FoxLabs
All Rights Reserved.
