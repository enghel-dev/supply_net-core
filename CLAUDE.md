# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Resumen del proyecto
**SupplyNet** ("Plataforma de Proveedores y productos finales") es el proyecto del equipo
**ByteFlow** para el Hackathon Nicaragua 2026, organizado por el
Centro Nacional de Innovacion "Francisco El Chele Moreno".

- **Categoría:** Aficionado · **Temática:** Emprendimiento · **Institución:** UDM, Managua
- **Reto oficial:** conectar a emprendedores y MiPymes con proveedores confiables de insumos,
  materia prima, servicios y equipos productivos (actualmente disperso/informal, sin
  plataforma centralizada).
- Funcionalidades núcleo: búsqueda geolocalizada de proveedores, cotización múltiple (RFQ) y
  sello de verificación.

## Equipo ByteFlow --- Desarrolladores
| Persona | Rol |
|---|---|
| Engel Zapata | Base de datos y frontend |
| Enghel Solorzano | Backend y deployment/Docker |
| Roger Matus | Diseño — branding y marketing (pitch deck, logo, redes). **No** UI/UX. |


## Stack tecnológico
- **BD:** PostgreSQL 16 + extensiones `cube`/`earthdistance` (geolocalización)
- **Cache:** Redis 7 (`allkeys-lru`)
- **Backend:** Python 3.12 + FastAPI + asyncpg (sin ORM) — ver "Arquitectura del backend"
- **Frontend:** Flutter (Windows desktop + Android + build web para el deploy en Docker)
- **Infra:** Docker / docker-compose (en este equipo, vía Podman — ver nota abajo)

## Comandos
```bash
cp .env.example .env               # primera vez
docker compose up -d --build       # levanta db + redis + backend + frontend
docker compose ps
docker compose logs -f db
./scripts/db-reset.sh              # borra el volumen de Postgres y fuerza a re-aplicar el schema
```

**Nota (Bazzite/Fedora Atomic, sin `dockerd`):** este equipo de desarrollo no tiene el daemon
de Docker — en su lugar corre **Podman rootless** (ya viene con el sistema) con su socket API
compatible con Docker activo en `/run/user/$(id -u)/podman/podman.sock`. El CLI `docker` +
plugin `docker compose` (instalados vía Homebrew) apuntan ahí con
`DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock` (ya persistido en `~/.bashrc`), así
que los comandos de arriba funcionan igual que con Docker real. Los bind-mounts del
`docker-compose.yml` (`services/db/init`, `services/db/schema`, `services/redis/redis.conf`)
llevan la opción `:Z` porque SELinux (enforcing en Fedora/Bazzite) bloquea el acceso del
contenedor a archivos con label `user_home_t` si no se reetiquetan — es un flag estándar de
Compose, inofensivo en Docker sin SELinux. El flujo db+redis+backend ya se probó de punta a
punta (registro → login → perfil de proveedor → producto → RFQ → oferta → aceptar) contra un
Postgres y Redis reales corriendo así.

## Estructura del repo
```
services/
  db/          # schema + 00-check-and-init.sh (idempotente, verifica to_regclass antes de aplicar)
  redis/       # redis.conf
  backend/     # FastAPI, monolito modular por dominio — ver "Arquitectura del backend"
  frontend/    # Flutter (lib/ con core + features por dominio) + Dockerfile multi-stage (build web + nginx)
docs/
  requerimientos-funcionales.md   # copia de DOCUMENTOS/Requerimientos.txt (raíz del hackatón)
```

## Estado actual
- Schema Postgres completo: `usuarios`, `categorias`, `proveedores`, `productos`,
  `rfq_solicitudes`, `rfq_ofertas`, `verificaciones`, con geolocalización, triggers de
  `updated_at` y sincronización automática de `proveedores.verificado`. **Validado contra un
  Postgres real** (vía Podman) — schema aplica limpio, extensiones `cube`/`earthdistance`
  instalan bien, seed de categorías carga.
- **Backend:** FastAPI completo — auth, perfil de proveedor, catálogo de productos,
  RFQ/ofertas y búsqueda geolocalizada con cache-aside en Redis (ver
  `services/backend/README.md` para la lista de endpoints). La verificación de proveedor tiene
  el flujo de solicitud/aprobación completo; la subida del documento de respaldo es la única
  pieza de ese módulo sin implementar todavía.
- **Frontend:** Flutter con pantallas por dominio bajo `lib/features/` (auth, proveedores,
  productos, RFQ, panel, verificación, categorías) y capa compartida en `lib/core/` (tema, API
  client con `dio`, modelos, router con `go_router`, storage seguro de token). Corre en
  Windows, Android y como build web (servido con nginx en el contenedor `frontend`).
