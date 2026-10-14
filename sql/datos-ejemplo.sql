-- =====================================================================
--  datos-ejemplo.sql — Datos válidos mínimos para probar el esquema
--  Práctica 3 · Sistema de Comandas Profesional
--
--      psql -v ON_ERROR_STOP=1 -U pg-practica1 -d comandas -f sql/datos-ejemplo.sql
--
--  Un evento (17) con dos mesas, dos cuentas, un paquete acordado,
--  comandas en distintos estados y un pago con propina. Los INSERT de
--  inserts-rechazados.sql se apoyan en estas filas.
-- =====================================================================

BEGIN;

-- Usuarios: supertipo y subtipo van en la misma transacción porque la
-- especialización es total (el disparador diferido lo revisa al COMMIT).
INSERT INTO usuario (id_usuario, nombre, usuario, fecha_nacimiento, contrasena_hash, rol) VALUES
    (1, 'Laura Méndez Ruiz',   'lmendez',  DATE '1998-04-12', '$2b$12$hashDeEjemploLaura',   'mesero'),
    (2, 'Óscar Pérez Lara',    'operez',   DATE '2001-09-30', '$2b$12$hashDeEjemploOscar',   'mesero'),
    (3, 'Rosa Gámez Torres',   'rgamez',   DATE '1990-01-05', '$2b$12$hashDeEjemploRosa',    'bar_cocina'),
    (4, 'Iván Soto Cruz',      'isoto',    DATE '1995-07-21', '$2b$12$hashDeEjemploIvan',    'bar_cocina'),
    (5, 'Marta Rivas Peña',    'mrivas',   DATE '1985-11-02', '$2b$12$hashDeEjemploMarta',   'cajero_admin');

INSERT INTO mesero       (id_usuario, turno_asignado)                VALUES (1, 'vespertino'), (2, 'nocturno');
INSERT INTO bar_cocina   (id_usuario, estacion_asignada)             VALUES (3, 'cocina'), (4, 'bar');
INSERT INTO cajero_admin (id_usuario, nivel_acceso, caja_asignada)   VALUES (5, 'administrador', 1);

-- Catálogo.
INSERT INTO producto (id_producto, nombre, categoria, precio, id_producto_principal) VALUES
    (1, 'Refresco',            'bebidas',   35.00, NULL),
    (2, 'Refresco de dieta',   'bebidas',   35.00, 1),
    (3, 'Pasta Alfredo',       'alimentos', 180.00, NULL),
    (4, 'Pastel de chocolate', 'dulceria',  95.00, NULL);

INSERT INTO producto_ingrediente (id_producto, ingrediente) VALUES
    (3, 'pasta'), (3, 'crema'), (3, 'queso parmesano'),
    (4, 'harina'), (4, 'cacao');

INSERT INTO paquete (numero_paquete, monto, detalles) VALUES
    (1, 45000.00, 'Paquete Plata: cena de tres tiempos y refresco ilimitado'),
    (2, 12000.00, 'Paquete Postres: mesa de dulces');

INSERT INTO paquete_producto (numero_paquete, id_producto) VALUES
    (1, 1), (1, 3), (2, 4);

-- Evento 17 con sus organizadores, mesas y cuentas.
INSERT INTO evento (numero_evento, fecha, tipo_evento, numero_asistentes, estado) VALUES
    (17, DATE '2026-10-17', 'boda', 180, 'en_curso');

INSERT INTO evento_organizador (numero_evento, organizador) VALUES
    (17, 'Ana Torres'), (17, 'Luis Herrera');

INSERT INTO acuerdo (numero_evento, numero_paquete, id_producto, cantidad_acordada) VALUES
    (17, 1, 1, 200),
    (17, 1, 3, 180),
    (17, 2, 4, 180),
    (17, 2, 1, 40);   -- el mismo producto acordado por otro paquete

INSERT INTO anticipo (monto, fecha, numero_evento) VALUES
    (20000.00, DATE '2026-09-01', 17);

INSERT INTO mesa (numero_evento, numero_mesa, id_mesero) VALUES
    (17, 1, 1),
    (17, 2, 1),
    (17, 3, 2);

INSERT INTO cuenta (numero_evento, secuencial, numero_mesa) VALUES
    (17, 1, 1),
    (17, 2, 1),
    (17, 3, 3);

-- Comandas: el precio cobrado se copia solo del catálogo.
INSERT INTO comanda (fecha_hora, estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina, id_cajero_cancela, detalles) VALUES
    (TIMESTAMPTZ '2026-10-17 21:05:00-06', 'entregada',      17, 1, 1, 1, 4, NULL, NULL),
    (TIMESTAMPTZ '2026-10-17 21:20:00-06', 'en_preparacion', 17, 1, 1, 3, 3, NULL, 'sin queso'),
    (TIMESTAMPTZ '2026-10-17 21:30:00-06', 'pendiente',      17, 2, 1, 4, NULL, NULL, NULL),
    (TIMESTAMPTZ '2026-10-17 21:35:00-06', 'cancelada',      17, 3, 2, 2, NULL, 5, NULL);

INSERT INTO pago (monto, forma_pago, fecha_hora, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina) VALUES
    (250.00, 'tarjeta', TIMESTAMPTZ '2026-10-17 23:40:00-06', 17, 1, 5, 1, 35.00);

COMMIT;
