# SupplyNet — Hackathon Nicaragua 2026

**Equipo:** ByteFlow · **Categoría:** Aficionado · **Institución:** UDM, Managua
**Temática:** Emprendimiento · **Reto:** Plataforma de proveedores y productos finales

Plataforma que conecta proveedores de insumos/materia prima con compradores
(emprendedores, pequeños negocios, empresas) mediante búsqueda geolocalizada
de proveedores, cotización múltiple (RFQ) y un sello de verificación.

## Tecnologías utilizadas

- **Base de datos:** PostgreSQL 16 + extensiones `cube`/`earthdistance` (geolocalización)
- **Cache:** Redis 7 (`allkeys-lru`)
- **Backend:** Python 3.12 + FastAPI + `asyncpg` (sin ORM), JWT para sesión
- **Frontend:** Flutter
- **Infraestructura:** Docker / docker-compose

## Estructura del proyecto

```
SupplyNet/
├── docker-compose.yml        # Orquesta todos los servicios
├── .env.example               # Variables de entorno (copiar a .env)
├── services/
│   ├── db/                    # PostgreSQL
│   │   ├── init/               # Scripts que Postgres corre al iniciar
│   │   └── schema/              # Schema SQL (fuente de verdad)
│   ├── redis/                 # Cache de lecturas
│   ├── backend/                # API FastAPI
│   └── frontend/               # Cliente Flutter
└── scripts/
    └── db-reset.sh             # Helper para reiniciar la DB local
```

Cada servicio vive en su propia carpeta bajo `services/`, con su propio
`README.md` explicando qué contiene y cómo se conecta con los demás.

## Cómo levantar el proyecto

Todo el proyecto corre sobre Docker / docker-compose — no hay una ruta
soportada fuera de contenedores.

1. Copia el archivo de variables de entorno:
   ```bash
   cp .env.example .env
   ```
2. Levanta los servicios:
   ```bash
   docker compose up -d --build
   ```
3. Verifica que todo esté sano:
   ```bash
   docker compose ps
   docker compose logs -f db
   ```
   Deberías ver en los logs algo como:
   `[supplynet-db-init] No se encontró el schema. Aplicando /sql/01-schema.sql ...`
   seguido de `Schema aplicado correctamente.` — eso solo pasa la primera vez.
   Si vuelves a hacer `docker compose restart db` o `down` + `up` (sin borrar
   el volumen), verás en su lugar:
   `[supplynet-db-init] La tabla 'usuarios' ya existe...` — es decir, no se
   vuelve a ejecutar el schema.

## Servicios

| Servicio | Puerto local | Notas |
|---|---|---|
| `db` (Postgres 16) | 5432 | Init condicional, no reaplica el schema si ya existe |
| `redis` (Redis 7) | 6379 | Cache de lecturas (catálogo, búsquedas) |
| `backend` (FastAPI) | 3000 | Auth, perfil de proveedor, catálogo, RFQ/ofertas, búsqueda geolocalizada con cache — ver `services/backend/README.md` |
| `frontend` (Flutter, build web) | 5173 | Cliente web servido con nginx; builds nativos de Windows/Android se generan aparte — ver `services/frontend/README.md` |

## Reiniciar la base de datos local desde cero

```bash
./scripts/db-reset.sh
```

Esto borra el volumen de Postgres y fuerza a que el init se vuelva a
correr (porque el volumen queda vacío otra vez).
