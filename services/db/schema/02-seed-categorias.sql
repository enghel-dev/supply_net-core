-- ==========================================================
-- SupplyNet - Seed de categorías base
-- ==========================================================
-- Idempotente (ON CONFLICT DO NOTHING sobre el UNIQUE de nombre): seguro
-- de correr más de una vez. Aplicado por 00-check-and-init.sh después del
-- schema, tanto en la primera inicialización como en reinicios del script.
--
-- Necesario para que el frontend pueda mostrar un selector de categoría
-- real en vez de pedir un categoria_id a mano (RF-03 catálogo, RF-05 RFQ).

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Materia prima agrícola', 'Granos, semillas, frutas y verduras al por mayor'),
    ('Insumos de construcción', 'Cemento, block, varilla, madera y materiales de obra'),
    ('Textiles y confección', 'Telas, hilos, botones y accesorios de costura'),
    ('Empaques y embalaje', 'Cajas, bolsas, etiquetas y materiales de empaque'),
    ('Equipos y maquinaria', 'Maquinaria industrial, herramientas y repuestos'),
    ('Alimentos y bebidas', 'Insumos para procesamiento de alimentos y bebidas'),
    ('Servicios logísticos', 'Transporte, almacenaje y distribución'),
    ('Productos de limpieza', 'Insumos de limpieza e higiene para negocios'),
    ('Artesanías y manualidades', 'Materia prima para artesanía y manualidades'),
    ('Otros', 'Categoría general para insumos que no encajan en las anteriores')
ON CONFLICT (nombre) DO NOTHING;
