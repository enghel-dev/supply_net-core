#!/bin/bash
# ==========================================================
# SupplyNet - Inicialización condicional de la base de datos
# ==========================================================
#
# Este script vive en /docker-entrypoint-initdb.d/, así que la imagen
# oficial de Postgres SOLO lo ejecuta la PRIMERA vez que se crea el
# contenedor (cuando el volumen de datos "db_data" está vacío). En
# arranques posteriores del contenedor, Postgres ni siquiera vuelve a
# entrar a esta carpeta.
#
# Aun así, agregamos una verificación explícita antes de aplicar el
# schema: comprobamos si la tabla "usuarios" ya existe. Esto evita
# errores (por ejemplo CREATE TYPE ya existente) si alguien vuelve a
# ejecutar este script a mano dentro del contenedor, o si en el futuro
# se reutiliza este mecanismo para otros escenarios.
#
# No usamos "set -e" ni "exit" aquí a propósito: Postgres puede correr
# este archivo con "source" en vez de ejecutarlo directamente si no
# tiene permiso de ejecución (típico al venir de un bind mount en
# Windows), y "exit"/"return" en ese contexto puede matar el proceso
# equivocado.

SCHEMA_FILE="/sql/01-schema.sql"
SEED_CATEGORIAS_FILE="/sql/02-seed-categorias.sql"

echo "[supplynet-db-init] Verificando si el schema ya existe..."

TABLE_EXISTS=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc \
  "SELECT to_regclass('public.usuarios') IS NOT NULL;" 2>/tmp/supplynet_check_err || echo "error")

if [ "$TABLE_EXISTS" = "t" ]; then
    echo "[supplynet-db-init] La tabla 'usuarios' ya existe. El schema ya fue aplicado, no se hace nada."
elif [ "$TABLE_EXISTS" = "f" ]; then
    if [ -f "$SCHEMA_FILE" ]; then
        echo "[supplynet-db-init] No se encontró el schema. Aplicando $SCHEMA_FILE ..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SCHEMA_FILE"
        echo "[supplynet-db-init] Schema aplicado correctamente."
    else
        echo "[supplynet-db-init] ERROR: no se encontró el archivo $SCHEMA_FILE (revisa el volumen montado)."
    fi
else
    echo "[supplynet-db-init] ERROR: no se pudo verificar el estado del schema. Detalle:"
    cat /tmp/supplynet_check_err 2>/dev/null
fi

# El seed de categorías es idempotente (ON CONFLICT DO NOTHING), así que se
# aplica siempre, tanto en la primera inicialización como en reinicios de
# este script — no depende de la verificación de "usuarios" de arriba.
if [ -f "$SEED_CATEGORIAS_FILE" ]; then
    echo "[supplynet-db-init] Aplicando seed de categorías (idempotente)..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$SEED_CATEGORIAS_FILE"
fi
