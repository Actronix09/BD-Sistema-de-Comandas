# Claves foráneas y acciones referenciales

Práctica 5, ejercicios 2.1 y 2.2 · Sistema de Comandas

Este documento enumera las 25 claves foráneas del esquema, relaciona cada una con el modelo EER, indica si admite `NULL` y justifica por separado qué ocurre al borrar o actualizar la fila referenciada.

## Cómo leer la tabla

- **Hija → padre** muestra las columnas de la tabla que guarda la referencia y las columnas a las que apunta.
- **NULL** indica si la relación puede estar ausente en una fila hija. Que admita `NULL` no significa que se borre automáticamente una referencia que ya existe.
- **`ON DELETE`** decide qué pasa con las hijas cuando se intenta borrar el padre.
- **`ON UPDATE`** decide qué pasa con las hijas cuando cambia la clave del padre.

El modelo tiene **25 claves foráneas**: 21 son obligatorias y 4 opcionales. El esquema usa `ON DELETE CASCADE` en 9 claves y `ON DELETE RESTRICT` en 16; para cambios de clave usa `ON UPDATE CASCADE` en 14 y `ON UPDATE RESTRICT` en 11. No se usa `SET NULL`: una relación opcional puede no existir desde el principio, pero si existe se conserva para no borrar una responsabilidad o un dato histórico.

## Inventario y justificación por clave

