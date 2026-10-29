-- =====================================================================
--  inserts-rechazados.sql — Instrucciones que el gestor DEBE rechazar
--  Práctica 3, Parte 6.2 · Sistema de Comandas Profesional
--
--  Se ejecuta DESPUÉS de esquema.sql y datos-ejemplo.sql, y SIN
--  ON_ERROR_STOP, para que cada instrucción muestre su error y se siga
--  con la siguiente:
--
--      psql -U pg-practica1 -d comandas -f sql/inserts-rechazados.sql
--
--  Cada bloque indica qué regla del modelo protege la restricción.
--  Ninguna de estas filas debe quedar guardada.
-- =====================================================================

\warn '--- 1. Mesa de un evento que no existe (FK, Regla 8: la mesa no existe sin su evento)'
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero) VALUES (99, 1, 1);

\warn '--- 2. Mesa 1 repetida en el evento 17 (PK compuesta, Regla 8: clave parcial + evento)'
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero) VALUES (17, 1, 2);

\warn '--- 3. Mesa sin mesero (NOT NULL, Regla 4: Atiende es (1,1) del lado de la mesa)'
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero) VALUES (17, 4, NULL);

\warn '--- 4. Cuenta del evento 17 abierta en una mesa que no está en ese evento (FK compuesta)'
INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, 4, 8, 'Amigos del novio');

\warn '--- 5. Propina para un usuario que es cajero, no mesero (FK al subtipo, Regla 9)'
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (300.00, 'efectivo', 17, 2, 5, 5, 40.00);

\warn '--- 6. Registrar como mesero a un usuario cuyo rol es cajero_admin (disyunción, Regla 9)'
INSERT INTO mesero (id_usuario, rol, turno_asignado) VALUES (5, 'mesero', 'matutino');

\warn '--- 7. Usuario sin fila en su subtipo (especialización total, se revisa al COMMIT)'
BEGIN;
INSERT INTO usuario (id_usuario, nombre, usuario, fecha_nacimiento, contrasena_hash, rol)
VALUES (6, 'Pedro Sin Rol', 'psinrol', DATE '2000-02-02', '$2b$12$hashDeEjemplo', 'mesero');
COMMIT;

\warn '--- 8. Nombre de usuario repetido (UNIQUE, clave alternativa de Usuario)'
INSERT INTO usuario (id_usuario, nombre, usuario, fecha_nacimiento, contrasena_hash, rol)
VALUES (7, 'Laura Méndez Ortiz', 'lmendez', DATE '1999-03-03', '$2b$12$hashDeEjemplo', 'mesero');

\warn '--- 9. Pago con monto cero (CHECK monto > 0)'
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero)
VALUES (0.00, 'efectivo', 17, 2, 5);

\warn '--- 10. Propina con mesero pero sin monto (CHECK: el atributo viaja con la relación)'
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina)
VALUES (150.00, 'efectivo', 17, 2, 5, 1);

\warn '--- 11. Comanda marcada como cancelada sin cajero que la cancele (CHECK de Cancela)'
INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto)
VALUES ('cancelada', 17, 2, 1, 1);

\warn '--- 12. Variante de una variante (disparador: la relación Variante tiene un solo nivel)'
INSERT INTO producto (nombre, categoria, precio, id_producto_principal)
VALUES ('Refresco de dieta sin gas', 'bebidas', 35.00, 2);

\warn '--- 13. Mismo producto del mismo paquete acordado dos veces para el evento (PK de la ternaria, Regla 7)'
INSERT INTO acuerdo (numero_evento, numero_paquete, id_producto, cantidad_acordada) VALUES (17, 1, 1, 10);

\warn '--- 14. Cambiar el precio cobrado de una comanda ya levantada (disparador)'
UPDATE comanda SET precio_cobrado = 1.00 WHERE id_comanda = 1;

\warn '--- 15. Borrar el evento 17, que ya tiene anticipo, comandas y pagos (RESTRICT protege el historial)'
DELETE FROM evento WHERE numero_evento = 17;

\warn '--- 16. Preparar un refresco de dieta sin stock de su ingrediente (disparador de stock, receta)'
INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
VALUES ('en_preparacion', 17, 2, 1, 2, 4);

\warn '--- 17. Dejar el stock de un ingrediente en negativo (CHECK stock_actual >= 0)'
UPDATE ingrediente SET stock_actual = -5 WHERE id_ingrediente = 6;

\warn '--- 18. Borrar un ingrediente que todavía usa una receta (RESTRICT de Receta)'
DELETE FROM ingrediente WHERE id_ingrediente = 4;

\warn '--- 19. Cuenta con nombre en blanco (CHECK ck_cuenta_nombre)'
INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, 5, 1, '   ');

\warn '--- 20. Nombre repetido en una cuenta abierta de la misma mesa (índice único parcial)'
INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, 6, 1, 'novios');

\warn '--- 21. Regresar de entregada a pendiente (disparador: los estados solo avanzan)'
UPDATE comanda SET estado = 'pendiente' WHERE id_comanda = 1;

\warn '--- 22. Regresar de lista a en_preparacion (disparador: los estados solo avanzan)'
UPDATE comanda SET estado = 'en_preparacion' WHERE id_comanda = 5;

\warn '--- 23. Descancelar una comanda (disparador: de cancelada no se sale)'
UPDATE comanda SET estado = 'pendiente', id_cajero_cancela = NULL WHERE id_comanda = 4;
