#!/bin/bash
# setup-sandbox.sh - Initialize Claude Code sandbox in a project
#
# Usage:
#   ./setup-sandbox.sh [TARGET_DIR]    # Setup sandbox in TARGET_DIR (default: parent directory)
#   ./setup-sandbox.sh --check         # Verify setup is complete
#   ./setup-sandbox.sh --update        # Update existing setup (refresh CLAUDE.md section)
#   ./setup-sandbox.sh --uninstall     # Remove sandbox files from project
#
# This script:
#   1. Copies docker-compose.yml to the target directory
#   2. Copies .env.example to .env (if .env doesn't exist)
#   3. Copies start-sandbox.sh
#   4. Updates .gitignore with sandbox files
#   5. Merges sandbox instructions into project's CLAUDE.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Marker comments for CLAUDE.md section
MARKER_BEGIN="<!-- BEGIN SANDBOX ENVIRONMENT -->"
MARKER_END="<!-- END SANDBOX ENVIRONMENT -->"

# Files to copy and add to .gitignore (Linux/macOS only)
SANDBOX_FILES=(
    "docker-compose.yml"
    "start-sandbox.sh"
    ".env"
)

# Print colored output
print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
print_warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Show usage
show_help() {
    echo "Usage: $0 [OPTIONS] [TARGET_DIR]"
    echo ""
    echo "Initialize Claude Code sandbox in a project directory."
    echo ""
    echo "Arguments:"
    echo "  TARGET_DIR          Target directory (default: parent directory)"
    echo ""
    echo "Options:"
    echo "  --check             Verify setup is complete"
    echo "  --update            Update existing setup (refresh CLAUDE.md section)"
    echo "  --uninstall         Remove sandbox files from project"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Setup in parent directory (typical after unzipping)"
    echo "  $0 .                # Setup in current directory"
    echo "  $0 /path/to/project # Setup in specific directory"
    echo "  $0 --check          # Check if setup is complete"
    echo "  $0 --update         # Update CLAUDE.md sandbox section"
}

# Prompt for Git identity if not configured in .env
prompt_git_identity() {
    local target_dir="$1"
    local env_file="$target_dir/.env"

    # Skip if .env doesn't exist
    if [[ ! -f "$env_file" ]]; then
        return 0
    fi

    # Check if GIT_AUTHOR_NAME is already set (uncommented) in .env
    local has_name has_email
    has_name=$(grep -E "^GIT_AUTHOR_NAME=.+" "$env_file" 2>/dev/null | grep -v "^#" || true)
    has_email=$(grep -E "^GIT_AUTHOR_EMAIL=.+" "$env_file" 2>/dev/null | grep -v "^#" || true)

    if [[ -n "$has_name" && -n "$has_email" ]]; then
        print_info "Git identity already configured in .env"
        return 0
    fi

    echo ""
    print_info "Git identity not configured. This is used for git commits inside the sandbox."
    echo ""

    # Prompt for name
    local git_name=""
    if [[ -z "$has_name" ]]; then
        read -p "Enter your name for git commits (or press Enter to skip): " git_name
    fi

    # Prompt for email
    local git_email=""
    if [[ -z "$has_email" ]]; then
        read -p "Enter your email for git commits (or press Enter to skip): " git_email
    fi

    # Append to .env if values provided
    if [[ -n "$git_name" || -n "$git_email" ]]; then
        echo "" >> "$env_file"
        echo "# Git Identity (added by setup)" >> "$env_file"
        if [[ -n "$git_name" ]]; then
            echo "GIT_AUTHOR_NAME=$git_name" >> "$env_file"
            echo "GIT_COMMITTER_NAME=$git_name" >> "$env_file"
        fi
        if [[ -n "$git_email" ]]; then
            echo "GIT_AUTHOR_EMAIL=$git_email" >> "$env_file"
            echo "GIT_COMMITTER_EMAIL=$git_email" >> "$env_file"
        fi
        print_success "Git identity added to .env"
    else
        print_info "Git identity skipped (you can add it later in .env)"
    fi
}

