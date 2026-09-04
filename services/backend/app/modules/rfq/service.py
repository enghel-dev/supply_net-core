import asyncpg
from fastapi import HTTPException, status

from app.modules.rfq.schemas import OfertaIn, OfertaOut, SolicitudIn, SolicitudOut


def _row_to_solicitud(row: asyncpg.Record) -> SolicitudOut:
    return SolicitudOut(
        id=str(row["id"]),
        comprador_id=str(row["comprador_id"]),
        categoria_id=row["categoria_id"],
        descripcion=row["descripcion"],
        cantidad=float(row["cantidad"]) if row["cantidad"] is not None else None,
        fecha_limite=row["fecha_limite"],
        estado=row["estado"],
    )


def _row_to_oferta(row: asyncpg.Record) -> OfertaOut:
    return OfertaOut(
        id=str(row["id"]),
        solicitud_id=str(row["solicitud_id"]),
        proveedor_id=str(row["proveedor_id"]),
        precio_ofertado=float(row["precio_ofertado"]),
        tiempo_entrega_dias=row["tiempo_entrega_dias"],
        mensaje=row["mensaje"],
        estado=row["estado"],
    )


async def crear_solicitud(db: asyncpg.Connection, comprador_id: str, data: SolicitudIn) -> SolicitudOut:
    row = await db.fetchrow(
        """
        INSERT INTO rfq_solicitudes (comprador_id, categoria_id, descripcion, cantidad, fecha_limite)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
        """,
        comprador_id,
        data.categoria_id,
        data.descripcion,
        data.cantidad,
        data.fecha_limite,
    )
    return _row_to_solicitud(row)


async def listar_solicitudes(
    db: asyncpg.Connection,
    categoria_id: int | None = None,
    estado: str | None = None,
    comprador_id: str | None = None,
) -> list[SolicitudOut]:
    condiciones = []
    valores: list = []
    if categoria_id is not None:
        valores.append(categoria_id)
        condiciones.append(f"categoria_id = ${len(valores)}")
    if estado is not None:
        valores.append(estado)
        condiciones.append(f"estado = ${len(valores)}")
    if comprador_id is not None:
        valores.append(comprador_id)
        condiciones.append(f"comprador_id = ${len(valores)}")

    where = f"WHERE {' AND '.join(condiciones)}" if condiciones else ""
    rows = await db.fetch(f"SELECT * FROM rfq_solicitudes {where} ORDER BY created_at DESC", *valores)
    return [_row_to_solicitud(row) for row in rows]


async def obtener_solicitud(db: asyncpg.Connection, solicitud_id: str) -> SolicitudOut:
    row = await db.fetchrow("SELECT * FROM rfq_solicitudes WHERE id = $1", solicitud_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    return _row_to_solicitud(row)


async def cambiar_estado_solicitud(
    db: asyncpg.Connection, solicitud_id: str, comprador_id: str, nuevo_estado: str
) -> SolicitudOut:
    row = await db.fetchrow("SELECT comprador_id FROM rfq_solicitudes WHERE id = $1", solicitud_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if str(row["comprador_id"]) != comprador_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Esta solicitud no te pertenece"
        )

    row = await db.fetchrow(
        "UPDATE rfq_solicitudes SET estado = $1 WHERE id = $2 RETURNING *", nuevo_estado, solicitud_id
    )
    return _row_to_solicitud(row)


async def crear_oferta(
    db: asyncpg.Connection, solicitud_id: str, proveedor_id: str, data: OfertaIn
) -> OfertaOut:
    solicitud = await db.fetchrow("SELECT estado FROM rfq_solicitudes WHERE id = $1", solicitud_id)
    if solicitud is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud["estado"] != "abierta":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Esta solicitud ya no está abierta"
        )

    try:
        row = await db.fetchrow(
            """
            INSERT INTO rfq_ofertas (solicitud_id, proveedor_id, precio_ofertado, tiempo_entrega_dias, mensaje)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            """,
            solicitud_id,
            proveedor_id,
            data.precio_ofertado,
            data.tiempo_entrega_dias,
            data.mensaje,
        )
    except asyncpg.UniqueViolationError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Ya enviaste una oferta para esta solicitud"
        ) from exc
    return _row_to_oferta(row)


async def listar_ofertas_de_solicitud(
    db: asyncpg.Connection, solicitud_id: str, comprador_id: str
) -> list[OfertaOut]:
    solicitud = await db.fetchrow("SELECT comprador_id FROM rfq_solicitudes WHERE id = $1", solicitud_id)
    if solicitud is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if str(solicitud["comprador_id"]) != comprador_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Esta solicitud no te pertenece"
        )

    rows = await db.fetch(
        "SELECT * FROM rfq_ofertas WHERE solicitud_id = $1 ORDER BY precio_ofertado ASC", solicitud_id
    )
    return [_row_to_oferta(row) for row in rows]


async def listar_mis_ofertas(db: asyncpg.Connection, proveedor_id: str) -> list[OfertaOut]:
    rows = await db.fetch(
        "SELECT * FROM rfq_ofertas WHERE proveedor_id = $1 ORDER BY created_at DESC", proveedor_id
    )
    return [_row_to_oferta(row) for row in rows]


async def responder_oferta(
    db: asyncpg.Connection, oferta_id: str, comprador_id: str, nuevo_estado: str
) -> OfertaOut:
    row = await db.fetchrow(
        """
        SELECT o.*, s.comprador_id AS solicitud_comprador_id
        FROM rfq_ofertas o
        JOIN rfq_solicitudes s ON s.id = o.solicitud_id
        WHERE o.id = $1
        """,
        oferta_id,
    )
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Oferta no encontrada")
    if str(row["solicitud_comprador_id"]) != comprador_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta oferta no corresponde a una solicitud tuya",
        )

    row = await db.fetchrow(
        "UPDATE rfq_ofertas SET estado = $1 WHERE id = $2 RETURNING *", nuevo_estado, oferta_id
    )
    return _row_to_oferta(row)
