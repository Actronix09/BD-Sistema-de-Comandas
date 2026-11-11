-- Pruebas de integridad referencial del Sistema de Comandas.
-- Se ejecuta después de esquema.sql y datos-ejemplo.sql, sobre comandas_pruebas.
-- Todos los cambios de prueba se revierten; al final se verifica la restauración.

\set ON_ERROR_STOP on
BEGIN;

\echo '=== FK inexistente: una mesa no puede apuntar a un evento ausente'
SELECT 'antes' AS momento, count(*) AS mesas FROM mesa;
DO $$
DECLARE v_error TEXT;
BEGIN
    BEGIN
        INSERT INTO mesa (numero_evento, numero_mesa, id_mesero)
        VALUES (99, 99, 1);
        RAISE EXCEPTION 'La FK fk_mesa_evento permitió una referencia inexistente';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
    END;
    RAISE NOTICE 'Error esperado: %', v_error;
    ASSERT v_error LIKE '%fk_mesa_evento%', 'el gestor rechazó por una regla distinta';
    ASSERT (SELECT count(*) FROM mesa) = 3, 'la fila inválida quedó guardada';
END $$;
SELECT 'después' AS momento, count(*) AS mesas FROM mesa;

\echo '=== Orden de carga: primero la hija falla, padre y luego hija funcionan'
SAVEPOINT orden_carga;
SELECT 'antes' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 900001) AS eventos_prueba,
       (SELECT count(*) FROM mesa WHERE numero_evento = 900001) AS mesas_prueba;
DO $$
DECLARE v_error TEXT;
BEGIN
    BEGIN
        INSERT INTO mesa (numero_evento, numero_mesa, id_mesero)
        VALUES (900001, 1, 1);
        RAISE EXCEPTION 'La FK permitió insertar la hija antes que el padre';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
    END;
    RAISE NOTICE 'Hija antes que padre, error esperado: %', v_error;
    ASSERT v_error LIKE '%fk_mesa_evento%', 'el orden incorrecto falló por otra regla';

    INSERT INTO evento (numero_evento, fecha, tipo_evento, numero_asistentes)
    VALUES (900001, DATE '2026-11-05', 'prueba referencial', 1);
    INSERT INTO mesa (numero_evento, numero_mesa, id_mesero)
    VALUES (900001, 1, 1);

    ASSERT (SELECT count(*) FROM evento WHERE numero_evento = 900001) = 1,
        'no se creó el evento padre';
    ASSERT (SELECT count(*) FROM mesa WHERE numero_evento = 900001) = 1,
        'no se creó la mesa hija después del padre';
END $$;
SELECT 'después del orden correcto' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 900001) AS eventos_prueba,
       (SELECT count(*) FROM mesa WHERE numero_evento = 900001) AS mesas_prueba;
ROLLBACK TO SAVEPOINT orden_carga;

\echo '=== ON DELETE RESTRICT: no borrar un ingrediente usado por una receta'
SELECT 'antes' AS momento,
       (SELECT count(*) FROM ingrediente WHERE id_ingrediente = 1) AS ingrediente,
       (SELECT count(*) FROM receta WHERE id_ingrediente = 1) AS recetas_que_lo_usan;
DO $$
DECLARE v_error TEXT;
BEGIN
    BEGIN
        DELETE FROM ingrediente WHERE id_ingrediente = 1;
        RAISE EXCEPTION 'La FK fk_receta_ingrediente permitió borrar un ingrediente usado';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
    END;
    RAISE NOTICE 'Error esperado: %', v_error;
    ASSERT v_error LIKE '%fk_receta_ingrediente%', 'el gestor rechazó por una regla distinta';
    ASSERT (SELECT count(*) FROM ingrediente WHERE id_ingrediente = 1) = 1,
        'se borró el ingrediente';
    ASSERT (SELECT count(*) FROM receta WHERE id_ingrediente = 1) = 1,
        'se perdió la receta que usa el ingrediente';
END $$;
SELECT 'después' AS momento,
       (SELECT count(*) FROM ingrediente WHERE id_ingrediente = 1) AS ingrediente,
       (SELECT count(*) FROM receta WHERE id_ingrediente = 1) AS recetas_que_lo_usan;

