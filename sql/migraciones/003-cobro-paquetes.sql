-- 003-cobro-paquetes.sql — Lo que incluye un paquete ya no se cobra, hasta lo acordado
--
-- Hasta ahora el acuerdo (evento, paquete, producto, cantidad acordada) solo se
-- guardaba: cada comanda se cobraba a precio de catálogo aunque su producto
-- viniera en el paquete del evento. Con esta migración cada producto acordado
-- tiene un modo de cobro:
--
--   aparte     el paquete no incluye ese consumo: todo se cobra (como antes; es
--              el valor por omisión, así los datos que ya existen no cambian)
--   cobrar     incluido hasta la cantidad acordada; después se cobra a la cuenta
--   bloquear   incluido hasta la cantidad acordada; después ya no se vende
--   anfitrion  incluido hasta la cantidad acordada; después se carga a la
--              cuenta del anfitrión del evento, no a la del invitado
--
-- La cantidad acordada es de todo el evento, no de cada cuenta. Si el mismo
-- producto viene en dos paquetes del evento, se suman, y manda la regla más
-- estricta (bloquear, luego anfitrion, luego cobrar).

BEGIN;

-- Acuerdo: cómo se cobra cada producto acordado
ALTER TABLE acuerdo
    ADD COLUMN modo_cobro VARCHAR(9) NOT NULL DEFAULT 'aparte',
    ADD CONSTRAINT ck_acuerdo_modo_cobro CHECK (modo_cobro IN ('aparte', 'cobrar', 'bloquear', 'anfitrion'));

COMMENT ON COLUMN acuerdo.modo_cobro IS
    'Cómo se cobra el producto en el evento: aparte (no incluido), o incluido hasta la cantidad acordada y después cobrar, bloquear o cargar al anfitrión.';

-- Evento: la cuenta del anfitrión, a la que van los excedentes en modo
-- anfitrion. Es una cuenta del mismo evento (clave foránea compuesta).
ALTER TABLE evento
    ADD COLUMN secuencial_anfitrion SMALLINT NULL,
    ADD CONSTRAINT fk_evento_cuenta_anfitrion FOREIGN KEY (numero_evento, secuencial_anfitrion)
        REFERENCES cuenta (numero_evento, secuencial)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT;

COMMENT ON COLUMN evento.secuencial_anfitrion IS
    'Cuenta del anfitrión dentro del evento; recibe los excedentes de los productos en modo anfitrion.';

-- Comanda: cómo se cobró
--   normal     a precio de catálogo, en su propia cuenta
--   paquete    incluida en el paquete del evento: precio 0
--   anfitrion  a precio de catálogo, pero la paga la cuenta del anfitrión
ALTER TABLE comanda
    ADD COLUMN tipo_cobro VARCHAR(9) NOT NULL DEFAULT 'normal',
    ADD CONSTRAINT ck_comanda_tipo_cobro CHECK (tipo_cobro IN ('normal', 'paquete', 'anfitrion')),
    ADD CONSTRAINT ck_comanda_paquete_sin_costo CHECK (tipo_cobro <> 'paquete' OR precio_cobrado = 0);

COMMENT ON COLUMN comanda.tipo_cobro IS
    'normal (precio de catálogo), paquete (incluida, precio 0) o anfitrion (la paga la cuenta del anfitrión). Se fija al levantarla.';

