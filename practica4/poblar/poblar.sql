-- =====================================================================
--  poblar.sql — Carga de los datos del Sistema de Comandas
--  Práctica 4, Ejercicio 1.4 · Bases de Datos (3CV4)
--
--  No se ejecuta solo: lo llama poblar.sh, que deja los CSV en
--  /tmp/poblar/datos dentro del contenedor.
--
--  Todo va en una transacción. Los CSV entran con \copy a tablas temporales
--  y de ahí pasan a las tablas reales en una sola sentencia por tabla. Si
--  esa sentencia falla, se repite renglón por renglón solo para anotar
--  cuáles rechazó el gestor y por qué. Con un solo rechazo, se revierte todo.
-- =====================================================================

\set ON_ERROR_STOP on
\set QUIET on
\pset footer off
SET client_min_messages = warning;

BEGIN;

CREATE TEMP TABLE rechazos (
    tabla        TEXT,
    renglon      BIGINT,
    restriccion  TEXT,
    mensaje      TEXT
);

CREATE TEMP TABLE resumen (
    orden        SERIAL,
    tabla        TEXT,
    leidos       BIGINT,
    insertados   BIGINT,
    ya_existian  BIGINT,
    rechazados   BIGINT
);

-- =====================================================================
--  1. FUNCIONES DE APOYO (temporales: desaparecen al terminar la sesión)
-- =====================================================================

-- Tabla temporal con todas las columnas de texto. Así un dato con el tipo
-- equivocado no detiene el \copy y lo rechaza después el gestor, renglón por
-- renglón. `renglon` es el número de renglón de datos del CSV.
CREATE FUNCTION pg_temp.preparar(p_tabla TEXT, p_columnas TEXT) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('CREATE TEMP TABLE %I (renglon BIGSERIAL, %s)', 'st_' || p_tabla,
                   (SELECT string_agg(format('%I TEXT', c), ', ') FROM unnest(string_to_array(p_columnas, ',')) AS c));
END;
$$;

-- Condición que compara la clave primaria de la tabla real `d` con la temporal `t`.
CREATE FUNCTION pg_temp.misma_clave(p_tabla TEXT) RETURNS TEXT
LANGUAGE sql AS $$
    SELECT string_agg(format('d.%I = t.%I::%s', a.attname, a.attname, format_type(a.atttypid, NULL)), ' AND ')
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
    WHERE c.conrelid = format('public.%I', p_tabla)::regclass AND c.contype = 'p';
$$;

-- Anota un rechazo con el mensaje del gestor.
CREATE FUNCTION pg_temp.anotar(p_tabla TEXT, p_renglon BIGINT, p_restriccion TEXT, p_estado TEXT, p_mensaje TEXT) RETURNS void
LANGUAGE sql AS $$
    INSERT INTO rechazos VALUES (p_tabla, p_renglon,
        COALESCE(NULLIF(p_restriccion, ''), CASE WHEN p_estado = '23514' THEN 'disparador' ELSE 'SQLSTATE ' || p_estado END),
        p_mensaje);
$$;

-- Pasa los renglones de la temporal a la tabla real. `p_fijos` da el valor con
-- el que entra una columna, en lugar del que trae el CSV. Filtra con NOT EXISTS
-- y no con ON CONFLICT: los disparadores BEFORE INSERT corren antes de revisar
-- el conflicto, y repetir un pago ya guardado fallaría por el saldo.
CREATE FUNCTION pg_temp.cargar(p_tabla TEXT, p_fijos JSONB DEFAULT '{}') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    v_temporal     TEXT := 'st_' || p_tabla;
    v_columnas     TEXT;
    v_valores      TEXT;
    v_sentencia    TEXT;
    v_renglon      BIGINT;
    v_leidos       BIGINT;
    v_insertados   BIGINT := 0;
    v_rechazados   BIGINT := 0;
    v_cuantos      BIGINT;
    v_restriccion  TEXT;
    v_estado       TEXT;
    v_mensaje      TEXT;
