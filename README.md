# ColdManual

An open-source lightweight desktop app for browsing, downloading, and reading offline documentation for programming languages, frameworks, and developer tools.

---

## Building

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

> [!CAUTION] THIS APP IS CURRENTLY UNDER WORK AND IS NOT IN A USABLE STATE


## License

This project is licensed under the [MIT License](LICENSE).
