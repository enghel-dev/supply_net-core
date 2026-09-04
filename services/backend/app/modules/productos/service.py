import asyncpg
from fastapi import HTTPException, status

from app.modules.productos.schemas import ProductoIn, ProductoOut, ProductoUpdateIn


def _row_to_producto(row: asyncpg.Record) -> ProductoOut:
    return ProductoOut(
        id=str(row["id"]),
        proveedor_id=str(row["proveedor_id"]),
        categoria_id=row["categoria_id"],
        nombre=row["nombre"],
        descripcion=row["descripcion"],
        precio=float(row["precio"]),
        unidad_medida=row["unidad_medida"],
        stock_disponible=float(row["stock_disponible"]),
        imagen_url=row["imagen_url"],
        activo=row["activo"],
    )


async def crear_producto(db: asyncpg.Connection, proveedor_id: str, data: ProductoIn) -> ProductoOut:
    row = await db.fetchrow(
        """
        INSERT INTO productos (proveedor_id, categoria_id, nombre, descripcion, precio, unidad_medida, stock_disponible, imagen_url)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
        """,
        proveedor_id,
        data.categoria_id,
        data.nombre,
        data.descripcion,
        data.precio,
        data.unidad_medida,
        data.stock_disponible,
        data.imagen_url,
    )
    return _row_to_producto(row)


async def listar_productos(
    db: asyncpg.Connection,
    categoria_id: int | None = None,
    proveedor_id: str | None = None,
    solo_activos: bool = True,
) -> list[ProductoOut]:
    condiciones = []
    valores: list = []
    if categoria_id is not None:
        valores.append(categoria_id)
        condiciones.append(f"categoria_id = ${len(valores)}")
    if proveedor_id is not None:
        valores.append(proveedor_id)
        condiciones.append(f"proveedor_id = ${len(valores)}")
    if solo_activos:
        condiciones.append("activo = true")

    where = f"WHERE {' AND '.join(condiciones)}" if condiciones else ""
    rows = await db.fetch(f"SELECT * FROM productos {where} ORDER BY created_at DESC", *valores)
    return [_row_to_producto(row) for row in rows]


async def obtener_producto(db: asyncpg.Connection, producto_id: str) -> ProductoOut:
    row = await db.fetchrow("SELECT * FROM productos WHERE id = $1", producto_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto no encontrado")
    return _row_to_producto(row)


async def _verificar_dueno(db: asyncpg.Connection, producto_id: str, proveedor_id: str) -> None:
    row = await db.fetchrow("SELECT proveedor_id FROM productos WHERE id = $1", producto_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto no encontrado")
    if str(row["proveedor_id"]) != proveedor_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Este producto no pertenece a tu catálogo"
        )


async def actualizar_producto(
    db: asyncpg.Connection, producto_id: str, proveedor_id: str, data: ProductoUpdateIn
) -> ProductoOut:
    await _verificar_dueno(db, producto_id, proveedor_id)
    cambios = data.model_dump(exclude_unset=True)
    if not cambios:
        return await obtener_producto(db, producto_id)

    sets = []
    valores: list = []
    for campo, valor in cambios.items():
        valores.append(valor)
        sets.append(f"{campo} = ${len(valores)}")
    valores.append(producto_id)

    row = await db.fetchrow(
        f"UPDATE productos SET {', '.join(sets)} WHERE id = ${len(valores)} RETURNING *", *valores
    )
    return _row_to_producto(row)


async def eliminar_producto(db: asyncpg.Connection, producto_id: str, proveedor_id: str) -> None:
    await _verificar_dueno(db, producto_id, proveedor_id)
    await db.execute("DELETE FROM productos WHERE id = $1", producto_id)
