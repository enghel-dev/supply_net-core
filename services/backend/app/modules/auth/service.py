import asyncpg
from fastapi import HTTPException, status

from app.core.security import create_access_token, hash_password, verify_password
from app.modules.auth.schemas import LoginIn, RegistroIn, TokenOut


async def registrar_usuario(db: asyncpg.Connection, data: RegistroIn) -> TokenOut:
    try:
        row = await db.fetchrow(
            """
            INSERT INTO usuarios (nombre, email, password_hash, rol, telefono)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, rol
            """,
            data.nombre,
            data.email,
            hash_password(data.password),
            data.rol,
            data.telefono,
        )
    except asyncpg.UniqueViolationError as exc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Ese email ya está registrado"
        ) from exc

    token = create_access_token(subject=str(row["id"]), rol=row["rol"])
    return TokenOut(access_token=token, usuario_id=str(row["id"]), rol=row["rol"])


async def iniciar_sesion(db: asyncpg.Connection, data: LoginIn) -> TokenOut:
    row = await db.fetchrow(
        "SELECT id, password_hash, rol FROM usuarios WHERE email = $1", data.email
    )
    if row is None or not verify_password(data.password, row["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas"
        )

    token = create_access_token(subject=str(row["id"]), rol=row["rol"])
    return TokenOut(access_token=token, usuario_id=str(row["id"]), rol=row["rol"])