\echo '=== ON UPDATE CASCADE: cambiar la clave del evento conserva sus referencias'
SAVEPOINT actualizacion_cascade;
SELECT 'antes' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 17) AS eventos,
       (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) AS organizadores,
       (SELECT count(*) FROM mesa WHERE numero_evento = 17) AS mesas,
       (SELECT count(*) FROM cuenta WHERE numero_evento = 17) AS cuentas,
       (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) AS acuerdos,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 17) AS anticipos,
       (SELECT count(*) FROM comanda WHERE numero_evento = 17) AS comandas,
       (SELECT count(*) FROM pago WHERE numero_evento = 17) AS pagos;
UPDATE evento SET numero_evento = 117 WHERE numero_evento = 17;
SELECT 'después' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 117) AS eventos,
       (SELECT count(*) FROM evento_organizador WHERE numero_evento = 117) AS organizadores,
       (SELECT count(*) FROM mesa WHERE numero_evento = 117) AS mesas,
       (SELECT count(*) FROM cuenta WHERE numero_evento = 117) AS cuentas,
       (SELECT count(*) FROM acuerdo WHERE numero_evento = 117) AS acuerdos,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 117) AS anticipos,
       (SELECT count(*) FROM comanda WHERE numero_evento = 117) AS comandas,
       (SELECT count(*) FROM pago WHERE numero_evento = 117) AS pagos;
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM evento WHERE numero_evento = 117) = 1, 'no se actualizó el evento';
    ASSERT (SELECT count(*) FROM evento_organizador WHERE numero_evento = 117) = 2, 'organizadores no siguieron al evento';
    ASSERT (SELECT count(*) FROM mesa WHERE numero_evento = 117) = 3, 'mesas no siguieron al evento';
    ASSERT (SELECT count(*) FROM cuenta WHERE numero_evento = 117) = 3, 'cuentas no siguieron al evento';
    ASSERT (SELECT count(*) FROM acuerdo WHERE numero_evento = 117) = 4, 'acuerdos no siguieron al evento';
    ASSERT (SELECT count(*) FROM anticipo WHERE numero_evento = 117) = 1, 'anticipo no siguió al evento';
    ASSERT (SELECT count(*) FROM comanda WHERE numero_evento = 117) = 5, 'comandas no siguieron a las cuentas';
    ASSERT (SELECT count(*) FROM pago WHERE numero_evento = 117) = 1, 'pago no siguió a la cuenta';
    ASSERT (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) = 0, 'quedaron organizadores con la clave antigua';
    ASSERT (SELECT count(*) FROM mesa WHERE numero_evento = 17) = 0, 'quedaron mesas con la clave antigua';
END $$;
ROLLBACK TO SAVEPOINT actualizacion_cascade;

\echo '=== ON UPDATE RESTRICT: no cambiar la identidad de un usuario referenciado'
SELECT 'antes' AS momento,
       (SELECT count(*) FROM usuario WHERE id_usuario = 1) AS usuario_original,
       (SELECT count(*) FROM mesero WHERE id_usuario = 1) AS subtipo_mesero,
       (SELECT count(*) FROM usuario) AS usuarios_totales;
DO $$
DECLARE v_error TEXT;
BEGIN
    BEGIN
        UPDATE usuario SET id_usuario = 101 WHERE id_usuario = 1;
        RAISE EXCEPTION 'La FK fk_mesero_usuario permitió cambiar una identidad referenciada';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
    END;
    RAISE NOTICE 'Error esperado: %', v_error;
    ASSERT v_error LIKE '%fk_mesero_usuario%', 'el gestor rechazó por una regla distinta';
    ASSERT (SELECT count(*) FROM usuario WHERE id_usuario = 1) = 1, 'cambió la identidad original';
    ASSERT (SELECT count(*) FROM usuario WHERE id_usuario = 101) = 0, 'apareció la identidad nueva';
    ASSERT (SELECT count(*) FROM mesero WHERE id_usuario = 1) = 1, 'se perdió el subtipo mesero';
END $$;
SELECT 'después' AS momento,
       (SELECT count(*) FROM usuario WHERE id_usuario = 1) AS usuario_original,
       (SELECT count(*) FROM mesero WHERE id_usuario = 1) AS subtipo_mesero,
       (SELECT count(*) FROM usuario) AS usuarios_totales;

