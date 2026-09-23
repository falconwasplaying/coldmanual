# ❄️ ColdManual

An open-source, ultra-low resource desktop application for browsing, downloading, and reading offline documentation for programming languages, frameworks, and developer tools.

Built natively with **C++20** and **Qt 6 (QML / Qt Quick)** for blazing fast startup and minimal RAM & storage usage.

---

## ✨ Features

- **🌐 Remote Catalog & Browsing**:
  - Discover and download documentation for top languages and frameworks (*Python, C++, Rust, Go, JavaScript, React, Qt 6, Node.js, SQLite, Docker, PostgreSQL, Django*, and more).
  - Filter by categories (*Languages, Frontend, Backend, Databases, Systems, DevOps*).
- **📌 Flexible Versioning & Auto-Update**:
  - Select specific versions (e.g. `Python 3.12`, `Python 3.11`, `PostgreSQL 16`).
  - Or select **"Latest Stable"** / **"Latest"** to automatically check for new releases and keep your local offline documentation updated in the background.
  - Per-docset auto-update toggles and global "Check for Updates" / "Update All" controls.
- **⚡ Ultra-Low RAM Overhead**:
  - Zero full-index memory loading. Uses on-disk **SQLite indexes** (`docSet.dsidx`) with paginated lookups, keeping idle RAM usage around **25–45 MB** (compared to 400MB+ for Electron-based wrappers).
- **🔍 Instant Omni-Search (`Ctrl+K` / `Ctrl+P`)**:
  - Floating spotlight-style launcher for searching functions, classes, types, methods, guides, and modules across all installed documentation sets.
- **📖 Offline Reader**:
  - Split view with table of contents & symbol tree on the left, rich typography reader on the right.
  - History navigation (Back / Forward), zoom scaling, and dark/light mode.
- **📁 Efficient Storage**:
  - Streaming downloads with live transfer speeds and progress bars.
  - Automated background extraction and archive cleanup.
  - Storage footprint tracking per library.

---

## 🏗️ Architecture

```
ColdManual
├── CMakeLists.txt              # CMake build definition (C++20, Qt6, LibArchive)
├── resources.qrc               # Embedded QML views, theme, and catalog
├── resources/
│   └── catalog.json            # Bundled default catalog manifest
├── src/
│   ├── main.cpp                # Application entry point & QML context wiring
│   ├── core/
│   │   ├── CatalogItem.h       # Models for catalog, versions, and installed items
│   │   ├── DocCatalogManager.* # Remote catalog fetch, filtering, and model
│   │   ├── DocsetDownloader.*  # Streaming HTTP downloader & LibArchive extraction
│   │   ├── DocsetManager.*     # Local registry, disk calculation & auto-updater
│   │   ├── DocsetSearchEngine.*# SQLite indexed symbol search & file content provider
│   │   └── SettingsManager.*   # Storage path, update interval, theme, font size
│   └── qml/
│       ├── Main.qml            # Root window, sidebar navigation, keyboard shortcuts
│       ├── Theme.qml           # Dark/Light theme design system
│       ├── components/
│       │   └── OmniSearchModal.qml # Floating spotlight symbol search (Ctrl+K)
│       └── views/
│           ├── ReaderView.qml  # Split TOC symbol tree & document reader
│           ├── CatalogView.qml # Grid of languages, version dropdowns, download progress
│           ├── InstalledView.qml # Installed docsets, storage sizes, auto-update switches
│           └── SettingsView.qml# Storage folder, update intervals, font scaling
└── tests/
    └── test_core.cpp           # Automated engine unit and integration tests
```

---

## 🚀 Building & Running

### Prerequisites (Windows)
- [MSYS2](https://www.msys2.org/) with UCRT64 toolchain.
- Qt 6 packages:
  ```powershell
  pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-qt6-base mingw-w64-ucrt-x86_64-qt6-declarative mingw-w64-ucrt-x86_64-qt6-svg mingw-w64-ucrt-x86_64-libarchive
  ```

### Build
```powershell
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

### Run
```powershell
.\build\coldmanual.exe
```

### Run Automated Tests
```powershell
cmake --build build --target test_core
.\build\test_core.exe
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Ctrl+K` or `Ctrl+P` | Open Omni-Search dialog |
| `Ctrl+1` | Switch to **Reader** view |
| `Ctrl+2` | Switch to **Browse Catalog** view |
| `Ctrl+3` | Switch to **Installed Documentation** view |
| `Ctrl+,` | Switch to **Settings** view |
| `Esc` | Close Omni-Search modal |

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
