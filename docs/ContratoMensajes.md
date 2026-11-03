# Contrato de mensajes entre el cliente y el servidor

**Estado:** borrador para revisar entre @Actronix09 y Samy. Cubre las partes 4.4–4.7 de `PENDIENTES.md`.

**Salió de:** la `Api` simulada (`cliente/Comandas/Api.qml`), que dice qué esperan las pantallas; `sql/esquema.sql`, que dice qué permite la base, y el servidor actual (`servidor/servidor.cpp`).

Donde esas fuentes no coinciden, la sección 1 propone qué hacer. **Lo que dependa de una decisión pendiente puede cambiar hasta que se resuelva.**

---

## 1. Decisiones

### Ya decididas

@Actronix09, 2 de noviembre de 2026:

| # | Decisión | Queda así | Qué implica |
| :--: | :-- | :-- | :-- |
| D4 | ¿Se puede crear o recuperar una cuenta sin sesión? | No. Solo un administrador crea usuarios y cambia contraseñas, desde Usuarios | Se quitan los dos botones del login. Las pantallas pendientes de 7.6 bajan de 4 a 2: Ver logs y Productos con receta |
| D7 | ¿Cómo se capturan los ingredientes? | Con unidad, mínimo y decimales | Cambia `DialogoIngrediente.qml` |
| D8 | ¿Un mesero entrega órdenes de otro? | No, solo las suyas. Si no, responde `NO_AUTORIZADO` | El servidor compara `comanda.id_mesero` con la sesión |
| D9 | ¿Dónde se maneja qué ingredientes lleva cada producto? | Dentro de Admin › Productos: se elige un producto y ahí se edita su receta | Hacen falta `OP_OBTENER_PRODUCTO` y `OP_GUARDAR_RECETA` (sección 6) |

### Faltan

| # | Decisión | El problema | Propuesta | Quién |
| :--: | :-- | :-- | :-- | :-- |
| D1 | ¿Cuándo se revisa el stock? | `descontar_stock` no revisa nada al crear una comanda `pendiente`: revisa y descuenta al pasar a preparación. Así, `OP_CREAR_PEDIDO` nunca recibe un error de stock de la base, y lo que pide la parte 6.6 (`SIN_STOCK` al pedir) no pasaría. La `Api` simulada sí aparta el stock al pedir | El servidor suma lo que pide la orden completa contra el stock y la rechaza con `SIN_STOCK`, sin apartar nada. Cocina todavía puede recibir `SIN_STOCK` al empezar si el stock se acabó. La `Api` simulada deja de apartar | Ambos |
| D2 | ¿Cómo distingue el servidor los errores? | Todos los disparadores usan `check_violation`, igual que los `CHECK`. El servidor no puede saber cuál fue la regla ni si el texto se puede mostrar, porque el de un `CHECK` es técnico y en inglés | Dos códigos propios en `esquema.sql`: `CM001` para las reglas de los disparadores y `CM002` para el stock (sección 4). Las pruebas de la base no cambian: solo exigen que cada caso falle | Samy |
| D3 | ¿Puede haber dos eventos en curso? | Nada lo impide. `OP_EVENTO_EN_CURSO` y el login necesitan uno solo | Índice único parcial sobre `evento` con `estado = 'en_curso'`. Si no hay ninguno, la respuesta trae `datos: null` | Samy |
| D5 | ¿Cómo se reconecta el teléfono? | Al bloquearlo se cae el WebSocket. Repetir el login obliga a guardar la contraseña en el teléfono | `OP_LOGIN` regresa un `token`, que el cliente guarda en memoria, y `OP_REANUDAR_SESION` lo usa al reconectar. El token caduca al cerrar sesión o al reiniciar el servidor | Ambos |
| D6 | ¿Se puede borrar un ingrediente usado en una receta? | El sistema en C y la `Api` simulada lo quitan de las recetas. La base lo impide (`fk_receta_ingrediente` con `ON DELETE RESTRICT`) | Seguir a la base: responde `EN_USO` e indica en qué productos se usa. Para borrarlo, primero se quita de esas recetas en Admin › Productos (D9) | Ambos |

**Ya abiertas en `PENDIENTES.md` que afectan al contrato:**

