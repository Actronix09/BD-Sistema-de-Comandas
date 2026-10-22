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
        VALUES ('Jamon', 'g')
        RETURNING id_ingrediente INTO v_id;
        ASSERT v_id > 8, format('la secuencia de ingrediente dio %s, que ya existía', v_id);

        -- 5) Producto sin id_producto
        INSERT INTO producto (nombre, categoria, precio)
        VALUES ('Sandwich', 'alimentos', '50.00')
        RETURNING id_producto INTO v_id;
        ASSERT v_id > 4, format('la secuencia de producto dio %s, que ya existía', v_id);

        -- 4) Paquete sin numero_paquete
        INSERT INTO paquete (monto, detalles)
        VALUES (20000.00, 'Paquete Mis Quince: ¡El paquete perfecto para tus quince años!')
        RETURNING numero_paquete INTO v_id;
        ASSERT v_id > 2, format('la secuencia de paquetes dio %s, que ya existía', v_id);

        -- 5) Evento sin numero_evento
        INSERT INTO evento (fecha, tipo_evento,  numero_asistentes)
        VALUES (DATE '2026-10-22', 'quince años', 3000)
        RETURNING numero_evento INTO v_id;
        ASSERT v_id > 17, format('la secuencia de evento dio %s, que ya existía', v_id);

    END $$;

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
    
ROLLBACK;




