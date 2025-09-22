#!/bin/bash

# Quick migration runner
# Usage: ./db_migrate.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/db_config.sh"

# Run migrations
echo -e "${BLUE}Running database migrations...${NC}"
"$SCRIPT_DIR/migrate.sh" up

echo -e "${GREEN}✓ Migrations completed successfully!${NC}"