- **2.7:** si cerrar una cuenta es definitivo.
- **3.5:** si las rondas son una entidad. Este contrato asume que no (sección 3).
- **3.6:** dónde viven los logs. Sin esto, `OP_LISTAR_LOGS` y `OP_VER_LOG` no se pueden definir.
- **3.13:** las reglas para cancelar. Mientras no estén en la base, las revisa el servidor.
- **3.14:** el estado de una cuenta cancelada. Este contrato asume que es una cuenta cerrada, sin pagos y con todas sus comandas canceladas.
- **6.11:** cifrar la conexión. Hoy las contraseñas viajan sin cifrar por `ws://`.

---

## 2. Formato

Todo viaja como JSON por un solo WebSocket. El servidor escucha en el puerto 9000.

```json
→ {"id": 7, "op": "OP_CREAR_PEDIDO", "datos": {"numero_evento": 17, "secuencial": 1, "lineas": [{"id_producto": 1, "cantidad": 2, "detalles": "sin hielo"}]}}
← {"id": 7, "ok": true, "mensaje": "Se enviaron 2 comandas · Novios · 17-1-1", "datos": {"creadas": 2, "folio": "17-1-1"}}
← {"id": 7, "ok": false, "error": {"codigo": "SIN_STOCK", "mensaje": "No alcanza Queso parmesano: se necesitan 3 y hay 1"}}
← {"aviso": "COMANDA_LISTA", "datos": {"id_mesero": 1, "numero_mesa": 1, "cuenta": "Novios · 17-1-1", "productos": ["2× Refresco"]}}
```

- **`id`:** lo elige el cliente, y la respuesta lo regresa igual.
- **`op`:** el nombre de `protocolo.h`. Las operaciones nuevas se agregan ahí.
- **`mensaje` al responder bien:** es opcional y las pantallas lo muestran como aviso. Es un cambio al formato de `PENDIENTES.md`, porque la `Api` simulada ya regresa ese texto. El servidor actual todavía no lo manda.
- **`error.mensaje`:** siempre se puede mostrar al usuario. Nunca lleva SQL ni detalles internos; esos van solo al log del servidor.
- **Avisos:** no llevan `id`, y el servidor los manda después del `COMMIT`.
- **Todo o nada:** una operación con varias comandas corre en una transacción. Si una falla, no se aplica ninguna.

La `Api` real convierte esto a la forma que ya usan las pantallas: `{codigo: "OK" | error.codigo, mensaje, datos}`. Así, las pantallas no cambian.

---

## 3. Tipos de datos

| Dato | En el JSON | Ejemplo | Nota |
| :-- | :-- | :-- | :-- |
| Dinero | Texto con 2 decimales | `"95.00"` | Nunca número. El cliente nunca manda un precio de producto: lo fija `fijar_precio_cobrado()` |
| Stock y cantidades de receta | Texto con 3 decimales | `"12.500"` | Por `NUMERIC(10,3)` |
| Fecha y hora | Texto ISO 8601 con zona | `"2026-11-02T19:40:00-06:00"` | La `Api` simulada usa milisegundos; la `Api` real convierte |
| Fecha | Texto | `"1998-04-12"` | |
| Identificadores | Número | `41` | |
| Cuenta | `numero_evento` + `secuencial` | `17`, `1` | Es la clave de `cuenta`. La `Api` simulada solo usa `secuencial`; la `Api` real agrega el evento |
| Sin valor | `null` | | |

**Nombre de una cuenta (C6):** `cuenta` es el nombre con el folio al final, `"Novios · 17-1-1"`, y lo arma el servidor.

**Ronda:** las comandas de una cuenta con la misma `fecha_hora` y el mismo mesero. Funciona porque `now()` vale lo mismo en toda la transacción de `OP_CREAR_PEDIDO`.

**`secuencial` nuevo:** la base no lo genera. Lo calcula el servidor dentro de la transacción de `OP_CREAR_CUENTA`, por evento.

---

## 4. Códigos de error (4.6)

