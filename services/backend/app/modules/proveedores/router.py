import json

from fastapi import APIRouter, Depends, Query

from app.core.database import get_db
from app.core.redis import get_redis
from app.core.security import CurrentUser, require_role
from app.modules.proveedores import service
from app.modules.proveedores.schemas import ProveedorCercanoOut, ProveedorOut, ProveedorPerfilIn

router = APIRouter(prefix="/proveedores", tags=["proveedores"])


@router.put("/me", response_model=ProveedorOut)
async def actualizar_mi_perfil(
    data: ProveedorPerfilIn,
    user: CurrentUser = Depends(require_role("proveedor")),
    db=Depends(get_db),
):
    return await service.upsert_perfil(db, user.id, data)


@router.get("/me", response_model=ProveedorOut)
async def mi_perfil(user: CurrentUser = Depends(require_role("proveedor")), db=Depends(get_db)):
    return await service.obtener_perfil_propio(db, user.id)


@router.get("", response_model=list[ProveedorCercanoOut])
async def buscar_proveedores_cercanos(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radio_km: float = Query(10, gt=0, le=500),
    db=Depends(get_db),
    redis=Depends(get_redis),
):
    # Cache-aside por RF-04 / NFR de < 2s (ver services/redis/README.md).
    cache_key = f"proveedores:cercanos:{round(lat, 3)}:{round(lng, 3)}:{round(radio_km, 1)}"
    cached = await redis.get(cache_key)
    if cached is not None:
        return json.loads(cached)

    resultados = await service.buscar_cercanos(db, lat, lng, radio_km)
    payload = [r.model_dump() for r in resultados]
    await redis.set(cache_key, json.dumps(payload), ex=60)
    return resultados


@router.get("/{proveedor_id}", response_model=ProveedorOut)
async def obtener_proveedor(proveedor_id: str, db=Depends(get_db)):
    return await service.obtener_por_id(db, proveedor_id)
