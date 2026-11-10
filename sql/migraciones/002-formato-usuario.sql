-- 002-formato-usuario.sql — Normaliza el formato del nombre de acceso.

BEGIN;

ALTER TABLE usuario
    ADD CONSTRAINT ck_usuario_formato
    CHECK (usuario ~ '^[A-Za-z][A-Za-z0-9]{2,39}$');

COMMIT;
