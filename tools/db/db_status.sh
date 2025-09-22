#!/bin/bash

# Quick status checker
# Usage: ./db_status.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/db_config.sh"

# Show status
"$SCRIPT_DIR/migrate.sh" status
