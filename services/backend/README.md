# Servicio: backend (pendiente)

Carpeta reservada para el código del backend (API) cuando el dev
correspondiente lo entregue.

## Qué se espera aquí

- Un `Dockerfile` en esta carpeta (`services/backend/Dockerfile`).
- La app debe leer estas variables de entorno (ya definidas en `.env.example` / `docker-compose.yml`):
  - `DATABASE_URL` — conexión a Postgres, ej: `postgresql://supplynet:supplynet_dev_password@db:5432/supplynet`
  - `REDIS_URL` — conexión a Redis, ej: `redis://redis:6379`
  - `PORT` — puerto en el que escucha la app dentro del contenedor (default sugerido: `3000`)

## Cómo activarlo en el deploy

En `docker-compose.yml` ya está el bloque `backend` listo pero **comentado**.
Cuando el código llegue:

1. Descomenta el servicio `backend` en `docker-compose.yml`.
2. Ajusta el puerto expuesto si tu framework usa otro distinto a 3000.
3. Corre `docker compose up -d --build backend`.

El servicio ya queda configurado para esperar a que `db` y `redis` estén
"healthy" antes de arrancar (`depends_on` con `condition: service_healthy`).
