#!/bin/bash

# Migration tool for PostgreSQL - Rails-style migrations
# Usage: ./migrate.sh [command] [options]

set -e

# Configuration - Use PostgreSQL standard environment variables
DB_HOST=${DB_HOST:-${POSTGRES_HOST:-localhost}}
DB_PORT=${DB_PORT:-${POSTGRES_PORT:-5432}}
DB_NAME=${DB_NAME:-${POSTGRES_DB:-turbotim}}
DB_USER=${DB_USER:-${POSTGRES_USER:-turbotim}}
DB_PASSWORD=${DB_PASSWORD:-${POSTGRES_PASSWORD:-turbotim123}}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Ajuste de ruta para la nueva estructura
MIGRATIONS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/db/migrations"

# PostgreSQL connection string
PGCONN="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if psql is available
check_psql() {
    if ! command -v psql &> /dev/null; then
        log_error "psql could not be found. Please install PostgreSQL client."
        exit 1
    fi
}

# Test database connection
test_connection() {
    log_info "Testing database connection..."
    if psql "$PGCONN" -c "SELECT 1;" &> /dev/null; then
        log_success "Database connection successful"
    else
        log_error "Cannot connect to database. Please check your connection settings."
        exit 1
    fi
}

# Initialize migrations table
init_migrations_table() {
    log_info "Initializing migrations table..."
    
    local init_sql="$MIGRATIONS_DIR/000_create_migrations_table.sql"
    if [[ -f "$init_sql" ]]; then
        # Extract UP section
        sed -n '/-- UP/,/-- DOWN/p' "$init_sql" | sed '$d' | tail -n +2 | psql "$PGCONN" -q
        log_success "Migrations table initialized"
    else
        log_error "Migration file 000_create_migrations_table.sql not found"
        exit 1
    fi
}

# Get pending migrations
get_pending_migrations() {
    local executed_migrations
    executed_migrations=$(psql "$PGCONN" -t -c "SELECT version FROM migrations WHERE status = 'executed' ORDER BY version;" 2>/dev/null | tr -d ' ' | grep -v '^$' || true)
    
    local all_migrations
    all_migrations=$(find "$MIGRATIONS_DIR" -name "*.sql" -exec basename {} \; | sort | sed 's/\.sql$//' | grep -v '^000_')
    
    local pending=()
    for migration in $all_migrations; do
        if ! echo "$executed_migrations" | grep -q "^$migration$"; then
            pending+=("$migration")
        fi
    done
    
    printf '%s\n' "${pending[@]}"
}

# Get executed migrations (for rollback)
get_executed_migrations() {
    psql "$PGCONN" -t -c "SELECT version FROM migrations WHERE status = 'executed' ORDER BY version DESC;" 2>/dev/null | tr -d ' ' | grep -v '^$' || true
}

# Run a single migration
run_migration() {
    local migration_file="$1"
    local migration_name=$(basename "$migration_file" .sql)
    
    log_info "Running migration: $migration_name"
    
    # Extract UP section
    local up_sql
    up_sql=$(sed -n '/-- UP/,/-- DOWN/p' "$migration_file" | sed '$d' | tail -n +2)
    
    if [[ -z "$up_sql" ]]; then
        log_error "No UP section found in migration $migration_name"
        return 1
    fi
    
    # Execute migration
    echo "$up_sql" | psql "$PGCONN" -q
    
    # Record migration
    local description
    description=$(grep "^-- Description:" "$migration_file" | sed 's/^-- Description: //' || echo "No description")
    
    psql "$PGCONN" -c "INSERT INTO migrations (version, name, executed_at, status) VALUES ('$migration_name', '$description', CURRENT_TIMESTAMP, 'executed');" -q
    
    log_success "Migration $migration_name completed"
}

# Rollback a single migration
rollback_migration() {
    local migration_file="$1"
    local migration_name=$(basename "$migration_file" .sql)
    
    log_info "Rolling back migration: $migration_name"
    
    # Extract DOWN section
    local down_sql
    down_sql=$(sed -n '/-- DOWN/,$p' "$migration_file" | tail -n +2)
    
    if [[ -z "$down_sql" ]]; then
        log_error "No DOWN section found in migration $migration_name"
        return 1
    fi
    
    # Execute rollback
    echo "$down_sql" | psql "$PGCONN" -q
    
    # Update migration record
    psql "$PGCONN" -c "UPDATE migrations SET rollback_at = CURRENT_TIMESTAMP, status = 'rolled_back' WHERE version = '$migration_name';" -q
    
    log_success "Migration $migration_name rolled back"
}

