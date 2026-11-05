-- 001-dominios.sql — Tipos compartidos para importes y cantidades.
-- Se aplica después de sql/esquema.sql y antes de los datos de ejemplo.

BEGIN;

CREATE DOMAIN dinero AS NUMERIC(10,2);
COMMENT ON DOMAIN dinero IS 'Importe monetario con dos decimales.';

CREATE DOMAIN cantidad AS NUMERIC(10,3);
COMMENT ON DOMAIN cantidad IS 'Cantidad de inventario o receta con tres decimales.';

-- Estas vistas exponen columnas cuyo tipo cambia en esta migración.
DROP VIEW v_comanda;
DROP VIEW v_producto;
DROP VIEW v_mesero;
DROP VIEW v_cuenta;

-- Retirar temporalmente los disparadores que usan las columnas modificadas.
DROP TRIGGER tg_comanda_precio ON comanda;
DROP TRIGGER tg_comanda_stock ON comanda;
DROP TRIGGER tg_pago_saldo ON pago;

ALTER TABLE producto
    ALTER COLUMN precio TYPE dinero USING precio::dinero;

ALTER TABLE paquete
    ALTER COLUMN monto TYPE dinero USING monto::dinero;

ALTER TABLE comanda
    ALTER COLUMN precio_cobrado TYPE dinero USING precio_cobrado::dinero;

ALTER TABLE pago
    ALTER COLUMN monto TYPE dinero USING monto::dinero,
    ALTER COLUMN monto_propina TYPE dinero USING monto_propina::dinero;

ALTER TABLE anticipo
    ALTER COLUMN monto TYPE dinero USING monto::dinero;

-- Quitar y restablecer defaults hace explícita la conversión al dominio.
ALTER TABLE ingrediente
    ALTER COLUMN stock_actual DROP DEFAULT,
    ALTER COLUMN stock_minimo DROP DEFAULT;

ALTER TABLE ingrediente
    ALTER COLUMN stock_actual TYPE cantidad USING stock_actual::cantidad,
    ALTER COLUMN stock_minimo TYPE cantidad USING stock_minimo::cantidad;

ALTER TABLE ingrediente
    ALTER COLUMN stock_actual SET DEFAULT 0::cantidad,
    ALTER COLUMN stock_minimo SET DEFAULT 0::cantidad;

ALTER TABLE receta
    ALTER COLUMN cantidad_por_porcion TYPE cantidad
        USING cantidad_por_porcion::cantidad;

-- Recrear las vistas con los tipos de las columnas ya actualizados.
CREATE VIEW v_cuenta AS
SELECT t.*,
       (t.total_acumulado - t.total_pagado)::NUMERIC(10,2) AS saldo
FROM (
    SELECT c.*,
        COALESCE((SELECT SUM(co.precio_cobrado)
                FROM comanda co
                WHERE co.numero_evento = c.numero_evento
                  AND co.secuencial    = c.secuencial
                  AND co.estado       <> 'cancelada'), 0)::NUMERIC(10,2) AS total_acumulado,
        COALESCE((SELECT SUM(p.monto - COALESCE(p.monto_propina, 0))
                FROM pago p
                WHERE p.numero_evento = c.numero_evento
                  AND p.secuencial    = c.secuencial), 0)::NUMERIC(10,2) AS total_pagado
    FROM cuenta c
) t;

CREATE VIEW v_mesero AS
SELECT m.id_usuario, u.nombre, m.turno_asignado,
       COALESCE((SELECT SUM(p.monto_propina)
                 FROM pago p
                 WHERE p.id_mesero_propina = m.id_usuario), 0)::NUMERIC(10,2) AS propinas_acumuladas
FROM mesero m
JOIN usuario u ON u.id_usuario = m.id_usuario;

CREATE VIEW v_producto AS
SELECT p.*,
       NOT EXISTS (SELECT 1
                   FROM receta r
                   JOIN ingrediente i ON i.id_ingrediente = r.id_ingrediente
                   WHERE r.id_producto = p.id_producto
                     AND i.stock_actual < r.cantidad_por_porcion) AS disponible
FROM producto p;

CREATE VIEW v_comanda AS
SELECT co.*, p.precio AS precio_catalogo
FROM comanda co
JOIN producto p ON p.id_producto = co.id_producto;

-- Reponer los disparadores retirados antes de alterar los tipos.
CREATE TRIGGER tg_comanda_precio
    BEFORE INSERT OR UPDATE OF precio_cobrado ON comanda
    FOR EACH ROW EXECUTE FUNCTION fijar_precio_cobrado();

CREATE TRIGGER tg_comanda_stock
    AFTER INSERT OR UPDATE OF estado ON comanda
    FOR EACH ROW EXECUTE FUNCTION descontar_stock();

CREATE TRIGGER tg_pago_saldo
    BEFORE INSERT ON pago
    FOR EACH ROW EXECUTE FUNCTION validar_pago_saldo();

COMMIT;
