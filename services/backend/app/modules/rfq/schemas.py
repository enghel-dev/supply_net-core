from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

EstadoRfq = Literal["abierta", "cerrada", "cancelada"]
EstadoOferta = Literal["pendiente", "aceptada", "rechazada"]


class SolicitudIn(BaseModel):
    categoria_id: int
    descripcion: str = Field(min_length=1)
    cantidad: float | None = Field(default=None, gt=0)
    fecha_limite: datetime | None = None


class SolicitudOut(BaseModel):
    id: str
    comprador_id: str
    categoria_id: int
    descripcion: str
    cantidad: float | None
    fecha_limite: datetime | None
    estado: EstadoRfq


class OfertaIn(BaseModel):
    precio_ofertado: float = Field(gt=0)
    tiempo_entrega_dias: int | None = Field(default=None, ge=0)
    mensaje: str | None = None


class OfertaOut(BaseModel):
    id: str
    solicitud_id: str
    proveedor_id: str
    precio_ofertado: float
    tiempo_entrega_dias: int | None
    mensaje: str | None
    estado: EstadoOferta
