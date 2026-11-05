# Edición de Valores y Transacciones

En este documento se registran las sentencias DML del ejercicio 2.4: inserciones, actualizaciones, borrados y transacciones, cada una a partir de una situación real del salón y comprobada con la base ya poblada.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** `INSERT` desde una consulta y con conflicto, `UPDATE` con otra tabla y con `CASE`, `DELETE` con subconsulta y borrado lógico, transacción con punto de recuperación y transacción que falla a la mitad.

**Archivos:** [`sql/edicion-de-valores.sql`](<sql/edicion-de-valores.sql>), [`sql/edicion-de-valores.sh`](<sql/edicion-de-valores.sh>) y la salida en [`evidencias/practica5/edicion-de-valores.txt`](<../evidencias/practica5/edicion-de-valores.txt>)

---

## Cómo se corre

Con la base ya cargada por `poblar.sh`:

```bash
practica5/sql/edicion-de-valores.sh
```

El script crea la copia `comandas_edicion`, corre ahí las sentencias, guarda la salida y borra la copia al terminar. Por eso se puede repetir y la base cargada no cambia. Las operaciones entran con `SET ROLE comandas_app`, el rol de la aplicación del ejercicio 1.6, salvo donde se indica otro.

Los casos usan el evento 231, que está en curso, y los eventos 232 y 233, que están programados.

## 1. Inserciones

### Un `INSERT` que toma sus valores de una consulta

**Situación:** el evento 233 ya tenía contratado el paquete 3 y agrega el paquete 12 para sus 237 invitados. Se pacta una porción de cada producto por invitado, así que no hay que capturar renglón por renglón.

```sql
INSERT INTO acuerdo (numero_evento, numero_paquete, id_producto, cantidad_acordada)
SELECT e.numero_evento, pp.numero_paquete, pp.id_producto, e.numero_asistentes
FROM evento e
JOIN paquete_producto pp ON pp.numero_paquete = 12
WHERE e.numero_evento = 233;
```

**Resultado:** entran 9 renglones, uno por cada producto del paquete, con cantidad 237. Los 4 del paquete 3 no cambian.

### Una inserción que resuelve el caso de que el renglón ya exista

**Situación:** llega el resurtido del proveedor. Si el ingrediente ya está en el inventario hay que sumarle lo recibido; si es nuevo, hay que darlo de alta.

```sql
INSERT INTO ingrediente (nombre, unidad_medida, stock_actual, stock_minimo)
VALUES ('Hielo', 'g', 20000, 0),
       ('AGUACATE', 'g', 5000, 0),
       ('Cardamomo', 'g', 500, 100)
ON CONFLICT (lower(nombre::text)) DO UPDATE
    SET stock_actual = ingrediente.stock_actual + EXCLUDED.stock_actual
RETURNING id_ingrediente, nombre, stock_actual, stock_minimo, (xmax = 0) AS es_nuevo;
```

| Ingrediente | Antes | Después | Qué pasó |
| :-- | --: | --: | :-- |
| Hielo | 12,625.900 g | 32,625.900 g | Ya existía: se sumó |
| Aguacate | 168.500 g | 5,168.500 g | Ya existía, aunque llegó escrito `AGUACATE`: se sumó |
| Cardamomo | No existía | 500.000 g | Se dio de alta con su mínimo de 100 g |

El conflicto se revisa contra `lower(nombre)` porque el índice `ux_ingrediente_nombre_minusculas` ya prohíbe dos nombres que solo cambien en mayúsculas. `EXCLUDED` es el renglón que se intentó insertar. `xmax = 0` solo sirve para mostrar en la salida cuáles renglones son nuevos.

## 2. Actualizaciones

### Un `UPDATE` que depende de otra tabla

**Situación:** el evento 232 es una boda programada. Para que el inventario avise a tiempo, el stock mínimo de cada ingrediente debe alcanzar al menos para lo que se acordó con ese evento.

```sql
UPDATE ingrediente i
   SET stock_minimo = n.necesario
  FROM (SELECT r.id_ingrediente,
               SUM(a.cantidad_acordada * r.cantidad_por_porcion) AS necesario
          FROM acuerdo a
          JOIN receta r ON r.id_producto = a.id_producto
         WHERE a.numero_evento = 232
         GROUP BY r.id_ingrediente) n
 WHERE i.id_ingrediente = n.id_ingrediente
   AND i.stock_minimo < n.necesario
RETURNING i.nombre, i.stock_actual, i.stock_minimo, i.unidad_medida;
```

**Resultado:** de los 10 ingredientes que usa el evento, 4 tenían un mínimo menor y se subieron. Los ingredientes por debajo de su mínimo pasan de 65 a 67, así que hay dos nuevos por resurtir. La condición `stock_minimo < n.necesario` evita bajarle el mínimo a un ingrediente que ya lo tenía más alto.

