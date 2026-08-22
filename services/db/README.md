# Servicio: db (PostgreSQL)

Entregado por: **Dev 1**

## Contenido

- `schema/01-schema.sql` — el schema completo (tablas, enums, triggers, extensiones geoespaciales). Este archivo **no** se ejecuta directo por Postgres; solo lo lee el script de inicialización.
- `init/00-check-and-init.sh` — script que Postgres corre automáticamente al **crear** el contenedor por primera vez. Verifica si la tabla `usuarios` ya existe antes de aplicar el schema, para que nunca se vuelva a correr por accidente.

## Cómo funciona la inicialización

1. Postgres solo procesa `/docker-entrypoint-initdb.d/` cuando el volumen `db_data` está **vacío** (primer arranque). En arranques siguientes ni siquiera entra ahí — esto ya lo hace Postgres por su cuenta.
2. Además, `00-check-and-init.sh` hace su propia verificación (`to_regclass('public.usuarios')`) antes de aplicar `01-schema.sql`, como capa extra de seguridad.

## Si necesitas reiniciar la base de datos desde cero (desarrollo)

```bash
docker compose down
docker volume rm supplynet_db_data
docker compose up -d db
```

O usa el helper: `scripts/db-reset.sh`.

## Cobertura de requerimientos

Este schema cubre el modelo de datos completo de los RF-01 a RF-09 definidos
en [`docs/requerimientos-funcionales.md`](../../docs/requerimientos-funcionales.md),
incluyendo las reglas de negocio de la sección 5 (email único, una oferta por
proveedor/solicitud, precios/stock ≥ 0, coordenadas válidas, sello de
verificación no editable a mano) vía `UNIQUE`, `CHECK` y triggers. Ver la
tabla de cobertura en el README raíz del proyecto para el detalle por
requerimiento.

## Notas para el resto del equipo

- Cualquier cambio al schema debe hacerse como una migración nueva (archivo numerado, ej. `02-agregar-tabla-x.sql`) referenciado desde `00-check-and-init.sh`, **no** editando `01-schema.sql` directamente una vez que alguien ya tenga datos locales.
- Extensión `earthdistance`/`cube` ya viene habilitada para búsquedas de proveedores cercanos por geolocalización (RF-04).
