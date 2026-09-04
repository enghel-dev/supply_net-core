from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis import asyncio as aioredis

from app.core.config import settings
from app.modules.auth.router import router as auth_router
from app.modules.categorias.router import router as categorias_router
from app.modules.productos.router import router as productos_router
from app.modules.proveedores.router import router as proveedores_router
from app.modules.rfq.router import router as rfq_router
from app.modules.verificaciones.router import router as verificaciones_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.db_pool = await asyncpg.create_pool(dsn=settings.database_url, min_size=1, max_size=10)
    app.state.redis = aioredis.from_url(settings.redis_url, decode_responses=True)
    yield
    await app.state.db_pool.close()
    await app.state.redis.aclose()


app = FastAPI(title="SupplyNet API", version="0.1.0", lifespan=lifespan)

# Permisivo a propósito: el cliente Flutter corre en web (navegador, origen
# distinto al backend), Windows y Android, y no hay tiempo en el hackatón
# para mantener una allowlist de orígenes. Sin esto, el build web del
# frontend no puede llamar a la API por CORS.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cada router es un módulo independiente (app/modules/<dominio>/) — ver
# "Arquitectura del backend" en CLAUDE.md antes de agregar uno nuevo.
app.include_router(auth_router)
app.include_router(categorias_router)
app.include_router(proveedores_router)
app.include_router(productos_router)
app.include_router(rfq_router)
app.include_router(verificaciones_router)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
