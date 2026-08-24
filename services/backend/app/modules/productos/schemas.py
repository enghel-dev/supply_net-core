from typing import Literal

from pydantic import BaseModel, Field

UnidadMedida = Literal["kg", "lb", "unidad", "saco", "litro", "quintal", "caja"]


class ProductoIn(BaseModel):
    categoria_id: int
    nombre: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    precio: float = Field(ge=0)
    unidad_medida: UnidadMedida = "unidad"
    stock_disponible: float = Field(ge=0, default=0)
    imagen_url: str | None = None


class ProductoUpdateIn(BaseModel):
    categoria_id: int | None = None
    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    descripcion: str | None = None
    precio: float | None = Field(default=None, ge=0)
    unidad_medida: UnidadMedida | None = None
    stock_disponible: float | None = Field(default=None, ge=0)
    imagen_url: str | None = None
    activo: bool | None = None


class ProductoOut(BaseModel):
    id: str
    proveedor_id: str
    categoria_id: int
    nombre: str
    descripcion: str | None
    precio: float
    unidad_medida: UnidadMedida
    stock_disponible: float
    imagen_url: str | None
    activo: bool
