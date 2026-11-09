-- =====================================================================
--  edicion-de-valores.sql — INSERT, UPDATE, DELETE y transacciones
--  Práctica 5, Ejercicio 2.4 · Bases de Datos (3CV4)
--
--  Corre sobre una copia de la base cargada: lo lanza edicion-de-valores.sh.
--  Las sentencias que deben fallar se encierran entre ON_ERROR_STOP off y on;
--  cualquier otro error detiene el script.
-- =====================================================================

\set ON_ERROR_STOP on
\pset pager off

DO $$
BEGIN
    IF current_database() <> 'comandas_edicion' THEN
        RAISE EXCEPTION 'Ejecute este archivo solo en comandas_edicion';
    END IF;
END $$;

-- Lo normal es entrar como la aplicación; donde hace falta otro rol se indica.
SET ROLE comandas_app;

\echo
\echo '=== 1a. INSERT desde una consulta: el evento 233 contrata también el paquete 12'
SELECT numero_paquete, count(*) AS productos_acordados
FROM acuerdo WHERE numero_evento = 233 GROUP BY numero_paquete;

INSERT INTO acuerdo (numero_evento, numero_paquete, id_producto, cantidad_acordada)
SELECT e.numero_evento, pp.numero_paquete, pp.id_producto, e.numero_asistentes
FROM evento e
JOIN paquete_producto pp ON pp.numero_paquete = 12
WHERE e.numero_evento = 233;

SELECT numero_paquete, count(*) AS productos_acordados, max(cantidad_acordada) AS cantidad
FROM acuerdo WHERE numero_evento = 233 GROUP BY numero_paquete ORDER BY numero_paquete;

\echo
\echo '=== 1b. Inserción que resuelve si ya existe: llega el resurtido del proveedor'
SELECT nombre, stock_actual FROM ingrediente
WHERE lower(nombre) IN ('hielo', 'aguacate', 'cardamomo') ORDER BY nombre;

INSERT INTO ingrediente (nombre, unidad_medida, stock_actual, stock_minimo)
VALUES ('Hielo', 'g', 20000, 0),
       ('AGUACATE', 'g', 5000, 0),
       ('Cardamomo', 'g', 500, 100)
ON CONFLICT (lower(nombre::text)) DO UPDATE
    SET stock_actual = ingrediente.stock_actual + EXCLUDED.stock_actual
RETURNING id_ingrediente, nombre, stock_actual, stock_minimo, (xmax = 0) AS es_nuevo;

\echo
\echo '=== 2a. UPDATE que depende de otra tabla: apartar lo que necesita la boda del evento 232'
SELECT count(*) AS ingredientes_bajo_minimo FROM ingrediente WHERE stock_actual < stock_minimo;

UPDATE ingrediente i
   SET stock_minimo = n.necesario
  FROM (SELECT r.id_ingrediente,
               SUM(a.cantidad_acordada * r.cantidad_por_porcion) AS necesario
          FROM acuerdo a
          JOIN receta r ON r.id_producto = a.id_producto
         WHERE a.numero_evento = 232
         GROUP BY r.id_ingrediente) n
 WHERE i.id_ingrediente = n.id_ingrediente
   AND i.stock_minimo < n.necesario
RETURNING i.nombre, i.stock_actual, i.stock_minimo, i.unidad_medida;

SELECT count(*) AS ingredientes_bajo_minimo FROM ingrediente WHERE stock_actual < stock_minimo;

\echo
\echo '=== 2b. UPDATE que clasifica con CASE: cada estación queda ocupada o desocupada'
SELECT estado, count(*) FROM bar_cocina GROUP BY estado ORDER BY estado;

UPDATE bar_cocina b
   SET estado = CASE
           WHEN EXISTS (SELECT 1 FROM comanda c
                         WHERE c.id_bar_cocina = b.id_usuario
                           AND c.estado = 'en_preparacion') THEN 'ocupado'
           ELSE 'desocupado'
       END;

SELECT estado, count(*) FROM bar_cocina GROUP BY estado ORDER BY estado;

\echo
\echo '=== 3a. DELETE con subconsulta: paquetes de temporada que nadie contrató'
WITH nuevo AS (
    INSERT INTO paquete (monto, detalles)
    VALUES (15000, 'Paquete Navidad 2026 (borrador)')
    RETURNING numero_paquete
)
INSERT INTO paquete_producto (numero_paquete, id_producto)
SELECT numero_paquete, p.id_producto
FROM nuevo CROSS JOIN (VALUES (18), (152)) AS p (id_producto);

SELECT (SELECT count(*) FROM paquete) AS paquetes,
       (SELECT count(*) FROM paquete_producto) AS contenido,
       (SELECT count(*) FROM acuerdo) AS acuerdos;

DELETE FROM paquete p
WHERE NOT EXISTS (SELECT 1 FROM acuerdo a WHERE a.numero_paquete = p.numero_paquete)
RETURNING p.numero_paquete, p.detalles;

SELECT (SELECT count(*) FROM paquete) AS paquetes,
       (SELECT count(*) FROM paquete_producto) AS contenido,
       (SELECT count(*) FROM acuerdo) AS acuerdos;

\echo
\echo '--- Un paquete que sí se contrató no se puede borrar (fk_acuerdo_paquete, RESTRICT)'
\set ON_ERROR_STOP off
DELETE FROM paquete WHERE numero_paquete = 12;
\set ON_ERROR_STOP on

