# Esquema Relacional, DDL Ejecutado y Diccionario

En este documento se presenta el resultado de la transformación del modelo EER del sistema de comandas: el esquema relacional completo, el script `esquema.sql` ejecutado sobre la base creada en la Parte 1, los `INSERT` que el gestor rechaza, el diagrama relacional y la verificación de que el significado del modelo se preservó.

---

**Cliente:** Salón de eventos — sistema de comandas

**Base de datos:** `comandas` en el contenedor `practica1-postgres` (PostgreSQL 16.4), ver [Entorno de la Práctica 3](<EntornoPractica3.md>)

**Contenido:** 6.1 Esquema completo · 6.2 Script de definición de datos y evidencia · 6.3 Diagrama relacional · 6.4 [Diccionario de datos](<DiccionarioDeDatos.md>) · 6.5 Preservación del significado

**Archivos:**

| Archivo | Contenido |
| :-- | :-- |
| [`sql/esquema.sql`](<../sql/esquema.sql>) | `CREATE TABLE` de las 17 tablas, disparadores, índices, vistas y comentarios |
| [`sql/datos-ejemplo.sql`](<../sql/datos-ejemplo.sql>) | Datos válidos mínimos (un evento con mesas, cuentas, comandas y un pago, y el inventario con las recetas) |
| [`sql/inserts-rechazados.sql`](<../sql/inserts-rechazados.sql>) | 20 instrucciones que violan una restricción cada una |
| [`modelo/diagrama-relacional.svg`](<../modelo/diagrama-relacional.svg>) | Diagrama relacional generado con *DBML ER Diagrams* |
| [`evidencias/practica3/parte6/`](<../evidencias/practica3/parte6>) | Capturas de cada ejecución |

---

## 6.1 Esquema completo

