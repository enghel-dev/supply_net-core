# Servicio: backend (FastAPI)

API de SupplyNet. Monolito modular: un solo proceso/Dockerfile, pero cada
dominio vive en su propio módulo bajo `app/modules/<dominio>/` (router +
schemas + service), separado de los demás — ver "Arquitectura del backend"
en el `CLAUDE.md` de la raíz del repo si vas a agregar un módulo nuevo o a
graduar uno a su propio servicio.

## Estructura

```
app/
├── main.py                # crea el FastAPI() app, registra routers, maneja el ciclo de vida (pool DB/Redis)
├── core/
│   ├── config.py           # Settings (lee DATABASE_URL, REDIS_URL, PORT, JWT_SECRET_KEY del entorno)
│   ├── database.py         # dependencia get_db() — conexión asyncpg del pool
│   ├── redis.py            # dependencia get_redis()
│   └── security.py         # hash de password, JWT, dependencia require_role()
└── modules/
    ├── auth/                # RF-01: registro, login
    ├── proveedores/         # RF-02 (perfil), RF-04 (búsqueda geo + cache Redis)
    ├── productos/           # RF-03: catálogo
    ├── rfq/                 # RF-05 (solicitudes), RF-06 (ofertas)
    └── verificaciones/      # RF-07 (could-have) — falta subida real de documento
```

No hay ORM ni migraciones: `services/db/schema/01-schema.sql` sigue siendo
la única fuente de verdad del modelo de datos. Este servicio solo lee y
escribe contra las tablas que ya existen.

## Correr en local (sin Docker)

```bash
cd services/backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL=postgresql://supplynet:supplynet_dev_password@localhost:5432/supplynet
export REDIS_URL=redis://localhost:6379
export JWT_SECRET_KEY=dev-secret
uvicorn app.main:app --reload --port 3000
```

Requiere que `db` y `redis` ya estén arriba (`docker compose up -d db redis`
desde la raíz del repo) y expuestos en localhost.

## Correr con Docker

Ya está descomentado en `docker-compose.yml` de la raíz:

```bash
docker compose up -d --build backend
```

## Endpoints (RF-01 a RF-06, ver docs/requerimientos-funcionales.md)

| Método | Ruta | Rol requerido | RF |
|---|---|---|---|
| POST | `/auth/registro` | — | RF-01 |
| POST | `/auth/login` | — | RF-01 |
| PUT | `/proveedores/me` | proveedor | RF-02 |
| GET | `/proveedores/me` | proveedor | RF-02 |
| GET | `/proveedores?lat&lng&radio_km` | — | RF-04 (cacheado en Redis, TTL 60s) |
| GET | `/proveedores/{id}` | — | RF-02/RF-04 |
| POST/GET/PUT/DELETE | `/productos[/{id}]` | proveedor (escritura) | RF-03 |
| POST | `/rfq/solicitudes` | comprador | RF-05 |
| GET | `/rfq/solicitudes?categoria_id&estado&solo_mias` | comprador/proveedor | RF-05, RF-08, RF-09 |
| PATCH | `/rfq/solicitudes/{id}/estado` | comprador (dueño) | RF-05 |
| POST | `/rfq/solicitudes/{id}/ofertas` | proveedor | RF-06 |
| GET | `/rfq/solicitudes/{id}/ofertas` | comprador (dueño) | RF-06, RF-09 |
| GET | `/rfq/mis-ofertas` | proveedor | RF-06, RF-08 |
| PATCH | `/rfq/ofertas/{id}/estado` | comprador (dueño de la solicitud) | RF-06 |
| POST | `/verificaciones` | proveedor | RF-07 (esqueleto, falta subida de doc) |
| GET | `/verificaciones/pendientes` | admin | RF-07 |
| PATCH | `/verificaciones/{id}/aprobar\|rechazar` | admin | RF-07 |

`GET /health` no requiere auth — útil para el `healthcheck` de Docker.

## Pendiente / siguiente paso

- Escribir tests (ninguno todavía).
- RF-08/RF-09 (paneles) hoy se resuelven combinando los endpoints de
  arriba desde el frontend; si hace falta un endpoint agregador propio,
  agregarlo como su propio módulo en vez de mezclarlo con `rfq/` o
  `proveedores/`.
- RF-07: falta el almacenamiento real del documento de verificación.

Ya se validó de punta a punta (registro → login → perfil de proveedor →
producto → RFQ → oferta → aceptar, incluyendo los 409/403 de las reglas de
negocio) contra un Postgres y Redis reales vía `docker compose up -d --build`.
