from fastapi import APIRouter, Depends, status

from app.core.database import get_db
from app.modules.auth import service
from app.modules.auth.schemas import LoginIn, RegistroIn, TokenOut

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/registro", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
async def registro(data: RegistroIn, db=Depends(get_db)):
    return await service.registrar_usuario(db, data)


@router.post("/login", response_model=TokenOut)
async def login(data: LoginIn, db=Depends(get_db)):
    return await service.iniciar_sesion(db, data)