| Código | Cuándo | Lo produce |
| :-- | :-- | :-- |
| `PETICION_INVALIDA` | JSON roto, o sin `id` u `op` | Servidor ✓ |
| `OP_DESCONOCIDA` | `op` no existe en `protocolo.h` | Servidor ✓ |
| `NO_IMPLEMENTADA` | La operación existe pero aún no está hecha | Servidor ✓ |
| `NO_AUTENTICADO` | Sin sesión en la conexión | Servidor ✓ |
| `NO_AUTORIZADO` | El rol no puede hacer esa operación | Servidor |
| `CREDENCIALES_INVALIDAS` | Usuario o contraseña incorrectos; el mismo texto en los dos casos | Servidor ✓ |
| `VALIDACION_FALLIDA` | Datos que faltan o no cumplen el formato | Servidor o `CHECK` de la base |
| `NO_EXISTE` | El registro ya no existe | Servidor |
| `YA_EXISTE` | Nombre o usuario repetido | Base, `23505` |
| `EN_USO` | No se puede borrar porque otro registro lo usa | Base, `23503` |
| `SIN_STOCK` | No alcanza un ingrediente | Servidor (D1) o base, `CM002` |
| `REGLA_INCUMPLIDA` | Regla de un disparador; se muestra su texto | Base, `CM001` |
| `SIN_EVENTO` | La operación necesita un evento en curso y no hay | Servidor |
| `ERROR_BD` | Cualquier otro error de la base o conexión perdida; se detalla solo en el log | Servidor ✓ |

✓ = el servidor ya lo responde. La `Api` simulada usa `ERROR` donde aquí va `NO_EXISTE`, y mete en `VALIDACION_FALLIDA` lo que aquí es `YA_EXISTE`, `EN_USO` o `REGLA_INCUMPLIDA`.

### Traducción de los errores de la base

El servidor lee el `SQLSTATE` con `QSqlError::nativeErrorCode()`.

| `SQLSTATE` | Código | Mensaje |
| :-- | :-- | :-- |
| `CM001` (propuesto, D2) | `REGLA_INCUMPLIDA` | El del disparador, con la primera letra en mayúscula |
| `CM002` (propuesto, D2) | `SIN_STOCK` | El del disparador, con la primera letra en mayúscula |
| `23514` | `VALIDACION_FALLIDA` | Texto del servidor; el de PostgreSQL es técnico |
| `23505` | `YA_EXISTE` | Texto del servidor según la operación |
| `23503` | `EN_USO` | Texto del servidor según la operación |
| `23502`, `22001`, `22P02` | `VALIDACION_FALLIDA` | Texto del servidor; lo normal es detectarlo antes de llegar a la base |
| Cualquier otro | `ERROR_BD` | "No se pudo consultar la base de datos" |

### Disparadores que usarían `CM001` y `CM002`

| Disparador | Código | Texto actual |
| :-- | :-- | :-- |
| `descontar_stock` | `CM002` | no hay stock suficiente de "%" para preparar la comanda (quedan % %, la receta pide %) |
| `validar_cambio_estado` | `CM001` | la comanda % está cancelada y no puede pasar a "%" |
| `validar_cambio_estado` | `CM001` | la comanda % no puede pasar del estado "%" al estado "%" |
| Pago contra el saldo | `CM001` | el pago excede el saldo de la cuenta (%) |
| Cierre de cuenta | `CM001` | la cuenta tiene comandas sin terminar |
| Cierre de cuenta | `CM001` | la cuenta tiene saldo pendiente (%) |
| Comanda en cuenta cerrada | `CM001` | no se pueden agregar comandas a una cuenta cerrada |
| Evento finalizado | `CM001` | el evento % esta finalizado |
| Estación de la comanda | `CM001` | la categoria % se prepara en %, no en % |
| Precio cobrado | `CM001` | el precio cobrado de la comanda % ya quedó fijado y no se puede modificar |
| Variantes de producto | `CM001` | el producto % es una variante y no puede tener variantes |
| Variantes de producto | `CM001` | el producto % tiene variantes y no puede volverse variante de otro |

`ck_ingrediente_stock` es un `CHECK` y respalda a `descontar_stock` cuando dos comandas compiten por el mismo ingrediente. Ahí el servidor responde `SIN_STOCK` si la operación era pasar a preparación.

---

## 5. Roles (4.5)

| Abreviatura | Rol en la base |
| :-- | :-- |
| **M** | `mesero` |
| **BC** | `bar_cocina` |
| **C** | `cajero_admin` con nivel `cajero` |
| **A** | `cajero_admin` con nivel `administrador` |

El servidor revisa el rol en cada operación. La base no sabe quién llama, así que esta tabla es la única defensa. Las pantallas también ocultan lo que no corresponde, pero eso no protege nada.

---

## 6. Operaciones (4.4 y 4.7)

✓ = ya está en el servidor. **Nueva** = hay que agregarla a `protocolo.h`.