\echo
\echo '=== 3b. Borrado lógico: el cajero cancela la comanda 37358 de la cuenta 231-1'
SELECT id_comanda, estado, precio_cobrado, id_cajero_cancela FROM comanda WHERE id_comanda = 37358;
SELECT folio, total_acumulado, saldo FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 1;

UPDATE comanda SET estado = 'cancelada', id_cajero_cancela = 176 WHERE id_comanda = 37358;

SELECT id_comanda, estado, precio_cobrado, id_cajero_cancela FROM comanda WHERE id_comanda = 37358;
SELECT folio, total_acumulado, saldo FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 1;

\echo
\echo '--- La aplicación no tiene permiso de borrarla de verdad'
\set ON_ERROR_STOP off
DELETE FROM comanda WHERE id_comanda = 37359;
\set ON_ERROR_STOP on

\echo
\echo '--- Con el rol de administración sí se puede: mismo total, pero ya no queda rastro (se revierte)'
SET ROLE comandas_admin;
BEGIN;
DELETE FROM comanda WHERE id_comanda = 37358;
SELECT count(*) AS comanda_37358 FROM comanda WHERE id_comanda = 37358;
SELECT folio, total_acumulado, saldo FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 1;
ROLLBACK;

\echo
\echo '--- Y la cuenta sigue protegida mientras conserve comandas (fk_comanda_cuenta, RESTRICT)'
\set ON_ERROR_STOP off
DELETE FROM cuenta WHERE numero_evento = 231 AND secuencial = 1;
\set ON_ERROR_STOP on
SET ROLE comandas_app;

\echo
\echo '=== 4. Transacción con punto de recuperación: entregar, cobrar y cerrar la cuenta 231-20'
SELECT id_comanda, estado, precio_cobrado FROM comanda
WHERE numero_evento = 231 AND secuencial = 20 ORDER BY id_comanda;
SELECT folio, estado, total_acumulado, total_pagado, saldo
FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 20;

BEGIN;

UPDATE comanda SET estado = 'entregada'
WHERE numero_evento = 231 AND secuencial = 20 AND estado IN ('en_preparacion', 'lista');

SAVEPOINT antes_del_pago;

-- El cajero captura mal la propina: se la asigna al mesero 24, que no atiende la mesa 11.
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (130, 'efectivo', 231, 20, 176, 24, 20);
SELECT count(*) AS pagos, sum(monto) AS cobrado FROM pago WHERE numero_evento = 231 AND secuencial = 20;

ROLLBACK TO SAVEPOINT antes_del_pago;
SELECT count(*) AS pagos FROM pago WHERE numero_evento = 231 AND secuencial = 20;
SELECT estado, count(*) FROM comanda
WHERE numero_evento = 231 AND secuencial = 20 GROUP BY estado;

INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (130, 'efectivo', 231, 20, 176, 65, 20);

UPDATE cuenta SET estado = 'cerrada' WHERE numero_evento = 231 AND secuencial = 20;

COMMIT;

SELECT folio, estado, total_acumulado, total_pagado, saldo
FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 20;
SELECT monto, forma_pago, id_mesero_propina, monto_propina
FROM pago WHERE numero_evento = 231 AND secuencial = 20;

\echo
\echo '=== 5. Transacción que falla a la mitad: un café y cinco aguas minerales de 2 L'
RESET ROLE;
CREATE TEMP TABLE foto AS
SELECT (SELECT count(*) FROM comanda) AS comandas,
       (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 14) AS cafe,
       (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 6) AS agua_mineral;
SELECT * FROM foto;
SET ROLE comandas_app;

BEGIN;

-- El precio no se captura: tg_comanda_precio lo copia del catálogo.
INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
VALUES ('en_preparacion', 231, 2, 95, 84, 156);

SELECT (SELECT count(*) FROM comanda) AS comandas,
       (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 14) AS cafe;

\set ON_ERROR_STOP off
INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
SELECT 'en_preparacion', 231, 2, 95, 75, 156
FROM generate_series(1, 5);

-- Después del error, el gestor no acepta nada más hasta que termine la transacción.
SELECT count(*) FROM comanda;
\set ON_ERROR_STOP on

ROLLBACK;

RESET ROLE;
SELECT (SELECT count(*) FROM comanda) AS comandas,
       (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 14) AS cafe,
       (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 6) AS agua_mineral;

DO $$
BEGIN
    ASSERT (SELECT comandas FROM foto) = (SELECT count(*) FROM comanda),
        'la transacción fallida dejó comandas';
    ASSERT (SELECT cafe FROM foto) = (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 14),
        'la transacción fallida dejó descontado el café';
    ASSERT (SELECT agua_mineral FROM foto) = (SELECT stock_actual FROM ingrediente WHERE id_ingrediente = 6),
        'la transacción fallida dejó descontada el agua mineral';
    -- Lo que sí se confirmó en los casos anteriores.
    ASSERT (SELECT estado FROM cuenta WHERE numero_evento = 231 AND secuencial = 20) = 'cerrada',
        'la cuenta 231-20 no quedó cerrada';
    ASSERT (SELECT id_mesero_propina FROM pago WHERE numero_evento = 231 AND secuencial = 20) = 65,
        'la propina no quedó con el mesero correcto';
    ASSERT (SELECT estado FROM comanda WHERE id_comanda = 37358) = 'cancelada',
        'la comanda 37358 no quedó cancelada';
END $$;

\echo
\echo 'Todas las comprobaciones pasaron.'
