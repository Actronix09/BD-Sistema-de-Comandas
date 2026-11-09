# Ejercicio 2.6 - experimento individual

**Integrante:** Hernandez Barrios Samuel Rodrigo  
**Proyecto:** Sistema de Comandas  
**Relación elegida:** `receta.id_ingrediente` → `ingrediente.id_ingrediente`  
**Acción original:** `ON DELETE RESTRICT`  
**Acción probada en la copia:** `ON DELETE CASCADE`

## Pregunta

¿Qué se pierde si se cambia `RESTRICT` por `CASCADE` y se borra un ingrediente que todavía forma parte de una receta?

## Datos utilizados

El experimento parte de una copia de `comandas_pruebas`, cargada con `sql/datos-ejemplo.sql`. En esos datos, el ingrediente 1 (`Refresco de cola 355 ml`) aparece una vez en la receta del producto 1 (`Refresco`). La base empieza con 8 ingredientes, 9 filas en `receta`, 4 productos y 5 comandas.

## Operación en la copia

El archivo [`../sql/experimento-2.6-samy.sql`](../sql/experimento-2.6-samy.sql) elimina y vuelve a crear temporalmente la FK con `ON DELETE CASCADE`, borra el ingrediente 1, cuenta las filas y revierte la transacción.

```sql
ALTER TABLE receta DROP CONSTRAINT fk_receta_ingrediente;
ALTER TABLE receta
    ADD CONSTRAINT fk_receta_ingrediente
    FOREIGN KEY (id_ingrediente)
    REFERENCES ingrediente (id_ingrediente)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

DELETE FROM ingrediente WHERE id_ingrediente = 1;
```

La base de producción y `comandas_pruebas` no cambian. `make -C sql experimento-samy` primero reconstruye y prueba `comandas_pruebas`, crea la base aislada `comandas_experimento_samy` como copia y ejecuta allí el archivo.

## Resultado

| Fila | Antes | Después de borrar el ingrediente bajo `CASCADE` |
| :-- | --: | --: |
| Ingredientes | 8 | 7 |
| Filas de `receta` | 9 | 8 |
| Usos del ingrediente 1 en recetas | 1 | 0 |
| Componentes de receta del producto 1 | 2 | 1 |
| Producto 1 en el catálogo | 1 | 1 |
| Comandas | 5 | 5 |

`CASCADE` borra el ingrediente y la fila de receta que dependía de él. El producto y las comandas históricas permanecen, pero el producto pierde silenciosamente un componente de su receta. La preparación y el descuento de inventario ya no representan la receta original.

El script hace `ROLLBACK` y comprueba que la copia vuelve a tener 8 ingredientes, 9 recetas y `ON DELETE RESTRICT`. La salida que confirma los números se guarda en [`../../evidencias/practica5/experimento-2.6-samy.txt`](../../evidencias/practica5/experimento-2.6-samy.txt) al ejecutar el objetivo Makefile.

## Decisión para el sistema

Para el sistema real debe conservarse **`ON DELETE RESTRICT`**. Un ingrediente usado por una receta no se puede eliminar sin antes revisar o reemplazar ese ingrediente en cada receta afectada. El sistema depende de la receta para preparar comandas y descontar existencias; borrarla automáticamente ocultaría un cambio al menú y al inventario.

**Firma:** Hernandez Barrios Samuel Rodrigo