### Un `UPDATE` que clasifica con `CASE`

**Situación:** la columna `bar_cocina.estado` debe decir si cada estación está trabajando, y eso depende de si tiene comandas en preparación.

```sql
UPDATE bar_cocina b
   SET estado = CASE
           WHEN EXISTS (SELECT 1 FROM comanda c
                         WHERE c.id_bar_cocina = b.id_usuario
                           AND c.estado = 'en_preparacion') THEN 'ocupado'
           ELSE 'desocupado'
       END;
```

**Resultado:** pasa de 18 ocupadas y 27 desocupadas a 26 ocupadas y 19 desocupadas. En los datos sintéticos este estado se generó sin revisar las comandas, y esta sentencia lo deja de acuerdo con ellas.

## 3. Borrados

### Un `DELETE` con subconsulta

**Situación:** se preparó el borrador `Paquete Navidad 2026` con dos productos, nadie lo contrató y se retira del catálogo. La regla es borrar los paquetes que ningún evento haya acordado.

```sql
DELETE FROM paquete p
WHERE NOT EXISTS (SELECT 1 FROM acuerdo a WHERE a.numero_paquete = p.numero_paquete)
RETURNING p.numero_paquete, p.detalles;
```

| Tabla | Antes | Después | Por qué |
| :-- | --: | --: | :-- |
| `paquete` | 13 | 12 | Se borró el borrador, el único sin acuerdos |
| `paquete_producto` | 102 | 100 | `fk_paquete_producto_paquete` es `CASCADE`: su contenido no tiene sentido sin el paquete |
| `acuerdo` | 634 | 634 | No había ninguno que apuntara al borrador |

Con un paquete que sí se contrató, el gestor no lo permite, porque `fk_acuerdo_paquete` es `RESTRICT`:

```text
DELETE FROM paquete WHERE numero_paquete = 12;
ERROR:  update or delete on table "paquete" violates foreign key constraint "fk_acuerdo_paquete" on table "acuerdo"
DETAIL:  Key (numero_paquete)=(12) is still referenced from table "acuerdo".
```

### Un borrado lógico

**Situación:** un cliente de la cuenta 231-1 ya no quiere sus burritos y el cajero cancela la comanda. La comanda no desaparece: cambia a `cancelada` y queda registrado quién la canceló.

```sql
UPDATE comanda SET estado = 'cancelada', id_cajero_cancela = 176 WHERE id_comanda = 37358;
```

No hizo falta agregar una columna como `activo`, porque el modelo ya tiene este borrado lógico: `v_cuenta` no suma las comandas canceladas y `ck_comanda_cancelacion` exige que toda cancelación tenga cajero.

| Forma de quitarla | Total de la cuenta | ¿Sigue la comanda? | ¿Se sabe quién y qué? |
| :-- | --: | :--: | :--: |
| Antes de quitarla | 490.00 | Sí | No aplica |
| Borrado lógico | 370.00 | Sí | Sí: cajero 176, 120.00 |
| `DELETE` | 370.00 | No | No |

El total queda igual en las dos formas; la diferencia es lo que se puede responder después. El `DELETE` se probó con `comandas_admin` y se revirtió, porque `comandas_app` no tiene ese permiso:

```text
DELETE FROM comanda WHERE id_comanda = 37359;
ERROR:  permission denied for table comanda
```

### Cuándo conviene cada uno y qué se pierde al borrar de verdad

| | Borrado real (`DELETE`) | Borrado lógico (cambio de estado) |
| :-- | :-- | :-- |
| **Conviene cuando** | El dato no tiene historia ni le importa a nadie más: un borrador que nadie contrató, una captura equivocada | El dato ya participó en la operación: dinero, responsables, consumo |
| **Lo que pasa después** | El renglón se va, y con `CASCADE` también sus hijos | El renglón sigue y las consultas deben filtrar su estado |
| **Costo** | No se puede saber qué hubo | La tabla crece y cada consulta debe recordar el filtro |

Al borrar una comanda de verdad se pierde lo siguiente:

- **El rastro de la cancelación:** qué se pidió, a qué precio, qué mesero la levantó y qué cajero la canceló. Ese control es la razón por la que en la entrevista los pedidos pasan por caja.
- **La explicación del inventario:** una comanda cancelada después de prepararse ya gastó sus ingredientes y no los devuelve. Sin ella, ese descuento de stock queda sin causa.
- **La protección de las claves foráneas:** las acciones del ejercicio 2.2 solo protegen mientras exista el hijo. `fk_comanda_cuenta`, `fk_comanda_producto` y `fk_comanda_mesero` son `RESTRICT`, así que una comanda impide borrar su cuenta, su producto y su mesero. Con el borrado lógico el renglón sigue y los protege:

