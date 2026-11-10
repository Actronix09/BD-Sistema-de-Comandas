-- Práctica 5, ejercicio 2.6: experimento individual de Samy.
-- Este archivo solo se puede ejecutar en la copia comandas_experimento_samy.
-- Cambia temporalmente RESTRICT por CASCADE, muestra el efecto y revierte todo.

\set ON_ERROR_STOP on

DO $$
BEGIN
    IF current_database() <> 'comandas_experimento_samy' THEN
        RAISE EXCEPTION 'Ejecuta este experimento solo en comandas_experimento_samy';
    END IF;
END $$;

BEGIN;

\echo '=== Estado inicial: el ingrediente 1 forma parte de la receta del producto 1'
SELECT 'antes' AS momento,
       (SELECT count(*) FROM ingrediente) AS ingredientes,
       (SELECT count(*) FROM receta) AS filas_receta,
       (SELECT count(*) FROM receta WHERE id_ingrediente = 1) AS usos_del_ingrediente,
       (SELECT count(*) FROM receta WHERE id_producto = 1) AS componentes_del_producto,
       (SELECT count(*) FROM producto WHERE id_producto = 1) AS producto,
       (SELECT count(*) FROM comanda) AS comandas;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM ingrediente) = 8, 'la copia no contiene los 8 ingredientes de datos-ejemplo.sql';
    ASSERT (SELECT count(*) FROM receta) = 9, 'la copia no contiene las 9 filas de receta de datos-ejemplo.sql';
    ASSERT (SELECT count(*) FROM receta WHERE id_ingrediente = 1) = 1, 'el ingrediente de prueba no está en una receta';
    ASSERT (SELECT count(*) FROM receta WHERE id_producto = 1) = 2, 'la receta del producto de prueba no es la esperada';
END $$;

\echo '=== Sustitución temporal de ON DELETE RESTRICT por ON DELETE CASCADE'
ALTER TABLE receta DROP CONSTRAINT fk_receta_ingrediente;
ALTER TABLE receta
    ADD CONSTRAINT fk_receta_ingrediente
    FOREIGN KEY (id_ingrediente)
    REFERENCES ingrediente (id_ingrediente)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

\echo '=== Borrado del ingrediente 1 bajo CASCADE'
DELETE FROM ingrediente WHERE id_ingrediente = 1;
SELECT 'después' AS momento,
       (SELECT count(*) FROM ingrediente) AS ingredientes,
       (SELECT count(*) FROM receta) AS filas_receta,
       (SELECT count(*) FROM receta WHERE id_ingrediente = 1) AS usos_del_ingrediente,
       (SELECT count(*) FROM receta WHERE id_producto = 1) AS componentes_del_producto,
       (SELECT count(*) FROM producto WHERE id_producto = 1) AS producto,
       (SELECT count(*) FROM comanda) AS comandas;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM ingrediente) = 7, 'CASCADE no eliminó el ingrediente';
    ASSERT (SELECT count(*) FROM receta) = 8, 'CASCADE no eliminó la fila de receta dependiente';
    ASSERT (SELECT count(*) FROM receta WHERE id_ingrediente = 1) = 0, 'quedó una receta apuntando al ingrediente borrado';
    ASSERT (SELECT count(*) FROM receta WHERE id_producto = 1) = 1, 'no se observó la pérdida de un componente de receta';
    ASSERT (SELECT count(*) FROM producto WHERE id_producto = 1) = 1, 'CASCADE borró el producto';
    ASSERT (SELECT count(*) FROM comanda) = 5, 'CASCADE borró comandas históricas';
END $$;

ROLLBACK;

-- El rollback deja intactos tanto los datos como la acción original.
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM ingrediente) = 8, 'el rollback no restauró los ingredientes';
    ASSERT (SELECT count(*) FROM receta) = 9, 'el rollback no restauró las recetas';
    ASSERT (SELECT count(*) FROM receta WHERE id_ingrediente = 1) = 1, 'el rollback no restauró la dependencia';
    ASSERT (
        SELECT confdeltype = 'r'
        FROM pg_constraint
        WHERE conname = 'fk_receta_ingrediente'
          AND conrelid = 'receta'::regclass
    ), 'el rollback no restauró ON DELETE RESTRICT';
END $$;

\echo 'Experimento terminado: CASCADE eliminó una fila de receta; rollback restauró RESTRICT y todos los datos.'

