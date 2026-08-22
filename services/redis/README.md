# Servicio: redis (cache de lecturas)

Redis se agrega para acelerar las lecturas más frecuentes de la app y
reducir carga sobre Postgres. Responde en particular al requerimiento no
funcional del doc de requerimientos (sección 7): *"las búsquedas por
cercanía deben responder en menos de 2 segundos"* (ligado a RF-04, búsqueda
geolocalizada de proveedores). Casos de uso sugeridos para el backend:

- **Catálogo de productos / categorías**: cachear listados (`GET /productos`, `GET /categorias`) con TTL corto (30–120s), invalidar la key al crear/editar un producto.
- **Búsqueda de proveedores cercanos**: cachear resultados por combinación de `lat,lng,radio` con TTL corto (la geolocalización cambia poco en minutos).
- **Sesiones / tokens**: si el backend usa JWT no hace falta, pero si se necesita invalidar sesiones o guardar refresh tokens, Redis es buen lugar.

## Patrón recomendado: cache-aside

```
1. Backend recibe GET /productos?categoria=X
2. Busca en Redis la key "productos:categoria:X"
3. Si existe -> responde desde Redis (rápido)
4. Si no existe -> consulta Postgres, guarda en Redis con TTL, responde
5. Al crear/editar/borrar un producto -> borrar (invalidar) las keys relacionadas
```

## Conexión desde el backend

Dentro de la red de Docker, el host es el nombre del servicio: `redis`, puerto `6379` (ver `REDIS_URL` en `.env.example`).
