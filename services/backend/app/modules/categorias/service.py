import asyncpg

from app.modules.categorias.schemas import CategoriaOut


def _row_to_categoria(row: asyncpg.Record) -> CategoriaOut:
    return CategoriaOut(
        id=row["id"],
        nombre=row["nombre"],
        descripcion=row["descripcion"],
        parent_id=row["parent_id"],
    )


async def listar_categorias(db: asyncpg.Connection) -> list[CategoriaOut]:
    rows = await db.fetch("SELECT * FROM categorias ORDER BY nombre")
    return [_row_to_categoria(row) for row in rows]
