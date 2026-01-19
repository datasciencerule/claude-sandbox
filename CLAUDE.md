# CLAUDE.md

## About This Repository

This repository provides a lightweight Docker-based sandbox for running Claude Code. It builds a ~1.5GB image that supports direct Anthropic API, AWS Bedrock, and LLM Gateway/Proxy.

## Repository Structure

```
├── build/                  # Docker image build files
│   ├── Dockerfile          # Image definition
│   ├── build.sh           # Build script (Linux/macOS)
│   ├── build.bat          # Build script (Windows)
│   ├── entrypoint.sh      # Container entrypoint (UID/GID mapping)
│   ├── python-packages.txt # Python dependencies
│   └── README.md          # Build documentation
├── runtime/               # Files to copy to user projects
│   ├── .env.example       # Environment template (copy to .env)
│   ├── CLAUDE.sandbox.md  # Sandbox instructions template (merged into project CLAUDE.md)
│   ├── docker-compose.yml # Container configuration
│   ├── setup-sandbox.sh   # One-time project setup (Linux/macOS)
│   ├── setup-sandbox.bat  # One-time project setup (Windows)
│   ├── start-sandbox.sh   # Container lifecycle (Linux/macOS)
│   └── start-sandbox.bat  # Container lifecycle (Windows)
└── CLAUDE.md              # This file (repo instructions)
```

## Building the Image

```bash
cd build
./build.sh                    # Standard build
./build.sh --no-cache         # Clean rebuild
./build.sh --version 1.0.75   # Specific Claude Code version
```

## What's Included in the Image

### Languages & Runtimes
| Language | Version | Command |
|----------|---------|---------|
| Node.js | 24.x | `node`, `npm` |
| Python | 3.11.x | `python3`, `pip3` |

### Pre-installed Python Packages
- **Data Science**: pandas, numpy, scipy, matplotlib
- **Document Processing**: pypdf, python-pptx, python-docx, openpyxl, Pillow
- **Web/Parsing**: beautifulsoup4, lxml, requests
- **Utilities**: PyYAML, tqdm

### CLI Tools
- **AWS CLI v2** - For Bedrock integration
- **GitHub CLI (gh)** - Repository management
- **git** with **delta** - Syntax-highlighted diffs
- **uv** - Fast Python package manager
- **jq** - JSON processing
- **curl**, **wget** - HTTP clients
- **poppler-utils** - PDF utilities
- **vim**, **nano** - Text editors
- **zsh** with **fzf** - Shell with fuzzy finder

## What's NOT Included

This is a lightweight image. The following are excluded:
- R language and packages
- LibreOffice, ffmpeg, ImageMagick
- Tesseract OCR, GDAL/GEOS/PROJ
- Heavy ML libraries (scikit-learn, opencv, pytorch, etc.)

## Key Files

### build/Dockerfile
Defines the Docker image. Key features:
- Based on `node:24-slim`
- Installs system packages, AWS CLI, GitHub CLI
- Installs Python packages from `python-packages.txt`
- Installs Claude Code via npm
- Uses `entrypoint.sh` for dynamic UID/GID mapping

### build/entrypoint.sh
Handles dynamic UID/GID mapping at runtime. Allows the container to run with the host user's permissions via `HOST_UID` and `HOST_GID` environment variables.

### build/python-packages.txt
Lists Python packages to pre-install. Modify this to add/remove packages from the image.

### runtime/CLAUDE.sandbox.md
Template containing sandbox environment instructions. The setup script merges this into your project's CLAUDE.md using markers (`<!-- BEGIN/END SANDBOX ENVIRONMENT -->`), allowing idempotent updates.

### runtime/setup-sandbox.sh / setup-sandbox.bat
One-time project initialization scripts. They:
1. Copy docker-compose.yml to the project
2. Copy .env.example to .env (if .env doesn't exist)
3. Copy start-sandbox.sh and start-sandbox.bat
4. Update .gitignore with sandbox files
5. Merge sandbox instructions into the project's CLAUDE.md

### runtime/start-sandbox.sh / start-sandbox.bat
Container lifecycle scripts. They only handle starting and stopping the container - no file creation or modification.

## Using the Sandbox in Projects

1. Copy or unzip the `runtime/` folder into your project directory
2. Run the setup script from within the runtime folder:
   ```bash
   # Linux/macOS
   cd your-project/runtime
   ./setup-sandbox.sh           # Defaults to parent directory

   # Windows
   cd your-project\runtime
   setup-sandbox.bat            # Defaults to parent directory
   ```
3. Edit `.env` in your project to configure API credentials
4. Start the sandbox:
   ```bash
   # Linux/macOS
   ./start-sandbox.sh

   # Windows
   start-sandbox.bat
   ```
5. (Optional) Delete the `runtime/` folder after setup

### Setup Script Options

```bash
./setup-sandbox.sh [TARGET_DIR]    # Full setup (default: parent directory)
./setup-sandbox.sh .               # Setup in current directory
./setup-sandbox.sh --check         # Verify setup is complete
./setup-sandbox.sh --update        # Update CLAUDE.md section only
./setup-sandbox.sh --uninstall     # Remove sandbox files
```

## API Configuration

The sandbox supports four authentication modes (configured via `.env` in user projects):

### Option 1: Direct Anthropic API
```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
```

### Option 2: AWS Bedrock with Profile
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_PROFILE=your-profile
AWS_REGION=us-east-1
```

### Option 3: AWS Bedrock with Bearer Token
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_BEARER_TOKEN_BEDROCK=ABSK...
AWS_REGION=us-east-1
```

### Option 4: LLM Gateway / Proxy
```bash
ANTHROPIC_AUTH_TOKEN=sk-ai-v1-...
ANTHROPIC_BASE_URL=https://your-gateway.example.com
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

## Development Notes

- Image builds in ~5-10 minutes depending on cache
- Target size is ~1.5GB (vs ~6.8GB for full-featured images)
- The `node` user (UID 1000) is the default; entrypoint remaps if needed
