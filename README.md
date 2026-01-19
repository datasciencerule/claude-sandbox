# Claude Code Sandbox

A lightweight Docker sandbox (~1.5GB) for running Claude Code in an isolated environment.

## Repository Structure

```
├── build/      # Docker image build files
└── runtime/    # Files for using the sandbox in projects
```

## Folders

### `build/`

Contains Dockerfile and scripts to build the `ccsandbox-node-py` Docker image.

**Use this when:** You need to build or customize the Docker image.

```bash
cd build
./build.sh
```

See [build/README.md](build/README.md) for details.

### `runtime/`

Contains setup scripts and configuration files to use the sandbox in your projects.

**Use this when:** You want to run Claude Code in a project using an existing Docker image.

```bash
# Copy runtime/ to your project, then:
cd your-project/runtime
./setup-sandbox.sh
```

See [runtime/README.md](runtime/README.md) for details.

## Workflow

1. **Build once**: Use `build/` to create the Docker image (or obtain a pre-built image)
2. **Use anywhere**: Copy `runtime/` to any project where you want to run Claude Code in the sandbox
