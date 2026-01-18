# Claude Code Sandbox - Build

A lightweight (~1.5GB) Docker image for running Claude Code with either direct Anthropic API or AWS Bedrock.

## Quick Start

```bash
./build.sh
```

## What's Included

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
- **vim**, **nano** - text editors
- **zsh** with **fzf** - modern shell with fuzzy finder

## Build Options

```bash
# Standard build
./build.sh

# Build without cache (clean rebuild)
./build.sh --no-cache

# Build with specific Claude Code version
./build.sh --version 1.0.75

# Build with custom tag
./build.sh --tag v1.0
```

## Image Size

Target: **~1.5GB** (compared to ~6.8GB full image)

| Component | Size |
|-----------|------|
| Base (node:24-slim) | ~250MB |
| System packages | ~300MB |
| Python packages | ~200MB |
| AWS CLI + tools | ~400MB |
| Claude Code + npm | ~350MB |

## Usage

After building, copy the runtime files to your project:

```bash
cp -r ../runtime/* /path/to/your/project/
cd /path/to/your/project
./start-sandbox.sh
```

## API Configuration

Configure in your project's `.env` file:

### Direct Anthropic API
```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
```

### AWS Bedrock
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_PROFILE=your-profile
AWS_REGION=us-east-1
```

## What's NOT Included (vs Full Image)

- R language and R packages
- LibreOffice, ffmpeg, ImageMagick
- Tesseract OCR, GDAL/GEOS/PROJ
- Corporate proxy/firewall configuration
- Heavy scientific computing libraries (scikit-learn, opencv, etc.)

For the full-featured image with R, document processing, and corporate proxy support, use the `build/` directory instead.
