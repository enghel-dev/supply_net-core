# Servicio: db (PostgreSQL)

## Contenido

- `schema/01-schema.sql` — el schema completo (tablas, enums, triggers, extensiones geoespaciales). Este archivo **no** se ejecuta directo por Postgres; solo lo lee el script de inicialización.
- `init/00-check-and-init.sh` — script que Postgres corre automáticamente al **crear** el contenedor por primera vez. Verifica si la tabla `usuarios` ya existe antes de aplicar el schema, para que nunca se vuelva a correr por accidente.

## Si necesitas reiniciar la base de datos desde cero (desarrollo)

```bash
docker compose down
docker volume rm supplynet_db_data
docker compose up -d db
```

O usa el helper: `scripts/db-reset.sh`.