Notación: clave primaria <ins>subrayada</ins>, clave foránea en *cursiva* y ⚙ para las columnas generadas por el gestor. La regla que origina cada tabla está en [Reglas de Transformación](<ReglasDeTransformacion.md#tablas-resultantes>).

### Tablas, columnas y tipos

| Tabla | Columnas |
| :-- | :-- |
| **evento** | <ins>numero_evento</ins> `INTEGER`, fecha `DATE`, fecha_dia ⚙ `SMALLINT`, fecha_mes ⚙ `SMALLINT`, fecha_anio ⚙ `SMALLINT`, tipo_evento `VARCHAR(40)`, numero_asistentes `INTEGER`, estado `VARCHAR(12)` |
| **evento_organizador** | *<ins>numero_evento</ins>* `INTEGER`, <ins>organizador</ins> `VARCHAR(120)` |
| **usuario** | <ins>id_usuario</ins> `INTEGER`, nombre `VARCHAR(120)`, usuario `VARCHAR(40)`, fecha_nacimiento `DATE`, fecha_nacimiento_dia ⚙ `SMALLINT`, fecha_nacimiento_mes ⚙ `SMALLINT`, fecha_nacimiento_anio ⚙ `SMALLINT`, contrasena_hash `VARCHAR(255)`, rol `VARCHAR(12)` |
| **mesero** | *<ins>id_usuario</ins>* `INTEGER`, *rol* `VARCHAR(12)`, turno_asignado `VARCHAR(12)` |
| **bar_cocina** | *<ins>id_usuario</ins>* `INTEGER`, *rol* `VARCHAR(12)`, estado `VARCHAR(10)`, estacion_asignada `VARCHAR(6)` |
| **cajero_admin** | *<ins>id_usuario</ins>* `INTEGER`, *rol* `VARCHAR(12)`, nivel_acceso `VARCHAR(13)`, caja_asignada `SMALLINT` |
| **mesa** | *<ins>numero_evento</ins>* `INTEGER`, <ins>numero_mesa</ins> `SMALLINT`, *id_mesero* `INTEGER` |
| **cuenta** | *<ins>numero_evento</ins>* `INTEGER`, <ins>secuencial</ins> `SMALLINT`, *numero_mesa* `SMALLINT`, nombre `VARCHAR(60)`, folio ⚙ `VARCHAR(30)`, estado `VARCHAR(8)` |
| **producto** | <ins>id_producto</ins> `INTEGER`, nombre `VARCHAR(80)`, descripcion `VARCHAR(255)`, categoria `VARCHAR(10)`, precio `NUMERIC(10,2)`, *id_producto_principal* `INTEGER` |
| **ingrediente** | <ins>id_ingrediente</ins> `INTEGER`, nombre `VARCHAR(60)`, unidad_medida `VARCHAR(5)`, stock_actual `NUMERIC(10,3)`, stock_minimo `NUMERIC(10,3)` |
| **receta** | *<ins>id_producto</ins>* `INTEGER`, *<ins>id_ingrediente</ins>* `INTEGER`, cantidad_por_porcion `NUMERIC(10,3)` |
| **paquete** | <ins>numero_paquete</ins> `INTEGER`, monto `NUMERIC(10,2)`, detalles `VARCHAR(255)` |
| **paquete_producto** | *<ins>numero_paquete</ins>* `INTEGER`, *<ins>id_producto</ins>* `INTEGER` |
| **acuerdo** | *<ins>numero_evento</ins>* `INTEGER`, *<ins>numero_paquete</ins>* `INTEGER`, *<ins>id_producto</ins>* `INTEGER`, cantidad_acordada `INTEGER` |
| **comanda** | <ins>id_comanda</ins> `INTEGER`, fecha_hora `TIMESTAMPTZ`, fecha_hora_dia ⚙ `SMALLINT`, fecha_hora_mes ⚙ `SMALLINT`, fecha_hora_anio ⚙ `SMALLINT`, fecha_hora_hora ⚙ `TIME`, precio_cobrado `NUMERIC(10,2)`, estado `VARCHAR(14)`, detalles `VARCHAR(255)`, *numero_evento* `INTEGER`, *secuencial* `SMALLINT`, *id_mesero* `INTEGER`, *id_producto* `INTEGER`, *id_bar_cocina* `INTEGER`, *id_cajero_cancela* `INTEGER` |
| **pago** | <ins>numero_pago</ins> `INTEGER`, monto `NUMERIC(10,2)`, forma_pago `VARCHAR(13)`, fecha_hora `TIMESTAMPTZ`, fecha_hora_dia ⚙ `SMALLINT`, fecha_hora_mes ⚙ `SMALLINT`, fecha_hora_anio ⚙ `SMALLINT`, fecha_hora_hora ⚙ `TIME`, *numero_evento* `INTEGER`, *secuencial* `SMALLINT`, *id_cajero* `INTEGER`, *id_mesero_propina* `INTEGER`, monto_propina `NUMERIC(10,2)` |
| **anticipo** | <ins>id_anticipo</ins> `INTEGER`, monto `NUMERIC(10,2)`, fecha `DATE`, fecha_dia ⚙ `SMALLINT`, fecha_mes ⚙ `SMALLINT`, fecha_anio ⚙ `SMALLINT`, *numero_evento* `INTEGER` |

### Claves foráneas y acciones referenciales

Las 25 claves foráneas del esquema, tal como quedaron registradas en el catálogo del gestor:

| # | Restricción | Tabla | Columnas | Referencia | ON DELETE | ON UPDATE |
| :--: | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | `fk_evento_organizador_evento` | evento_organizador | numero_evento | evento (numero_evento) | CASCADE | CASCADE |
| 2 | `fk_mesero_usuario` | mesero | id_usuario, rol | usuario (id_usuario, rol) | CASCADE | RESTRICT |
| 3 | `fk_bar_cocina_usuario` | bar_cocina | id_usuario, rol | usuario (id_usuario, rol) | CASCADE | RESTRICT |
| 4 | `fk_cajero_admin_usuario` | cajero_admin | id_usuario, rol | usuario (id_usuario, rol) | CASCADE | RESTRICT |
| 5 | `fk_mesa_evento` | mesa | numero_evento | evento (numero_evento) | CASCADE | CASCADE |
| 6 | `fk_mesa_mesero` | mesa | id_mesero | mesero (id_usuario) | RESTRICT | RESTRICT |
| 7 | `fk_cuenta_evento` | cuenta | numero_evento | evento (numero_evento) | CASCADE | CASCADE |
| 8 | `fk_cuenta_mesa` | cuenta | numero_evento, numero_mesa | mesa (numero_evento, numero_mesa) | RESTRICT | RESTRICT |
| 9 | `fk_producto_principal` | producto | id_producto_principal | producto (id_producto) | RESTRICT | RESTRICT |
| 10 | `fk_receta_producto` | receta | id_producto | producto (id_producto) | CASCADE | CASCADE |
| 11 | `fk_receta_ingrediente` | receta | id_ingrediente | ingrediente (id_ingrediente) | RESTRICT | CASCADE |
| 12 | `fk_paquete_producto_paquete` | paquete_producto | numero_paquete | paquete (numero_paquete) | CASCADE | CASCADE |
| 13 | `fk_paquete_producto_producto` | paquete_producto | id_producto | producto (id_producto) | RESTRICT | CASCADE |
| 14 | `fk_acuerdo_evento` | acuerdo | numero_evento | evento (numero_evento) | CASCADE | CASCADE |
| 15 | `fk_acuerdo_paquete` | acuerdo | numero_paquete | paquete (numero_paquete) | RESTRICT | CASCADE |
| 16 | `fk_acuerdo_producto` | acuerdo | id_producto | producto (id_producto) | RESTRICT | CASCADE |
| 17 | `fk_comanda_cuenta` | comanda | numero_evento, secuencial | cuenta (numero_evento, secuencial) | RESTRICT | CASCADE |
| 18 | `fk_comanda_mesero` | comanda | id_mesero | mesero (id_usuario) | RESTRICT | RESTRICT |
| 19 | `fk_comanda_producto` | comanda | id_producto | producto (id_producto) | RESTRICT | CASCADE |
| 20 | `fk_comanda_bar_cocina` | comanda | id_bar_cocina | bar_cocina (id_usuario) | RESTRICT | RESTRICT |
| 21 | `fk_comanda_cajero_cancela` | comanda | id_cajero_cancela | cajero_admin (id_usuario) | RESTRICT | RESTRICT |
| 22 | `fk_pago_cuenta` | pago | numero_evento, secuencial | cuenta (numero_evento, secuencial) | RESTRICT | CASCADE |
| 23 | `fk_pago_cajero` | pago | id_cajero | cajero_admin (id_usuario) | RESTRICT | RESTRICT |
| 24 | `fk_pago_mesero_propina` | pago | id_mesero_propina | mesero (id_usuario) | RESTRICT | RESTRICT |
| 25 | `fk_anticipo_evento` | anticipo | numero_evento | evento (numero_evento) | RESTRICT | CASCADE |

El criterio de cada acción está en [Reglas de Transformación — Acciones referenciales](<ReglasDeTransformacion.md#acciones-referenciales>).

### Restricciones por tabla

| Tabla | PK | FK | UNIQUE | CHECK | Otras |
| :-- | :--: | :--: | :--: | :--: | :-- |
| evento | 1 | 0 | 0 | 2 | 3 columnas generadas |
| evento_organizador | 1 | 1 | 0 | 0 | |
| usuario | 1 | 0 | 2 | 2 | 3 columnas generadas; disparador diferido de completitud |
| mesero | 1 | 1 | 0 | 2 | Disparador diferido de completitud |
| bar_cocina | 1 | 1 | 0 | 3 | Disparador diferido de completitud |
| cajero_admin | 1 | 1 | 0 | 3 | Disparador diferido de completitud |
| mesa | 1 | 2 | 0 | 1 | |
| cuenta | 1 | 2 | 0 | 3 | Folio generado |
| producto | 1 | 1 | 1 | 3 | Disparador de variante de un nivel |
| ingrediente | 1 | 0 | 1 | 3 | |
| receta | 1 | 2 | 0 | 1 | |
| paquete | 1 | 0 | 0 | 1 | |
| paquete_producto | 1 | 2 | 0 | 0 | |
| acuerdo | 1 | 3 | 0 | 1 | |
| comanda | 1 | 5 | 0 | 4 | 4 columnas generadas; disparadores de precio cobrado y de stock |
| pago | 1 | 3 | 0 | 4 | 4 columnas generadas |
| anticipo | 1 | 1 | 0 | 1 | 3 columnas generadas |
| **Total** | **17** | **25** | **4** | **34** | |

Además de las restricciones, el esquema incluye:

| Objeto | Cantidad | Para qué |
| :-- | :--: | :-- |
| Disparadores de restricción diferidos | 4 | Completitud total de la jerarquía de Usuario |
| Disparadores normales | 3 | Variante de un solo nivel; precio cobrado fijo; descuento del stock al preparar una comanda |
| Índices sobre claves foráneas | 16 | PostgreSQL no indexa las claves foráneas por su cuenta |
| Vistas | 6 | Atributos derivados (`v_evento`, `v_cuenta`, `v_usuario`, `v_mesero`, `v_producto`, `v_comanda`) |
| Índice único parcial | 1 | Nombre de cuenta sin repetir entre las cuentas abiertas de una mesa |

---

## 6.2 Script de definición de datos

El archivo [`sql/esquema.sql`](<../sql/esquema.sql>) sigue la estructura que pide la práctica: cada tabla se declara con sus columnas y tipos, y las claves y restricciones van con nombre propio (`CONSTRAINT pk_…`, `fk_…`, `uq_…`, `ck_…`) para que los mensajes de error digan exactamente qué regla se violó. Por ejemplo, la entidad débil Mesa:

```sql
CREATE TABLE mesa (
    numero_evento  INTEGER   NOT NULL,
    numero_mesa    SMALLINT  NOT NULL,
    id_mesero      INTEGER   NOT NULL,
    CONSTRAINT pk_mesa PRIMARY KEY (numero_evento, numero_mesa),
    CONSTRAINT ck_mesa_numero CHECK (numero_mesa > 0),
    CONSTRAINT fk_mesa_evento FOREIGN KEY (numero_evento)
        REFERENCES evento (numero_evento)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_mesa_mesero FOREIGN KEY (id_mesero)
        REFERENCES mesero (id_usuario)
        ON DELETE RESTRICT
        ON UPDATE RESTRICT
);
```

El script está organizado en ocho secciones: evento, jerarquía de usuario, entidades débiles, catálogo, operación, índices, vistas de atributos derivados y comentarios del diccionario. Todo va dentro de una transacción (`BEGIN` … `COMMIT`): si cualquier instrucción falla, no se crea nada y la base queda vacía.

### Ejecución

Se ejecutó sobre la base `comandas`, vacía, creada en la Parte 1. `ON_ERROR_STOP=1` hace que `psql` se detenga en el primer error y termine con un código distinto de cero, así que un código de salida 0 significa que no hubo ningún error:

```bash
docker cp sql/esquema.sql practica1-postgres:/tmp/esquema.sql
docker exec practica1-postgres psql -v ON_ERROR_STOP=1 -U pg-practica1 -d comandas -f /tmp/esquema.sql
```

```
BEGIN
CREATE TABLE
CREATE TABLE
...
COMMENT
COMMENT
COMMIT
Código de salida: 0
```

| Instrucción | Veces |
| :-- | :--: |
| `CREATE TABLE` | 17 |
| `CREATE FUNCTION` | 4 |
| `CREATE TRIGGER` | 7 |
| `CREATE INDEX` | 17 |
| `CREATE VIEW` | 6 |
| `COMMENT` | 114 |
| `ERROR` | 0 |

![Final de la ejecución de esquema.sql: los COMMENT, el COMMIT y el código de salida 0](<../evidencias/practica3/parte6/01 - Ejecución del esquema.sql.png>)

### Listado de tablas creadas

```bash
docker exec practica1-postgres psql -U pg-practica1 -d comandas -c '\dt' -c '\dv'
```

```
                 List of relations
 Schema |        Name        | Type  |    Owner
--------+--------------------+-------+--------------
 public | acuerdo            | table | pg-practica1
 public | anticipo           | table | pg-practica1
 public | bar_cocina         | table | pg-practica1
 public | cajero_admin       | table | pg-practica1
 public | comanda            | table | pg-practica1
 public | cuenta             | table | pg-practica1
 public | evento             | table | pg-practica1
 public | evento_organizador | table | pg-practica1
 public | ingrediente        | table | pg-practica1
 public | mesa               | table | pg-practica1
 public | mesero             | table | pg-practica1
 public | pago               | table | pg-practica1
 public | paquete            | table | pg-practica1
 public | paquete_producto   | table | pg-practica1
 public | producto           | table | pg-practica1
 public | receta             | table | pg-practica1
 public | usuario            | table | pg-practica1
(17 rows)

             List of relations
 Schema |    Name    | Type |    Owner
--------+------------+------+--------------
 public | v_comanda  | view | pg-practica1
 public | v_cuenta   | view | pg-practica1
 public | v_evento   | view | pg-practica1
 public | v_mesero   | view | pg-practica1
 public | v_producto | view | pg-practica1
 public | v_usuario  | view | pg-practica1
(6 rows)
```

![Listado de las 17 tablas y las 6 vistas creadas en la base comandas](<../evidencias/practica3/parte6/02 - Listado de tablas creadas.png>)

### Datos de ejemplo

Para que los rechazos se puedan probar hacen falta filas válidas contra las cuales chocar. [`sql/datos-ejemplo.sql`](<../sql/datos-ejemplo.sql>) carga el evento 17 (una boda de 180 invitados) con dos organizadores, tres mesas, tres cuentas, dos paquetes acordados, cuatro comandas en estados distintos, un pago con propina y el inventario: ocho ingredientes con su stock y la receta de cada uno de los cuatro productos. Se ejecutó también con `ON_ERROR_STOP=1` y terminó con código 0.

![Carga de datos-ejemplo.sql: los INSERT dentro de la transacción, el COMMIT y el código de salida 0](<../evidencias/practica3/parte6/03 - Carga de datos de ejemplo.png>)

Con esos datos, las vistas calculan los atributos derivados y las columnas generadas se llenan solas:

| Consulta | Resultado |
| :-- | :-- |
| `SELECT folio, nombre, total_acumulado FROM v_cuenta` | `17-1-1` Novios → 215.00 · `17-1-2` Padrinos → 95.00 · `17-3-3` Familia Torres → 0.00 (su única comanda está cancelada) |
| `SELECT numero_mesas FROM v_evento` | 3 |
| `SELECT propinas_acumuladas FROM v_mesero` | Laura Méndez 35.00 · Óscar Pérez 0.00 |
| `SELECT nombre, disponible FROM v_producto` | Refresco, Pasta Alfredo y Pastel de chocolate → `true` · Refresco de dieta → `false` (su refresco light está en 0) |
| `SELECT nombre, stock_actual FROM ingrediente` | Refresco de cola 48 → 47 · Hielo 20000 → 19850 · Pasta 5000 → 4880 · Crema 3000 → 2900 · Queso parmesano 800 → 770: solo descontaron las dos comandas que entraron preparadas (refresco y pasta); la pendiente y la cancelada no tocaron el inventario |
| `SELECT nombre FROM ingrediente WHERE stock_actual < stock_minimo` | Refresco de cola light 355 ml · Queso parmesano: los dos que hay que resurtir |
| `SELECT fecha_hora_dia, fecha_hora_hora FROM comanda` | 17 · 21:05:00 (la comanda se insertó como `2026-10-17 21:05:00-06`) |

### Instrucciones rechazadas por el gestor

[`sql/inserts-rechazados.sql`](<../sql/inserts-rechazados.sql>) contiene 20 instrucciones; cada una viola una restricción distinta. Se ejecuta **sin** `ON_ERROR_STOP` para que cada error se muestre y se siga con la siguiente:

```bash
docker exec practica1-postgres psql -U pg-practica1 -d comandas -f /tmp/inserts-rechazados.sql
```

![Ejecución de inserts-rechazados.sql con los 20 mensajes de error del gestor](<../evidencias/practica3/parte6/04 - INSERT rechazados.png>)

Las 20 fueron rechazadas. Los cuatro casos centrales del modelo:

**1. Mesa de un evento que no existe**: la entidad débil no puede existir sin su propietaria (Regla 8).

```sql
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero) VALUES (99, 1, 1);
```
```
ERROR:  insert or update on table "mesa" violates foreign key constraint "fk_mesa_evento"
DETAIL:  Key (numero_evento)=(99) is not present in table "evento".
```

**5. Propina para un usuario que es cajero**: la relación *Recibe propina* solo admite meseros (Regla 9, estrategia A).

```sql
INSERT INTO pago (monto, forma_pago, numero_evento, secuencial, id_cajero, id_mesero_propina, monto_propina)
VALUES (300.00, 'efectivo', 17, 2, 5, 5, 40.00);
```
```
ERROR:  insert or update on table "pago" violates foreign key constraint "fk_pago_mesero_propina"
DETAIL:  Key (id_mesero_propina)=(5) is not present in table "mesero".
```

**7. Usuario sin fila en su subtipo**: la especialización es total; el error aparece al hacer `COMMIT`.

```sql
BEGIN;
INSERT INTO usuario (id_usuario, nombre, usuario, fecha_nacimiento, contrasena_hash, rol)
VALUES (6, 'Pedro Sin Rol', 'psinrol', DATE '2000-02-02', '$2b$12$hashDeEjemplo', 'mesero');
COMMIT;
```
```
ERROR:  el usuario 6 tiene rol "mesero" pero no tiene fila en ese subtipo
HINT:  La especialización de Usuario es total: inserte también la fila del subtipo en la misma transacción.
```

**16. Preparar un producto sin stock**: la receta se descuenta del inventario y el gestor no deja preparar lo que no alcanza.

```sql
INSERT INTO comanda (estado, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina)
VALUES ('en_preparacion', 17, 2, 1, 2, 4);
```
```
ERROR:  no hay stock suficiente de "Refresco de cola light 355 ml" para preparar la comanda (quedan 0.000 pieza, la receta pide 1.000)
HINT:  Resurta el ingrediente o cancele la comanda.
```

Las 20 instrucciones y la restricción que las detuvo:

| # | Instrucción | Restricción que la rechaza | Regla que protege |
| :--: | :-- | :-- | :-- |
| 1 | Mesa en el evento 99, que no existe | `fk_mesa_evento` | Regla 8: Mesa no existe sin Evento |
| 2 | Segunda mesa 1 en el evento 17 | `pk_mesa` | Regla 8: clave parcial + clave del propietario |
| 3 | Mesa sin mesero | `NOT NULL` en `id_mesero` | Regla 4: *Atiende* es (1,1) del lado de la mesa |
| 4 | Cuenta del evento 17 en la mesa 8, que no está en ese evento | `fk_cuenta_mesa` | Regla 4 con clave foránea compuesta |
| 5 | Propina para el cajero 5 | `fk_pago_mesero_propina` | Regla 9: la relación apunta al subtipo |
| 6 | Registrar como mesero al usuario 5, que es cajero | `fk_mesero_usuario` | Regla 9: disyunción |
| 7 | Usuario con rol mesero sin fila en mesero | `ct_usuario_total` (al `COMMIT`) | Regla 9: completitud total |
| 8 | Segundo usuario con nombre de acceso `lmendez` | `uq_usuario_usuario` | Regla 1: clave alternativa |
| 9 | Pago de 0.00 | `ck_pago_monto` | Regla 1: `CHECK` de dominio |
| 10 | Propina con mesero pero sin monto | `ck_pago_propina_completa` | Regla 4: el atributo viaja con la relación |
| 11 | Comanda cancelada sin cajero que la cancele | `ck_comanda_cancelacion` | Regla 4: *Cancela* ligada al estado |
| 12 | Variante del producto 2, que ya es variante | `tg_producto_variante` | Regla de negocio de *Variante* |
| 13 | Acordar dos veces el mismo producto del mismo paquete para el evento 17 | `pk_acuerdo` | Regla 7: clave de la ternaria |
| 14 | Cambiar el precio cobrado de una comanda ya levantada | `tg_comanda_precio` | Regla de negocio del precio cobrado |
| 15 | Borrar el evento 17, que ya tiene anticipo, comandas y pagos | `fk_anticipo_evento` (`RESTRICT`) | Acciones referenciales: el historial no se borra en cascada |
| 16 | Preparar un refresco de dieta sin refresco light en inventario | `tg_comanda_stock` | Regla de negocio del inventario: no se prepara lo que no alcanza |
| 17 | Dejar en −5 el stock del queso parmesano | `ck_ingrediente_stock` | Regla 1: `CHECK` de dominio |
| 18 | Borrar la pasta, que usa la receta de Pasta Alfredo | `fk_receta_ingrediente` (`RESTRICT`) | Regla 5: la receta no se queda incompleta |
| 19 | Cuenta con el nombre en blanco | `ck_cuenta_nombre` | El alias de la cuenta no queda vacío |
| 20 | Cuenta con el mismo nombre que otra abierta en la misma mesa (`novios` contra `Novios`) | `ux_cuenta_nombre_abierta` (índice único parcial) | No hay dos cuentas abiertas con el mismo nombre en una mesa, sin distinguir mayúsculas |

Después de las 20 instrucciones, el conteo de filas es el mismo que dejó `datos-ejemplo.sql`: ninguna fila inválida quedó guardada.

```
 usuarios | meseros | mesas | cuentas | comandas | pagos | productos | acuerdos | eventos | ingredientes | recetas | stock_parmesano 
----------+---------+-------+---------+----------+-------+-----------+----------+---------+--------------+---------+-----------------
        5 |       2 |     3 |       3 |        4 |     1 |         4 |        4 |       1 |            8 |       9 |         770.000
```

![Conteo de usuarios, mesas, cuentas, comandas y pagos después de los rechazos, igual al que dejaron los datos de ejemplo](<../evidencias/practica3/parte6/05 - Conteo tras los rechazos.png>)

---

## 6.3 Diagrama relacional

![Diagrama relacional del sistema de comandas](<../modelo/diagrama-relacional.svg>)

El diagrama se diseñó a partir del [Diagrama Entidad-Relación Extendido](<../modelo/diagrama-eer-chen.svg>) y del [Inventario del Modelo Entidad-Relación Extendido](<InventarioModeloEER.md>): con el análisis de ambos se determinó la estructura de cada tabla, se escribió en DBML y se dibujó con el plugin *DBML ER Diagrams*.

- Cada línea une una clave foránea con la clave primaria que referencia y toma el color de la tabla a la que apunta. La pata de gallo queda del lado de la FK, que es el lado muchos, y la barra del lado de la clave primaria, el lado uno. Un círculo en el extremo indica que la FK admite nulos (mínimo 0).
- 🔑 marca la clave primaria de una sola columna, 🔗 las claves foráneas y `NN` las columnas `NOT NULL`. Las claves primarias compuestas (`mesa`, `cuenta`, `receta`, `acuerdo`, `paquete_producto` y `evento_organizador`) no llevan 🔑 porque el plugin solo marca las de una columna; están en 6.1.
- Las FK compuestas se dibujan desde la columna que las distingue: `numero_mesa` en `cuenta`, `secuencial` en `comanda` y `pago`, e `id_usuario` en los subtipos, aunque su FK sea `(id_usuario, rol)`. Las de los subtipos son uno a uno y no llevan pata de gallo.
- Los tipos son los del esquema, salvo dos que no caben en el ancho fijo de las tablas: `producto.id_producto_principal` aparece como `int` (es `INTEGER`) y `receta.cantidad_por_porcion` como `numeric` (es `NUMERIC(10,3)`).
- Las columnas generadas (los componentes de fecha y hora y `cuenta.folio`) aparecen como columnas normales; en 6.1 van marcadas con ⚙.
- Las tablas se agrupan por área: arriba el catálogo y el inventario (ingrediente, receta, producto y paquete); a la izquierda el evento con sus organizadores, anticipos y cuentas; al centro mesa, acuerdo, comanda y pago; a la derecha la jerarquía de Usuario.

---

## 6.4 Diccionario de datos

Está en un documento aparte por su tamaño: [Diccionario de Datos](<DiccionarioDeDatos.md>). Documenta las 97 columnas de las 17 tablas con tabla, columna, tipo, restricciones y descripción, más las columnas calculadas de las seis vistas. Se generó desde el catálogo, y las descripciones son los `COMMENT ON COLUMN` del propio `esquema.sql`, así que cualquiera puede consultarlas también desde el gestor:

```sql
SELECT column_name, col_description('comanda'::regclass, ordinal_position)
FROM information_schema.columns
WHERE table_name = 'comanda';
```

---

## 6.5 Preservación del significado

Se revisa el esquema contra el [Inventario del Modelo EER](<InventarioModeloEER.md>), elemento por elemento.

### Entidades

| Elemento del inventario | Tabla | Clave primaria | ¿Se conserva? |
| :-- | :-- | :-- | :--: |
| Evento | evento | numero_evento | ✓ |
| Usuario | usuario | id_usuario | ✓ |
| Producto | producto | id_producto | ✓ |
| Comanda | comanda | id_comanda | ✓ |
| Pago | pago | numero_pago | ✓ |
| Anticipo | anticipo | id_anticipo | ✓ |
| Paquete | paquete | numero_paquete | ✓ |
| Ingrediente | ingrediente | id_ingrediente | ✓ |
| Mesa (débil) | mesa | (numero_evento, numero_mesa) | ✓ |
| Cuenta (débil) | cuenta | (numero_evento, secuencial) | ✓ |
| Mesero (subtipo) | mesero | id_usuario | ✓ |
| Bar/Cocina (subtipo) | bar_cocina | id_usuario | ✓ |
| Cajero/Administrador (subtipo) | cajero_admin | id_usuario | ✓ |

Las 8 entidades fuertes, las 2 débiles y los 3 subtipos tienen su tabla.

### Relaciones y cardinalidades

En el modelo relacional la cardinalidad no se dibuja: se expresa con restricciones. El **máximo 1** de un lado queda en dónde vive la clave foránea (una columna guarda un solo valor), el **máximo N** en que esa columna no es `UNIQUE`, y el **mínimo** en `NOT NULL` (mínimo 1) o en que admita nulos (mínimo 0).

| # | Relación | Cardinalidad EER | Cómo quedó en el esquema | ¿Se conserva? |
| :--: | :-- | :-- | :-- | :--: |
| R1 | *Pertenece* | Mesa (1,1) · Evento (1,N) | `mesa.numero_evento` es parte de la PK: obligatoria y única por mesa. Evento puede tener varias | ✓ \* |
| R2 | *Abre* | Cuenta (1,1) · Evento (0,N) | `cuenta.numero_evento` es parte de la PK | ✓ |
| R3 | *Atiende* | Mesa (1,1) · Mesero (0,N) | `mesa.id_mesero NOT NULL` → mesero | ✓ |
| R4 | *Tiene* | Cuenta (1,1) · Mesa (0,N) | `cuenta.numero_mesa NOT NULL`, FK compuesta → mesa | ✓ |
| R5 | *Genera* | Comanda (1,1) · Cuenta (0,N) | `comanda.(numero_evento, secuencial) NOT NULL` → cuenta | ✓ |
| R6 | *Levanta* | Comanda (1,1) · Mesero (0,N) | `comanda.id_mesero NOT NULL` → mesero | ✓ |
| R7 | *Referencia* | Comanda (1,1) · Producto (0,N) | `comanda.id_producto NOT NULL` → producto | ✓ |
| R8 | *Prepara* | Comanda (0,1) · Bar/Cocina (0,N) | `comanda.id_bar_cocina` admite `NULL` → bar_cocina | ✓ |
| R9 | *Cancela* | Comanda (0,1) · Cajero (0,N) | `comanda.id_cajero_cancela` admite `NULL` → cajero_admin | ✓ |
| R10 | *Recibe* | Pago (1,1) · Cuenta (0,N) | `pago.(numero_evento, secuencial) NOT NULL` → cuenta | ✓ |
| R11 | *Maneja* | Pago (1,1) · Cajero (0,N) | `pago.id_cajero NOT NULL` → cajero_admin | ✓ |
| R12 | *Recibe propina* | Pago (0,1) · Mesero (0,N) | `pago.id_mesero_propina` admite `NULL` → mesero, con `monto_propina` | ✓ |
| R13 | *Recibe* | Anticipo (1,1) · Evento (0,N) | `anticipo.numero_evento NOT NULL` → evento | ✓ |
| R14 | *Variante* | Variante (0,1) · Principal (0,N) | `producto.id_producto_principal` admite `NULL` → producto | ✓ |
| R15 | *Incluye* | Paquete (1,N) · Producto (0,N) | Tabla `paquete_producto`, PK de las dos claves | ✓ \* |
| R16 | *Acuerda* | Evento, Paquete, Producto (0,N) | Tabla `acuerdo`, PK de las tres claves, con `cantidad_acordada` | ✓ |
| R17 | *Receta* | Producto (1,N) · Ingrediente (0,N) | Tabla `receta`, PK de las dos claves, con `cantidad_por_porcion` | ✓ \* |

Las 17 relaciones están en el esquema, y las 25 claves foráneas se explican completas: 2 de las relaciones identificadoras, 12 de las uno a muchos, 2 de *Incluye*, 2 de *Receta*, 3 de *Acuerda*, 1 del atributo multivaluado y 3 de los subtipos.

\* En tres relaciones, el **mínimo 1 del lado uno** no se hace cumplir en el gestor: que todo evento tenga al menos una mesa, que todo paquete incluya al menos un producto y que todo producto lleve al menos un ingrediente. Las tres se dejaron fuera a propósito y la razón está en [Lo que el esquema no puede garantizar](<ReglasDeTransformacion.md#lo-que-el-esquema-no-puede-garantizar>).

### Atributos

| Elemento del inventario | Cantidad | Cómo quedó | ¿Se conserva? |
| :-- | :--: | :-- | :--: |
| Atributos simples | — | Una columna cada uno, con su tipo y sus `CHECK` | ✓ |
| Claves alternativas (Usuario, nombre de Ingrediente) | 2 | `uq_usuario_usuario` y `uq_ingrediente_nombre` | ✓ |
| Atributos opcionales (Detalles de Comanda, Descripción de Producto) | 2 | Únicas columnas de entidad que admiten `NULL` | ✓ |
| Multivaluados | 1 | Tabla `evento_organizador` | ✓ |
| Compuestos | 5 | Columna padre con tipo nativo + una columna generada por componente (17 en total) | ✓ |
| Derivados | 7 | Seis vistas y la columna generada `cuenta.folio` | ✓ |
| Atributos de relación | 3 | `pago.monto_propina`, `acuerdo.cantidad_acordada` y `receta.cantidad_por_porcion` | ✓ |

### Reglas del modelo EER

| Regla del EER (Práctica 2) | Dónde quedó | Probado en |
| :-- | :-- | :-- |
| Mesa y Cuenta se identifican por el evento | PK compuestas + `ON DELETE CASCADE` | Rechazos 1 y 2 |
| La cuenta se abre en una mesa del mismo evento | FK compuesta `fk_cuenta_mesa` | Rechazo 4 |
| Jerarquía de Usuario disjunta | FK `(id_usuario, rol)` + `CHECK` del rol en cada subtipo | Rechazo 6 |
| Jerarquía de Usuario total | Disparadores de restricción diferidos | Rechazo 7 |
| Solo un mesero recibe propinas; solo un cajero maneja pagos y cancela comandas | FK hacia la tabla del subtipo | Rechazo 5 |
| Una comanda la prepara una sola estación, o ninguna si está pendiente o cancelada | `ck_comanda_preparacion` | Datos de ejemplo (comanda 3 pendiente sin estación) |
| Una comanda cancelada siempre tiene quién la canceló | `ck_comanda_cancelacion` | Rechazo 11 |
| La propina se registra con su monto | `ck_pago_propina_completa` | Rechazo 10 |
| Una variante no tiene variantes | `tg_producto_variante` | Rechazo 12 |
| Lo acordado depende de evento, paquete y producto a la vez | PK de `acuerdo` con las tres claves | Rechazo 13 y datos de ejemplo (refresco acordado por dos paquetes) |
| Lo acordado puede salir del catálogo del paquete | `acuerdo` sin FK a `paquete_producto` | Datos de ejemplo (refresco acordado en el Paquete Postres, que no lo incluye) |
| El precio cobrado se copia del catálogo y ya no cambia | `tg_comanda_precio` | Datos de ejemplo (precio copiado) y rechazo 14 |
| El total de la cuenta es la suma de sus comandas | Vista `v_cuenta` (no se guarda, no se desincroniza) | Datos de ejemplo |
| Al preparar una comanda se descuenta su receta y el stock nunca queda negativo | `tg_comanda_stock` + `ck_ingrediente_stock` | Datos de ejemplo (stock descontado) y rechazos 16 y 17 |
| Un producto está disponible si su receta alcanza | Vista `v_producto` | Datos de ejemplo (refresco de dieta no disponible) |
| Un ingrediente en uso no se borra | `fk_receta_ingrediente` (`RESTRICT`) | Rechazo 18 |
| Lo ya cobrado no se pierde | `ON DELETE RESTRICT` en comanda, pago y anticipo | Rechazo 15 |
| La cuenta tiene nombre visible | `ck_cuenta_nombre` | Rechazo 19 |
| Una cuenta abierta no repite nombre en su mesa | Índice único parcial `ux_cuenta_nombre_abierta` | Rechazo 20 |

### Lo que no se preservó

Solo una regla del modelo EER se pierde en el esquema: **cambiar el rol de un usuario conservando lo que registró con el rol anterior**. La disyunción declarativa lo impide (se intentó `UPDATE usuario SET rol = 'cajero_admin' WHERE id_usuario = 2` y el gestor lo rechazó por `fk_mesero_usuario`). Se aceptó esa pérdida para conservar la separación de responsabilidades, y la alternativa, una tabla de historial de roles, quedó documentada en [Reglas de Transformación](<ReglasDeTransformacion.md#lo-que-se-sacrifica-el-cambio-de-rol>).

![Intento de cambiar el rol del usuario 2 a cajero_admin, rechazado por fk_mesero_usuario](<../evidencias/practica3/parte6/06 - Cambio de rol rechazado.png>)
