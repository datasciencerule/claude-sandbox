#!/bin/bash
# start-sandbox.sh - Start the Claude Code sandbox container (Lite)
#
# Usage:
#   ./start-sandbox.sh                  # Run claude --dangerously-skip-permissions (default)
#   ./start-sandbox.sh -p|--permissions # Run claude (with normal permissions)
#   ./start-sandbox.sh -s|--shell       # Run zsh shell
#
# This script:
#   1. Starts the container with docker compose up -d
#   2. Waits for the container to be ready
#   3. Runs the specified command as the node user
#   4. When you exit, stops the container with docker compose down

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure sandbox files are in .gitignore
GITIGNORE_FILE="$SCRIPT_DIR/.gitignore"
SANDBOX_FILES=(
    "docker-compose.yml"
    "start-sandbox.sh"
    "CLAUDE.md"
    ".env"
)

# Create .gitignore if it doesn't exist
if [[ ! -f "$GITIGNORE_FILE" ]]; then
    touch "$GITIGNORE_FILE"
fi

# Add each sandbox file to .gitignore if not already present
for file in "${SANDBOX_FILES[@]}"; do
    if ! grep -qxF "$file" "$GITIGNORE_FILE" 2>/dev/null; then
        echo "$file" >> "$GITIGNORE_FILE"
    fi
done

# Generate a unique project name based on user and directory
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
# Sanitize project name (lowercase, alphanumeric only)
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
export COMPOSE_PROJECT_NAME="sandbox-${USER}-${PROJECT_NAME}"

# Load from .env file if it exists (strip Windows CR characters)
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source <(tr -d '\r' < "$SCRIPT_DIR/.env")
    set +a
fi

# Check API configuration
if [[ -z "$ANTHROPIC_API_KEY" && -z "$ANTHROPIC_AUTH_TOKEN" && -z "$CLAUDE_CODE_USE_BEDROCK" ]]; then
    echo "WARNING: No API configuration in .env file."
    echo "  1) ANTHROPIC_API_KEY=sk-ant-...      (Direct API)"
    echo "  2) ANTHROPIC_AUTH_TOKEN=...         (Gateway/Proxy)"
    echo "  3) CLAUDE_CODE_USE_BEDROCK=1        (AWS Bedrock)"
    echo ""
fi

# When using Bedrock, clear ANTHROPIC_API_KEY to prevent conflicts
# (host environment may have this set from another Claude session)
if [[ -n "$CLAUDE_CODE_USE_BEDROCK" ]]; then
    unset ANTHROPIC_API_KEY
    export ANTHROPIC_API_KEY=""
fi

# Export git identity if set
export GIT_AUTHOR_NAME
export GIT_AUTHOR_EMAIL
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"

# Export API configuration for Gateway/Proxy
export ANTHROPIC_AUTH_TOKEN
export ANTHROPIC_BASE_URL
export ANTHROPIC_MODEL

# Export model defaults if set
export ANTHROPIC_DEFAULT_HAIKU_MODEL
export ANTHROPIC_DEFAULT_OPUS_MODEL
export ANTHROPIC_DEFAULT_SONNET_MODEL

# Export runtime configuration if set
export CLAUDE_CODE_ENTRYPOINT
export CLAUDE_CODE_SSE_PORT
export CLAUDE_CODE_GIT_BASH_PATH

# Export host UID/GID for dynamic user mapping in container
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)

# Parse command line arguments
MODE="default"
CLAUDE_VERSION="latest"
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--permissions)
            MODE="permissions"
            shift
            ;;
        -s|--shell)
            MODE="shell"
            shift
            ;;
        -v|--version)
            CLAUDE_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (none)            Run claude --dangerously-skip-permissions (default)"
            echo "  -p, --permissions Run claude with normal permissions"
            echo "  -s, --shell       Run zsh shell"
            echo "  -v, --version VER Install specific Claude Code version (default: latest)"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Set command based on mode
case $MODE in
    default)
        CMD="claude --dangerously-skip-permissions"
        DESC="Claude Code (skip permissions)"
        ;;
    permissions)
        CMD="claude"
        DESC="Claude Code (with permissions)"
        ;;
    shell)
        CMD="zsh"
        DESC="zsh shell"
        ;;
esac

echo "Starting Claude Code sandbox (lite)..."
docker compose up -d

# Wait for container to be ready
echo "Waiting for container to initialize..."
sleep 2

# Check if container is running
if ! docker compose ps --format json | grep -q '"State":"running"'; then
    echo "ERROR: Container failed to start. Check logs with: docker compose logs"
    exit 1
fi

# Install Claude Code CLI (specified version or latest)
# Note: npm install runs as root for write access to global npm directory
echo "Installing Claude Code CLI version: $CLAUDE_VERSION..."
docker compose exec claude-code npm install -g --loglevel=error --no-fund --no-update-notifier @anthropic-ai/claude-code@"$CLAUDE_VERSION"
echo "Installation complete."

echo "Container ready. Starting $DESC as node user..."
echo "Type 'exit' to leave and stop the container."
echo "----------------------------------------"

# Enter the container as node user (exec defaults to root, so -u node is required)
docker compose exec -u node claude-code $CMD || true

echo "----------------------------------------"
echo "Stopping container..."
docker compose down -t 2

echo "Done."
