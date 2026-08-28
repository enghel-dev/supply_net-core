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


## Reiniciar la base de datos local desde cero

```bash
./scripts/db-reset.sh
```

Esto borra el volumen de Postgres y fuerza a que el init se vuelva a
correr (porque el volumen queda vacío otra vez).
