#!/bin/bash
# Reinicia la base de datos de desarrollo desde cero:
# apaga los contenedores, borra el volumen de datos de Postgres
# y lo vuelve a levantar (esto dispara el init script de nuevo,
# ya que el volumen queda vacío).
#
# Uso: ./scripts/db-reset.sh

set -e

cd "$(dirname "$0")/.."

echo "Esto va a borrar TODOS los datos locales de Postgres. Continuar? (s/N)"
read -r CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo "Cancelado."
    exit 0
fi

docker compose down
docker volume rm supplynet_db_data
docker compose up -d db
echo "Listo. Revisa los logs con: docker compose logs -f db"
