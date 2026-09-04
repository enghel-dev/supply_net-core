# Servicio: backend (FastAPI)

API de SupplyNet. Monolito modular: un solo proceso/Dockerfile, pero cada
dominio vive en su propio módulo bajo `app/modules/<dominio>/` (router +
schemas + service), separado de los demás.

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
    ├── auth/                # Registro y login
    ├── categorias/          # Listado de categorías (para selects del frontend)
    ├── proveedores/         # Perfil de proveedor y búsqueda geolocalizada (cache Redis)
    ├── productos/           # Catálogo
    ├── rfq/                 # Solicitudes de cotización y ofertas
    └── verificaciones/      # Sello de verificación
```

## Cómo correrlo

Todo con Docker, desde la raíz del repo:

```bash
docker compose up -d --build backend
```

Requiere `db` y `redis` arriba (ya orquestados en el mismo `docker-compose.yml`).

## Endpoints

| Método | Ruta | Rol requerido |
|---|---|---|
| POST | `/auth/registro` | — |
| POST | `/auth/login` | — |
| GET | `/categorias` | — |
| PUT | `/proveedores/me` | proveedor |
| GET | `/proveedores/me` | proveedor |
| GET | `/proveedores?lat&lng&radio_km` | — (cacheado en Redis, TTL 60s) |
| GET | `/proveedores/{id}` | — |
| POST/GET/PUT/DELETE | `/productos[/{id}]` | proveedor (escritura) |
| POST | `/rfq/solicitudes` | comprador |
| GET | `/rfq/solicitudes?categoria_id&estado&solo_mias` | comprador/proveedor |
| PATCH | `/rfq/solicitudes/{id}/estado` | comprador (dueño) |
| POST | `/rfq/solicitudes/{id}/ofertas` | proveedor |
| GET | `/rfq/solicitudes/{id}/ofertas` | comprador (dueño) |
| GET | `/rfq/mis-ofertas` | proveedor |
| PATCH | `/rfq/ofertas/{id}/estado` | comprador (dueño de la solicitud) |
| POST | `/verificaciones` | proveedor |
| GET | `/verificaciones/pendientes` | admin |
| PATCH | `/verificaciones/{id}/aprobar\|rechazar` | admin |