# Run all pending migrations
migrate_up() {
    log_info "Running pending migrations..."
    
    local pending_migrations
    pending_migrations=$(get_pending_migrations)
    
    if [[ -z "$pending_migrations" ]]; then
        log_info "No pending migrations found"
        return 0
    fi
    
    local count=0
    while IFS= read -r migration; do
        local migration_file="$MIGRATIONS_DIR/$migration.sql"
        if [[ -f "$migration_file" ]]; then
            run_migration "$migration_file"
            ((count++))
        else
            log_error "Migration file not found: $migration_file"
        fi
    done <<< "$pending_migrations"
    
    log_success "Completed $count migrations"
}

# Rollback last migration
migrate_down() {
    local steps=${1:-1}
    log_info "Rolling back last $steps migration(s)..."
    
    local executed_migrations
    executed_migrations=$(get_executed_migrations)
    
    if [[ -z "$executed_migrations" ]]; then
        log_info "No migrations to rollback"
        return 0
    fi
    
    local count=0
    while IFS= read -r migration && [[ $count -lt $steps ]]; do
        local migration_file="$MIGRATIONS_DIR/$migration.sql"
        if [[ -f "$migration_file" ]]; then
            rollback_migration "$migration_file"
            ((count++))
        else
            log_error "Migration file not found: $migration_file"
        fi
    done <<< "$executed_migrations"
    
    log_success "Rolled back $count migration(s)"
}

# Show migration status
show_status() {
    log_info "Migration Status:"
    echo
    
    # Check if migrations table exists
    if ! psql "$PGCONN" -c "SELECT 1 FROM migrations LIMIT 1;" &> /dev/null; then
        log_warning "Migrations table not found. Run 'migrate.sh init' first."
        return 1
    fi
    
    echo -e "${BLUE}Executed Migrations:${NC}"
    psql "$PGCONN" -c "
        SELECT 
            version,
            name,
            executed_at,
            CASE 
                WHEN status = 'executed' THEN '✓'
                ELSE '✗'
            END as status
        FROM migrations 
        WHERE status = 'executed'
        ORDER BY version;
    " || true
    
    echo
    echo -e "${YELLOW}Pending Migrations:${NC}"
    local pending_migrations
    pending_migrations=$(get_pending_migrations)
    
    if [[ -n "$pending_migrations" ]]; then
        while IFS= read -r migration; do
            local description
            description=$(grep "^-- Description:" "$MIGRATIONS_DIR/$migration.sql" | sed 's/^-- Description: //' 2>/dev/null || echo "No description")
            printf "  %-30s %s\n" "$migration" "$description"
        done <<< "$pending_migrations"
    else
        echo "  No pending migrations"
    fi
    
    echo
    echo -e "${RED}Rolled Back Migrations:${NC}"
    psql "$PGCONN" -c "
        SELECT 
            version,
            name,
            rollback_at
        FROM migrations 
        WHERE status = 'rolled_back'
        ORDER BY version;
    " || true
}

# Create new migration
create_migration() {
    local name="$1"
    if [[ -z "$name" ]]; then
        log_error "Migration name is required"
        echo "Usage: migrate.sh create <migration_name>"
        exit 1
    fi
    
    # Get next migration number
    local last_migration
    last_migration=$(find "$MIGRATIONS_DIR" -name "*.sql" -exec basename {} \; | sort | tail -1 | sed 's/_.*//')
    
    local next_num
    if [[ -z "$last_migration" ]]; then
        next_num="001"
    else
        next_num=$(printf "%03d" $((10#$last_migration + 1)))
    fi
    
    local migration_file="$MIGRATIONS_DIR/${next_num}_${name}.sql"
    
    cat > "$migration_file" << EOF
-- Migration: ${next_num}_${name}
-- Description: ${name//_/ }
-- Created: $(date +%Y-%m-%d)

-- UP


-- DOWN

EOF
    
    log_success "Created migration: $migration_file"
    echo "Edit the file to add your SQL commands in the UP and DOWN sections."
}

# Show help
show_help() {
    echo "Migration Tool for PostgreSQL"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  init              Initialize migrations table"
    echo "  up                Run all pending migrations"
    echo "  down [steps]      Rollback migrations (default: 1 step)"
    echo "  status            Show migration status"
    echo "  create <name>     Create new migration file"
    echo "  help              Show this help"
    echo
    echo "Environment Variables:"
    echo "  DB_HOST           Database host (default: localhost)"
    echo "  DB_PORT           Database port (default: 5432)"
    echo "  DB_NAME           Database name (default: n8n)"
    echo "  DB_USER           Database user (default: postgres)"
    echo "  DB_PASSWORD       Database password (default: password)"
}

# Main script
main() {
    check_psql
    
    case "${1:-help}" in
        "init")
            test_connection
            init_migrations_table
            ;;
        "up")
            test_connection
            migrate_up
            ;;
        "down")
            test_connection
            migrate_down "${2:-1}"
            ;;
        "status")
            test_connection
            show_status
            ;;
        "create")
            create_migration "$2"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

main "$@"