# Update .gitignore with sandbox files
update_gitignore() {
    local target_dir="$1"
    local gitignore_file="$target_dir/.gitignore"
    local added_files=()

    # Create .gitignore if it doesn't exist
    if [[ ! -f "$gitignore_file" ]]; then
        touch "$gitignore_file"
        print_info "Created .gitignore"
    fi

    # Add each sandbox file to .gitignore if not already present
    for file in "${SANDBOX_FILES[@]}"; do
        if ! grep -qxF "$file" "$gitignore_file" 2>/dev/null; then
            echo "$file" >> "$gitignore_file"
            added_files+=("$file")
        fi
    done

    if [[ ${#added_files[@]} -gt 0 ]]; then
        print_success "Added to .gitignore: ${added_files[*]}"
    else
        print_info ".gitignore already up to date"
    fi
}

# Merge sandbox instructions into CLAUDE.md using markers
merge_claude_md() {
    local target_dir="$1"
    local template_file="$SCRIPT_DIR/CLAUDE.sandbox.md"
    local target_file="$target_dir/CLAUDE.md"

    if [[ ! -f "$template_file" ]]; then
        print_error "Template file not found: $template_file"
        return 1
    fi

    # Read template content
    local template_content
    template_content=$(cat "$template_file")

    # Content to insert (with markers)
    local insert_content
    insert_content=$(printf "%s\n%s\n%s" "$MARKER_BEGIN" "$template_content" "$MARKER_END")

    if [[ ! -f "$target_file" ]]; then
        # No CLAUDE.md exists - create with markers
        echo "$insert_content" > "$target_file"
        print_success "Created CLAUDE.md with sandbox instructions"
    elif grep -qF "$MARKER_BEGIN" "$target_file"; then
        # Markers exist - replace content between them
        # Use awk to replace content between markers
        awk -v new_content="$insert_content" '
            BEGIN { skip=0; printed=0 }
            /<!-- BEGIN SANDBOX ENVIRONMENT -->/ { skip=1; if (!printed) { print new_content; printed=1 } next }
            /<!-- END SANDBOX ENVIRONMENT -->/ { skip=0; next }
            !skip { print }
        ' "$target_file" > "$target_file.tmp" && mv "$target_file.tmp" "$target_file"
        print_success "Updated sandbox section in CLAUDE.md"
    else
        # No markers - append with markers
        echo "" >> "$target_file"
        echo "$insert_content" >> "$target_file"
        print_success "Appended sandbox instructions to CLAUDE.md"
    fi
}

# Remove sandbox section from CLAUDE.md
remove_claude_md_section() {
    local target_dir="$1"
    local target_file="$target_dir/CLAUDE.md"

    if [[ ! -f "$target_file" ]]; then
        return 0
    fi

    if grep -qF "$MARKER_BEGIN" "$target_file"; then
        # Remove content between markers (inclusive)
        awk '
            /<!-- BEGIN SANDBOX ENVIRONMENT -->/ { skip=1; next }
            /<!-- END SANDBOX ENVIRONMENT -->/ { skip=0; next }
            !skip { print }
        ' "$target_file" > "$target_file.tmp"

        # Remove trailing empty lines
        sed -i'' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$target_file.tmp" 2>/dev/null || \
        sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$target_file.tmp" 2>/dev/null || true

        mv "$target_file.tmp" "$target_file"

        # If file is empty or only whitespace, remove it
        if [[ ! -s "$target_file" ]] || [[ -z "$(grep -v '^[[:space:]]*$' "$target_file")" ]]; then
            rm "$target_file"
            print_success "Removed CLAUDE.md (was empty after removing sandbox section)"
        else
            print_success "Removed sandbox section from CLAUDE.md"
        fi
    fi
}

# Check if setup is complete
check_setup() {
    local target_dir="$1"
    local missing=()
    local status=0

    echo "Checking sandbox setup in: $target_dir"
    echo ""

    # Check for required files
    for file in "docker-compose.yml" "start-sandbox.sh" ".env"; do
        if [[ -f "$target_dir/$file" ]]; then
            print_success "$file exists"
        else
            print_error "$file missing"
            missing+=("$file")
            status=1
        fi
    done

    # Check .gitignore
    local gitignore_file="$target_dir/.gitignore"
    if [[ -f "$gitignore_file" ]]; then
        local gitignore_ok=true
        for file in "${SANDBOX_FILES[@]}"; do
            if ! grep -qxF "$file" "$gitignore_file" 2>/dev/null; then
                gitignore_ok=false
                break
            fi
        done
        if $gitignore_ok; then
            print_success ".gitignore contains sandbox files"
        else
            print_warning ".gitignore missing some sandbox files"
        fi
    else
        print_warning ".gitignore not found"
    fi

    # Check CLAUDE.md for sandbox section
    local claude_file="$target_dir/CLAUDE.md"
    if [[ -f "$claude_file" ]]; then
        if grep -qF "$MARKER_BEGIN" "$claude_file"; then
            print_success "CLAUDE.md contains sandbox instructions"
        else
            print_warning "CLAUDE.md exists but missing sandbox section"
        fi
    else
        print_warning "CLAUDE.md not found"
    fi

    echo ""
    if [[ $status -eq 0 ]]; then
        print_success "Setup is complete!"
    else
        print_error "Setup incomplete. Run setup-sandbox.sh to fix."
    fi

    return $status
}

# Uninstall sandbox files
uninstall() {
    local target_dir="$1"

    echo "Removing sandbox files from: $target_dir"
    echo ""

    # Remove sandbox files
    for file in "docker-compose.yml" "start-sandbox.sh"; do
        if [[ -f "$target_dir/$file" ]]; then
            rm "$target_dir/$file"
            print_success "Removed $file"
        fi
    done

    # Remove sandbox section from CLAUDE.md
    remove_claude_md_section "$target_dir"

    # Note: We don't remove .env (may contain user credentials)
    # Note: We don't modify .gitignore (may have user additions)

    print_warning "Note: .env and .gitignore were not modified (may contain user data)"
    echo ""
    print_success "Sandbox files removed. You may manually delete .env if no longer needed."
}

# Main setup function
setup() {
    local target_dir="$1"
    local update_only="$2"

    echo "Setting up Claude Code sandbox in: $target_dir"
    echo ""

    # Verify source files exist
    if [[ ! -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        print_error "Source files not found. Run this script from the runtime directory."
        exit 1
    fi

    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        print_info "Created directory: $target_dir"
    fi

    if [[ "$update_only" != "true" ]]; then
        # Copy docker-compose.yml
        if [[ ! -f "$target_dir/docker-compose.yml" ]]; then
            cp "$SCRIPT_DIR/docker-compose.yml" "$target_dir/"
            print_success "Copied docker-compose.yml"
        else
            print_info "docker-compose.yml already exists (skipped)"
        fi

        # Copy .env.example to .env
        if [[ ! -f "$target_dir/.env" ]]; then
            if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
                cp "$SCRIPT_DIR/.env.example" "$target_dir/.env"
                print_success "Copied .env.example to .env"
            else
                print_warning ".env.example not found, skipping"
            fi
        else
            print_warning ".env already exists (not overwritten - check for updates manually)"
        fi

        # Prompt for Git identity if not configured
        prompt_git_identity "$target_dir"

        # Copy start script (Linux/macOS only)
        cp "$SCRIPT_DIR/start-sandbox.sh" "$target_dir/"
        chmod +x "$target_dir/start-sandbox.sh"
        print_success "Copied start-sandbox.sh"

        # Update .gitignore
        update_gitignore "$target_dir"
    fi

    # Merge CLAUDE.md (always done, even for update-only)
    merge_claude_md "$target_dir"

    echo ""
    print_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .env with your API credentials"
    echo "  2. Run ./start-sandbox.sh to start the sandbox"
    echo ""
}

# Parse arguments
MODE="setup"
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            MODE="check"
            shift
            ;;
        --update)
            MODE="update"
            shift
            ;;
        --uninstall)
            MODE="uninstall"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Default target directory to parent directory (assumes script is in runtime/ subfolder)
if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR=".."
fi

# Convert to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    # Directory doesn't exist yet, create it
    mkdir -p "$TARGET_DIR"
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
}

# Execute based on mode
case $MODE in
    setup)
        setup "$TARGET_DIR" "false"
        ;;
    update)
        setup "$TARGET_DIR" "true"
        ;;
    check)
        check_setup "$TARGET_DIR"
        ;;
    uninstall)
        uninstall "$TARGET_DIR"
        ;;
esac