- `docker-compose.yml`: **db**, **redis**, **backend** y **frontend** activos y funcionando —
  `docker compose up -d --build` levanta el stack completo.
- Reglas de negocio (email único, una oferta por proveedor/solicitud, precios/stock ≥ 0,
  coordenadas válidas, sello no editable a mano) viven en BD como `UNIQUE`/`CHECK`/triggers —
  no dependen del backend. Probadas end-to-end (email duplicado → 409, oferta duplicada → 409).
- Redis acelera la búsqueda geolocalizada de proveedores (NFR de respuesta < 2s); el
  cache-aside de `GET /proveedores` ya se probó con TTL real. Ver `services/redis/README.md`.
- La identidad visual del frontend (paleta, tipografía, logo) está definida en
  `SUPPLYNET MANUAL.pdf` (carpeta `DOCUMENTOS/` en la raíz del hackatón); la paleta implementada
  hoy en `lib/core/theme/app_colors.dart` es un placeholder y todavía no coincide con esa
  paleta de marca — ajustarla es la siguiente iteración de UI.

## Arquitectura del backend
`services/backend/` es un **monolito modular**: un solo proceso FastAPI (`app/main.py`), un
solo Dockerfile/puerto, pero organizado en módulos independientes por dominio bajo
`app/modules/<dominio>/` (cada uno con su propio `router.py` / `schemas.py` / `service.py`).
La idea es poder separar un módulo a su propio servicio/Dockerfile más adelante sin reescribir
lógica de negocio — solo mover la carpeta y darle su propio `main.py`. Infra compartida
(conexión a BD, Redis, seguridad/JWT) vive en `app/core/` y es lo único que un módulo
"graduado" a microservicio tendría que duplicar o extraer a un paquete común.

Acceso a datos: `asyncpg` directo (sin ORM/ORM-migrations) — el schema SQL en `services/db/`
sigue siendo la única fuente de verdad, el backend solo lee/escribe contra las tablas que ya
existen, nunca las crea ni las migra.

## Arquitectura del frontend
`services/frontend/` es una app Flutter única (Windows + Android + web), organizada por
dominio bajo `lib/features/<dominio>/` (pantallas + provider), con infraestructura compartida
en `lib/core/`: `api/` (cliente `dio` + un archivo por módulo del backend), `models/`, `theme/`,
`router/` (`go_router`, con guards por rol) y `storage/` (token JWT vía
`flutter_secure_storage`). El backend expone CORS abierto (`allow_origins=["*"]`) para que el
build web funcione sin configuración extra.

Para el deploy en Docker, el `Dockerfile` de `services/frontend/` es multi-stage: genera el
andamiaje nativo de `web/` (no versionado en git), corre `flutter build web` y sirve el
resultado con nginx. Los builds nativos de Windows (`.exe`) y Android (`.apk`) se generan
aparte con el SDK de Flutter y se distribuyen fuera del contenedor — ver
`services/frontend/README.md`.

## Notas para Claude Code
- Cualquier cambio al schema de BD va como migración nueva numerada (ej. `02-agregar-tabla-x.sql`)
  referenciada desde `services/db/init/00-check-and-init.sh`, nunca editando `01-schema.sql`
  directo si ya hay datos locales.
- El detalle línea por línea de los requerimientos funcionales vive en
  `docs/requerimientos-funcionales.md`; consultarlo antes de asumir el alcance exacto de una
  funcionalidad.
- Al agregar un módulo nuevo en `services/backend/app/modules/`, seguir el mismo patrón
  `router.py`/`schemas.py`/`service.py` que los módulos existentes para mantener la
  independencia entre dominios.
- Al agregar una pantalla nueva en `services/frontend/lib/features/`, seguir el mismo patrón
  pantalla + provider que las existentes, y consumir el backend a través de `lib/core/api/`
  (no llamar `dio` directo desde una pantalla).
- Ningún comando de este proyecto se corre "sin Docker" — todo el flujo (BD, cache, backend,
  frontend) se levanta con `docker compose up -d --build`.

## Uso de Claude Code en el desarrollo
Parte del desarrollo de SupplyNet (backend, frontend, documentación y configuración de
Docker/CI) se hizo con **Claude Code** como asistente de desarrollo del equipo. Vale la pena
declararlo en el material de entrega (README, pitch) como parte real del flujo de trabajo
técnico del equipo ByteFlow.
