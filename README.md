# SupplyNet — Hackathon Nicaragua 2026

**Equipo:** ByteFlow · **Categoría:** Aficionado · **Institución:** UDM, Managua
**Temática:** Emprendimiento · **Reto:** Plataforma de proveedores y productos finales

Plataforma que conecta proveedores de insumos/materia prima con compradores
(emprendedores, pequeños negocios, empresas) mediante búsqueda geolocalizada
de proveedores, cotización múltiple (RFQ) y un sello de verificación.

Requerimientos funcionales completos: [`docs/requerimientos-funcionales.md`](./docs/requerimientos-funcionales.md)
(copia de `DOCUMENTOS/Requerimientos.txt` del hackatón).

## Estructura del proyecto

```
SupplyNet/
├── docker-compose.yml        # Orquesta todos los servicios
├── .env.example               # Variables de entorno (copiar a .env)
├── docs/
│   └── requerimientos-funcionales.md  # RF-01..09, reglas de negocio, MoSCoW
├── services/
│   ├── db/                    # PostgreSQL — entregado por Dev 1
│   │   ├── init/               # Scripts que Postgres corre al iniciar
│   │   └── schema/              # Schema SQL (fuente de verdad)
│   ├── redis/                 # Cache de lecturas
│   ├── backend/                # API — pendiente de entrega
│   └── frontend/               # Cliente web — pendiente de entrega
└── scripts/
    └── db-reset.sh             # Helper para reiniciar la DB local
```

Cada servicio vive en su propia carpeta bajo `services/`, con su propio
`README.md` explicando qué contiene y cómo se conecta con los demás.

## Cómo levantar el proyecto

1. Copia el archivo de variables de entorno:
   ```bash
   cp .env.example .env
   ```
2. Levanta lo que ya está listo (db + redis):
   ```bash
   docker compose up -d
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

| Servicio | Estado | Puerto local | Notas |
|---|---|---|---|
| `db` (Postgres 16) | ✅ Listo | 5432 | Schema de Dev 1, con init condicional |
| `redis` (Redis 7) | ✅ Listo | 6379 | Cache de lecturas (catálogo, búsquedas) |
| `backend` | ⏳ Pendiente | 3000 (sugerido) | Bloque comentado en `docker-compose.yml`, listo para descomentar |
| `frontend` | ⏳ Pendiente | 5173 (sugerido) | Bloque comentado en `docker-compose.yml`, listo para descomentar |

## Cobertura de requerimientos funcionales

El schema de `db` (entregado por Dev 1) ya modela los datos para **los 9
requerimientos funcionales** (RF-01 a RF-09) de `docs/requerimientos-funcionales.md`.
Lo que falta para que cada uno funcione de punta a punta es el backend (API)
y el frontend, todavía pendientes:

| Prioridad (MoSCoW) | Requerimiento | Datos en `db` | Falta |
|---|---|---|---|
| Must have | RF-01 Registro/autenticación | `usuarios` (con `password_hash`, `rol`) | Backend: hashing, login, sesión/JWT |
| Must have | RF-02 Perfil de proveedor | `proveedores` (+ `verificado`) | Backend: CRUD perfil |
| Must have | RF-03 Catálogo de productos | `productos` (precio/stock con `CHECK >= 0`) | Backend: CRUD productos |
| Must have | RF-05 Solicitud de cotización (RFQ) | `rfq_solicitudes` | Backend: CRUD RFQ |
| Must have | RF-06 Ofertas de proveedores | `rfq_ofertas` (`UNIQUE` solicitud+proveedor) | Backend: CRUD ofertas, aceptar/rechazar |
| Should have | RF-04 Búsqueda geolocalizada | índice `gist` + `earthdistance` en `proveedores` | Backend: endpoint de búsqueda por radio; **cachear en Redis** (ver abajo) |
| Should have | RF-08 Panel del proveedor | join `productos` + `rfq_solicitudes` por categoría + `rfq_ofertas` | Backend + frontend |
| Should have | RF-09 Panel del comprador | join `rfq_solicitudes` + `rfq_ofertas` | Backend + frontend |
| Could have | RF-07 Verificación / sello | `verificaciones` (trigger ya sincroniza `proveedores.verificado`) | Backend: subida de documento, panel admin |

Reglas de negocio de la sección 5 del doc de requerimientos (email único,
oferta única por proveedor/solicitud, precios/stock ≥ 0, coordenadas válidas,
sello no editable a mano) ya están aplicadas como `UNIQUE`, `CHECK` y
triggers en el schema — no dependen del backend para cumplirse.

## Por qué Redis

Se agregó Redis como cache de lecturas frecuentes (listados de productos,
categorías, búsquedas de proveedores cercanos) para no golpear Postgres en
cada request del frontend. También responde directamente al requerimiento
no funcional del doc de requerimientos: *"las búsquedas por cercanía deben
responder en menos de 2 segundos"* (RF-04) — cachear resultados por
`lat,lng,radio` evita recalcular la búsqueda geoespacial en cada request.
Ver `services/redis/README.md` para el patrón de uso recomendado
(cache-aside) y qué keys cachear.

## Cuando lleguen los demás devs

1. El dev de backend deja su código + `Dockerfile` en `services/backend/`.
2. El dev de frontend deja su código + `Dockerfile` en `services/frontend/`.
3. Se descomentan los bloques correspondientes en `docker-compose.yml`.
4. `docker compose up -d --build`.

Ambos servicios ya quedan pre-configurados para conectarse a `db` y
`redis` por nombre de servicio (red interna de Docker), usando las
variables `DATABASE_URL` / `REDIS_URL` — no hace falta hardcodear hosts.

## Reiniciar la base de datos local desde cero

```bash
./scripts/db-reset.sh
```

Esto borra el volumen de Postgres y fuerza a que el init se vuelva a
correr (porque el volumen queda vacío otra vez).
