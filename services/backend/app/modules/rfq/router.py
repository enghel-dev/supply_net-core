from typing import Literal

from fastapi import APIRouter, Depends, Query, status

from app.core.database import get_db
from app.core.security import CurrentUser, require_role
from app.modules.proveedores.service import obtener_id_por_usuario
from app.modules.rfq import service
from app.modules.rfq.schemas import OfertaIn, OfertaOut, SolicitudIn, SolicitudOut

router = APIRouter(prefix="/rfq", tags=["rfq"])


@router.post("/solicitudes", response_model=SolicitudOut, status_code=status.HTTP_201_CREATED)
async def crear_solicitud(
    data: SolicitudIn, user: CurrentUser = Depends(require_role("comprador")), db=Depends(get_db)
):
    return await service.crear_solicitud(db, user.id, data)


@router.get("/solicitudes", response_model=list[SolicitudOut])
async def listar_solicitudes(
    categoria_id: int | None = Query(default=None),
    estado: Literal["abierta", "cerrada", "cancelada"] | None = Query(default=None),
    solo_mias: bool = Query(default=False),
    user: CurrentUser = Depends(require_role("comprador", "proveedor")),
    db=Depends(get_db),
):
    # RF-08 (panel proveedor): listar solicitudes abiertas de su categoría.
    # RF-09 (panel comprador): solo_mias=true filtra a las suyas.
    comprador_id = user.id if (solo_mias and user.rol == "comprador") else None
    return await service.listar_solicitudes(
        db, categoria_id=categoria_id, estado=estado, comprador_id=comprador_id
    )


@router.get("/solicitudes/{solicitud_id}", response_model=SolicitudOut)
async def obtener_solicitud(solicitud_id: str, db=Depends(get_db)):
    return await service.obtener_solicitud(db, solicitud_id)


@router.patch("/solicitudes/{solicitud_id}/estado", response_model=SolicitudOut)
async def cambiar_estado_solicitud(
    solicitud_id: str,
    nuevo_estado: Literal["cerrada", "cancelada"],
    user: CurrentUser = Depends(require_role("comprador")),
    db=Depends(get_db),
):
    return await service.cambiar_estado_solicitud(db, solicitud_id, user.id, nuevo_estado)


@router.post(
    "/solicitudes/{solicitud_id}/ofertas", response_model=OfertaOut, status_code=status.HTTP_201_CREATED
)
async def crear_oferta(
    solicitud_id: str,
    data: OfertaIn,
    user: CurrentUser = Depends(require_role("proveedor")),
    db=Depends(get_db),
):
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    return await service.crear_oferta(db, solicitud_id, proveedor_id, data)


@router.get("/solicitudes/{solicitud_id}/ofertas", response_model=list[OfertaOut])
async def listar_ofertas_de_solicitud(
    solicitud_id: str, user: CurrentUser = Depends(require_role("comprador")), db=Depends(get_db)
):
    return await service.listar_ofertas_de_solicitud(db, solicitud_id, user.id)


@router.get("/mis-ofertas", response_model=list[OfertaOut])
async def mis_ofertas(user: CurrentUser = Depends(require_role("proveedor")), db=Depends(get_db)):
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    return await service.listar_mis_ofertas(db, proveedor_id)


@router.patch("/ofertas/{oferta_id}/estado", response_model=OfertaOut)
async def responder_oferta(
    oferta_id: str,
    nuevo_estado: Literal["aceptada", "rechazada"],
    user: CurrentUser = Depends(require_role("comprador")),
    db=Depends(get_db),
):
    return await service.responder_oferta(db, oferta_id, user.id, nuevo_estado)
