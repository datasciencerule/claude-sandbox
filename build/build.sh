#!/bin/bash
# build.sh - Build the Claude Code Sandbox Lite image
#
# Usage:
#   ./build.sh                    # Build with default settings
#   ./build.sh --no-cache         # Build without cache
#   ./build.sh --version 1.0.75   # Build with specific Claude Code version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
IMAGE_NAME="ccsandbox-node-py"
IMAGE_TAG="latest"
CLAUDE_VERSION="latest"
BUILD_ARGS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            BUILD_ARGS="$BUILD_ARGS --no-cache"
            shift
            ;;
        --version)
            CLAUDE_VERSION="$2"
            shift 2
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-cache        Build without Docker cache"
            echo "  --version VER     Claude Code version (default: latest)"
            echo "  --tag TAG         Image tag (default: latest)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect proxy from environment
PROXY_ARGS=""
if [[ -n "${HTTP_PROXY:-${http_proxy:-}}" ]]; then
    DETECTED_PROXY="${HTTP_PROXY:-${http_proxy}}"
    PROXY_ARGS="--build-arg HTTP_PROXY=$DETECTED_PROXY --build-arg HTTPS_PROXY=$DETECTED_PROXY"
    echo "Detected proxy: $DETECTED_PROXY"
fi

echo "Building Claude Code Sandbox (Lite)..."
echo "  Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "  Claude Code version: ${CLAUDE_VERSION}"
echo ""

docker build \
    $BUILD_ARGS \
    $PROXY_ARGS \
    --build-arg CLAUDE_CODE_VERSION="$CLAUDE_VERSION" \
    --build-arg TZ="$(cat /etc/timezone 2>/dev/null || echo UTC)" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo ""
echo "Build complete!"
echo ""
echo "Image size:"
docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
