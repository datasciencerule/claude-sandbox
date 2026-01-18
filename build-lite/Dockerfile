# Claude Code Sandbox - Lite Edition
# A lightweight Docker image (~1.5GB) for running Claude Code
# Supports both Anthropic API (direct) and AWS Bedrock

FROM node:24-slim

ARG TZ=UTC
ENV TZ="$TZ"

# Optional proxy configuration for build (pass via --build-arg)
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY="localhost,127.0.0.1"
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=${NO_PROXY}
ENV NO_PROXY=${NO_PROXY}

# Install system dependencies (minimal set)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    git \
    gnupg2 \
    gosu \
    jq \
    less \
    locales \
    man-db \
    nano \
    poppler-utils \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    unzip \
    vim \
    wget \
    zip \
    zsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Generate and set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install GitHub CLI
RUN curl -kfsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl -k "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Copy and install Python packages
COPY python-packages.txt /tmp/python-packages.txt
RUN pip3 install --no-cache-dir --break-system-packages \
    --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org \
    -r /tmp/python-packages.txt

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

# Note: UID/GID mapping to match host user is handled dynamically at runtime
# by the entrypoint script. The default node user (UID 1000) is kept as-is.
RUN chown -R node:node /home/node /usr/local/share

ARG USERNAME=node

# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory

# Set `DOCKER_BASED_SANDBOX` environment variable to help with orientation
ENV DOCKER_BASED_SANDBOX=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Install git-delta for better diffs
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget --no-check-certificate "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Set up non-root user
USER node

# Configure git and npm for SSL bypass (if behind corporate proxy)
RUN git config --global http.sslVerify false && \
    npm config set strict-ssl false

# Install global npm packages location
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh
ENV SHELL=/bin/zsh

# Disable zsh compfix warnings (for permission issues with mounted volumes)
ENV ZSH_DISABLE_COMPFIX=true

# Set the default editor
ENV EDITOR=nano
ENV VISUAL=nano

# Install zsh with plugins
ARG ZSH_IN_DOCKER_VERSION=1.2.1
RUN sh -c "$(wget --no-check-certificate -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null || true" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# Create .cache directory for various tools
RUN mkdir -p /home/node/.cache

# Install uv for fast Python package management
ARG UV_VERSION=0.9.21
RUN mkdir -p /home/node/.local/bin && \
    curl -kLsS "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/uv.tar.gz && \
    tar -xzf /tmp/uv.tar.gz -C /tmp && \
    mv /tmp/uv-x86_64-unknown-linux-gnu/uv /home/node/.local/bin/ && \
    mv /tmp/uv-x86_64-unknown-linux-gnu/uvx /home/node/.local/bin/ && \
    chmod +x /home/node/.local/bin/uv /home/node/.local/bin/uvx && \
    rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# Add uv to PATH
ENV PATH="/home/node/.local/bin:$PATH"

# Install Claude Code
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Clear proxy environment variables (used only during build)
ENV http_proxy=""
ENV https_proxy=""
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
ENV no_proxy=""
ENV NO_PROXY=""

# Copy and set up entrypoint script for dynamic UID/GID mapping
USER root
COPY entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Container starts as root; entrypoint.sh handles UID mapping and drops to node user
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh"]