-- El precio y el tipo de cobro se fijan al levantar la comanda y ya no cambian.
-- Las comandas incluidas se cuentan sin las canceladas: cancelar una devuelve
-- su lugar en el paquete. Las filas del acuerdo se bloquean para que dos
-- meseros a la vez no se lleven la última porción incluida.
CREATE OR REPLACE FUNCTION fijar_precio_cobrado() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_nombre     VARCHAR(80);
    v_acordado   INTEGER;
    v_modo       VARCHAR(9);
    v_incluidas  INTEGER;
    v_anfitrion  SMALLINT;
    v_estado     VARCHAR(8);
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.precio_cobrado IS DISTINCT FROM OLD.precio_cobrado THEN
            RAISE EXCEPTION 'el precio cobrado de la comanda % ya quedó fijado y no se puede modificar', OLD.id_comanda
                USING ERRCODE = 'check_violation';
        END IF;
        IF NEW.tipo_cobro IS DISTINCT FROM OLD.tipo_cobro THEN
            RAISE EXCEPTION 'el tipo de cobro de la comanda % ya quedó fijado y no se puede modificar', OLD.id_comanda
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN NEW;
    END IF;

    SELECT precio, nombre INTO NEW.precio_cobrado, v_nombre FROM producto WHERE id_producto = NEW.id_producto;
    NEW.tipo_cobro := 'normal';

    PERFORM 1 FROM acuerdo
     WHERE numero_evento = NEW.numero_evento AND id_producto = NEW.id_producto AND modo_cobro <> 'aparte'
       FOR UPDATE;
    SELECT SUM(cantidad_acordada),
           (array_agg(modo_cobro ORDER BY array_position(ARRAY['bloquear', 'anfitrion', 'cobrar']::VARCHAR[], modo_cobro)))[1]
      INTO v_acordado, v_modo
      FROM acuerdo
     WHERE numero_evento = NEW.numero_evento AND id_producto = NEW.id_producto AND modo_cobro <> 'aparte';
    IF v_acordado IS NULL THEN
        RETURN NEW;  -- no viene en ningún paquete del evento, o se cobra aparte
    END IF;

    SELECT COUNT(*) INTO v_incluidas
      FROM comanda
     WHERE numero_evento = NEW.numero_evento AND id_producto = NEW.id_producto
       AND tipo_cobro = 'paquete' AND estado <> 'cancelada';
    IF v_incluidas < v_acordado THEN
        NEW.precio_cobrado := 0;
        NEW.tipo_cobro := 'paquete';
        RETURN NEW;
    END IF;

    IF v_modo = 'bloquear' THEN
        RAISE EXCEPTION 'ya se sirvió todo lo acordado de "%" para este evento (%)', v_nombre, v_acordado
            USING ERRCODE = 'check_violation',
                  HINT    = 'El organizador decidió no vender más de lo que incluye el paquete.';
    ELSIF v_modo = 'anfitrion' THEN
        SELECT e.secuencial_anfitrion, c.estado INTO v_anfitrion, v_estado
          FROM evento e
          LEFT JOIN cuenta c ON c.numero_evento = e.numero_evento AND c.secuencial = e.secuencial_anfitrion
         WHERE e.numero_evento = NEW.numero_evento;
        IF v_anfitrion IS NULL THEN
            RAISE EXCEPTION 'se acabó lo incluido de "%" en el paquete y el evento no tiene cuenta del anfitrión',
                            v_nombre
                USING ERRCODE = 'check_violation';
        END IF;
        IF v_estado <> 'abierta' THEN
            RAISE EXCEPTION 'se acabó lo incluido de "%" en el paquete y la cuenta del anfitrión ya está cerrada',
                            v_nombre
                USING ERRCODE = 'check_violation';
        END IF;
        NEW.tipo_cobro := 'anfitrion';
    END IF;
    RETURN NEW;  -- cobrar: precio de catálogo en su propia cuenta
END;
$$;

DROP TRIGGER tg_comanda_precio ON comanda;
CREATE TRIGGER tg_comanda_precio
    BEFORE INSERT OR UPDATE OF precio_cobrado, tipo_cobro ON comanda
    FOR EACH ROW EXECUTE FUNCTION fijar_precio_cobrado();

-- Total acumulado de una cuenta: sus comandas no canceladas, sin las que paga
-- el anfitrión; y si es la cuenta del anfitrión, además todas las comandas del
-- evento que se le cargaron. Las mismas columnas que antes, así que
-- tg_pago_saldo y tg_cuenta_cierre siguen funcionando sin cambios.
CREATE OR REPLACE VIEW v_cuenta AS
SELECT t.*,
       (t.total_acumulado - t.total_pagado)::NUMERIC(10,2) AS saldo
FROM (
    SELECT c.*,
        COALESCE((SELECT SUM(co.precio_cobrado)
                FROM comanda co
                WHERE co.numero_evento = c.numero_evento
                  AND co.estado       <> 'cancelada'
                  AND ((co.secuencial = c.secuencial AND co.tipo_cobro <> 'anfitrion')
                       OR (co.tipo_cobro = 'anfitrion'
                           AND EXISTS (SELECT 1 FROM evento e
                                        WHERE e.numero_evento = c.numero_evento
                                          AND e.secuencial_anfitrion = c.secuencial)))), 0)::NUMERIC(10,2) AS total_acumulado,
        COALESCE((SELECT SUM(p.monto - COALESCE(p.monto_propina, 0))
                FROM pago p
                WHERE p.numero_evento = c.numero_evento
                  AND p.secuencial    = c.secuencial), 0)::NUMERIC(10,2) AS total_pagado
    FROM cuenta c
) t;

COMMIT;
