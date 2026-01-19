# Claude Code Sandbox Runtime

A lightweight Docker sandbox for running Claude Code in an isolated environment.

## Prerequisites

- Docker installed and running
- Docker image `ccsandbox-node-py` available locally

## Quick Start

### 1. Setup (One-Time)

Copy the `runtime/` folder to your project, then run the setup script:

```bash
# Linux/macOS
cd your-project/runtime
./setup-sandbox.sh

# Windows
cd your-project\runtime
setup-sandbox.bat
```

This copies the necessary files to your project's root directory (parent of `runtime/`).

### 2. Configure API Credentials

Edit `.env` in your project directory. Choose one of these options:

**Option 1: Direct Anthropic API**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
```

**Option 2: AWS Bedrock with Profile** (uses `~/.aws/credentials`)
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_PROFILE=default
AWS_REGION=us-east-1
ANTHROPIC_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
```

**Option 3: AWS Bedrock with Bearer Token**
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_BEARER_TOKEN_BEDROCK=ABSKQm...
AWS_REGION=us-east-1
ANTHROPIC_MODEL=us.anthropic.claude-sonnet-4-20250514-v1:0
```

**Option 4: LLM Gateway / Proxy**
```bash
ANTHROPIC_AUTH_TOKEN=sk-ai-v1-...
ANTHROPIC_BASE_URL=https://your-gateway.example.com
ANTHROPIC_MODEL=claude-sonnet-4-20250514
```

### 3. Start the Sandbox

```bash
# Linux/macOS
./start-sandbox.sh

# Windows
start-sandbox.bat
```

### 4. Exit

Type `exit` or press `Ctrl+D` to leave the sandbox. The container stops automatically.

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Host Machine                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Your Project Directory                              │   │
│  │  ├── your-code/                                      │   │
│  │  ├── .env              ← API credentials             │   │
│  │  ├── docker-compose.yml                              │   │
│  │  └── start-sandbox.sh                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           │ mounted as /workspace           │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Docker Container (ccsandbox-node-py)               │   │
│  │  ├── /workspace/       ← Your project (read/write)  │   │
│  │  ├── Claude Code CLI   ← Installed at startup       │   │
│  │  ├── Node.js 24.x                                   │   │
│  │  ├── Python 3.11.x                                  │   │
│  │  └── Pre-installed tools & packages                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Lifecycle

1. **Start**: `start-sandbox.sh` runs `docker compose up -d` to start the container
2. **Install**: Claude Code CLI is installed via npm (latest version or specified)
3. **Run**: An interactive Claude Code session starts inside the container
4. **Work**: Claude can read/write files in `/workspace` (your project directory)
5. **Exit**: When you exit, `docker compose down` stops and removes the container

### Data Persistence

| Data | Container Path | Storage | Persists? |
|------|----------------|---------|-----------|
| Project files | `/workspace` | Host mount | Yes - on host |
| Claude settings | `/home/node/.claude` | Docker volume | Yes |
| GitHub CLI config | `/home/node/.config/gh` | Docker volume | Yes |
| Shell history | `/commandhistory` | Docker volume | Yes |
| AWS credentials | `/home/node/.aws` | Host mount (read-only) | Yes - on host |
| Installed packages | Container filesystem | Container | No - lost on exit |

### User Mapping

The container runs as the `node` user. The `HOST_UID` and `HOST_GID` environment variables map container user permissions to your host user, so files created in the container have correct ownership on the host.

---

## Files Reference

### Files Modified by Setup

| File | Action | Purpose |
|------|--------|---------|
| `docker-compose.yml` | Created | Container configuration |
| `start-sandbox.sh` or `.bat` | Created | Start script for your OS |
| `.env` | Created (if not exists) | API credentials (from `.env.example`) |
| `.gitignore` | Created or updated | Excludes sandbox files from git |
| `CLAUDE.md` | Created or updated | Sandbox instructions for Claude |

### Setup Script Options

```bash
./setup-sandbox.sh              # Setup in parent directory
./setup-sandbox.sh .            # Setup in current directory
./setup-sandbox.sh /path/to/dir # Setup in specified directory
./setup-sandbox.sh --check      # Verify setup is complete
./setup-sandbox.sh --update     # Update CLAUDE.md section only
./setup-sandbox.sh --uninstall  # Remove sandbox files
```

### Start Script Options

```bash
./start-sandbox.sh              # Default: skip permissions mode
./start-sandbox.sh -p           # With permissions prompts
./start-sandbox.sh -s           # Shell only (no Claude)
./start-sandbox.sh -c           # Continue last conversation
./start-sandbox.sh -r [ID]      # Resume specific session
./start-sandbox.sh -v 1.0.75    # Use specific Claude Code version
```

---

## What's Included

### Languages & Runtimes

| Language | Version | Commands |
|----------|---------|----------|
| Node.js | 24.x | `node`, `npm` |
| Python | 3.11.x | `python3`, `pip3` |

### Pre-installed Python Packages

- **Data Science**: numpy, scipy, pandas, matplotlib
- **Document Processing**: pypdf, python-pptx, python-docx, openpyxl, Pillow
- **Web/Parsing**: beautifulsoup4, lxml, requests
- **Utilities**: PyYAML, tqdm

### CLI Tools

- **AWS CLI v2** - For Bedrock integration
- **GitHub CLI (gh)** - Repository management
- **git** with **delta** - Syntax-highlighted diffs
- **uv** - Fast Python package manager
- **jq** - JSON processor
- **curl**, **wget** - HTTP clients
- **poppler-utils** - PDF utilities