BEGIN
    -- El tipo va sin precisión a propósito: `'abc'::VARCHAR(2)` recorta sin
    -- avisar, y así es la asignación a la columna la que rechaza el dato.
    SELECT string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum),
           string_agg(COALESCE(p_fijos ->> a.attname,
                               format('NULLIF(t.%I, '''')::%s', a.attname, format_type(a.atttypid, NULL))), ', ' ORDER BY a.attnum)
      INTO v_columnas, v_valores
      FROM pg_attribute a
     WHERE a.attrelid = format('public.%I', p_tabla)::regclass
       AND a.attnum > 0 AND NOT a.attisdropped AND a.attgenerated = ''
       AND EXISTS (SELECT 1 FROM pg_attribute s
                    WHERE s.attrelid = v_temporal::regclass AND s.attname = a.attname AND NOT s.attisdropped);

    v_sentencia := format('INSERT INTO public.%I (%s) SELECT %s FROM %I t WHERE NOT EXISTS (SELECT 1 FROM public.%I d WHERE %s)',
                          p_tabla, v_columnas, v_valores, v_temporal, p_tabla, pg_temp.misma_clave(p_tabla));
    EXECUTE format('SELECT count(*) FROM %I', v_temporal) INTO v_leidos;

    BEGIN
        EXECUTE v_sentencia || ' ORDER BY t.renglon';
        GET DIAGNOSTICS v_insertados = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
        FOR v_renglon IN EXECUTE format('SELECT renglon FROM %I ORDER BY renglon', v_temporal) LOOP
            BEGIN
                EXECUTE v_sentencia || ' AND t.renglon = $1' USING v_renglon;
                GET DIAGNOSTICS v_cuantos = ROW_COUNT;
                v_insertados := v_insertados + v_cuantos;
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS v_restriccion = CONSTRAINT_NAME, v_estado = RETURNED_SQLSTATE, v_mensaje = MESSAGE_TEXT;
                PERFORM pg_temp.anotar(p_tabla, v_renglon, v_restriccion, v_estado, v_mensaje);
                v_rechazados := v_rechazados + 1;
            END;
        END LOOP;
    END;

    INSERT INTO resumen (tabla, leidos, insertados, ya_existian, rechazados)
    VALUES (p_tabla, v_leidos, v_insertados, v_leidos - v_insertados - v_rechazados, v_rechazados);
END;
$$;

-- Pone el estado final de `evento` y `cuenta`. Solo toca los renglones que aún
-- no lo tienen, así que en una segunda corrida no cambia nada.
CREATE FUNCTION pg_temp.aplicar_estado(p_tabla TEXT) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    v_temporal     TEXT := 'st_' || p_tabla;
    v_sentencia    TEXT;
    v_renglon      BIGINT;
    v_restriccion  TEXT;
    v_estado       TEXT;
    v_mensaje      TEXT;
BEGIN
    v_sentencia := format('UPDATE public.%I d SET estado = t.estado FROM %I t WHERE %s AND d.estado <> t.estado',
                          p_tabla, v_temporal, pg_temp.misma_clave(p_tabla));
    BEGIN
        EXECUTE v_sentencia;
    EXCEPTION WHEN OTHERS THEN
        FOR v_renglon IN EXECUTE format('SELECT renglon FROM %I ORDER BY renglon', v_temporal) LOOP
            BEGIN
                EXECUTE v_sentencia || ' AND t.renglon = $1' USING v_renglon;
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS v_restriccion = CONSTRAINT_NAME, v_estado = RETURNED_SQLSTATE, v_mensaje = MESSAGE_TEXT;
                PERFORM pg_temp.anotar(p_tabla, v_renglon, v_restriccion, v_estado, v_mensaje);
                UPDATE resumen SET rechazados = rechazados + 1 WHERE tabla = p_tabla;
            END;
        END LOOP;
    END;
END;
$$;

-- =====================================================================
--  2. LECTURA DE LOS CSV
-- =====================================================================

\echo '==> Leyendo los CSV con \\copy'
\o /dev/null

SELECT pg_temp.preparar('ingrediente', 'id_ingrediente,nombre,unidad_medida,stock_actual,stock_minimo,origen');
\copy st_ingrediente (id_ingrediente, nombre, unidad_medida, stock_actual, stock_minimo, origen) FROM '/tmp/poblar/datos/ingrediente.csv' CSV HEADER
SELECT pg_temp.preparar('producto', 'id_producto,nombre,descripcion,categoria,precio,id_producto_principal,origen');
\copy st_producto (id_producto, nombre, descripcion, categoria, precio, id_producto_principal, origen) FROM '/tmp/poblar/datos/producto.csv' CSV HEADER
SELECT pg_temp.preparar('receta', 'id_producto,id_ingrediente,cantidad_por_porcion,origen');
\copy st_receta (id_producto, id_ingrediente, cantidad_por_porcion, origen) FROM '/tmp/poblar/datos/receta.csv' CSV HEADER
SELECT pg_temp.preparar('usuario', 'id_usuario,nombre,usuario,fecha_nacimiento,contrasena_hash,rol');
\copy st_usuario (id_usuario, nombre, usuario, fecha_nacimiento, contrasena_hash, rol) FROM '/tmp/poblar/datos/usuario.csv' CSV HEADER
SELECT pg_temp.preparar('mesero', 'id_usuario,turno_asignado');
\copy st_mesero (id_usuario, turno_asignado) FROM '/tmp/poblar/datos/mesero.csv' CSV HEADER
SELECT pg_temp.preparar('bar_cocina', 'id_usuario,estado,estacion_asignada');
\copy st_bar_cocina (id_usuario, estado, estacion_asignada) FROM '/tmp/poblar/datos/bar_cocina.csv' CSV HEADER
SELECT pg_temp.preparar('cajero_admin', 'id_usuario,nivel_acceso,caja_asignada');
\copy st_cajero_admin (id_usuario, nivel_acceso, caja_asignada) FROM '/tmp/poblar/datos/cajero_admin.csv' CSV HEADER
SELECT pg_temp.preparar('paquete', 'numero_paquete,monto,detalles');
\copy st_paquete (numero_paquete, monto, detalles) FROM '/tmp/poblar/datos/paquete.csv' CSV HEADER
SELECT pg_temp.preparar('paquete_producto', 'numero_paquete,id_producto');
\copy st_paquete_producto (numero_paquete, id_producto) FROM '/tmp/poblar/datos/paquete_producto.csv' CSV HEADER
SELECT pg_temp.preparar('evento', 'numero_evento,fecha,tipo_evento,numero_asistentes,estado');
\copy st_evento (numero_evento, fecha, tipo_evento, numero_asistentes, estado) FROM '/tmp/poblar/datos/evento.csv' CSV HEADER
SELECT pg_temp.preparar('evento_organizador', 'numero_evento,organizador');
\copy st_evento_organizador (numero_evento, organizador) FROM '/tmp/poblar/datos/evento_organizador.csv' CSV HEADER
SELECT pg_temp.preparar('acuerdo', 'numero_evento,numero_paquete,id_producto,cantidad_acordada');
\copy st_acuerdo (numero_evento, numero_paquete, id_producto, cantidad_acordada) FROM '/tmp/poblar/datos/acuerdo.csv' CSV HEADER
SELECT pg_temp.preparar('anticipo', 'id_anticipo,monto,fecha,numero_evento');
\copy st_anticipo (id_anticipo, monto, fecha, numero_evento) FROM '/tmp/poblar/datos/anticipo.csv' CSV HEADER
SELECT pg_temp.preparar('mesa', 'numero_evento,numero_mesa,id_mesero');
\copy st_mesa (numero_evento, numero_mesa, id_mesero) FROM '/tmp/poblar/datos/mesa.csv' CSV HEADER
SELECT pg_temp.preparar('cuenta', 'numero_evento,secuencial,numero_mesa,nombre,estado');
\copy st_cuenta (numero_evento, secuencial, numero_mesa, nombre, estado) FROM '/tmp/poblar/datos/cuenta.csv' CSV HEADER
SELECT pg_temp.preparar('comanda', 'id_comanda,fecha_hora,precio_cobrado,estado,detalles,numero_evento,secuencial,id_mesero,id_producto,id_bar_cocina,id_cajero_cancela');
\copy st_comanda (id_comanda, fecha_hora, precio_cobrado, estado, detalles, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina, id_cajero_cancela) FROM '/tmp/poblar/datos/comanda.csv' CSV HEADER
SELECT pg_temp.preparar('pago', 'numero_pago,monto,forma_pago,fecha_hora,numero_evento,secuencial,id_cajero,id_mesero_propina,monto_propina');
\copy st_pago (numero_pago, monto, forma_pago, fecha_hora, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina) FROM '/tmp/poblar/datos/pago.csv' CSV HEADER

-- =====================================================================
--  3. CARGA EN EL ORDEN QUE PIDEN LAS CLAVES Y LOS DISPARADORES
--     Primero las tablas de las que dependen las demás. Además:
--       - el evento entra `programado` y la cuenta `abierta`, porque
--         tg_comanda_evento y tg_comanda_cuenta_abierta rechazan comandas
--         en eventos finalizados o en cuentas cerradas;
--       - los pagos entran después de las comandas, porque tg_pago_saldo
--         compara contra el saldo de la cuenta;
--       - las cuentas se cierran con todo pagado (tg_cuenta_cierre), y los
--         eventos se finalizan al último.
-- =====================================================================

\echo '==> Cargando las tablas'

SELECT pg_temp.cargar('ingrediente');
SELECT pg_temp.cargar('producto');
SELECT pg_temp.cargar('receta');
SELECT pg_temp.cargar('usuario');
SELECT pg_temp.cargar('mesero');
SELECT pg_temp.cargar('bar_cocina');
SELECT pg_temp.cargar('cajero_admin');
SELECT pg_temp.cargar('paquete');
SELECT pg_temp.cargar('paquete_producto');
SELECT pg_temp.cargar('evento', '{"estado": "''programado''"}');
SELECT pg_temp.cargar('evento_organizador');
SELECT pg_temp.cargar('acuerdo');
SELECT pg_temp.cargar('anticipo');
SELECT pg_temp.cargar('mesa');
SELECT pg_temp.cargar('cuenta', '{"estado": "''abierta''"}');
SELECT pg_temp.cargar('comanda');
SELECT pg_temp.cargar('pago');
SELECT pg_temp.aplicar_estado('cuenta');
SELECT pg_temp.aplicar_estado('evento');

-- Los identificadores se cargan explícitos: las secuencias deben seguir después
-- del mayor, o el siguiente alta chocaría con un renglón ya cargado.
SELECT setval(pg_get_serial_sequence(format('public.%I', c.table_name), c.column_name),
              (xpath('/row/m/text()', query_to_xml(format('SELECT COALESCE(max(%I), 1) AS m FROM public.%I', c.column_name, c.table_name), false, true, '')))[1]::TEXT::BIGINT)
FROM information_schema.columns c
WHERE c.table_schema = 'public' AND c.is_identity = 'YES';
\o

-- =====================================================================
--  4. REPORTE Y CONFIRMACIÓN
-- =====================================================================

\echo
\echo '==> Renglones por tabla'
SELECT tabla, leidos, insertados, ya_existian, rechazados FROM resumen ORDER BY orden;

SELECT sum(leidos) AS leidos, sum(insertados) AS insertados, sum(ya_existian) AS ya_existian, sum(rechazados) AS rechazados FROM resumen;

\copy (SELECT tabla, renglon, restriccion, mensaje FROM rechazos ORDER BY tabla, renglon) TO '/tmp/poblar/rechazos.csv' CSV HEADER

SELECT count(*) > 0 AS hay_rechazos FROM rechazos \gset

\if :hay_rechazos
    \echo
    \echo '==> Rechazos por restricción'
    SELECT tabla, restriccion, count(*) AS renglones FROM rechazos GROUP BY tabla, restriccion ORDER BY tabla, restriccion;
    \echo
    \echo '==> Primeros renglones rechazados'
    SELECT tabla, renglon, restriccion, mensaje FROM rechazos ORDER BY tabla, renglon LIMIT 10;
    ROLLBACK;
    \echo
    \echo '==> CARGA REVERTIDA: la base quedó como estaba'
\else
    COMMIT;
    \echo
    \echo '==> Carga confirmada'
\endif
