# Claude Code Sandbox - Build

Scripts and configuration to build the `ccsandbox-node-py` Docker image (~1.5GB).

## Quick Start

```bash
# Linux/macOS
./build.sh

# Windows
build.bat
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Docker image definition |
| `build.sh` | Build script for Linux/macOS |
| `build.bat` | Build script for Windows |
| `entrypoint.sh` | Container entrypoint (handles UID/GID mapping at runtime) |
| `python-packages.txt` | Python packages to pre-install in the image |

## Build Options

```bash
./build.sh                    # Standard build
./build.sh --no-cache         # Clean rebuild (no cache)
./build.sh --version 1.0.75   # Specific Claude Code version
./build.sh --tag my-tag       # Custom image tag
```

## What's Included in the Image

### Languages & Runtimes
- **Node.js 24** (from base image)
- **Python 3.11** (system Python with pip)

### Pre-installed Python Packages
- **Data Science**: pandas, numpy, scipy, matplotlib
- **Document Processing**: pypdf, python-pptx, python-docx, openpyxl, Pillow
- **Web/Parsing**: beautifulsoup4, lxml, requests
- **Utilities**: PyYAML, tqdm

### CLI Tools
- **AWS CLI v2** - for Bedrock integration
- **GitHub CLI (gh)** - repository management
- **git** with **delta** - syntax-highlighted diffs
- **uv** - fast Python package manager
- **jq** - JSON processing
- **curl**, **wget** - HTTP clients
- **poppler-utils** - PDF utilities
- **vim**, **nano** - text editors
- **zsh** with **fzf** - shell with fuzzy finder

## Customization

### Adding Python Packages

Edit `python-packages.txt` to add or remove packages, then rebuild.

### Modifying the Image

Edit `Dockerfile` to change system packages, tools, or configuration.

## After Building

Use the `runtime/` folder to run the sandbox in your projects. See [runtime/README.md](../runtime/README.md).
