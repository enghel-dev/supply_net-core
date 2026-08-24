import asyncpg
from fastapi import HTTPException, status

from app.modules.verificaciones.schemas import VerificacionIn, VerificacionOut


def _row_to_verificacion(row: asyncpg.Record) -> VerificacionOut:
    return VerificacionOut(
        id=str(row["id"]),
        proveedor_id=str(row["proveedor_id"]),
        tipo_documento=row["tipo_documento"],
        estado=row["estado"],
    )


async def solicitar_verificacion(
    db: asyncpg.Connection, proveedor_id: str, data: VerificacionIn
) -> VerificacionOut:
    row = await db.fetchrow(
        "INSERT INTO verificaciones (proveedor_id, tipo_documento) VALUES ($1, $2) RETURNING *",
        proveedor_id,
        data.tipo_documento,
    )
    return _row_to_verificacion(row)


async def listar_pendientes(db: asyncpg.Connection) -> list[VerificacionOut]:
    rows = await db.fetch("SELECT * FROM verificaciones WHERE estado = 'pendiente' ORDER BY created_at ASC")
    return [_row_to_verificacion(row) for row in rows]


async def revisar_verificacion(db: asyncpg.Connection, verificacion_id: str, aprobado: bool) -> VerificacionOut:
    nuevo_estado = "aprobado" if aprobado else "rechazado"
    row = await db.fetchrow(
        "UPDATE verificaciones SET estado = $1, fecha_revision = now() WHERE id = $2 RETURNING *",
        nuevo_estado,
        verificacion_id,
    )
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Verificación no encontrada")
    return _row_to_verificacion(row)