| # | Restricción y relación del EER | Hija → padre | ¿NULL? | `ON DELETE` y regla protegida | `ON UPDATE` y regla protegida |
| :--: | :-- | :-- | :--: | :-- | :-- |
| 1 | `fk_evento_organizador_evento`<br>Atributo multivaluado Organizador | `evento_organizador.numero_evento` → `evento.numero_evento` | No | **CASCADE.** Un organizador es parte de la descripción de un evento; al borrar el evento, sus organizadores dejan de tener sentido. | **CASCADE.** Si se corrige el número del evento, sus organizadores siguen asociados al mismo evento. |
| 2 | `fk_mesero_usuario`<br>Jerarquía Usuario → Mesero | `mesero.(id_usuario, rol)` → `usuario.(id_usuario, rol)` | No | **CASCADE.** La fila de mesero es el subtipo de una persona; no puede quedar sin su usuario. | **RESTRICT.** No se cambia la identidad ni el rol de una persona por debajo de su subtipo; así se conserva la disyunción de roles y las referencias del historial. |
| 3 | `fk_bar_cocina_usuario`<br>Jerarquía Usuario → Bar/Cocina | `bar_cocina.(id_usuario, rol)` → `usuario.(id_usuario, rol)` | No | **CASCADE.** La fila de estación es parte del usuario de ese rol. | **RESTRICT.** Cambiar la identidad o el rol rompería la clasificación del personal y el rastro de quién preparó comandas. |
| 4 | `fk_cajero_admin_usuario`<br>Jerarquía Usuario → Cajero/Administrador | `cajero_admin.(id_usuario, rol)` → `usuario.(id_usuario, rol)` | No | **CASCADE.** La fila de caja es el subtipo del usuario y no tiene significado independiente. | **RESTRICT.** La identidad y el rol del usuario no se cambian mientras existan datos asociados a sus funciones de caja o cancelación. |
| 5 | `fk_mesa_evento`<br>R1 Pertenece: Mesa → Evento | `mesa.numero_evento` → `evento.numero_evento` | No | **CASCADE.** Mesa es débil: su número solo identifica una mesa dentro de un evento. Sin el evento, la mesa no se identifica. | **CASCADE.** Al corregir el número del evento, las mesas conservan su pertenencia y su clave compuesta se actualiza. |
| 6 | `fk_mesa_mesero`<br>R3 Atiende: Mesa → Mesero | `mesa.id_mesero` → `mesero.id_usuario` | No | **RESTRICT.** No se elimina un mesero mientras tenga mesas asignadas; se conserva quién es responsable de atenderlas. | **RESTRICT.** No se cambia la identidad del mesero mientras esté referenciada por sus asignaciones. |
| 7 | `fk_cuenta_evento`<br>R2 Abre: Cuenta → Evento | `cuenta.numero_evento` → `evento.numero_evento` | No | **CASCADE.** La cuenta es débil y su clave incluye el evento; sin él no se puede identificar. | **CASCADE.** Si se corrige el número del evento, se actualiza el componente de la clave de la cuenta y sus referencias dependientes. |
| 8 | `fk_cuenta_mesa`<br>R4 Tiene: Cuenta → Mesa | `cuenta.(numero_evento, numero_mesa)` → `mesa.(numero_evento, numero_mesa)` | No | **RESTRICT.** No se borra una mesa que aún tiene cuentas; se preserva en qué mesa se generó el consumo. | **RESTRICT.** No se cambia la identificación de una mesa que conserva cuentas asociadas. |
| 9 | `fk_producto_principal`<br>R14 Variante: Producto variante → Producto principal | `producto.id_producto_principal` → `producto.id_producto` | **Sí.** Un producto normal no tiene principal. | **RESTRICT.** No se borra un producto principal mientras tenga variantes; así no quedan variantes sin origen. | **RESTRICT.** No se cambia la identidad del producto principal mientras otras variantes dependan de ella. |
| 10 | `fk_receta_producto`<br>R17 Receta: Receta → Producto | `receta.id_producto` → `producto.id_producto` | No | **CASCADE.** Las filas de receta describen la composición de un producto; sin ese producto no significan nada. | **CASCADE.** Si se corrige el identificador del producto, sus ingredientes siguen describiendo el mismo producto. |
| 11 | `fk_receta_ingrediente`<br>R17 Receta: Receta → Ingrediente | `receta.id_ingrediente` → `ingrediente.id_ingrediente` | No | **RESTRICT.** No se borra un ingrediente usado por una receta; hacerlo dejaría incompleta la receta y el descuento de inventario. | **CASCADE.** Si se corrige la clave del ingrediente, las recetas siguen apuntando al mismo ingrediente. |
| 12 | `fk_paquete_producto_paquete`<br>R15 Incluye: Contenido → Paquete | `paquete_producto.numero_paquete` → `paquete.numero_paquete` | No | **CASCADE.** La fila de inclusión es parte del paquete; no debe quedar sin él. | **CASCADE.** Si cambia el número del paquete, su contenido continúa ligado al mismo paquete. |
| 13 | `fk_paquete_producto_producto`<br>R15 Incluye: Contenido → Producto | `paquete_producto.id_producto` → `producto.id_producto` | No | **RESTRICT.** No se borra un producto que forma parte de un paquete ofrecido; se conserva la definición del catálogo. | **CASCADE.** Si se corrige la clave de un producto, el paquete sigue incluyendo ese producto. |
| 14 | `fk_acuerdo_evento`<br>R16 Acuerda: Acuerdo → Evento | `acuerdo.numero_evento` → `evento.numero_evento` | No | **CASCADE.** El acuerdo es específico de un evento; sin ese evento deja de existir. | **CASCADE.** Si se corrige el número del evento, sus acuerdos conservan el vínculo. |
| 15 | `fk_acuerdo_paquete`<br>R16 Acuerda: Acuerdo → Paquete | `acuerdo.numero_paquete` → `paquete.numero_paquete` | No | **RESTRICT.** No se borra un paquete que forma parte de un acuerdo; se conserva lo contratado. | **CASCADE.** Si se corrige la clave del paquete, el acuerdo sigue señalando el paquete contratado. |
| 16 | `fk_acuerdo_producto`<br>R16 Acuerda: Acuerdo → Producto | `acuerdo.id_producto` → `producto.id_producto` | No | **RESTRICT.** No se borra el producto asociado a un acuerdo; se conserva el detalle de lo pactado para el evento. | **CASCADE.** Si se corrige la clave del producto, el acuerdo mantiene la misma referencia comercial. |
| 17 | `fk_comanda_cuenta`<br>R5 Genera: Cuenta → Comanda | `comanda.(numero_evento, secuencial)` → `cuenta.(numero_evento, secuencial)` | No | **RESTRICT.** No se borra una cuenta que tenga comandas; el consumo es parte del historial que permite cobrarla. | **CASCADE.** Si se corrige la clave compuesta de la cuenta, sus comandas siguen dentro de esa misma cuenta. |
| 18 | `fk_comanda_mesero`<br>R6 Levanta: Mesero → Comanda | `comanda.id_mesero` → `mesero.id_usuario` | No | **RESTRICT.** Se conserva qué mesero levantó cada comanda. | **RESTRICT.** No se cambia la identidad del mesero que aparece en el historial de comandas. |
| 19 | `fk_comanda_producto`<br>R7 Referencia: Producto → Comanda | `comanda.id_producto` → `producto.id_producto` | No | **RESTRICT.** No se borra un producto que ya aparece en comandas; así se conserva qué se pidió y cobró. | **CASCADE.** Si se corrige la clave del producto, las comandas mantienen su referencia; el precio cobrado queda guardado como dato histórico. |
| 20 | `fk_comanda_bar_cocina`<br>R8 Prepara: Bar/Cocina → Comanda | `comanda.id_bar_cocina` → `bar_cocina.id_usuario` | **Sí.** Puede faltar antes de preparar o en una cancelación temprana. | **RESTRICT.** Si una comanda ya tiene estación, no se borra al responsable de preparación. | **RESTRICT.** Se conserva la identidad de quien preparó o recibió la comanda. |
| 21 | `fk_comanda_cajero_cancela`<br>R9 Cancela: Cajero/Administrador → Comanda | `comanda.id_cajero_cancela` → `cajero_admin.id_usuario` | **Sí.** Solo existe cuando la comanda se cancela. | **RESTRICT.** No se borra al cajero que autorizó una cancelación; ese dato forma parte de la auditoría. | **RESTRICT.** No se cambia la identidad del cajero asociado a una cancelación histórica. |
| 22 | `fk_pago_cuenta`<br>R10 Recibe: Cuenta → Pago | `pago.(numero_evento, secuencial)` → `cuenta.(numero_evento, secuencial)` | No | **RESTRICT.** Una cuenta con pagos no se borra; hacerlo perdería el historial de cobros. | **CASCADE.** Si se corrige la clave de una cuenta, los pagos siguen vinculados a ella. |
| 23 | `fk_pago_cajero`<br>R11 Maneja: Cajero/Administrador → Pago | `pago.id_cajero` → `cajero_admin.id_usuario` | No | **RESTRICT.** Se conserva quién recibió cada pago. | **RESTRICT.** No se cambia la identidad de quien manejó dinero registrado. |
| 24 | `fk_pago_mesero_propina`<br>R12 Recibe propina: Mesero → Pago | `pago.id_mesero_propina` → `mesero.id_usuario` | **Sí.** Un pago puede no llevar propina. | **RESTRICT.** Si existe una propina, no se borra su destinatario; la pareja mesero/monto se conserva. | **RESTRICT.** No se cambia la identidad del mesero que recibió una propina registrada. |
| 25 | `fk_anticipo_evento`<br>R13 Recibe: Evento → Anticipo | `anticipo.numero_evento` → `evento.numero_evento` | No | **RESTRICT.** No se borra un evento que ya tiene un anticipo; se conserva el movimiento de dinero. | **CASCADE.** Si se corrige la clave del evento, el anticipo sigue vinculado al evento que lo recibió. |

