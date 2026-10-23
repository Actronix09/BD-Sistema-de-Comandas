-- ==========================================================================
-- pruebas-validas.sql - Operaciones que el gestor debe aceptar
-- ==========================================================================

BEGIN;

    \warn '=== 1. El precio cobrado se copia del catálogo y ya no cambia'
    DO $$
    DECLARE
        v_id        INTEGER;
        v_precio    NUMERIC(10,2);
    BEGIN
        INSERT INTO comanda (numero_evento, secuencial, id_mesero, id_producto)
        VALUES (17, 2, 1, 3)
        RETURNING id_comanda, precio_cobrado INTO v_id, v_precio;
        ASSERT v_precio = 180.00, format('se esperaba 180.00 y se guardó %s', v_precio);

        UPDATE producto SET precio = 200.00 WHERE id_producto = 3;
        SELECT precio_cobrado INTO v_precio FROM comanda WHERE id_comanda = v_id;
        ASSERT v_precio = 180.00, format('el precio cambio a %s al subir el catálogo', v_precio);

    END $$;
    \warn '✓ 1 de 9'

    \warn '=== 2. Altas sin id o numero: las secuencias no chocan'
    DO $$
    DECLARE
        v_id    INTEGER;
    BEGIN
        -- 1) Usuario sin id_usuario: lo pone la secuencia
        INSERT INTO usuario (nombre, usuario, fecha_nacimiento, contrasena_hash, rol)
        VALUES ('Pedro Nuevo Díaz', 'pnuevo', DATE '2000-02-02', '$2b$12$hashDeEjemploPedro', 'mesero')
        RETURNING id_usuario INTO v_id;
        ASSERT v_id > 5, format('la secuencia de usuario dio %s, que ya existía', v_id);

        -- 2) Su fila de subtipo, con el mismo id
        INSERT INTO mesero (id_usuario, turno_asignado) VALUES (v_id, 'matutino');

        -- 3) Revisar la especialización total, sin COMMIT
        SET CONSTRAINTS ALL IMMEDIATE;

        -- 4) Ingrediente sin id_ingrediente
        INSERT INTO ingrediente (nombre, unidad_medida)
        VALUES ('Papas de Bolsa', 'g')
        RETURNING id_ingrediente INTO v_id;
        ASSERT v_id > 8, format('la secuencia de ingrediente dio %s, que ya existía', v_id);

        -- 5) Producto sin id_producto
        INSERT INTO producto (nombre, categoria, precio)
        VALUES ('Papas de Bolsa', 'alimentos', 50.00)
        RETURNING id_producto INTO v_id;
        ASSERT v_id > 4, format('la secuencia de producto dio %s, que ya existía', v_id);

        -- 6) Paquete sin numero_paquete
        INSERT INTO paquete (monto, detalles)
        VALUES (20000.00, 'Paquete Mis Quince: ¡El paquete perfecto para tus quince años!')
        RETURNING numero_paquete INTO v_id;
        ASSERT v_id > 2, format('la secuencia de paquetes dio %s, que ya existía', v_id);

        -- 7) Evento sin numero_evento
        INSERT INTO evento (fecha, tipo_evento,  numero_asistentes)
        VALUES (DATE '2026-10-22', 'quince años', 3000)
        RETURNING numero_evento INTO v_id;
        ASSERT v_id > 17, format('la secuencia de evento dio %s, que ya existía', v_id);

    END $$;
    \warn '✓ 2 de 9'

    \warn '=== 3. Flujo completo de un producto: el stock se toca una sola vez'
    DO $$
    DECLARE
        v_id        INTEGER;
        v_harina    NUMERIC(10,3);
        v_cacao     NUMERIC(10,3);
        v_ahora     NUMERIC(10,3);
    BEGIN
        -- 1) captura inicial
        SELECT stock_actual INTO v_harina FROM ingrediente WHERE id_ingrediente = 7;
        SELECT stock_actual INTO v_cacao FROM ingrediente WHERE id_ingrediente = 8;
        
        -- 2) levantar comanda
        INSERT INTO comanda (estado, id_producto, numero_evento, secuencial, id_mesero) VALUES ('pendiente', 4, 17, 1, 1)
        RETURNING id_comanda INTO v_id;

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 7;
        ASSERT v_ahora = v_harina, format('pendiente gastó harina: %s -> %s', v_harina, v_ahora); 

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 8;
        ASSERT v_ahora = v_cacao, format('pendiente gastó cacao: %s -> %s', v_cacao, v_ahora);

        -- 3) en preparación
        UPDATE comanda SET estado = 'en_preparacion', id_bar_cocina = 3 WHERE id_comanda = v_id;
        
        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 7;
        ASSERT v_ahora = v_harina - 60, format('en preparación no descontó bien harina %s != %s', v_ahora, v_harina - 60); 

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 8;
        ASSERT v_ahora = v_cacao - 20, format('en preparación no descontó bien cacao: %s != %s', v_ahora, v_cacao - 20);

        -- 4) lista
        UPDATE comanda SET estado = 'lista' WHERE id_comanda = v_id;
        
        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 7;
        ASSERT v_ahora = v_harina - 60, format('lista se mantiene harina: %s = %s', v_ahora, v_harina - 60); 

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 8;
        ASSERT v_ahora = v_cacao - 20, format('lista se mantiene cacao: %s = %s', v_ahora, v_cacao - 20);

        -- 5) entregada
        UPDATE comanda SET estado = 'entregada' WHERE id_comanda = v_id;
        
        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 7;
        ASSERT v_ahora = v_harina - 60, format('entregada se mantiene harina: %s = %s', v_ahora, v_harina - 60); 

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 8;
        ASSERT v_ahora = v_cacao - 20, format('entregada se mantiene cacao: %s = %s', v_ahora, v_cacao - 20);

    END $$;
    \warn '✓ 3 de 9'

    \warn '=== 4. Cancelar una comanda pendiente: el stock no cambia'
    DO $$
    DECLARE
        v_id        INTEGER;
        v_pasta     NUMERIC(10,3);
        v_crema     NUMERIC(10,3);
        v_queso     NUMERIC(10,3);
        v_ahora     NUMERIC(10,3);
    BEGIN
        -- 1) captura inicial
        SELECT stock_actual INTO v_pasta FROM ingrediente WHERE id_ingrediente = 4; 
        SELECT stock_actual INTO v_crema FROM ingrediente WHERE id_ingrediente = 5; 
        SELECT stock_actual INTO v_queso FROM ingrediente WHERE id_ingrediente = 6;

        -- 2) levantar comanda
        INSERT INTO comanda (estado, id_producto, numero_evento, secuencial, id_mesero) VALUES ('pendiente', 3, 17, 1, 1)
        RETURNING id_comanda INTO v_id;

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 4;
        ASSERT v_ahora = v_pasta, format('pendiente gastó pasta: %s -> %s', v_pasta, v_ahora);

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 5;
        ASSERT v_ahora = v_crema, format('pendiente gastó crema: %s -> %s', v_crema, v_ahora);

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 6;
        ASSERT v_ahora = v_queso, format('pendiente gastó queso parmesano: %s -> %s', v_queso, v_ahora);

        -- 3) cancelar comanda
        UPDATE comanda SET estado = 'cancelada', id_cajero_cancela = 5 where id_comanda = v_id;

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 4;
        ASSERT v_ahora = v_pasta, format('cancelar gastó pasta: %s -> %s', v_pasta, v_ahora);

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 5;
        ASSERT v_ahora = v_crema, format('cancelar gastó crema: %s -> %s', v_crema, v_ahora);

        SELECT stock_actual INTO v_ahora FROM ingrediente WHERE id_ingrediente = 6;
        ASSERT v_ahora = v_queso, format('cancelar gastó queso parmesano: %s -> %s', v_queso, v_ahora);
        
    END $$;
    \warn '✓ 4 de 9'

    \warn '=== 5. Total de una cuenta no considera las comandas canceladas'
    DO $$
    DECLARE
        v_id                INTEGER;
        v_secuencial        SMALLINT;
        v_total             NUMERIC(10,2);
        v_precio_refresco   NUMERIC(10,2);
        v_precio_pasta      NUMERIC(10,2);
        v_precio_pastel     NUMERIC(10,2);
    BEGIN
        -- 1) Se crea una cuenta nueva
        SELECT max(secuencial) + 1 INTO v_secuencial FROM cuenta WHERE numero_evento = 17;

        INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, v_secuencial, 2, 'Ato Mico');

        SELECT total_acumulado INTO v_total FROM v_cuenta WHERE numero_evento = 17 AND secuencial = v_secuencial;
        ASSERT v_total = 0, format('la cuenta no inicia en ceros, total cuenta: %s', v_total);

        -- 2) Se levantan 3 comandas a la cuenta
        INSERT INTO comanda (estado, id_producto, numero_evento, secuencial, id_mesero) VALUES ('pendiente', 1, 17, v_secuencial, 1)
        RETURNING precio_cobrado INTO v_precio_refresco;
        
        INSERT INTO comanda (estado, id_producto, numero_evento, secuencial, id_mesero) VALUES ('pendiente', 3, 17, v_secuencial, 1)
        RETURNING precio_cobrado INTO v_precio_pasta;

        INSERT INTO comanda (estado, id_producto, numero_evento, secuencial, id_mesero) VALUES ('pendiente', 4, 17, v_secuencial, 1)
        RETURNING id_comanda, precio_cobrado INTO v_id, v_precio_pastel;

        SELECT total_acumulado INTO v_total FROM v_cuenta WHERE numero_evento = 17 AND secuencial = v_secuencial;
        ASSERT v_total = v_precio_refresco + v_precio_pasta + v_precio_pastel, format('la cuenta no tiene el valor esperado de %s despues de levantar comandas, total cuenta: %s', v_precio_refresco + v_precio_pasta + v_precio_pastel, v_total);
        
        UPDATE comanda SET estado = 'cancelada', id_cajero_cancela = 5 where id_comanda = v_id;

        SELECT total_acumulado INTO v_total FROM v_cuenta WHERE numero_evento = 17 AND secuencial = v_secuencial;
        ASSERT v_total = v_precio_refresco + v_precio_pasta, format('la cuenta no tiene el valor esperado de %s despues de cancelar comanda, total cuenta: %s', v_precio_refresco + v_precio_pasta, v_total);
        
    END $$;
    \warn '✓ 5 de 9'

    \warn '=== 6. Nombre de cuenta repetido: otra mesa o cuenta cerrada'
    DO $$
    DECLARE
        v_secuencial    SMALLINT;
        v_secuencial_1  SMALLINT;
    BEGIN
        -- 1) Se crea una cuenta en la mesa 1
        SELECT max(secuencial) + 1 INTO v_secuencial_1 FROM cuenta WHERE numero_evento = 17;

        INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, v_secuencial_1, 1, 'Paco');

        -- 2) Se crea una cuenta en el mismo nombre en la mesa 2
        SELECT max(secuencial) + 1 INTO v_secuencial FROM cuenta WHERE numero_evento = 17;

        INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, v_secuencial, 2, 'Paco');

        -- 3) Se cierra la cuenta de la mesa 1 y se crea una nueva con el mismo nombre
        UPDATE cuenta SET estado = 'cerrada' WHERE secuencial = v_secuencial_1 AND numero_evento = 17;
        ASSERT FOUND, 'no se encontró la cuenta para cerrarla';

        SELECT max(secuencial) + 1 INTO v_secuencial FROM cuenta WHERE numero_evento = 17;

        INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, v_secuencial, 1, 'Paco');
        
    END $$;
    \warn '✓ 6 de 9'

    \warn '=== 7. Disponibilidad del producto según el stock'
    DO $$
    DECLARE
        v_id_sandwich   INTEGER;
        v_id_queso      INTEGER;
        v_id_mayonesa   INTEGER;
        v_id_jamon      INTEGER;
        v_disponible    BOOLEAN;
    BEGIN
        -- 1) Crear ingredientes y producto
        INSERT INTO producto (nombre, categoria, precio) VALUES ('Sandwich', 'alimentos', 25.00)
        RETURNING id_producto INTO v_id_sandwich;

        INSERT INTO ingrediente (nombre, unidad_medida, stock_actual, stock_minimo) VALUES ('Queso Manchego', 'pieza', 20, 20)
        RETURNING id_ingrediente INTO v_id_queso;
        INSERT INTO ingrediente (nombre, unidad_medida, stock_actual, stock_minimo) VALUES ('Mayonesa', 'g', 50, 60)
        RETURNING id_ingrediente INTO v_id_mayonesa;
        INSERT INTO ingrediente (nombre, unidad_medida, stock_actual, stock_minimo) VALUES ('Jamon', 'g', 0, 20)
        RETURNING id_ingrediente INTO v_id_jamon;
        
        -- 2) Crear receta para el producto
        INSERT INTO receta (id_producto, id_ingrediente, cantidad_por_porcion) VALUES
        (v_id_sandwich, v_id_queso, 2),
        (v_id_sandwich, v_id_mayonesa, 15),
        (v_id_sandwich, v_id_jamon, 2);

        -- 3) Verificar si se puede preparar
        SELECT disponible INTO v_disponible FROM v_producto WHERE id_producto = v_id_sandwich;
        ASSERT v_disponible = false, 'el producto se encuentra disponible con un stock de cero de un ingrediente';

        -- 4) Aumentar stock y verificar si ahora se puede preparar
        UPDATE ingrediente SET stock_actual = 50 WHERE id_ingrediente = v_id_jamon;

        SELECT disponible INTO v_disponible FROM v_producto WHERE id_producto = v_id_sandwich;
        ASSERT v_disponible = true, 'el producto no se encuentra disponible con stock disponible';
        
    END $$;
    \warn '✓ 7 de 9'

    \warn '=== 8. Las propinas se acumulan al mesero'
    DO $$
    DECLARE
        v_id            INTEGER;
        v_propina       NUMERIC(10,2);
        v_acumuladas    NUMERIC(10,2);
        v_secuencial    SMALLINT;
    BEGIN
        -- 1) Propinas acumuladas actuales
        SELECT propinas_acumuladas INTO v_acumuladas FROM v_mesero WHERE id_usuario = 1;

        -- 2) Registrar pago con propina
        SELECT max(secuencial) + 1 INTO v_secuencial FROM cuenta WHERE numero_evento = 17;
        INSERT INTO cuenta (numero_evento, secuencial, numero_mesa, nombre) VALUES (17, v_secuencial, 1, 'Juancho');
        
        INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
        VALUES (500, 'tarjeta', 17, v_secuencial, 5, 1, 50);

        -- 3) Verificar acumulación de propina
        SELECT propinas_acumuladas INTO v_propina FROM v_mesero WHERE id_usuario = 1;
        
        ASSERT v_propina = v_acumuladas + 50, format('la propina acumulada final no fue la esperada de %s, la propina acumulada fue de %s', v_acumuladas + 50, v_propina);
    END $$;
    \warn '✓ 8 de 9'

    \warn '=== 9. Crear una variante de un producto principal'
    DO $$
    DECLARE
        v_id            INTEGER;
        v_principal     INTEGER;
        v_secuencial    SMALLINT;
    BEGIN
        -- 1) Crear variante del producto

        INSERT INTO producto (nombre, categoria, precio, id_producto_principal) 
        VALUES ('Pasta Alfredo con Pollo', 'alimentos', 230, 3)
        RETURNING id_producto INTO v_id;

        -- 2) Verificar que la variante exista
        SELECT id_producto_principal INTO v_principal FROM producto WHERE id_producto = v_id;
        ASSERT v_principal = 3, format('la variante quedó ligada al producto %s y no al 3', v_principal);
    END $$;
    \warn '✓ 9 de 9'
    
ROLLBACK;




