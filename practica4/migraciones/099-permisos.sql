-- =====================================================================
--  099-permisos.sql — Roles y permisos del Sistema de Comandas
--  Práctica 4, Ejercicio 1.6 · Bases de Datos (3CV4)
--
--  Lleva el número 099 para correr después de las demás migraciones: así los
--  permisos alcanzan a las tablas y columnas que esas agreguen.
--
--  Los roles no entran a la base: agrupan permisos. Los usuarios que sí entran
--  los crea poblar/crear_usuarios.sql, con su contraseña en una variable de entorno.
-- =====================================================================

BEGIN;

-- Los roles son de todo el servidor, no de una base: pueden existir ya.
DO $$
DECLARE
    v_rol TEXT;
BEGIN
    FOREACH v_rol IN ARRAY ARRAY['comandas_app', 'comandas_consulta', 'comandas_admin'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_rol) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', v_rol);
        END IF;
    END LOOP;
END;
$$;

COMMENT ON ROLE comandas_app      IS 'Lo que usan el servidor y el script de carga: opera el salón, sin tocar la estructura.';
COMMENT ON ROLE comandas_consulta IS 'Solo lectura, para reportes; no ve las contraseñas.';
COMMENT ON ROLE comandas_admin    IS 'Administración de los datos: todo sobre las tablas, sin ser dueño de ellas.';

-- Por omisión, cualquier usuario puede conectarse y crear tablas temporales.
-- Se quita y cada rol recibe solo lo que necesita.
DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO comandas_app', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO comandas_consulta', current_database());
    EXECUTE format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO comandas_admin', current_database());
END;
$$;

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO comandas_app, comandas_consulta, comandas_admin;

-- =====================================================================
--  ADMINISTRACIÓN
-- =====================================================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO comandas_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO comandas_admin;

-- =====================================================================
--  CONSULTA
--  Lee todo, salvo el hash de la contraseña: en `usuario` el permiso va por
--  columna. Se arma con el catálogo para incluir las columnas que se agreguen.
-- =====================================================================

GRANT SELECT ON ALL TABLES IN SCHEMA public TO comandas_consulta;
REVOKE SELECT ON usuario FROM comandas_consulta;

DO $$
BEGIN
    EXECUTE (SELECT format('GRANT SELECT (%s) ON usuario TO comandas_consulta', string_agg(quote_ident(attname), ', ' ORDER BY attnum))
               FROM pg_attribute
              WHERE attrelid = 'usuario'::regclass AND attnum > 0 AND NOT attisdropped AND attname <> 'contrasena_hash');
END;
$$;

-- =====================================================================
--  APLICACIÓN
--  Lee todo, porque el servidor valida las contraseñas y arma las pantallas.
-- =====================================================================

GRANT SELECT ON ALL TABLES IN SCHEMA public TO comandas_app;

-- El administrador de la aplicación da de alta y de baja usuarios y el catálogo,
-- y al guardar una receta se reemplaza completa.
GRANT INSERT, UPDATE, DELETE ON
    usuario, mesero, bar_cocina, cajero_admin,
    producto, ingrediente, receta,
    paquete, paquete_producto,
    evento_organizador, acuerdo
TO comandas_app;

-- Eventos, mesas y cuentas no se borran: cambian de estado. Las comandas tampoco:
-- se cancelan, y la cancelación queda registrada.
GRANT INSERT, UPDATE ON evento, mesa, cuenta, comanda TO comandas_app;

-- El dinero recibido no se edita ni se borra.
GRANT INSERT ON pago, anticipo TO comandas_app;

-- La carga pone los identificadores y ajusta las secuencias con setval.
GRANT USAGE, UPDATE ON ALL SEQUENCES IN SCHEMA public TO comandas_app;

COMMIT;
