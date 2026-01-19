#!/bin/bash
# entrypoint.sh - Dynamic UID/GID mapping for container user
#
# This script runs as root at container startup and:
# 1. Checks if HOST_UID/HOST_GID environment variables are set
# 2. If they differ from the node user's UID/GID, updates the node user to match
# 3. Fixes ownership of node's home directory and related paths
# 4. Drops privileges and executes the command as the node user
#
# This allows the container to run with the host user's UID/GID, ensuring
# proper file ownership without needing to chmod 755 sensitive directories.

set -e

# Default UID/GID (matches what's set in Dockerfile)
DEFAULT_UID=1000
DEFAULT_GID=1000

# Get host UID/GID from environment (set by docker-compose)
HOST_UID="${HOST_UID:-$DEFAULT_UID}"
HOST_GID="${HOST_GID:-$DEFAULT_GID}"

# Get current node user's UID/GID
CURRENT_UID=$(id -u node)
CURRENT_GID=$(id -g node)

# Function to update user/group IDs
update_uid_gid() {
    local new_uid=$1
    local new_gid=$2

    echo "Updating node user UID:GID from $CURRENT_UID:$CURRENT_GID to $new_uid:$new_gid"

    # Update group ID if different
    if [[ "$new_gid" != "$CURRENT_GID" ]]; then
        # Check if target GID already exists (and isn't node's group)
        if getent group "$new_gid" > /dev/null 2>&1; then
            existing_group=$(getent group "$new_gid" | cut -d: -f1)
            if [[ "$existing_group" != "node" ]]; then
                echo "Warning: GID $new_gid already exists as group '$existing_group', removing it"
                groupdel "$existing_group" 2>/dev/null || true
            fi
        fi
        groupmod -g "$new_gid" node
    fi

    # Update user ID if different
    if [[ "$new_uid" != "$CURRENT_UID" ]]; then
        # Check if target UID already exists (and isn't node)
        if getent passwd "$new_uid" > /dev/null 2>&1; then
            existing_user=$(getent passwd "$new_uid" | cut -d: -f1)
            if [[ "$existing_user" != "node" ]]; then
                echo "Warning: UID $new_uid already exists as user '$existing_user', removing it"
                userdel "$existing_user" 2>/dev/null || true
            fi
        fi
        usermod -u "$new_uid" node
    fi

    # Fix ownership of node's directories
    # Note: /workspace is mounted from host and already has correct ownership
    chown -R node:node /home/node 2>/dev/null || true
    chown -R node:node /usr/local/share/npm-global 2>/dev/null || true
    chown -R node:node /commandhistory 2>/dev/null || true
}

# Update UID/GID if needed
if [[ "$HOST_UID" != "$CURRENT_UID" ]] || [[ "$HOST_GID" != "$CURRENT_GID" ]]; then
    update_uid_gid "$HOST_UID" "$HOST_GID"
fi

# Execute the command as the node user
# Using gosu for proper signal handling and TTY support
exec gosu node "$@"