### Sesión

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LOGIN` ✓ | Sin sesión | `usuario`, `contrasena` | `id_usuario`, `nombre`, `usuario`, `fecha_nacimiento`, `rol`, y su dato de puesto: `turno_asignado`, `estacion_asignada` o `nivel_acceso` + `caja_asignada`. Con D5, también `token` | `CREDENCIALES_INVALIDAS` |
| `OP_REANUDAR_SESION` **Nueva** (D5) | Sin sesión | `token` | Lo mismo que `OP_LOGIN` | `NO_AUTENTICADO` |
| `OP_LOGOUT` ✓ | Con sesión | Nada | `null` | |
| `OP_EVENTO_EN_CURSO` **Nueva** | Sin sesión (lo muestra el login) | Nada | `numero_evento`, `fecha`, `tipo_evento`, `numero_asistentes`, `estado`, `organizadores: [texto]`, o `null` | |

### Mesas y cuentas

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LISTAR_MESAS` **Nueva** | M, C, A | `numero_evento` | `[{numero_mesa, id_mesero, mesero, mia}]`; las del mesero primero | `SIN_EVENTO` |
| `OP_LISTAR_CUENTAS` **Nueva** | M, C, A | `numero_evento`, `numero_mesa` | Las abiertas: `[{secuencial, numero_mesa, nombre, folio, cuenta, total}]` | `NO_EXISTE` |
| `OP_CREAR_CUENTA` **Nueva** | M, C, A | `numero_evento`, `numero_mesa`, `nombre` (hasta 60) | La cuenta, con la misma forma | `VALIDACION_FALLIDA`, `YA_EXISTE`, `NO_EXISTE`, `REGLA_INCUMPLIDA` |

### Productos

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LISTAR_PRODUCTOS` ✓ | Con sesión | Nada | `[{id_producto, nombre, descripcion, categoria, precio, id_producto_principal, variante_de, ingredientes: [texto], maximo, disponible}]` | |
| `OP_OBTENER_PRODUCTO` | A | `id_producto` | Lo mismo que en la lista, más `receta: [{id_ingrediente, ingrediente, unidad_medida, cantidad_por_porcion}]` | `NO_EXISTE` |
| `OP_CREAR_PRODUCTO` | A | `nombre`, `descripcion`, `categoria`, `precio`, `id_producto_principal` | El producto | `VALIDACION_FALLIDA`, `YA_EXISTE`, `REGLA_INCUMPLIDA` |
| `OP_MODIFICAR_PRODUCTO` | A | Lo mismo, con `id_producto` | El producto | Los mismos y `NO_EXISTE` |
| `OP_GUARDAR_RECETA` **Nueva** | A | `id_producto`, `receta: [{id_ingrediente, cantidad_por_porcion}]` | El producto con su receta | `VALIDACION_FALLIDA`, `NO_EXISTE` |
| `OP_ELIMINAR_PRODUCTO` | A | `id_producto` | `null` | `NO_EXISTE`, `EN_USO` si ya tiene comandas |

- **`maximo`:** cuántas unidades alcanzan con el stock actual; sin receta vale 99, igual que en la `Api` simulada. No cuenta lo que ya está pedido y sigue pendiente.
- **`OP_GUARDAR_RECETA`:** reemplaza la receta completa en una transacción, y una lista vacía deja el producto sin receta. Cada `cantidad_por_porcion` debe ser mayor que 0 y cada ingrediente aparece una vez.
- **Cambiar una receta:** vale para lo que se prepare después. Una comanda pendiente descuenta con la receta vigente cuando pasa a preparación; una ya preparada no cambia.

### Comandas

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_CREAR_PEDIDO` | M | `numero_evento`, `secuencial`, `lineas: [{id_producto, cantidad, detalles}]` | `creadas`, `secuencial`, `folio`, `cuenta`, `numero_mesa` | `VALIDACION_FALLIDA`, `NO_EXISTE`, `SIN_STOCK` (D1), `REGLA_INCUMPLIDA` |
| `OP_LISTAR_PEDIDOS` | M, BC | `estacion` (`cocina`, `bar` o `todas`), `id_mesero`, `estados: [texto]`; todos opcionales | Rondas: `[{fecha_hora, numero_evento, secuencial, numero_mesa, folio, nombre_cuenta, cuenta, id_mesero, mesero, total, comandas: [...], lineas: [...]}]` | |
| `OP_CAMBIAR_ESTADO_PEDIDO` | BC a `en_preparacion` y `lista`; M a `entregada`, solo las suyas | `ids: [id_comanda]`, `estado` | `actualizadas` | `VALIDACION_FALLIDA`, `NO_AUTORIZADO`, `SIN_STOCK`, `REGLA_INCUMPLIDA` |
| `OP_ELIMINAR_PEDIDO` | A | `ids: [id_comanda]` | `canceladas`, `saldo` | `VALIDACION_FALLIDA`, `REGLA_INCUMPLIDA` |

