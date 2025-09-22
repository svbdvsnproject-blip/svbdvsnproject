# Database Migrations System

Sistema de migraciones estilo Rails para PostgreSQL usando Bash.

## Estructura

```plaintext
db/
├── migrations/
│   ├── 000_create_migrations_table.sql
│   ├── 001_create_profile_brand.sql
│   └── ...
└── README.md

tools/
├── migrate.sh          # Script principal de migraciones
├── db_config.sh        # Configuración de base de datos
├── db_migrate.sh       # Ejecutar migraciones
├── db_rollback.sh      # Hacer rollback
└── db_status.sh        # Ver estado de migraciones
```

## Configuración

Configura las variables de entorno en `tools/db_config.sh` o exporta directamente:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=n8n
export DB_USER=postgres
export DB_PASSWORD=your_password
```

## Uso Básico

### 1. Inicializar el sistema de migraciones

```bash
cd tools
./migrate.sh init
```

### 2. Ejecutar migraciones pendientes

```bash
./db_migrate.sh
# o
./migrate.sh up
```

### 3. Ver estado de migraciones

```bash
./db_status.sh
# o
./migrate.sh status
```

### 4. Hacer rollback

```bash
./db_rollback.sh        # Rollback 1 migración
./db_rollback.sh 3      # Rollback 3 migraciones
# o
./migrate.sh down       # Rollback 1 migración
./migrate.sh down 3     # Rollback 3 migraciones
```

### 5. Crear nueva migración

```bash
./migrate.sh create add_user_table
# Crea: 002_add_user_table.sql
```

## Formato de Migraciones

Cada migración debe tener esta estructura:

```sql
-- Migration: 001_create_profile_brand
-- Description: Create profile_brand table for storing brand information
-- Created: 2025-07-05

-- UP
CREATE TABLE profile_brand (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

-- DOWN
DROP TABLE IF EXISTS profile_brand;
```

## Características

- ✅ **Versionado**: Migraciones numeradas secuencialmente
- ✅ **Tracking**: Tabla `migrations` que registra qué se ejecutó y cuándo
- ✅ **Rollback**: Capacidad de deshacer migraciones
- ✅ **Estado**: Ver qué migraciones están ejecutadas o pendientes
- ✅ **Timestamps**: Registro de cuándo se ejecutó cada migración
- ✅ **Validación**: Verificación de conexión a base de datos
- ✅ **Colores**: Output con colores para mejor legibilidad

## Comandos Disponibles

| Comando | Descripción |
|---------|-------------|
| `migrate.sh init` | Inicializa la tabla de migraciones |
| `migrate.sh up` | Ejecuta todas las migraciones pendientes |
| `migrate.sh down [steps]` | Hace rollback de migraciones |
| `migrate.sh status` | Muestra el estado de todas las migraciones |
| `migrate.sh create <name>` | Crea una nueva migración |
| `migrate.sh help` | Muestra ayuda |

## Scripts de Conveniencia

- `db_migrate.sh` - Ejecuta migraciones rápidamente
- `db_rollback.sh [steps]` - Hace rollback rápidamente  
- `db_status.sh` - Ve el estado rápidamente

## Tabla de Migraciones

El sistema crea automáticamente una tabla `migrations` con:

- `id`: ID único
- `version`: Versión de la migración (ej: "001_create_profile_brand")
- `name`: Descripción de la migración
- `executed_at`: Timestamp de cuándo se ejecutó
- `rollback_at`: Timestamp de cuándo se hizo rollback (si aplica)
- `status`: Estado ('executed' o 'rolled_back')

¡Listo para usar! 🚀