## Por qué `NULL` no significa `SET NULL`

Las cuatro relaciones opcionales son `producto.id_producto_principal`, `comanda.id_bar_cocina`, `comanda.id_cajero_cancela` y `pago.id_mesero_propina`. `NULL` significa que la relación aún no existe o no aplica: un producto puede no ser variante, una comanda puede no estar preparada o cancelada y un pago puede no incluir propina. Si la referencia ya se guardó, se usa `RESTRICT` para que borrar a la persona o producto no elimine en silencio el dato de responsabilidad o historial.

En las relaciones obligatorias, la columna es `NOT NULL`. En claves compuestas, todas las columnas de la clave foránea son obligatorias.

## Relación con las reglas del modelo

- Las filas débiles y de composición (organizadores, mesas, cuentas, subtipos, recetas de un producto, contenido de paquete y acuerdo de un evento) usan `CASCADE` cuando el padre es su propietario y la hija no tiene sentido separada.
- Las filas que representan consumo, cobro, asignación de personal o un compromiso comercial usan `RESTRICT` para preservar historial y responsabilidades.
- `CASCADE` en actualización mantiene la misma relación si se corrige una clave primaria; `RESTRICT` evita cambiar identidades de personal y referencias donde eso alteraría la atribución histórica.
- El caso ejecutable de cada clase de acción y las consultas de comprobación están en [`pruebas-referenciales.md`](pruebas-referenciales.md) y [`sql/practica5/pruebas-referenciales.sql`](../../sql/practica5/pruebas-referenciales.sql).

