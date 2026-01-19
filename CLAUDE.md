# CLAUDE.md

Docker-based sandbox for running Claude Code. Supports Anthropic API, AWS Bedrock, and LLM Gateway/Proxy.

## Repository Structure

```
├── build/                  # Docker image build files
│   ├── Dockerfile          # Image definition (node:24-slim base)
│   ├── build.sh           # Build script (Linux/macOS)
│   ├── build.bat          # Build script (Windows)
│   ├── entrypoint.sh      # Container entrypoint (UID/GID mapping)
│   └── python-packages.txt # Python dependencies to pre-install
├── runtime/               # Files distributed to user projects
│   ├── .env.example       # Environment template
│   ├── CLAUDE.sandbox.md  # Merged into project CLAUDE.md
│   ├── docker-compose.yml # Container configuration
│   ├── setup-sandbox.sh   # One-time setup (Linux/macOS)
│   ├── setup-sandbox.bat  # One-time setup (Windows)
│   ├── start-sandbox.sh   # Container lifecycle (Linux/macOS)
│   └── start-sandbox.bat  # Container lifecycle (Windows)
```

## Key Files

### build/Dockerfile
- Base: `node:24-slim`
- Installs: system packages, AWS CLI, GitHub CLI, Python packages from `python-packages.txt`, Claude Code via npm
- Uses `entrypoint.sh` for dynamic UID/GID mapping

### build/entrypoint.sh
Remaps container user UID/GID at runtime via `HOST_UID`/`HOST_GID` env vars.

### runtime/CLAUDE.sandbox.md
Template merged into project CLAUDE.md using markers: `<!-- BEGIN SANDBOX ENVIRONMENT -->` / `<!-- END SANDBOX ENVIRONMENT -->`. Supports idempotent updates.

### runtime/setup-sandbox.sh
1. Copies docker-compose.yml, .env.example, start scripts to project
2. Updates .gitignore
3. Merges CLAUDE.sandbox.md into project's CLAUDE.md

### runtime/start-sandbox.sh
Container lifecycle only (start/stop). No file modifications.

## Environment Variables

Auth modes configured via `.env`:
- `ANTHROPIC_API_KEY` - Direct API
- `CLAUDE_CODE_USE_BEDROCK`, `AWS_PROFILE`/`AWS_BEARER_TOKEN_BEDROCK`, `AWS_REGION` - Bedrock
- `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_MODEL` - Gateway/Proxy
