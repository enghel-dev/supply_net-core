from fastapi import APIRouter, Depends, Query, status

from app.core.database import get_db
from app.core.security import CurrentUser, require_role
from app.modules.productos import service
from app.modules.productos.schemas import ProductoIn, ProductoOut, ProductoUpdateIn
from app.modules.proveedores.service import obtener_id_por_usuario

router = APIRouter(prefix="/productos", tags=["productos"])


@router.post("", response_model=ProductoOut, status_code=status.HTTP_201_CREATED)
async def crear_producto(
    data: ProductoIn, user: CurrentUser = Depends(require_role("proveedor")), db=Depends(get_db)
):
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    return await service.crear_producto(db, proveedor_id, data)


@router.get("", response_model=list[ProductoOut])
async def listar_productos(
    categoria_id: int | None = Query(default=None),
    proveedor_id: str | None = Query(default=None),
    db=Depends(get_db),
):
    return await service.listar_productos(db, categoria_id=categoria_id, proveedor_id=proveedor_id)


@router.get("/{producto_id}", response_model=ProductoOut)
async def obtener_producto(producto_id: str, db=Depends(get_db)):
    return await service.obtener_producto(db, producto_id)


@router.put("/{producto_id}", response_model=ProductoOut)
async def actualizar_producto(
    producto_id: str,
    data: ProductoUpdateIn,
    user: CurrentUser = Depends(require_role("proveedor")),
    db=Depends(get_db),
):
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    return await service.actualizar_producto(db, producto_id, proveedor_id, data)


@router.delete("/{producto_id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_producto(
    producto_id: str, user: CurrentUser = Depends(require_role("proveedor")), db=Depends(get_db)
):
    proveedor_id = await obtener_id_por_usuario(db, user.id)
    await service.eliminar_producto(db, producto_id, proveedor_id)