\echo '=== ON DELETE CASCADE: borrar el evento elimina sus filas dependientes'
SAVEPOINT borrado_cascade;
SELECT 'datos de ejemplo al inicio' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 17) AS eventos,
       (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) AS organizadores,
       (SELECT count(*) FROM mesa WHERE numero_evento = 17) AS mesas,
       (SELECT count(*) FROM cuenta WHERE numero_evento = 17) AS cuentas,
       (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) AS acuerdos,
       (SELECT count(*) FROM comanda WHERE numero_evento = 17) AS comandas,
       (SELECT count(*) FROM pago WHERE numero_evento = 17) AS pagos,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 17) AS anticipos;
-- Se quitan temporalmente las filas de historial protegidas por RESTRICT.
-- El SAVEPOINT las restaura después; así el borrado del evento prueba CASCADE.
DELETE FROM pago WHERE numero_evento = 17;
DELETE FROM comanda WHERE numero_evento = 17;
DELETE FROM anticipo WHERE numero_evento = 17;
SELECT 'justo antes del CASCADE' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 17) AS eventos,
       (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) AS organizadores,
       (SELECT count(*) FROM mesa WHERE numero_evento = 17) AS mesas,
       (SELECT count(*) FROM cuenta WHERE numero_evento = 17) AS cuentas,
       (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) AS acuerdos,
       (SELECT count(*) FROM comanda WHERE numero_evento = 17) AS comandas,
       (SELECT count(*) FROM pago WHERE numero_evento = 17) AS pagos,
       (SELECT count(*) FROM anticipo WHERE numero_evento = 17) AS anticipos;
DELETE FROM evento WHERE numero_evento = 17;
SELECT 'después del CASCADE' AS momento,
       (SELECT count(*) FROM evento WHERE numero_evento = 17) AS eventos,
       (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) AS organizadores,
       (SELECT count(*) FROM mesa WHERE numero_evento = 17) AS mesas,
       (SELECT count(*) FROM cuenta WHERE numero_evento = 17) AS cuentas,
       (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) AS acuerdos;
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM evento WHERE numero_evento = 17) = 0, 'el evento no se borró';
    ASSERT (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) = 0, 'quedaron organizadores huérfanos';
    ASSERT (SELECT count(*) FROM mesa WHERE numero_evento = 17) = 0, 'quedaron mesas del evento';
    ASSERT (SELECT count(*) FROM cuenta WHERE numero_evento = 17) = 0, 'quedaron cuentas del evento';
    ASSERT (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) = 0, 'quedaron acuerdos del evento';
END $$;
ROLLBACK TO SAVEPOINT borrado_cascade;

\echo '=== Auditorías: las tres consultas deben devolver cero filas'
CREATE TEMP TABLE auditoria_fks (restriccion TEXT, filas_huerfanas BIGINT);
DO $$
DECLARE
    fk RECORD;
    v_union TEXT;
    v_no_nulos TEXT;
    v_cantidad BIGINT;
BEGIN
    FOR fk IN
        SELECT conname, conrelid, confrelid, conkey, confkey
        FROM pg_constraint
        WHERE contype = 'f' AND connamespace = 'public'::regnamespace
    LOOP
        SELECT string_agg(format('h.%I = p.%I', ha.attname, pa.attname), ' AND ' ORDER BY hk.ord),
               string_agg(format('h.%I IS NOT NULL', ha.attname), ' AND ' ORDER BY hk.ord)
        INTO v_union, v_no_nulos
        FROM unnest(fk.conkey) WITH ORDINALITY AS hk(attnum, ord)
        JOIN unnest(fk.confkey) WITH ORDINALITY AS pk(attnum, ord) USING (ord)
        JOIN pg_attribute ha ON ha.attrelid = fk.conrelid AND ha.attnum = hk.attnum
        JOIN pg_attribute pa ON pa.attrelid = fk.confrelid AND pa.attnum = pk.attnum;

        EXECUTE format(
            'SELECT count(*) FROM %s h WHERE %s AND NOT EXISTS (SELECT 1 FROM %s p WHERE %s)',
            fk.conrelid::regclass, v_no_nulos, fk.confrelid::regclass, v_union
        ) INTO v_cantidad;
        IF v_cantidad > 0 THEN
            INSERT INTO auditoria_fks VALUES (fk.conname, v_cantidad);
        END IF;
    END LOOP;
END $$;

