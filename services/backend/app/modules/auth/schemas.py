from typing import Literal

from pydantic import BaseModel, EmailStr, Field

RolUsuario = Literal["comprador", "proveedor", "admin"]


class RegistroIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8)
    rol: RolUsuario = "comprador"
    telefono: str | None = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario_id: str
    rol: RolUsuario
