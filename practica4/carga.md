# Script de Carga del Sistema de Comandas

En este documento se explica cómo se puebla la base con un solo comando y se muestra la evidencia de cada requisito: que sea repetible, ordenado, todo o nada, con cuentas, sin credenciales y eficiente.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Uso del script, decisiones de la carga, salida de las dos ejecuciones, comparación de tiempos y registro de rechazos.

**Datos:** [Fuente de Datos](<fuente.md>)

---

## Cómo se ejecuta

```bash
cp practica4/poblar/.env.example practica4/poblar/.env   # y llenar los valores
practica4/poblar/poblar.sh
```

Si la base no existe, el script la crea con `sql/esquema.sql` y las migraciones de `practica4/migraciones/`. Con `--recrear` la borra y la carga desde cero; hace falta cuando se agrega una migración. Esa opción no toca las bases `comandas` ni `comandas_pruebas`, que son de `sql/Makefile`.

| Archivo | Para qué |
| :-- | :-- |
| [`poblar/poblar.sh`](<poblar/poblar.sh>) | Arma la conexión, crea la base si hace falta y corre la carga |
| [`poblar/poblar.sql`](<poblar/poblar.sql>) | La carga en sí: lectura, orden, reporte y confirmación |
| [`poblar/.env.example`](<poblar/.env.example>) | Variables que necesita la conexión |
| [`poblar/comparar_tiempos.sh`](<poblar/comparar_tiempos.sh>) | Compara `\copy` contra un `INSERT` por renglón |
| [`poblar/probar_rechazos.sh`](<poblar/probar_rechazos.sh>) | Comprueba que los datos malos se rechacen |

## Cómo cumple cada requisito

| Requisito | Cómo se cumple |
| :-- | :-- |
| Repetible | Cada tabla filtra con `NOT EXISTS` por su clave primaria. La segunda ejecución inserta 0 renglones y no termina en error |
| Ordenado | Primero las tablas de las que dependen las demás, y además el orden que piden los disparadores (abajo) |
| Todo o nada | Todo va en una transacción. Con un solo rechazo se revierte, y se informa el renglón y el motivo |
| Con cuentas | Al terminar informa, por tabla, los renglones leídos, insertados, los que ya existían y los rechazados |
| Sin credenciales | La conexión y las contraseñas salen de variables de entorno. `.env` no se sube al repositorio. La carga entra como `app_comandas`, el usuario del rol de la aplicación ([Usuarios y Permisos](<permisos.md>)) |
| Eficiente | Los CSV entran con `\copy` a tablas temporales y pasan a las reales en tandas de 1000 renglones |

### Por qué `NOT EXISTS` y no `ON CONFLICT`

`ON CONFLICT DO NOTHING` no sirve en este esquema. Los disparadores `BEFORE INSERT` corren antes de que el gestor revise el conflicto: si se repite un pago que ya está guardado, `tg_pago_saldo` lo compara contra una cuenta que ya está pagada y la carga falla con "el pago excede el saldo de la cuenta". Por eso los renglones que ya existen se filtran antes de insertar.

### El orden no es solo el de las claves foráneas

| Momento | Tablas | Por qué |
| :-- | :-- | :-- |
| 1 | `ingrediente`, `producto`, `receta` | Catálogo; los productos principales van antes que sus variantes (`tg_producto_variante`) |
| 2 | `usuario`, `mesero`, `bar_cocina`, `cajero_admin` | La especialización total se revisa al confirmar (`ct_usuario_total`) |
| 3 | `paquete`, `paquete_producto` | Dependen del catálogo |
| 4 | `evento` como `programado`, y lo que depende de él | `tg_comanda_evento` rechaza comandas en eventos finalizados |
| 5 | `mesa`, `cuenta` como `abierta` | `tg_comanda_cuenta_abierta` rechaza comandas en cuentas cerradas |
| 6 | `comanda` | Aquí corre el descuento de stock (`tg_comanda_stock`) |
| 7 | `pago` | `tg_pago_saldo` compara contra el saldo que dejaron las comandas |
| 8 | Estado final de `cuenta` y de `evento` | `tg_cuenta_cierre` exige la cuenta pagada y las comandas terminadas |
| 9 | Secuencias | Los identificadores se cargan explícitos; las secuencias siguen después del mayor |

### Cómo se ubica el renglón que falló

Las tablas temporales tienen todas sus columnas como texto, así que un dato con el tipo equivocado no detiene el `\copy`. Cada tanda de 1000 renglones va en una subtransacción: si falla, solo esa tanda se repite renglón por renglón para anotar qué rechazó el gestor. Así, los datos correctos no pagan el costo de revisar uno por uno.

## Salida de las dos ejecuciones

Primera ejecución, sobre una base recién creada ([salida completa](<../evidencias/practica4/carga-primera-ejecucion.txt>) y [captura](<../evidencias/practica4/carga-primera-ejecucion.png>)):