- **`OP_CREAR_PEDIDO`:** cada unidad es una comanda. Es la operación que guarda `id_mesero` a partir de la sesión, no de lo que mande el cliente.
- **`OP_CAMBIAR_ESTADO_PEDIDO`:** guarda en `id_bar_cocina` al usuario de la sesión. Aunque la base permite saltar estados hacia adelante, el servidor solo acepta los de la `Api` simulada: `pendiente` → `en_preparacion` o `lista`; `en_preparacion` → `lista`; `lista` → `entregada`.
- **`OP_ELIMINAR_PEDIDO`:** cancela, no borra, y guarda en `id_cajero_cancela` al usuario de la sesión. Hasta que exista 3.13, el servidor rechaza cancelar en una cuenta cerrada o dejar lo pagado por encima del consumo. Una comanda pendiente no consumió stock; una ya preparada no lo devuelve.

Cada elemento de `comandas` lleva `id_comanda`, `id_producto`, `producto`, `categoria`, `estacion`, `estado`, `detalles` y `precio_cobrado`. Cada elemento de `lineas` junta las iguales: `id_producto`, `producto`, `detalles`, `estado`, `estacion`, `cantidad`, `ids`.

### Caja

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LISTAR_CUENTAS_CAJA` **Nueva** | C, A | `numero_evento` | `[{secuencial, numero_mesa, nombre, folio, cuenta, estado, cancelada, id_mesero, mesero, fecha_hora, total, pagado, saldo, por_terminar}]`, de `v_cuenta` | `SIN_EVENTO` |
| `OP_DETALLE_CUENTA` **Nueva** | C, A | `numero_evento`, `secuencial` | `secuencial`, `lineas: [{id_producto, producto, estado, precio, cantidad, ids}]`, `pagos: [{numero_pago, monto, forma_pago, monto_propina, fecha_hora, mesero_propina}]` | `NO_EXISTE` |
| `OP_REGISTRAR_PAGO` **Nueva** | C, A | `numero_evento`, `secuencial`, `monto`, `forma_pago`, `monto_propina` | `saldo` | `VALIDACION_FALLIDA`, `NO_EXISTE`, `REGLA_INCUMPLIDA` |
| `OP_CERRAR_CUENTA` **Nueva** | C, A | `numero_evento`, `secuencial` | `null` | `NO_EXISTE`, `REGLA_INCUMPLIDA` |
| `OP_CANCELAR_CUENTA` **Nueva** | A | `numero_evento`, `secuencial` | `null` | `NO_EXISTE`, `REGLA_INCUMPLIDA` |

- **`OP_REGISTRAR_PAGO`:** `monto` incluye la propina. Guarda en `id_cajero` al usuario de la sesión, y en `id_mesero_propina` al mesero de la mesa si hay propina.
- **`OP_CANCELAR_CUENTA`:** en una transacción, cancela sus comandas y la cierra. Se rechaza si la cuenta ya tiene pagos.

### Ingredientes

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LISTAR_INGREDIENTES` | A | Nada | `[{id_ingrediente, nombre, unidad_medida, stock, stock_minimo, usos, productos: [texto]}]`, por nombre | |
| `OP_CREAR_INGREDIENTE` | A | `nombre`, `unidad_medida` (`g`, `ml` o `pieza`), `stock`, `stock_minimo` | El ingrediente | `VALIDACION_FALLIDA`, `YA_EXISTE` |
| `OP_MODIFICAR_INGREDIENTE` | A | Lo mismo, con `id_ingrediente` | El ingrediente | Los mismos y `NO_EXISTE` |
| `OP_AJUSTAR_STOCK` **Nueva** | A | `id_ingrediente`, `delta` | El ingrediente | `NO_EXISTE` |
| `OP_ELIMINAR_INGREDIENTE` | A | `id_ingrediente` | `null` | `NO_EXISTE`, `EN_USO` (D6) |
| `OP_REINICIAR_STOCK` **Nueva** | A | Nada | `null` | |

`OP_AJUSTAR_STOCK` es aparte de `OP_MODIFICAR_INGREDIENTE` para que el servidor sume sobre el valor actual: si dos personas ajustan a la vez, no se pisan.

