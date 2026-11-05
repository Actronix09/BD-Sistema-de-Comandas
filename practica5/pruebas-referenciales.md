# Pruebas de integridad referencial

Práctica 5, ejercicio 2.3 · Sistema de Comandas

Este documento describe cómo comprobar las claves foráneas y sus acciones referenciales con los datos de ejemplo del sistema. Las sentencias ejecutables están en [`sql/pruebas-referenciales.sql`](sql/pruebas-referenciales.sql); el objetivo `make pruebas` las corre después de los rechazos y casos válidos.

## Base de prueba y seguridad

Se usa `comandas_pruebas`, que `make -C sql pruebas` reconstruye con `sql/esquema.sql`, las migraciones y `sql/datos-ejemplo.sql`. El archivo nuevo inicia una transacción, usa `SAVEPOINT` para las operaciones que deben revertirse de forma independiente y termina con `ROLLBACK`. Después comprueba que el evento 17 y sus filas de ejemplo sigan presentes. No deja cambios en la base.

**Resultado comprobado el 4 de noviembre de 2026:** `make -C sql pruebas` terminó con 36 de 36 rechazos, 15 de 15 casos válidos y todas las pruebas referenciales pasaron. Las auditorías de claves foráneas, índices únicos y columnas `NOT NULL` devolvieron cero filas. La salida referencial está guardada en [`evidencias/practica5/pruebas-referenciales.txt`](../evidencias/practica5/pruebas-referenciales.txt).

El evento 17 del fixture representa datos del dominio: tiene dos organizadores, tres mesas, tres cuentas, cuatro acuerdos, cinco comandas, un pago y un anticipo. También hay ocho ingredientes y nueve filas de receta. Los conteos siguientes se derivan de `sql/datos-ejemplo.sql`; `SELECT` los muestra durante la ejecución para que se puedan comparar.

| Tabla / fila | Antes de las pruebas |
| :-- | --: |
| `evento` 17 | 1 |
| `evento_organizador` del evento 17 | 2 |
| `mesa` del evento 17 | 3 |
| `cuenta` del evento 17 | 3 |
| `acuerdo` del evento 17 | 4 |
| `comanda` del evento 17 | 5 |
| `pago` del evento 17 | 1 |
| `anticipo` del evento 17 | 1 |
| Ingredientes | 8 |
| Recetas | 9 |

## Pruebas de las acciones referenciales

La consigna pide un caso de cada acción usada. El esquema utiliza cuatro: `ON DELETE CASCADE`, `ON DELETE RESTRICT`, `ON UPDATE CASCADE` y `ON UPDATE RESTRICT`.

| Acción | Datos y operación | Antes | Después esperado | Qué demuestra |
| :-- | :-- | :-- | :-- | :-- |
| `ON DELETE RESTRICT` | Intentar borrar el ingrediente 1, que aparece en una receta. | Ingrediente 1: 1; recetas que lo usan: 1. | Ingrediente 1: 1; recetas que lo usan: 1. | El gestor rechaza el borrado por `fk_receta_ingrediente`; no deja una receta incompleta. El mismo error ya aparece en el rechazo 18 de `sql/inserts-rechazados.sql`. |
| `ON UPDATE CASCADE` | Cambiar en una transacción el número del evento 17 a 117. | Evento: 1; organizadores: 2; mesas: 3; cuentas: 3; acuerdos: 4; anticipos: 1; comandas: 5; pagos: 1. | Bajo el número 117 quedan exactamente 1, 2, 3, 3, 4, 1, 5 y 1 filas; bajo el número 17 quedan 0. | La corrección de la clave del evento se propaga por las relaciones dependientes. Se revierte al `SAVEPOINT`. |
| `ON UPDATE RESTRICT` | Intentar cambiar el `id_usuario` 1 mientras existe su subtipo de mesero. | Usuario 1: 1; fila de mesero 1: 1; usuarios totales: 5. | Usuario 1: 1; usuario 101: 0; fila de mesero 1: 1; usuarios totales: 5. | El gestor devuelve `update or delete on table "usuario" violates foreign key constraint "fk_mesero_usuario" on table "mesero"`; no rompe la jerarquía ni la atribución del personal. |
| `ON DELETE CASCADE` | Tras quitar temporalmente las filas de historial que tienen `RESTRICT` (pago, comanda y anticipo), borrar el evento 17. | Antes de borrar el evento: evento 1; organizadores 2; mesas 3; cuentas 3; acuerdos 4. | Después: 0 en esas cinco tablas. | Al eliminar el propietario desaparecen sus organizadores, mesas, cuentas y acuerdos dependientes. Se revierte al `SAVEPOINT`, así que los datos iniciales vuelven. |

