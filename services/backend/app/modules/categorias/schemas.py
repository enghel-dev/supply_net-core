from pydantic import BaseModel


class CategoriaOut(BaseModel):
    id: int
    nombre: str
    descripcion: str | None
    parent_id: int | None
