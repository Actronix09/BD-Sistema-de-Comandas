# Ejercicio 2.6 - experimento individual

**Integrante:** Damas Garnica Adrian  
**Proyecto:** Sistema de Comandas  
**Relación elegida:** `comanda.(numero_evento, secuencial)` → `cuenta.(numero_evento, secuencial)`, la relación *Genera* del EER  
**Acción original:** `ON DELETE RESTRICT`  
**Acción probada en la copia:** `ON DELETE CASCADE`

## Pregunta

¿Qué se pierde si se cambia `RESTRICT` por `CASCADE` y se borra una cuenta que todavía tiene comandas?

## Datos utilizados

El experimento parte de una copia de la base cargada con `poblar.sh`, con 61,809 renglones. Se usa la cuenta 231-29, de la mesa 16 del evento 231, que está en curso. Sigue abierta, no tiene pagos y debe 85.00:

| Comanda | Estado | Precio | Producto |
| :-- | :-- | --: | :-- |
| 37526 | `en_preparacion` | 25.00 | Churritos naturales |
| 37527 | `lista` | 60.00 | Tinto de verano |
| 37528 | `cancelada` por el cajero 198 | 180.00 | Cubetazo de 6 cervezas |

## Operación en la copia

El archivo [`sql/practica5/experimento-2.6-adrian.sql`](../../../sql/practica5/experimento-2.6-adrian.sql) intenta borrar la cuenta con `RESTRICT`, cambia la clave foránea a `CASCADE` y repite la misma sentencia.

```sql
ALTER TABLE comanda DROP CONSTRAINT fk_comanda_cuenta;
ALTER TABLE comanda
    ADD CONSTRAINT fk_comanda_cuenta
    FOREIGN KEY (numero_evento, secuencial)
    REFERENCES cuenta (numero_evento, secuencial)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

DELETE FROM cuenta WHERE numero_evento = 231 AND secuencial = 29;
```

`sql/practica5/experimento-2.6-adrian.sh` crea la base `comandas_experimento_adrian` como copia, corre ahí el archivo y la borra al terminar. Después revisa que la base cargada siga con `RESTRICT`.

## Resultado

Con `RESTRICT`, el gestor rechaza el borrado y nada cambia:

```text
ERROR:  update or delete on table "cuenta" violates foreign key constraint "fk_comanda_cuenta" on table "comanda"
DETAIL:  Key (numero_evento, secuencial)=(231, 29) is still referenced from table "comanda".
```

Con `CASCADE`, la misma sentencia se acepta:

| Dato | Con `RESTRICT` | Con `CASCADE` |
| :-- | --: | --: |
| Cuentas | 7,515 | 7,514 |
| Comandas | 37,528 | 37,525 |
| Comandas de la cuenta 231-29 | 3 | 0 |
| Por cobrar en el evento 231 | 10,025.00 | 9,940.00 |
| Pagos | 9,640 | 9,640 |
| Mesas | 3,943 | 3,943 |
| Meseros | 130 | 130 |
| Productos | 214 | 214 |

### Qué se pierde

- **La deuda:** los 85.00 por cobrar desaparecen sin que nadie los haya pagado. El sistema ya no sabe que esa cuenta debía algo.
- **El consumo:** ya no se sabe qué se pidió, a qué precio ni qué mesero lo levantó. El reporte de consumo real contra lo acordado queda por debajo de lo que de verdad se sirvió.
- **El rastro de la cancelación:** también se va la comanda 37528, y con ella que el cajero 198 canceló el cubetazo.
- **La explicación del inventario:** el stock de azúcar, churritos de maíz, mezcal y vino blanco queda igual, es decir, sigue descontado. Los ingredientes sí se gastaron, pero ya no hay comanda que lo explique.

### Qué se conserva

- **Los catálogos y el personal:** la mesa, el mesero y los productos siguen, porque son padres de la comanda y no dependen de ella.
- **Las cuentas con pagos:** `fk_pago_cuenta` no cambió, así que la cuenta 230-1, con 195.00 pagados, se sigue rechazando. Por eso `CASCADE` no daña lo ya cobrado, pero sí expone justo lo que falta cobrar: las 29 cuentas del evento 231 tienen saldo y no tienen pagos.

### El efecto no se queda en la cuenta

`fk_cuenta_evento` ya era `CASCADE`, así que el cambio también abre un camino desde el evento. Quitando los dos anticipos del evento 231, la misma operación da resultados muy distintos:

| Con los anticipos ya quitados, `DELETE FROM evento` | Resultado |
| :-- | :-- |
| Con `RESTRICT` | Se rechaza por `fk_comanda_cuenta` |
| Con `CASCADE` | Se acepta: se borran 28 cuentas, 169 comandas y 16 mesas (se revirtió) |

Esas 28 cuentas y 169 comandas son las que quedaban después de borrar la cuenta 231-29. Como el evento 231 todavía no tiene pagos, una vez quitados sus anticipos la única clave que impide borrarlo es la que este experimento cambió.

## Decisión para el sistema

Debe conservarse **`ON DELETE RESTRICT`**. La acción `CASCADE` corresponde cuando el hijo no tiene sentido sin el padre, y una comanda sí lo tiene: es la prueba de un consumo que se pidió, que pudo gastar inventario y que se debe cobrar.

`RESTRICT` tampoco estorba en la operación normal:

- Una cuenta abierta por error y sin comandas se puede borrar, porque nada la referencia.
- Una comanda que no procede se cancela, y la cuenta ajusta su total sin perder el rastro.
- La aplicación no puede borrar cuentas: `comandas_app` no tiene ese permiso. Pero eso no reemplaza a la restricción, porque `comandas_admin` sí puede, y es ahí donde `RESTRICT` protege contra un error humano.

La salida completa está en [`evidencias/practica5/experimento-2.6-adrian.txt`](../../../evidencias/practica5/experimento-2.6-adrian.txt).