La prueba de `CASCADE` muestra las dos reglas juntas: los hijos que son parte del evento se borran con él, pero el gestor no permite borrar un evento que todavía conserva pagos, anticipos o comandas. Por eso la prueba elimina esas filas dentro del `SAVEPOINT` antes de probar la cascada; al revertir el punto de guardado, todo el ejemplo queda restaurado.

## Clave foránea inexistente y orden de carga

Una mesa no puede apuntar a un evento que no existe. La inserción del evento 99 se rechaza por `fk_mesa_evento`; el número de mesas queda en 3 antes y después. El mensaje observado en el rechazo 1 es:

```text
insert or update on table "mesa" violates foreign key constraint "fk_mesa_evento"
```

El mismo caso demuestra por qué la carga debe insertar primero la tabla padre. Para que la segunda mitad del caso también sea visible, el script intenta insertar la mesa antes del evento 900001 y captura el rechazo; luego inserta el evento y la mesa. Durante la transacción, el conteo de filas de prueba pasa de evento 0 / mesa 0 a evento 1 / mesa 1. El `SAVEPOINT` revierte ambas filas al terminar.

```sql
-- Orden incorrecto: la mesa falla porque el evento aún no existe.
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero)
VALUES (900001, 1, 1);

-- Orden correcto: primero el padre; después la hija.
INSERT INTO evento (numero_evento, fecha, tipo_evento, numero_asistentes)
VALUES (900001, DATE '2026-11-05', 'prueba referencial', 1);
INSERT INTO mesa (numero_evento, numero_mesa, id_mesero)
VALUES (900001, 1, 1);
```

## Auditorías que deben devolver cero filas

Al final, el SQL recorre el catálogo de PostgreSQL y ejecuta tres auditorías sobre las tablas del esquema `public`:

1. **Referencias huérfanas:** revisa las 25 claves foráneas y busca filas hijas sin su padre. Los `NULL` de referencias opcionales no cuentan como huérfanos.
2. **Duplicados:** revisa las claves primarias, restricciones `UNIQUE` e índices únicos, incluidos los índices por minúsculas y el índice parcial de nombres de cuentas abiertas.
3. **Nulos indebidos:** revisa las columnas declaradas `NOT NULL` en las tablas.

Las consultas de salida son `SELECT * FROM auditoria_fks`, `SELECT * FROM auditoria_unicos` y `SELECT * FROM auditoria_not_null`. En la corrida guardada, cada una mostró `(0 rows)`. Si aparece una fila, el script falla en vez de reportar que las pruebas pasaron.

## Cómo ejecutarlo

Desde la raíz del repositorio, ejecuta:

```bash
make -C sql pruebas
```

El objetivo reconstruye `comandas_pruebas`, aplica el esquema y las migraciones, corre las pruebas de dominio y después estas pruebas referenciales. La salida final observada fue:

```text
Todas las pruebas referenciales pasaron; los datos de ejemplo quedaron restaurados.
==> Todas las pruebas pasaron sobre comandas_pruebas
```

Este documento cubre **el proyecto de Comandas**. La consigna también pide las comprobaciones de huérfanos, duplicados y nulos en la base del proyecto asignado. Esa segunda ejecución y su evidencia quedan para la parte de Sismos, según el orden de trabajo acordado.

