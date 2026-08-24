from pydantic import BaseModel, Field


class ProveedorPerfilIn(BaseModel):
    nombre_empresa: str = Field(min_length=1, max_length=150)
    descripcion: str | None = None
    direccion: str | None = None
    latitud: float | None = Field(default=None, ge=-90, le=90)
    longitud: float | None = Field(default=None, ge=-180, le=180)
    telefono_contacto: str | None = None


class ProveedorOut(BaseModel):
    id: str
    usuario_id: str
    nombre_empresa: str
    descripcion: str | None
    direccion: str | None
    latitud: float | None
    longitud: float | None
    telefono_contacto: str | None
    verificado: bool


class ProveedorCercanoOut(ProveedorOut):
    distancia_km: float
