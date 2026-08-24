from typing import Literal

from pydantic import BaseModel

TipoDocumento = Literal["cedula_ruc", "registro_sanitario", "licencia_operacion", "otro"]
EstadoVerificacion = Literal["pendiente", "aprobado", "rechazado"]


class VerificacionIn(BaseModel):
    tipo_documento: TipoDocumento = "otro"


class VerificacionOut(BaseModel):
    id: str
    proveedor_id: str
    tipo_documento: TipoDocumento
    estado: EstadoVerificacion
