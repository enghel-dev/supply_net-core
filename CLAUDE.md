# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Resumen del proyecto
**SupplyNet** ("Plataforma de Proveedores y productos finales") es el proyecto del equipo
**ByteFlow** para el Hackathon Nicaragua 2026 (HN10, "¡Siempre más allá!"), organizado por el
CNIT "Francisco El Chele Moreno" / GRUN.

- **Categoría:** Aficionado · **Temática:** Emprendimiento · **Institución:** UDM, Managua
- **Reto oficial:** conectar a emprendedores y MiPymes con proveedores confiables de insumos,
  materia prima, servicios y equipos productivos (actualmente disperso/informal, sin
  plataforma centralizada).
- Funcionalidades núcleo: búsqueda geolocalizada de proveedores, cotización múltiple (RFQ) y
  sello de verificación.

## Equipo ByteFlow
| Persona | Rol |
|---|---|
| Engel Zapata | Dev 1 — base de datos y frontend |
| Enghel Solorzano | Dev 2 — backend y deployment/Docker |
| Roger Matus | Diseño — branding y marketing (pitch deck, logo, redes). **No** UI/UX. |

Trello: un único board compartido ("SupplyNet - Tareas Técnicas (Devs)") con labels y
asignados en la descripción de cada card (la asignación nativa de miembros vía MCP no está
disponible).

## Stack tecnológico
- **BD:** PostgreSQL 16 + extensiones `cube`/`earthdistance` (geolocalización)
- **Cache:** Redis 7 (`allkeys-lru`)
- **Backend:** Python 3.12 + FastAPI + asyncpg (sin ORM) — ver "Arquitectura del backend"
- **Frontend:** React + Vite + TailwindCSS + React Router + React-Leaflet + Axios + Zustand
- **Infra:** Docker / docker-compose (en este equipo, vía Podman — ver nota abajo)

## Comandos
```bash
cp .env.example .env               # primera vez
docker compose up -d               # levanta db + redis
docker compose up -d --build backend
docker compose ps
docker compose logs -f db
./scripts/db-reset.sh              # borra el volumen de Postgres y fuerza a re-aplicar el schema
```

**Nota (Bazzite/Fedora Atomic, sin `dockerd`):** este equipo de desarrollo no tiene el daemon
de Docker — en su lugar corre **Podman rootless** (ya viene con el sistema) con su socket API
compatible con Docker activo en `/run/user/$(id -u)/podman/podman.sock`. El CLI `docker` +
plugin `docker compose` (instalados vía Homebrew) apuntan ahí con
`DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock` (ya persistido en `~/.bashrc`), así
que los comandos de arriba funcionan igual que con Docker real. Los tres bind-mounts del
`docker-compose.yml` (`services/db/init`, `services/db/schema`, `services/redis/redis.conf`)
llevan la opción `:Z` porque SELinux (enforcing en Fedora/Bazzite) bloquea el acceso del
contenedor a archivos con label `user_home_t` si no se reetiquetan — es un flag estándar de
Compose, inofensivo en Docker sin SELinux. Todo esto ya se probó de punta a punta (registro →
login → perfil de proveedor → producto → RFQ → oferta → aceptar) contra un Postgres y Redis
reales corriendo así.

## Estructura del repo
```
services/
  db/          # schema + 00-check-and-init.sh (idempotente, verifica to_regclass antes de aplicar)
  redis/       # redis.conf
  backend/     # FastAPI, monolito modular por dominio (Dev 2) — ver "Arquitectura del backend"
  frontend/    # vacío (solo README + .gitkeep) — pendiente de entrega (Dev 1)
docs/
  requerimientos-funcionales.md   # copia de DOCUMENTOS/Requerimientos.txt (raíz del hackatón)
```

## Estado actual (al 23-ago-2026)
- Schema Postgres completo (Dev 1): `usuarios`, `categorias`, `proveedores`, `productos`,
  `rfq_solicitudes`, `rfq_ofertas`, `verificaciones`, con geolocalización, triggers de
  `updated_at` y sincronización automática de `proveedores.verificado`. **Validado contra un
  Postgres real** (vía Podman) — schema aplica limpio, extensiones `cube`/`earthdistance`
  instalan bien, seed de categorías carga.
- `docker-compose.yml`: **db**, **redis** y **backend** funcionando y probados de punta a
  punta; **frontend** sigue comentado (pendiente de entrega, Dev 1).
- Reglas de negocio (email único, una oferta por proveedor/solicitud, precios/stock ≥ 0,
  coordenadas válidas, sello no editable a mano) ya viven en BD como `UNIQUE`/`CHECK`/triggers
  — no dependen del backend. Probadas end-to-end (email duplicado → 409, oferta duplicada → 409).
- Redis se justifica explícitamente por el NFR de RF-04 (búsquedas por cercanía < 2s); el
  cache-aside de `GET /proveedores` ya se probó con TTL real. Ver `services/redis/README.md`.
- **Backend:** esqueleto FastAPI completo cubriendo RF-01, 02, 03, 04, 05, 06 (todos los
  must-have + RF-04 should-have) — ver "Arquitectura del backend" y
  `services/backend/README.md` para la lista de endpoints. RF-07 (verificación) tiene
  esqueleto pero le falta la subida real del documento. RF-08/RF-09 (paneles) se resuelven
  combinando endpoints existentes desde el frontend, sin endpoint agregador propio todavía.
- `services/frontend/` solo tiene `README.md` + `.gitkeep` — sin código todavía.

## Pendiente (prioridad MoSCoW)
- **Frontend:** aún sin entregar — es lo único que bloquea una demo end-to-end, dado que
  backend + BD ya están completos para los must-have.
- **Backend:** falta la subida de documento para RF-07 (could-have) y tests automatizados
  (no hay ninguno todavía).
- Al llegar el código de frontend: descomentar su bloque en `docker-compose.yml` y correr
  `docker compose up -d --build frontend`.
- Asignación nativa de miembros en Trello: pendiente, hacerlo manualmente vía UI.

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

## Notas para Claude Code
- Cualquier cambio al schema de BD va como migración nueva numerada (ej. `02-agregar-tabla-x.sql`)
  referenciada desde `services/db/init/00-check-and-init.sh`, nunca editando `01-schema.sql`
  directo si ya hay datos locales.
- El detalle línea por línea de RF-01 a RF-09 vive en `docs/requerimientos-funcionales.md`;
  consultarlo antes de asumir el alcance exacto de un requerimiento.
- Al agregar un módulo nuevo en `services/backend/app/modules/`, seguir el mismo patrón
  `router.py`/`schemas.py`/`service.py` que los módulos existentes para mantener la
  independencia entre dominios.