```text
DELETE FROM cuenta WHERE numero_evento = 231 AND secuencial = 1;
ERROR:  update or delete on table "cuenta" violates foreign key constraint "fk_comanda_cuenta" on table "comanda"
DETAIL:  Key (numero_evento, secuencial)=(231, 1) is still referenced from table "comanda".
```

El mismo razonamiento explica el paquete: se puede borrar porque ningún `acuerdo` lo usa, y su contenido se va con él porque `CASCADE` indica que ese contenido solo existe como parte del paquete.

## 4. Transacción con punto de recuperación

**Situación:** en la cuenta 231-20 (mesa 11, mesero 65) quedan dos comandas por entregar y un saldo de 110.00. El cajero entrega, cobra 130.00 en efectivo con 20.00 de propina y cierra la cuenta. Toca tres tablas: `comanda`, `pago` y `cuenta`. Debe quedar entera o no quedar: una cuenta no puede cerrarse sin su pago.

Al capturar el pago, el cajero le asigna la propina al mesero 24, que no atiende esa mesa. Solo se deshace el pago; la entrega de las comandas ya estaba bien.

```sql
BEGIN;

UPDATE comanda SET estado = 'entregada'
WHERE numero_evento = 231 AND secuencial = 20 AND estado IN ('en_preparacion', 'lista');

SAVEPOINT antes_del_pago;

-- Propina al mesero equivocado.
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (130, 'efectivo', 231, 20, 176, 24, 20);

ROLLBACK TO SAVEPOINT antes_del_pago;

INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (130, 'efectivo', 231, 20, 176, 65, 20);

UPDATE cuenta SET estado = 'cerrada' WHERE numero_evento = 231 AND secuencial = 20;

COMMIT;
```

| Momento | Comandas entregadas | Pagos | Estado de la cuenta |
| :-- | --: | --: | :-- |
| Antes de `BEGIN` | 0 de 2 | 0 | abierta |
| Con el pago equivocado | 2 de 2 | 1 | abierta |
| Después de `ROLLBACK TO` | 2 de 2 | 0 | abierta |
| Después de `COMMIT` | 2 de 2 | 1 (propina del mesero 65) | cerrada |

El saldo pasa de 110.00 a 0.00, porque el pago cubre 130.00 menos 20.00 de propina, que no cuenta como consumo. El orden importa: `tg_cuenta_cierre` no deja cerrar una cuenta con comandas sin terminar o con saldo.

## 5. Transacción que falla a la mitad

**Situación:** la cuenta 231-2 pide un café y cinco aguas minerales de 2 L, todo directo a preparación. Cada producto es una comanda y al entrar a preparación descuenta su receta. Quedan 4.575 aguas: después de la cuarta quedan 0.575 y la quinta ya no alcanza.

La regla es que el stock nunca quede negativo. La vigila el disparador `tg_comanda_stock`, que rechaza con el código de violación de `CHECK` (`check_violation`), y el `CHECK` `ck_ingrediente_stock` la respalda.

```sql
BEGIN;

INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
VALUES ('en_preparacion', 231, 2, 95, 84, 156);

INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
SELECT 'en_preparacion', 231, 2, 95, 75, 156
FROM generate_series(1, 5);

ROLLBACK;
```

El mensaje del gestor:

```text
ERROR:  no hay stock suficiente de "Agua mineral de 2 L" para preparar la comanda (quedan 0.575 pieza, la receta pide 1.000)
HINT:  Resurta el ingrediente o cancele la comanda.
CONTEXT:  PL/pgSQL function descontar_stock() line 22 at RAISE
```

Después del error, el gestor no acepta nada más hasta que termine la transacción:

```text
SELECT count(*) FROM comanda;
ERROR:  current transaction is aborted, commands ignored until end of transaction block
```

La comprobación de que la base quedó como estaba:

| Momento | Comandas | Café molido (g) | Agua mineral de 2 L (piezas) |
| :-- | --: | --: | --: |
| Antes de `BEGIN` | 37,528 | 72.500 | 4.575 |
| Después del café | 37,529 | 62.500 | 4.575 |
| Después de `ROLLBACK` | 37,528 | 72.500 | 4.575 |

También se revirtieron el café, que ya se había descontado, y las aguas que sí alcanzaban: en el pedido no se entrega una parte. El script lo comprueba con `ASSERT` y termina con error si algo no coincide. Lo único que no regresa es el contador de `id_comanda`: las secuencias no se revierten, así que los números que se gastaron quedan como un hueco.
