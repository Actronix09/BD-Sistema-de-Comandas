-- =====================================================================
--  crear_usuarios.sql — Un usuario para cada rol de 099-permisos.sql
--  Práctica 4, Ejercicio 1.6 · Bases de Datos (3CV4)
--
--  No se ejecuta solo: lo llama poblar.sh con el usuario administrador. Las
--  contraseñas salen de variables de entorno con \getenv, nunca de este
--  archivo. Se puede repetir: si la contraseña cambió, la actualiza.
-- =====================================================================

\set ON_ERROR_STOP on
\set QUIET on
-- GRANT avisa si el usuario ya tenía el rol; al repetir no es un problema.
SET client_min_messages = warning;

\getenv clave_app COMANDAS_APP_CLAVE
\getenv clave_consulta COMANDAS_CONSULTA_CLAVE
\getenv clave_admin COMANDAS_ADMIN_CLAVE

DO $$
DECLARE
    v_usuario TEXT;
BEGIN
    FOREACH v_usuario IN ARRAY ARRAY['app_comandas', 'consulta_comandas', 'admin_comandas'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_usuario) THEN
            EXECUTE format('CREATE ROLE %I LOGIN', v_usuario);
        END IF;
    END LOOP;
END;
$$;

ALTER ROLE app_comandas PASSWORD :'clave_app';
ALTER ROLE consulta_comandas PASSWORD :'clave_consulta';
ALTER ROLE admin_comandas PASSWORD :'clave_admin';

GRANT comandas_app TO app_comandas;
GRANT comandas_consulta TO consulta_comandas;
GRANT comandas_admin TO admin_comandas;
