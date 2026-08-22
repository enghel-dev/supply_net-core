# Servicio: frontend (pendiente)

Carpeta reservada para el código del frontend cuando el dev
correspondiente lo entregue.

## Qué se espera aquí

- Un `Dockerfile` en esta carpeta (`services/frontend/Dockerfile`), idealmente multi-stage (build + servir con nginx o similar).
- La app debe apuntar la URL del backend a través de una variable de entorno, ej. `VITE_API_URL` / `NEXT_PUBLIC_API_URL` (ajustar según el framework que se use) apuntando a `http://localhost:<puerto_backend>` en desarrollo.

## Cómo activarlo en el deploy

En `docker-compose.yml` ya está el bloque `frontend` listo pero **comentado**.
Cuando el código llegue:

1. Descomenta el servicio `frontend` en `docker-compose.yml`.
2. Ajusta el puerto expuesto según el framework (Vite=5173, Next=3000, CRA=3000, etc).
3. Corre `docker compose up -d --build frontend`.