```
       tabla        | leidos | insertados | ya_existian | rechazados 
--------------------+--------+------------+-------------+------------
 ingrediente        |    208 |        208 |           0 |          0
 producto           |    214 |        214 |           0 |          0
 receta             |    681 |        681 |           0 |          0
 usuario            |    200 |        200 |           0 |          0
 mesero             |    130 |        130 |           0 |          0
 bar_cocina         |     45 |         45 |           0 |          0
 cajero_admin       |     25 |         25 |           0 |          0
 paquete            |     12 |         12 |           0 |          0
 paquete_producto   |    100 |        100 |           0 |          0
 evento             |    240 |        240 |           0 |          0
 evento_organizador |    360 |        360 |           0 |          0
 acuerdo            |    625 |        625 |           0 |          0
 anticipo           |    343 |        343 |           0 |          0
 mesa               |   3943 |       3943 |           0 |          0
 cuenta             |   7515 |       7515 |           0 |          0
 comanda            |  37528 |      37528 |           0 |          0
 pago               |   9640 |       9640 |           0 |          0

 leidos | insertados | ya_existian | rechazados 
--------+------------+-------------+------------
  61809 |      61809 |           0 |          0

==> Carga confirmada
==> Tiempo total: 356 s
```

Segunda ejecución, sobre la misma base ([salida completa](<../evidencias/practica4/carga-segunda-ejecucion.txt>) y [captura](<../evidencias/practica4/carga-segunda-ejecucion.png>)):

```
 leidos | insertados | ya_existian | rechazados 
--------+------------+-------------+------------
  61809 |          0 |       61809 |          0

==> Carga confirmada
==> Tiempo total: 1 s
```

No duplicó renglones ni descontó stock otra vez: la suma de `stock_actual` fue 404,116.975 después de las dos ejecuciones.

## Comparación de tiempos

`comparar_tiempos.sh` carga `comanda.csv` en una tabla sin restricciones ni disparadores, para medir solo la forma de cargar ([salida](<../evidencias/practica4/comparacion-de-tiempos.txt>) y [captura](<../evidencias/practica4/comparacion-de-tiempos.png>)):

| Forma de cargar 37,528 renglones | Tiempo | Contra `\copy` |
| :-- | :--: | :--: |
| `\copy` | 0.17 s | — |
| `INSERT` por renglón, en una transacción | 2.50 s | 15 veces más |
| `INSERT` por renglón, con *autocommit* | 12.11 s | 71 veces más |

La lectura de los CSV es casi instantánea. Casi todo el tiempo de la carga real se va en los disparadores de `comanda`, que descuentan el stock de cada receta: es el costo de que la base proteja sus reglas.

## Registro de rechazos

### Los datos reales

**La carga final no tiene rechazos.** El único caso real apareció antes de llegar a la base, al transcribir el menú: el grupo "Caguama Modelo" y la marca del mismo nombre daban dos productos iguales, lo que habría violado `uq_producto_nombre`. El error estaba en el dato, y el grupo pasó a llamarse "Caguama de la marca Modelo".

### Los datos de prueba

Para comprobar que las restricciones protegen la carga, `probar_rechazos.sh` agrega renglones malos a una copia de los CSV. **Estos renglones son de prueba y no están en `practica4/datos/`.** Se rechazaron los 11, se revirtió la carga completa y las tablas quedaron en 0 renglones ([salida](<../evidencias/practica4/carga-con-rechazos.txt>) y [captura](<../evidencias/practica4/carga-con-rechazos.png>)).

| Tabla | Renglón | Dato | Restricción | Mensaje del gestor | ¿Dónde estaba el error? |
| :-- | :--: | :-- | :-- | :-- | :-- |
| `ingrediente` | 209 | Unidad `kg` | `ck_ingrediente_unidad` | new row for relation "ingrediente" violates check constraint | En el dato: se convierte a `g` |
| `producto` | 215 | Precio `-5.00` | `ck_producto_precio` | new row for relation "producto" violates check constraint | En el dato |
| `producto` | 216 | Categoría `postres` | `ck_producto_categoria` | new row for relation "producto" violates check constraint | En el dato: el menú solo tiene tres categorías |
| `producto` | 217 | Otro producto `Tacos` | `uq_producto_nombre` | duplicate key value violates unique constraint | En el dato |
| `producto` | 218 | Sin precio | `NOT NULL` | null value in column "precio" of relation "producto" violates not-null constraint | En el dato |
| `usuario` | 201 | Rol `gerente` | `ck_usuario_rol` | new row for relation "usuario" violates check constraint | En el dato: el modelo no tiene ese rol |
| `usuario` | 202 | Fecha `31/02/1990` | Tipo de dato | date/time field value out of range: "31/02/1990" | En el dato: la fecha no existe |
| `evento` | 241 | 0 asistentes | `ck_evento_asistentes` | new row for relation "evento" violates check constraint | En el dato |
| `mesa` | 3944 | Evento 9999 | `fk_mesa_evento` | insert or update on table "mesa" violates foreign key constraint | En el dato: el evento no existe |
| `comanda` | 37529 | Prepara el usuario 1, que es mesero | `fk_comanda_bar_cocina` | insert or update on table "comanda" violates foreign key constraint | En el dato |
| `pago` | 9641 | `$999,999` a una cuenta pagada | `tg_pago_saldo` | el pago excede el saldo de la cuenta (0.00) | En el dato |

En ningún caso el error estaba en la restricción, así que no hizo falta ninguna migración.