CREATE TEMP TABLE auditoria_unicos (indice TEXT, grupos_duplicados BIGINT);
DO $$
DECLARE
    ix RECORD;
    v_claves TEXT;
    v_filtro TEXT;
    v_sql TEXT;
    v_cantidad BIGINT;
BEGIN
    FOR ix IN
        SELECT i.indexrelid, i.indrelid, i.indnkeyatts,
               pg_get_expr(i.indpred, i.indrelid) AS predicado
        FROM pg_index i
        JOIN pg_class t ON t.oid = i.indrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE i.indisunique AND i.indisvalid
          AND n.nspname = 'public' AND t.relkind IN ('r', 'p')
    LOOP
        SELECT string_agg(pg_get_indexdef(ix.indexrelid, k.posicion, true), ', ' ORDER BY k.posicion)
        INTO v_claves
        FROM generate_series(1, ix.indnkeyatts) AS k(posicion);

        v_filtro := CASE WHEN ix.predicado IS NULL THEN '' ELSE ' WHERE ' || ix.predicado END;
        v_sql := format(
            'SELECT count(*) FROM (SELECT 1 FROM %s%s GROUP BY %s HAVING count(*) > 1) d',
            ix.indrelid::regclass, v_filtro, v_claves
        );
        EXECUTE v_sql INTO v_cantidad;
        IF v_cantidad > 0 THEN
            INSERT INTO auditoria_unicos VALUES (ix.indexrelid::regclass::text, v_cantidad);
        END IF;
    END LOOP;
END $$;

CREATE TEMP TABLE auditoria_not_null (tabla TEXT, columna TEXT, filas_nulas BIGINT);
DO $$
DECLARE c RECORD; v_cantidad BIGINT;
BEGIN
    FOR c IN
        SELECT col.table_name, col.column_name
        FROM information_schema.columns col
        JOIN information_schema.tables tab
          ON tab.table_schema = col.table_schema AND tab.table_name = col.table_name
        WHERE col.table_schema = 'public'
          AND tab.table_type = 'BASE TABLE'
          AND col.is_nullable = 'NO'
    LOOP
        EXECUTE format('SELECT count(*) FROM public.%I WHERE %I IS NULL', c.table_name, c.column_name)
        INTO v_cantidad;
        IF v_cantidad > 0 THEN
            INSERT INTO auditoria_not_null VALUES (c.table_name, c.column_name, v_cantidad);
        END IF;
    END LOOP;
END $$;

SELECT * FROM auditoria_fks ORDER BY restriccion;
SELECT * FROM auditoria_unicos ORDER BY indice;
SELECT * FROM auditoria_not_null ORDER BY tabla, columna;
DO $$
BEGIN
    ASSERT NOT EXISTS (SELECT 1 FROM auditoria_fks), 'la auditoría encontró claves foráneas huérfanas';
    ASSERT NOT EXISTS (SELECT 1 FROM auditoria_unicos), 'la auditoría encontró claves únicas duplicadas';
    ASSERT NOT EXISTS (SELECT 1 FROM auditoria_not_null), 'la auditoría encontró NULL en columnas obligatorias';
END $$;

ROLLBACK;

-- Comprueba que la transacción de pruebas restauró el conjunto de ejemplo.
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM evento WHERE numero_evento = 17) = 1, 'no se restauró el evento 17';
    ASSERT (SELECT count(*) FROM evento_organizador WHERE numero_evento = 17) = 2, 'no se restauraron los organizadores';
    ASSERT (SELECT count(*) FROM mesa WHERE numero_evento = 17) = 3, 'no se restauraron las mesas';
    ASSERT (SELECT count(*) FROM cuenta WHERE numero_evento = 17) = 3, 'no se restauraron las cuentas';
    ASSERT (SELECT count(*) FROM acuerdo WHERE numero_evento = 17) = 4, 'no se restauraron los acuerdos';
    ASSERT (SELECT count(*) FROM comanda WHERE numero_evento = 17) = 5, 'no se restauraron las comandas';
    ASSERT (SELECT count(*) FROM pago WHERE numero_evento = 17) = 1, 'no se restauró el pago';
    ASSERT (SELECT count(*) FROM anticipo WHERE numero_evento = 17) = 1, 'no se restauró el anticipo';
END $$;
\echo 'Todas las pruebas referenciales pasaron; los datos de ejemplo quedaron restaurados.'

