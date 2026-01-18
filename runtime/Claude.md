# CLAUDE.md

## Sandbox Environment

This Claude Code is running in a lightweight Docker sandbox. Your workspace (`/workspace`) is mounted from the host project directory.

### Available Languages & Runtimes

| Language | Version | Command |
|----------|---------|---------|
| **Node.js** | 24.x | `node`, `npm` |
| **Python** | 3.11.x | `python3`, `pip3` |

### Python Environment

#### Package Manager
- **uv** - Fast package manager; use for virtual environments
- **pip3** - Standard package manager

#### Recommended: Use Virtual Environments
```bash
uv venv && source .venv/bin/activate
uv pip install package-name
```

#### Pre-installed Python Packages

**Data Science:**
- `numpy`, `scipy`, `pandas`, `matplotlib`

**Document Processing:**
- PDF: `pypdf`
- Office: `python-pptx`, `python-docx`, `openpyxl`
- Images: `Pillow`

**Web/Parsing:**
- `beautifulsoup4`, `lxml`, `requests`

**Utilities:**
- `PyYAML`, `tqdm`

### System Tools

#### CLI Tools
- **AWS CLI v2** - Cloud operations (for Bedrock)
- **GitHub CLI (`gh`)** - GitHub operations (use `gh auth login` to authenticate)
- **Git** with **delta** - Version control with syntax highlighting
- **jq** - JSON processor
- **curl**, **wget** - HTTP clients
- **poppler-utils** - PDF utilities (`pdftotext`, `pdftoppm`, etc.)

#### Editors
- **nano** (default), **vim**

### File Structure

| Path | Purpose |
|------|---------|
| `/workspace` | Your project directory (mounted from host) |
| `/workspace/.venv` | Python virtual environment (create with `uv venv`) |
| `/home/node/.claude` | Claude Code global settings |

### API Configuration

This sandbox supports two API modes (configure in `.env`):

#### Direct Anthropic API
```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
```

#### AWS Bedrock
```bash
CLAUDE_CODE_USE_BEDROCK=1
AWS_PROFILE=your-profile
AWS_REGION=us-east-1
```

### Common Tasks

#### Create a Python virtual environment
```bash
uv venv && source .venv/bin/activate
```

#### Install Python packages
```bash
# In virtual environment (recommended)
uv pip install package-name

# System-wide (use sparingly)
pip3 install --break-system-packages package-name
```

#### Authenticate with GitHub
```bash
gh auth login
```

#### Run scripts
```bash
python3 script.py
node script.js
```

### Notes

- Shell: `zsh` (default) with fzf integration
- Editor: `nano` (default), `vim` available
- Your project files persist on the host; container state persists in Docker volumes
- No proxy configuration required - direct internet access
