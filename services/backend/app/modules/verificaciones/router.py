from fastapi import APIRouter, Depends, status

from app.core.database import get_db
from app.core.security import CurrentUser, require_role
from app.modules.proveedores.service import obtener_id_por_usuario
from app.modules.verificaciones import service
from app.modules.verificaciones.schemas import VerificacionIn, VerificacionOut

router = APIRouter(prefix="/verificaciones", tags=["verificaciones"])


@router.post("", response_model=VerificacionOut, status_code=status.HTTP_201_CREATED)
async def solicitar_verificacion(
    data: VerificacionIn, user: CurrentUser = Depends(require_role("proveedor")), db=Depends(get_db)
):
    # TODO (RF-07, could-have): falta la subida del documento en sí (ej. a un
    # bucket S3-compatible) — este endpoint solo registra la solicitud de
    # revisión con el tipo de documento declarado.
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    return await service.solicitar_verificacion(db, proveedor_id, data)


@router.get("/pendientes", response_model=list[VerificacionOut])
async def listar_pendientes(user: CurrentUser = Depends(require_role("admin")), db=Depends(get_db)):
    return await service.listar_pendientes(db)


@router.patch("/{verificacion_id}/aprobar", response_model=VerificacionOut)
async def aprobar(
    verificacion_id: str, user: CurrentUser = Depends(require_role("admin")), db=Depends(get_db)
):
    return await service.revisar_verificacion(db, verificacion_id, aprobado=True)


@router.patch("/{verificacion_id}/rechazar", response_model=VerificacionOut)
async def rechazar(
    verificacion_id: str, user: CurrentUser = Depends(require_role("admin")), db=Depends(get_db)
):
    return await service.revisar_verificacion(db, verificacion_id, aprobado=False)
