#!/bin/bash

# Quick rollback runner
# Usage: ./db_rollback.sh [steps]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/db_config.sh"

STEPS=${1:-1}

# Run rollback
echo -e "${YELLOW}Rolling back $STEPS migration(s)...${NC}"
"$SCRIPT_DIR/migrate.sh" down "$STEPS"

echo -e "${GREEN}✓ Rollback completed successfully!${NC}"