### Usuarios

| Operación | Quién | `datos` que recibe | `datos` que regresa | Errores |
| :-- | :-- | :-- | :-- | :-- |
| `OP_LISTAR_USUARIOS` | A | Nada | Los campos de `OP_LOGIN` para cada uno, más `es_yo` y `motivo_sin_baja` | |
| `OP_CREAR_USUARIO` | A | `nombre`, `usuario`, `fecha_nacimiento`, `contrasena`, `rol` y su dato de puesto | El usuario | `VALIDACION_FALLIDA`, `YA_EXISTE` |
| `OP_MODIFICAR_USUARIO` | A | Lo mismo, con `id_usuario`; `contrasena` vacía no la cambia y `rol` no puede cambiar | El usuario | Los mismos y `NO_EXISTE` |
| `OP_ELIMINAR_USUARIO` | A | `id_usuario` | `null` | `NO_EXISTE`, `EN_USO`, `VALIDACION_FALLIDA` si es uno mismo |

La contraseña se revisa con `validar_password` del sistema en C. El hash nunca sale del servidor. Un administrador no puede quitarse su propio nivel ni eliminarse.

### Sin definir o sin pantalla

| Operación | Propuesta |
| :-- | :-- |
| `OP_LISTAR_LOGS`, `OP_VER_LOG` | Definirlas cuando se resuelva 3.6; solo A |
| `OP_RECUPERAR_PASS`, `OP_VERIFICAR_USUARIO` | No se hacen (D4): el administrador cambia la contraseña con `OP_MODIFICAR_USUARIO` |
| `OP_OBTENER_USUARIO`, `OP_OBTENER_INGREDIENTE`, `OP_OBTENER_PEDIDO`, `OP_VERIFICAR_DISPONIBILIDAD_PRODUCTO` | Ninguna pantalla las usa: los listados ya traen esos datos. Siguen respondiendo `NO_IMPLEMENTADA` hasta que hagan falta |

---

## 7. Avisos

Los manda el servidor después del `COMMIT`. Casi todos solo le dicen a la pantalla que vuelva a pedir sus datos; corresponden a las señales de la `Api` simulada.

| Aviso | Para quién | `datos` | Señal en el cliente |
| :-- | :-- | :-- | :-- |
| `COMANDA_CAMBIO` | Con sesión, salvo que se limite después | `null` | `comandasCambiaron` |
| `COMANDA_LISTA` | Solo las conexiones del mesero que la levantó | `id_mesero`, `numero_mesa`, `cuenta`, `productos: ["2× Refresco"]`; uno por ronda | `ordenLista` |
| `CUENTA_CAMBIO` **Nuevo** | M, C, A | `null` | `cuentasCambiaron` |
| `INVENTARIO_CAMBIO` **Nuevo** | Con sesión | `null` | `inventarioCambio` |
| `USUARIOS_CAMBIO` **Nuevo** | A | `null` | `usuariosCambiaron` |

`PENDIENTES.md` solo tenía los dos primeros, y `COMANDA_LISTA` llevaba un `id_comanda`. Aquí usa los campos que la pantalla ya muestra.

---

## 8. Qué cambia con este contrato

**Base (Samy):**

- D2: usar `CM001` y `CM002` en los disparadores.
- D3: índice único para el evento en curso.
- Las partes ya anotadas: 2.6, 2.7, 3.9, 3.12 y 3.13.

**Servidor:**

- Agregar las operaciones nuevas a `protocolo.h`.
- Traducir los errores como en la sección 4.
- Mandar `mensaje` en las respuestas correctas.
- Revisar los roles de la sección 6.

**Cliente:**

- `Api.qml`: dejar de apartar stock al pedir (D1) y no quitar ingredientes de las recetas (D6).
- `DialogoIngrediente.qml`: unidad, mínimo y decimales (D7).
- `PantallaLogin.qml`: quitar "Crear usuario" y "Recuperar contraseña" (D4).
- Admin › Productos: catálogo y editor de receta (D9).
- Cambiar los códigos de error por los de la sección 4.
- `Api` real (7.2): convertir el dinero y las fechas, agregar `numero_evento` y reconectar (D5).

**`PENDIENTES.md`:**

- 6.6 pide `SIN_STOCK` al crear el pedido: depende de D1.
- 7.6 ya refleja D4 y D9.
- La tabla de operaciones de la Fase 4 se reemplaza por este documento.
