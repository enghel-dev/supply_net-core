from fastapi import APIRouter, Depends

from app.core.database import get_db
from app.modules.categorias import service
from app.modules.categorias.schemas import CategoriaOut

router = APIRouter(prefix="/categorias", tags=["categorias"])


@router.get("", response_model=list[CategoriaOut])
async def listar_categorias(db=Depends(get_db)):
    return await service.listar_categorias(db)
