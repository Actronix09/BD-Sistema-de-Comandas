-- =====================================================================
--  experimento-2.6-adrian.sql — comanda → cuenta, de RESTRICT a CASCADE
--  Práctica 5, Ejercicio 2.6 · Bases de Datos (3CV4)
--
--  Corre sobre una copia de la base cargada: lo lanza experimento-2.6-adrian.sh.
--  Las sentencias que deben fallar se encierran entre ON_ERROR_STOP off y on;
--  cualquier otro error detiene el script.
-- =====================================================================

\set ON_ERROR_STOP on
\pset pager off

DO $$
BEGIN
    IF current_database() <> 'comandas_experimento_adrian' THEN
        RAISE EXCEPTION 'Ejecute este archivo solo en comandas_experimento_adrian';
    END IF;
END $$;

\echo
\echo '=== Estado inicial: la cuenta 231-29 sigue abierta y debe 85.00'
SELECT folio, estado, total_acumulado, total_pagado, saldo
FROM v_cuenta WHERE numero_evento = 231 AND secuencial = 29;

SELECT co.id_comanda, co.estado, co.precio_cobrado, p.nombre AS producto, co.id_mesero, co.id_cajero_cancela
FROM comanda co
JOIN producto p ON p.id_producto = co.id_producto
WHERE co.numero_evento = 231 AND co.secuencial = 29
ORDER BY co.id_comanda;

-- Ingredientes que ya se descontaron por las dos comandas que entraron a preparación.
CREATE TEMP TABLE stock_antes AS
SELECT DISTINCT i.id_ingrediente, i.nombre, i.stock_actual
FROM comanda co
JOIN receta r ON r.id_producto = co.id_producto
JOIN ingrediente i ON i.id_ingrediente = r.id_ingrediente
WHERE co.numero_evento = 231 AND co.secuencial = 29
  AND co.estado IN ('en_preparacion', 'lista');

CREATE TEMP VIEW conteos AS
SELECT (SELECT count(*) FROM cuenta) AS cuentas,
       (SELECT count(*) FROM comanda) AS comandas,
       (SELECT count(*) FROM pago) AS pagos,
       (SELECT count(*) FROM mesa) AS mesas,
       (SELECT count(*) FROM mesero) AS meseros,
       (SELECT count(*) FROM producto) AS productos;

SELECT * FROM conteos;

\echo
\echo '=== Con ON DELETE RESTRICT: el gestor no deja borrar la cuenta'
SELECT confdeltype AS accion_al_borrar FROM pg_constraint WHERE conname = 'fk_comanda_cuenta';
\set ON_ERROR_STOP off
DELETE FROM cuenta WHERE numero_evento = 231 AND secuencial = 29;
\set ON_ERROR_STOP on
SELECT * FROM conteos;

\echo
\echo '--- Y tampoco el evento, aunque se le quiten primero los anticipos (se revierte)'
BEGIN;
DELETE FROM anticipo WHERE numero_evento = 231;
\set ON_ERROR_STOP off
DELETE FROM evento WHERE numero_evento = 231;
\set ON_ERROR_STOP on
ROLLBACK;

\echo
\echo '=== Se cambia la acción en la copia: de RESTRICT a CASCADE'
ALTER TABLE comanda DROP CONSTRAINT fk_comanda_cuenta;
ALTER TABLE comanda
    ADD CONSTRAINT fk_comanda_cuenta
    FOREIGN KEY (numero_evento, secuencial)
    REFERENCES cuenta (numero_evento, secuencial)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
SELECT confdeltype AS accion_al_borrar FROM pg_constraint WHERE conname = 'fk_comanda_cuenta';

\echo
\echo '=== Con ON DELETE CASCADE: la misma sentencia borra la cuenta y sus comandas'
SELECT count(*) AS cuentas_con_saldo, sum(saldo) AS por_cobrar
FROM v_cuenta WHERE numero_evento = 231 AND saldo > 0;

DELETE FROM cuenta WHERE numero_evento = 231 AND secuencial = 29;

SELECT * FROM conteos;
SELECT count(*) AS comandas_de_la_cuenta FROM comanda WHERE numero_evento = 231 AND secuencial = 29;
SELECT count(*) AS cuentas_con_saldo, sum(saldo) AS por_cobrar
FROM v_cuenta WHERE numero_evento = 231 AND saldo > 0;

\echo
\echo '--- Los ingredientes siguen descontados, pero ya no hay comanda que lo explique'
SELECT a.nombre, a.stock_actual AS antes, i.stock_actual AS despues
FROM stock_antes a
JOIN ingrediente i ON i.id_ingrediente = a.id_ingrediente
ORDER BY a.nombre;

\echo
\echo '--- Una cuenta con pagos sigue protegida por fk_pago_cuenta, que no cambió'
SELECT folio, estado, total_pagado FROM v_cuenta WHERE numero_evento = 230 AND secuencial = 1;
\set ON_ERROR_STOP off
DELETE FROM cuenta WHERE numero_evento = 230 AND secuencial = 1;
\set ON_ERROR_STOP on

\echo
\echo '--- El evento en curso ahora se puede borrar con todo su consumo (se revierte)'
BEGIN;
SELECT (SELECT count(*) FROM cuenta WHERE numero_evento = 231) AS cuentas,
       (SELECT count(*) FROM comanda WHERE numero_evento = 231) AS comandas,
       (SELECT count(*) FROM mesa WHERE numero_evento = 231) AS mesas,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 231) AS anticipos;
DELETE FROM anticipo WHERE numero_evento = 231;
DELETE FROM evento WHERE numero_evento = 231;
SELECT (SELECT count(*) FROM cuenta WHERE numero_evento = 231) AS cuentas,
       (SELECT count(*) FROM comanda WHERE numero_evento = 231) AS comandas,
       (SELECT count(*) FROM mesa WHERE numero_evento = 231) AS mesas,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 231) AS anticipos;
ROLLBACK;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM cuenta WHERE numero_evento = 231 AND secuencial = 29) = 0,
        'CASCADE no borró la cuenta';
    ASSERT (SELECT count(*) FROM comanda WHERE numero_evento = 231 AND secuencial = 29) = 0,
        'CASCADE no borró las comandas de la cuenta';
    ASSERT (SELECT count(*) FROM stock_antes a JOIN ingrediente i USING (id_ingrediente)
             WHERE a.stock_actual <> i.stock_actual) = 0,
        'el borrado cambió el stock';
    ASSERT (SELECT count(*) FROM cuenta WHERE numero_evento = 230 AND secuencial = 1) = 1,
        'se borró una cuenta con pagos';
    ASSERT (SELECT count(*) FROM evento WHERE numero_evento = 231) = 1,
        'no se revirtió el borrado del evento';
END $$;

\echo
\echo 'Todas las comprobaciones pasaron.'
