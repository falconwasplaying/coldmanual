# ColdManual

An open-source lightweight desktop app for browsing, downloading, and reading offline documentation for programming languages, frameworks, and developer tools.

---

## Building

### Prerequisites (Windows)

- [MSYS2](https://www.msys2.org/) with UCRT64 toolchain.
- Install the required toolchain and Qt 6 packages via the MSYS2 UCRT64 terminal:

  ```bash
  pacman -S mingw-w64-ucrt-x86_64-gcc \
            mingw-w64-ucrt-x86_64-ninja \
            mingw-w64-ucrt-x86_64-cmake \
            mingw-w64-ucrt-x86_64-qt6-base \
            mingw-w64-ucrt-x86_64-qt6-declarative \
            mingw-w64-ucrt-x86_64-qt6-svg \
            mingw-w64-ucrt-x86_64-libarchive
  ```

> [!NOTE]
> If building from Windows PowerShell or Command Prompt, ensure the MSYS2 UCRT64 `bin` directory (typically `C:\msys64\ucrt64\bin`) is added to your `PATH`:
> ```powershell
> $env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"
> ```

---

### Configure & Build

1. **Configure CMake** (Release mode with Ninja):
   ```powershell
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
   ```

2. **Build the Project**:
   ```powershell
   cmake --build build --parallel 2
   ```
   *(Or using Ninja directly: `ninja -C build -j 2`)*

> [!TIP]
> **Memory Optimization (`--parallel 2` / `-j 2`)**:
> ColdManual includes Precompiled Headers (PCH) and an object library architecture to accelerate compilation. On machines with 8 GB RAM or lower, limiting concurrent compilation jobs to 2 (`--parallel 2` or `-j 2`) prevents compiler memory spikes and keeps RAM usage under ~1 GB throughout the build.

---

### Run

```powershell
.\build\coldmanual.exe
```

---

### Run Automated Tests

To compile and execute the test suite:

```powershell
cmake --build build --target test_core --parallel 2
.\build\test_core.exe
```

---

> [!WARNING]
> THIS APP IS CURRENTLY UNDER WORK AND IS NOT IN A USABLE STATE

## License

This project is licensed under the [MIT License](LICENSE).
