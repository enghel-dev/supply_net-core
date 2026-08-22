-- ==========================================================
-- SupplyNet - Schema de base de datos (PostgreSQL)
-- Versión normalizada v2
-- ==========================================================

-- Extensión para geolocalización (proveedores cercanos)
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- Función genérica para mantener updated_at al día
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==========================
-- USUARIOS
-- ==========================
CREATE TYPE rol_usuario AS ENUM ('proveedor', 'comprador', 'admin');

CREATE TABLE usuarios (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    rol             rol_usuario NOT NULL DEFAULT 'comprador',
    telefono        VARCHAR(20),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================
-- CATEGORÍAS (insumos, materia prima, servicios, equipos)
-- ==========================
CREATE TABLE categorias (
    id              SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL UNIQUE,
    descripcion     TEXT,
    parent_id       INTEGER REFERENCES categorias(id) -- para subcategorías
);

CREATE INDEX idx_categorias_parent ON categorias(parent_id);

-- ==========================
-- PROVEEDORES (perfil extendido de usuarios con rol 'proveedor')
-- ==========================
CREATE TABLE proveedores (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre_empresa      VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    direccion           VARCHAR(255),
    latitud             DOUBLE PRECISION CHECK (latitud BETWEEN -90 AND 90),
    longitud            DOUBLE PRECISION CHECK (longitud BETWEEN -180 AND 180),
    telefono_contacto   VARCHAR(20),
    verificado          BOOLEAN NOT NULL DEFAULT false, -- se actualiza automático vía trigger, no a mano
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para búsquedas geoespaciales rápidas
CREATE INDEX idx_proveedores_geo ON proveedores
    USING gist (ll_to_earth(latitud, longitud));

CREATE TRIGGER trg_proveedores_updated_at
    BEFORE UPDATE ON proveedores
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==========================
-- PRODUCTOS / CATÁLOGO
-- ==========================
CREATE TYPE unidad_medida_producto AS ENUM ('kg', 'lb', 'unidad', 'saco', 'litro', 'quintal', 'caja');

CREATE TABLE productos (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id        UUID NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    categoria_id        INTEGER NOT NULL REFERENCES categorias(id),
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    precio              NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    unidad_medida       unidad_medida_producto NOT NULL DEFAULT 'unidad',
    stock_disponible    NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (stock_disponible >= 0),
    imagen_url          TEXT,
    activo              BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_proveedor ON productos(proveedor_id);

CREATE TRIGGER trg_productos_updated_at
    BEFORE UPDATE ON productos
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==========================
-- SOLICITUDES DE COTIZACIÓN (RFQ)
-- ==========================
CREATE TYPE estado_rfq AS ENUM ('abierta', 'cerrada', 'cancelada');

CREATE TABLE rfq_solicitudes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comprador_id    UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    categoria_id    INTEGER NOT NULL REFERENCES categorias(id),
    descripcion     TEXT NOT NULL,
    cantidad        NUMERIC(12,2) CHECK (cantidad > 0),
    fecha_limite    TIMESTAMPTZ,
    estado          estado_rfq NOT NULL DEFAULT 'abierta',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_rfq_solicitudes_comprador ON rfq_solicitudes(comprador_id);
CREATE INDEX idx_rfq_solicitudes_categoria ON rfq_solicitudes(categoria_id);

CREATE TRIGGER trg_rfq_solicitudes_updated_at
    BEFORE UPDATE ON rfq_solicitudes
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==========================
-- OFERTAS DE PROVEEDORES A UNA SOLICITUD
-- ==========================
CREATE TYPE estado_oferta AS ENUM ('pendiente', 'aceptada', 'rechazada');

CREATE TABLE rfq_ofertas (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id        UUID NOT NULL REFERENCES rfq_solicitudes(id) ON DELETE CASCADE,
    proveedor_id        UUID NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    precio_ofertado     NUMERIC(12,2) NOT NULL CHECK (precio_ofertado > 0),
    tiempo_entrega_dias INTEGER CHECK (tiempo_entrega_dias >= 0),
    mensaje             TEXT,
    estado              estado_oferta NOT NULL DEFAULT 'pendiente',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (solicitud_id, proveedor_id) -- un proveedor solo oferta 1 vez por solicitud
);

CREATE INDEX idx_rfq_ofertas_solicitud ON rfq_ofertas(solicitud_id);
CREATE INDEX idx_rfq_ofertas_proveedor ON rfq_ofertas(proveedor_id);

CREATE TRIGGER trg_rfq_ofertas_updated_at
    BEFORE UPDATE ON rfq_ofertas
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==========================
-- VERIFICACIÓN / SELLO DE CONFIANZA
-- ==========================
CREATE TYPE estado_verificacion AS ENUM ('pendiente', 'aprobado', 'rechazado');
CREATE TYPE tipo_documento_verificacion AS ENUM ('cedula_ruc', 'registro_sanitario', 'licencia_operacion', 'otro');

CREATE TABLE verificaciones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id    UUID NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    tipo_documento  tipo_documento_verificacion NOT NULL DEFAULT 'otro',
    estado          estado_verificacion NOT NULL DEFAULT 'pendiente',
    fecha_revision  TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_verificaciones_proveedor ON verificaciones(proveedor_id);

CREATE TRIGGER trg_verificaciones_updated_at
    BEFORE UPDATE ON verificaciones
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger: cuando una verificación se aprueba/rechaza, sincroniza proveedores.verificado
-- automáticamente (evita que el booleano quede desactualizado respecto al estado real).
CREATE OR REPLACE FUNCTION sync_proveedor_verificado()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'aprobado' THEN
        UPDATE proveedores SET verificado = true WHERE id = NEW.proveedor_id;
    ELSIF NEW.estado = 'rechazado' THEN
        UPDATE proveedores SET verificado = false WHERE id = NEW.proveedor_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_proveedor_verificado
    AFTER INSERT OR UPDATE OF estado ON verificaciones
    FOR EACH ROW EXECUTE FUNCTION sync_proveedor_verificado();

-- ==========================
-- SEED DATA MÍNIMO PARA DESARROLLO
-- ==========================
INSERT INTO categorias (nombre) VALUES
  ('Insumos agrícolas'), ('Materia prima'), ('Equipos productivos'), ('Servicios especializados');

-- ==========================================================
-- QUERY DE EJEMPLO: buscar proveedores cercanos
-- (no se ejecuta al correr el script, es solo referencia)
-- ==========================================================
-- SELECT p.id, p.nombre_empresa, p.latitud, p.longitud,
--        earth_distance(ll_to_earth(p.latitud, p.longitud), ll_to_earth(:lat, :lng)) / 1000 AS distancia_km
-- FROM proveedores p
-- WHERE earth_box(ll_to_earth(:lat, :lng), :radio_metros) @> ll_to_earth(p.latitud, p.longitud)
-- ORDER BY distancia_km ASC
-- LIMIT 20;
