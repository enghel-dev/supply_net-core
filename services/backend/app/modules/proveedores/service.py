import asyncpg
from fastapi import HTTPException, status

from app.modules.proveedores.schemas import ProveedorCercanoOut, ProveedorOut, ProveedorPerfilIn


def _row_to_proveedor(row: asyncpg.Record) -> ProveedorOut:
    return ProveedorOut(
        id=str(row["id"]),
        usuario_id=str(row["usuario_id"]),
        nombre_empresa=row["nombre_empresa"],
        descripcion=row["descripcion"],
        direccion=row["direccion"],
        latitud=row["latitud"],
        longitud=row["longitud"],
        telefono_contacto=row["telefono_contacto"],
        verificado=row["verificado"],
    )


async def upsert_perfil(db: asyncpg.Connection, usuario_id: str, data: ProveedorPerfilIn) -> ProveedorOut:
    row = await db.fetchrow(
        """
        INSERT INTO proveedores (usuario_id, nombre_empresa, descripcion, direccion, latitud, longitud, telefono_contacto)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (usuario_id) DO UPDATE SET
            nombre_empresa = EXCLUDED.nombre_empresa,
            descripcion = EXCLUDED.descripcion,
            direccion = EXCLUDED.direccion,
            latitud = EXCLUDED.latitud,
            longitud = EXCLUDED.longitud,
            telefono_contacto = EXCLUDED.telefono_contacto
        RETURNING *
        """,
        usuario_id,
        data.nombre_empresa,
        data.descripcion,
        data.direccion,
        data.latitud,
        data.longitud,
        data.telefono_contacto,
    )
    return _row_to_proveedor(row)


async def obtener_perfil_propio(db: asyncpg.Connection, usuario_id: str) -> ProveedorOut:
    row = await db.fetchrow("SELECT * FROM proveedores WHERE usuario_id = $1", usuario_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todavía no has creado tu perfil de proveedor",
        )
    return _row_to_proveedor(row)


async def obtener_id_por_usuario(db: asyncpg.Connection, usuario_id: str) -> str:
    """Resuelve proveedores.id a partir del usuario autenticado.

    Los módulos de productos/rfq guardan proveedor_id (no usuario_id), así
    que cualquier endpoint de proveedor que escribe datos pasa por aquí.
    """
    row = await db.fetchrow("SELECT id FROM proveedores WHERE usuario_id = $1", usuario_id)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Primero debes crear tu perfil de proveedor",
        )
    return str(row["id"])


async def obtener_por_id(db: asyncpg.Connection, proveedor_id: str) -> ProveedorOut:
    row = await db.fetchrow("SELECT * FROM proveedores WHERE id = $1", proveedor_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proveedor no encontrado")
    return _row_to_proveedor(row)


async def buscar_cercanos(
    db: asyncpg.Connection, lat: float, lng: float, radio_km: float
) -> list[ProveedorCercanoOut]:
    """RF-04: proveedores dentro de un radio, ordenados por cercanía.

    earth_box(...) @> ... aprovecha el índice gist idx_proveedores_geo antes
    del cálculo exacto de earth_distance, para que la búsqueda sea rápida
    (el NFR pide < 2s) incluso sin el cache de Redis (ver router.py).
    """
    rows = await db.fetch(
        """
        SELECT *, earth_distance(ll_to_earth(latitud, longitud), ll_to_earth($1, $2)) / 1000 AS distancia_km
        FROM proveedores
        WHERE latitud IS NOT NULL AND longitud IS NOT NULL
          AND earth_box(ll_to_earth($1, $2), $3 * 1000) @> ll_to_earth(latitud, longitud)
          AND earth_distance(ll_to_earth(latitud, longitud), ll_to_earth($1, $2)) <= $3 * 1000
        ORDER BY distancia_km ASC
        """,
        lat,
        lng,
        radio_km,
    )
    return [
        ProveedorCercanoOut(**_row_to_proveedor(row).model_dump(), distancia_km=round(row["distancia_km"], 2))
        for row in rows
    ]
