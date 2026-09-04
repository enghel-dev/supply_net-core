from fastapi import Request


async def get_db(request: Request):
    """Entrega una conexión del pool de asyncpg para un solo request.

    No hay ORM ni migraciones aquí a propósito: el schema en services/db/ es
    la única fuente de verdad, este módulo solo pide prestada una conexión.
    """
    async with request.app.state.db_pool.acquire() as connection:
        yield connection
