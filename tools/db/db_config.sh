#!/bin/bash

# Database configuration for migrations
# Source this file to set environment variables

# Inside container configuration
if [ -f /.dockerenv ]; then
    # We're inside a container, use localhost and POSTGRES_ variables
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_NAME=${POSTGRES_DB:-n8n}
    export DB_USER=${POSTGRES_USER:-n8n}
    export DB_PASSWORD=${POSTGRES_PASSWORD:-n8n}
else
    # We're outside container, use docker-compose service name as host
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_NAME=${DB_NAME:-n8n}
    export DB_USER=${DB_USER:-n8n}
    export DB_PASSWORD=${DB_PASSWORD:-n8n}
fi

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

echo -e "${BLUE}Database Configuration Loaded:${NC}"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: [HIDDEN]"
echo

# Function to test database connection
test_db_connection() {
    echo -e "${BLUE}Testing database connection...${NC}"
    if psql "postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME" -c "SELECT 1;" &> /dev/null; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
        return 0
    else
        echo -e "${RED}✗ Cannot connect to database${NC}"
        return 1
    fi
}
