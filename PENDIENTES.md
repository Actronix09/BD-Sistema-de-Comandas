# Pendientes del Sistema de Comandas

Lo que falta para terminar el sistema, dividido en fases. Sirve para ponernos de acuerdo en qué sigue y quién lo hace: cada parte tiene una columna **Responsable** y una casilla para marcarla cuando esté lista.

**Actualizado:** 1 de noviembre de 2026

**Hacia dónde va:** el programa en C (memoria compartida, ncurses y archivos de texto) pasa a ser una aplicación con interfaz gráfica para Windows, Linux y Android, **toda en C++ con Qt**.

```
 PC de caja                                       PC y celulares (todos los roles)
┌──────────────────────────────────┐             ┌───────────────────────────────┐
│ Servidor (C++ con Qt)            │  WiFi del   │ App cliente (C++ con Qt)      │
│  · QWebSocketServer + JSON       │◀──salón───▶ │  · Pantallas en QML           │
│  · Lógica que ya está en C       │             │  · Conexión C++ (QWebSocket)  │
│  · QtSql (driver QPSQL)          │             │  · Misma app en PC y Android  │
│        │                         │             └───────────────────────────────┘
│        ▼                         │
│ PostgreSQL 16.4 (Podman)         │
└──────────────────────────────────┘
```

- **Cliente:** una sola app que se compila para Windows, Linux y Android. Cualquier usuario entra desde la PC o desde el celular, según su rol.
- **Servidor:** solo en la PC de caja, junto con la base. Aprovecha la lógica que ya está en C; lo que cambia es cómo se comunica (sockets de Qt en lugar de memoria compartida) y dónde guarda (PostgreSQL en lugar de archivos).

---

## Lo que ya está hecho

| Qué | Dónde |
| :-- | :-- |
| Esquema de 17 tablas, con disparadores, índices, vistas y comentarios | `sql/esquema.sql` |
| Documentación del modelo (EER, reglas de transformación, modelo relacional, diccionario) y diagramas, ya con Saldo | `docs/`, `modelo/` |
| Datos de ejemplo: evento 17 con 3 mesas, 3 cuentas, 5 comandas, un pago con propina y el inventario | `sql/datos-ejemplo.sql` |
| `make -C sql pruebas`: recrea la base de pruebas y corre todo | `sql/Makefile` |
| 34 inserts rechazados, todos pasan | `sql/inserts-rechazados.sql` |
| 13 casos válidos, todos pasan | `sql/pruebas-validas.sql` |
| Máquina de estados de la comanda: solo avanza, se puede cancelar desde cualquier estado y una cancelada ya no cambia | `validar_cambio_estado()` |
| `v_cuenta` con `total_acumulado`, `total_pagado` y `saldo` | `sql/esquema.sql` |
| Reglas del cobro: pago ≤ saldo, propina ≤ monto, cierre sin adeudo ni comandas abiertas, no pedir en cuenta cerrada | `tg_pago_saldo`, `ck_pago_propina_limite`, `tg_cuenta_cierre`, `tg_comanda_cuenta_abierta` |
| Precio cobrado siempre del catálogo, nombres únicos sin importar mayúsculas, sin comandas en eventos finalizados y estación por categoría | `fijar_precio_cobrado()`, índices `ux_*_minusculas`, `tg_comanda_evento`, `tg_comanda_estacion` |
| Prototipo de la interfaz en QML (login, mesero, cocina/bar, admin e ingredientes) | Repo `Sistema-de-Comandas`, `prototipos/qml/` |
| Cliente en C++/Qt con Material, las correcciones C1–C8 y C11 del lado del cliente, la pantalla Caja y pantallas adaptables, todo sobre la `Api` simulada | Repo `Sistema-de-Comandas`, `cliente/` (rama `Interfaz-grafica-profesional-V1`) |

## Cómo trabajamos

- **Solo el servidor toca la base.** Ninguna pantalla lee ni escribe en la base directamente.
- **Lo que la base ya protege no se repite en el servidor.** El descuento de stock, la máquina de estados y las reglas del cobro viven en disparadores. Si el servidor también los hace, se hacen dos veces.
- Cada regla nueva de la base lleva tres cosas: su disparador o `CHECK`, un caso en `inserts-rechazados.sql` y un caso en `pruebas-validas.sql`. **Primero el disparador** y después los casos. Si no, el Makefile marca el rechazo como fallido.
- Antes de cada commit, `make -C sql pruebas` debe terminar en `Todas las pruebas pasaron`.
- Numeración: el siguiente rechazo es el **35** y el siguiente caso válido es el **14**.
- Los disparadores lanzan `RAISE EXCEPTION … USING ERRCODE = 'check_violation'`, igual que `fijar_precio_cobrado()`.

## Reparto

| Quién | Qué | Partes |
| :-- | :-- | :-- |
| Samy | Terminar las pruebas de la base: cada regla con su disparador, sus rechazos, su caso válido y su documentación | Correcciones de la revisión: 2.4, 2.6–2.8, 3.9–3.11; y 3.8. Para los perfiles y las cancelaciones del cliente: 3.12 y 3.13 |
| @Actronix09 | La interfaz y el sistema en QML: el proyecto del cliente, la `Api` simulada y las pantallas | 4.1 y Fase 7 completa |
| Ambos | Lo que afecta a la base y a las pantallas a la vez | Decisiones 3.3, 3.5, 3.6, 3.7 y 3.14; contrato 4.4–4.7 |

Las fases 5, 6, 8 y 9 se reparten cuando terminen las anteriores.

Para no estorbarnos:
- **Cada quien en su carpeta y en su rama.** Samy trabaja en `sql/` y `docs/`; @Actronix09, en el cliente. Los cambios entran a `main` por PR.
- **Los números de los casos son de Samy.** Como solo una persona agrega rechazos y casos válidos, no hay choques en la numeración.
- **Cada regla nueva se avisa con su mensaje de error.** Samy pasa el texto del error y @Actronix09 lo agrega a la `Api` simulada. Así las pantallas ya muestran esos errores antes de que exista el servidor, y de ahí salen los códigos de 4.6. Los de la Fase 2 ya están en `esquema.sql` (por ejemplo, "el pago excede el saldo de la cuenta (95.00)").

---

## Fase 1: Cerrar lo que está en curso

**Objetivo:** dejar el repo de la base en verde antes de empezar reglas nuevas.
**Depende de:** nada.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 1.1 | - [x] Caso válido 12: pagos parciales | Cuenta propia con Refresco y Pastel (130; la Pasta no sirve porque el caso 1 le sube el precio). Paga 100 → saldo 30; paga 65 con 35 de propina al mesero 1 → saldo 0 y `total_pagado` 130 | `Válidas: 12 de 12` ✓ | |
| 1.2 | - [x] Contadores de los `\warn` | Los `✓ N de 11` pasaron a `de 12` | La salida dice `de 12` ✓ | |
| 1.3 | - [x] Comprobar que el caso detecta el error | Sin la resta de la propina en `v_cuenta`, el caso falla con saldo −35.00 | Comprobado ✓ | |
| 1.4 | - [x] Commit | Caso 12 + contadores | Subido en `e90730e` ✓ | |

---

## Fase 2: Reglas del cobro en la base

**Objetivo:** que la base no deje cobrar de más, cerrar una cuenta con adeudo ni pedir en una cuenta cerrada.
**Depende de:** Fase 1, porque B y C usan el `saldo`.

Decisiones que ya están tomadas:
- `pago.monto` **incluye** la propina: lo que paga el consumo es `monto − monto_propina`.
- Una cuenta puede tener varios pagos.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 2.1 | - [x] **B:** un pago no excede el saldo | `tg_pago_saldo` compara `monto − propina` contra el `saldo` y bloquea la cuenta (`FOR UPDATE`) para que dos pagos a la vez no se pasen. `ck_pago_propina_limite`. El caso válido 8 ahora paga 145 (pastel de 95 + 50 de propina) | Rechazos 24 y 25; casos válidos 8 y 13 ✓ |  Samy |
| 2.2 | - [x] **C:** cerrar una cuenta | `tg_cuenta_cierre`: todas sus comandas en `entregada` o `cancelada` y `saldo` 0. Quién cierra lo decide el servidor (sugerencia: el cajero, a mano) | Rechazos 26 y 27; caso válido 13 ✓ |  Samy |
| 2.3 | - [x] **D:** no pedir en una cuenta cerrada | `tg_comanda_cuenta_abierta` | Rechazo 28 ✓ |  Samy |
| 2.4 | - [ ] Documentación | Ya están: `pago.monto` en el diccionario y las filas del cobro en `ModeloRelacional.md`. **Falta:** (1) la sección "Validaciones de catalogo y operacion" está copiada igual en `DiccionarioDeDatos.md` y `ModeloRelacional.md` y sin acentos: dejarla en un solo lugar y con acentos; (2) en `ModeloRelacional.md`, las reglas de los rechazos 29–34 van como filas de la tabla de reglas, igual que las del cobro; (3) `ReglasDeTransformacion.md` no se actualizó | Los documentos coinciden con el esquema |  Samy |
| 2.5 | - [x] Commit | Reglas B, C y D | Subido en `d3d9de0` (PR #29) ✓ |  Samy |
| 2.6 | - [ ] Pagos a una cuenta cerrada | Hoy se acepta un pago que es **solo propina** (monto = propina) en una cuenta cerrada, porque el consumo es 0 y 0 ≤ saldo 0. Que `validar_pago_saldo` rechace cualquier pago a una cuenta cerrada | Rechazo: pago de solo propina a una cuenta cerrada |  Samy |
| 2.7 | - [ ] **Decidir:** ¿cerrar es definitivo? | Hoy una cuenta pasa de `cerrada` a `abierta` con un `UPDATE` y se le vuelve a pedir, lo que brinca la regla D. Si cerrar es definitivo, rechazarlo en `validar_cierre_cuenta` | Decisión escrita; si es definitivo, su rechazo |  Ambos deciden; la regla, Samy |
| 2.8 | - [ ] Caso válido de D | La regla D no tiene caso válido. Se puede agregar al caso 13: después de abrir la nueva "Novios", levantarle una comanda | Caso válido que pide en la cuenta nueva |  Samy |

---

## Fase 3: Reglas abiertas y decisiones del esquema

**Objetivo:** cerrar los huecos que encontró la revisión del esquema y tomar las decisiones que el servidor necesita.
**Depende de:** nada. Puede ir en paralelo con la Fase 2, cuidando la numeración de los casos.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 3.1 | - [x] `precio_cobrado` siempre del catálogo | `fijar_precio_cobrado()` ignora el precio enviado y copia `producto.precio` | Caso válido 1 ✓ |  Samy |
| 3.2 | - [x] Nombres únicos sin importar mayúsculas | `ux_usuario_usuario_minusculas` y `ux_ingrediente_nombre_minusculas` | Rechazos 29 y 30 ✓ |  Samy |
| 3.3 | - [ ] **Decidir:** estación de cada producto | Regla hecha: sale de `producto.categoria`, bebidas → bar; alimentos y **dulcería → cocina** (`tg_comanda_estacion`, rechazos 32–34). Coincide con el prototipo. **Falta que @Actronix09 confirme** que la dulcería va a cocina | Decisión confirmada |  Ambos deciden; la regla, Samy |
| 3.4 | - [x] Evento finalizado | `tg_comanda_evento` | Rechazo 31 ✓ |  Samy |
| 3.5 | - [ ] **Decidir:** rondas para cocina | ¿Cocina agrupa por cuenta + `fecha_hora` o se crea una entidad `ronda`? | Decisión escrita; si es entidad, tabla y diagramas |  Ambos |
| 3.6 | - [ ] **Decidir:** dónde viven los logs | ¿Tabla de bitácora en la base o archivos en un volumen? | Decisión escrita |  Ambos |
| 3.7 | - [ ] Mínimos que el SQL no hace cumplir | Todo evento con al menos una mesa (*Pertenece*) y todo producto con al menos un ingrediente (*Receta*). ¿Se hacen cumplir en la base o los valida la aplicación? | Decisión anotada en `ReglasDeTransformacion.md` |  Ambos |
| 3.8 | - [ ] *(Opcional)* Capturas de `ModeloRelacional.md` | Las capturas todavía dicen 20 rechazos y 4 comandas. Si el documento es el reporte de la Práctica 3 como se entregó, mejor dejarlo así | Decisión tomada |  Samy |
| 3.9 | - [ ] Eventos cancelados | `tg_comanda_evento` solo bloquea `finalizado`; un evento `cancelado` sigue aceptando comandas. Cambiar a `IN ('finalizado', 'cancelado')`. *(Menor)* También se pueden abrir cuentas nuevas en un evento finalizado: decidir si se bloquea | Rechazo: comanda en un evento cancelado |  Samy |
| 3.10 | - [ ] Casos válidos que faltan | Cada regla lleva su caso válido. Faltan: **estación** (cocina prepara el pastel de dulcería y bar prepara el refresco; es el más importante, porque fija la decisión de 3.3), evento (comanda en un evento `en_curso`) y mayúsculas (un nombre distinto sí entra) | Un caso válido por regla |  Samy |
| 3.11 | - [ ] Limpieza del esquema | Los mensajes de error van sin acentos ("el evento % esta finalizado", "la categoria %") y los demás del esquema sí los llevan. Sobran 4 líneas en blanco después de `v_comanda` | `make -C sql pruebas` sigue en verde |  Samy |
| 3.12 | - [ ] Perfiles en `datos-ejemplo.sql` | El cliente ya separa los niveles de 4.5: `mrivas` es `cajero` y hay una administradora nueva, `dcampos` (id 6, "Daniela Campos Vega", nacida el 1982-03-15, caja 2). En `datos-ejemplo.sql`, `mrivas` sigue como `administrador` y no existe `dcampos`. La comanda cancelada de ejemplo la cancela el usuario 5; en el cliente ya la cancela el 6 | Los datos coinciden con el cliente y `make -C sql pruebas` sigue en verde |  Samy |
| 3.13 | - [ ] Reglas para cancelar comandas | La `Api` simulada las revisa, pero la base no: (1) cancelar una comanda de una cuenta cerrada; (2) cancelar de más en una cuenta con pagos: el `saldo` queda negativo y `tg_cuenta_cierre` ya no deja cerrarla. Mensajes del cliente: "La cuenta está cerrada; sus comandas ya no se pueden cancelar" y "No se puede cancelar: el consumo que queda sería menor que lo ya pagado (35.00)". *(Revisar)* `tg_comanda_estacion` también corre al cambiar `estado`: si a un cocinero le cambian la estación, ya no se pueden cancelar ni avanzar las comandas que preparó, y el cliente permite ese cambio | Un rechazo por regla y un caso válido: cancelar sin pasarse del saldo |  Samy |
| 3.14 | - [ ] **Decidir:** estado de una cuenta cancelada | `ck_cuenta_estado` solo admite `abierta` y `cerrada`. Hoy el cliente cancela todas las comandas, cierra la cuenta y la muestra como "Cancelada" si quedó sin pagos y sin comandas activas, así que una cuenta vacía cerrada normalmente también sale como cancelada. La otra opción es agregar el estado `cancelada`: hay que ampliar `cuenta.estado`, que es `VARCHAR(8)`, y actualizar `tg_cuenta_cierre` y la documentación. En ambos casos, una cuenta con pagos no se cancela mientras no se puedan registrar devoluciones | Decisión escrita; si se agrega el estado, su regla y sus casos |  Ambos deciden; la regla, Samy |

---

## Fase 4: Decisiones del sistema y contrato de mensajes

**Objetivo:** fijar lo que necesitan el servidor y el cliente para trabajar por separado.
**Depende de:** nada. Se puede hacer mientras avanzan las fases 1–3.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 4.1 | - [x] **D1:** estilo visual | **Material**, el que abre `./ejecutar.sh` sin opciones. Se fija dentro de la app (no por variable de entorno) para que se vea igual en Windows, Linux y Android | Decidido ✓ |  @Actronix09 |
| 4.2 | - [x] **D2:** lenguaje del cliente | **C++ con Qt en todas las plataformas.** Las pantallas en QML; la conexión y el arranque en C++ | Decidido ✓ | |
| 4.3 | - [x] Servidor | **C++ con Qt**, en la PC de caja: `QWebSocketServer` con mensajes JSON, `QtSql` con el driver `QPSQL` y la lógica que ya está en C | Decidido ✓ | |
| 4.4 | - [ ] Contrato de mensajes | Para cada operación (tabla abajo): qué `datos` recibe, qué devuelve, qué errores puede dar y qué rol la puede usar | Documento del contrato en el repo |  Ambos |
| 4.5 | - [ ] Roles y permisos | Mesero → `mesero`. Cocina → `bar_cocina` con estación. Admin → `cajero_admin`: con nivel `cajero` solo cobra y cierra cuentas; con nivel `administrador`, además maneja el catálogo y los usuarios y cancela comandas | Tabla de permisos por operación |  Ambos |
| 4.6 | - [ ] Códigos de error | Cómo se traduce cada error de la base a un código claro. Ejemplo: el `check_violation` de stock → `SIN_STOCK`; una violación de clave única → `YA_EXISTE` | Lista de códigos |  Ambos |
| 4.7 | - [ ] Operaciones nuevas | Las que el sistema en C no tenía y piden el modelo y el prototipo: mesas y cuentas (C5), cobro (C4) y avisos (C11). Ver la segunda tabla | Agregadas al contrato |  Ambos |

**Formato de los mensajes.** Todo viaja como JSON por un solo WebSocket. Cada petición lleva un `id` para emparejarla con su respuesta, y `op` con el nombre de `protocolo.h`:

```json
→ {"id": 7, "op": "OP_CREAR_PEDIDO", "datos": {"numero_evento": 17, "secuencial": 1, "productos": [1, 1, 3]}}
← {"id": 7, "ok": true,  "datos": {"comandas": [41, 42, 43]}}
← {"id": 7, "ok": false, "error": {"codigo": "SIN_STOCK", "mensaje": "No hay stock suficiente de Queso parmesano"}}
← {"aviso": "COMANDA_LISTA", "datos": {"id_comanda": 41, "mesa": 1, "cuenta": "Novios · 17-1-1"}}
```

- Los **avisos** no llevan `id`: el servidor los manda sin que nadie pregunte.
- La **sesión** vive en la conexión: después de `OP_LOGIN`, el servidor recuerda el usuario y el rol de ese socket. Si el celular se desconecta, al reconectar repite el login (o manda un token, si se decide usar uno).
- El **dinero** viaja como texto (`"95.00"`), nunca como número con decimales.

| Operaciones que ya existen en `protocolo.h` | Qué hacen ahora |
| :-- | :-- |
| `OP_LOGIN`, `OP_LOGOUT` | Abrir y cerrar la sesión de la conexión |
| `OP_CREAR_USUARIO`, `OP_VERIFICAR_USUARIO`, `OP_RECUPERAR_PASS` | Alta de usuario, revisar si un nombre está libre y cambiar la contraseña |
| `OP_LISTAR_USUARIOS`, `OP_OBTENER_USUARIO`, `OP_MODIFICAR_USUARIO`, `OP_ELIMINAR_USUARIO` | Administración de usuarios |
| `OP_LISTAR_PRODUCTOS`, `OP_OBTENER_PRODUCTO`, `OP_CREAR_PRODUCTO`, `OP_MODIFICAR_PRODUCTO`, `OP_ELIMINAR_PRODUCTO`, `OP_VERIFICAR_DISPONIBILIDAD_PRODUCTO` | Catálogo con su receta. La disponibilidad sale de la vista `v_producto` |
| `OP_LISTAR_INGREDIENTES`, `OP_OBTENER_INGREDIENTE`, `OP_CREAR_INGREDIENTE`, `OP_MODIFICAR_INGREDIENTE`, `OP_ELIMINAR_INGREDIENTE` | Inventario |
| `OP_CREAR_PEDIDO` | Una lista de productos se vuelve N comandas, **en una sola transacción** |
| `OP_LISTAR_PEDIDOS`, `OP_OBTENER_PEDIDO`, `OP_CAMBIAR_ESTADO_PEDIDO`, `OP_ELIMINAR_PEDIDO` | Comandas y sus estados. `OP_ELIMINAR_PEDIDO` pasa a ser **cancelar**: la base no deja borrar lo que ya se cobró |
| `OP_LISTAR_LOGS`, `OP_VER_LOG` | Bitácora (depende de la decisión 3.6) |

| Operaciones nuevas (propuesta) | Para qué |
| :-- | :-- |
| `OP_LISTAR_MESAS`, `OP_LISTAR_CUENTAS`, `OP_CREAR_CUENTA` | El flujo mesa → cuenta → productos (C5) |
| `OP_REGISTRAR_PAGO`, `OP_CERRAR_CUENTA` | La pantalla Caja (C4) |
| Aviso `COMANDA_CAMBIO` | Cocina/bar y caja ven los cambios sin recargar |
| Aviso `COMANDA_LISTA` | Solo al mesero que levantó la comanda (C11) |

---

## Fase 5: Contenedores con Podman

**Objetivo:** levantar la base del sistema con un solo comando, sin chocar con el contenedor de las prácticas.
**Depende de:** Fase 2, para que el esquema que se monte ya tenga las reglas del cobro.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 5.1 | - [ ] Instalar Podman | `sudo pacman -S podman podman-compose`. Puede convivir con Docker | `podman --version` | |
| 5.2 | - [ ] `compose.yaml` con el servicio `db` | Imagen `docker.io/library/postgres:16.4-alpine`. Proyecto `comandas`, volumen `comandas-pgdata` y puerto `5433:5432`, para no chocar con `practica1-postgres`. `healthcheck` con `pg_isready` | `podman compose up -d` y la base responde en el 5433 | |
| 5.3 | - [ ] Carga inicial | `db/init/` con `esquema.sql` y `datos-ejemplo.sql`, montada en `/docker-entrypoint-initdb.d`. Solo corre con el volumen vacío | La base arranca con datos | |
| 5.4 | - [ ] Credenciales | `.env` fuera de git y `.env.example` de muestra | `.env` en `.gitignore` | |
| 5.5 | - [ ] Pruebas con Podman | `make -C sql pruebas MOTOR=podman` | Todas pasan | |
| 5.6 | - [ ] Arranque automático | Quadlet (systemd) en la PC de caja con Linux, o Podman Desktop en Windows | La base arranca al prender la PC | |

Ojo: `podman compose down -v` borra el volumen con todos los datos.

---

## Fase 6: Servidor (C++ con Qt)

**Objetivo:** el servidor del contrato de la Fase 4, en la PC de caja. Es lo único que toca la base.
**Depende de:** fases 4 y 5.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 6.1 | - [ ] Proyecto | `servidor/` con CMake y Qt 6 (`Core`, `WebSockets`, `Sql`). Los archivos `.c` que se conserven se compilan dentro del proyecto (con `extern "C"` en sus `.h`) | Compila y arranca | |
| 6.2 | - [ ] Conexión con la base | `QSqlDatabase` con el driver `QPSQL` hacia el contenedor (puerto 5433). Datos de conexión desde el `.env` o un archivo de configuración, no en el código | El servidor consulta `v_cuenta` | |
| 6.3 | - [ ] `QWebSocketServer` | Escucha en la red local (`QHostAddress::Any`). Por cada mensaje: leer el JSON, revisar el rol de la conexión y mandarlo a la función de su `op`. Es el `switch` de `Servidor.c`, pero leyendo JSON en lugar de la memoria compartida | Un cliente de prueba hace login y lista productos | |
| 6.4 | - [ ] Lógica en C → PostgreSQL | Pasar cada módulo según la tabla de abajo: lo que leía o escribía archivos ahora hace consultas | Cada operación del contrato funciona | |
| 6.5 | - [ ] Sesión y permisos | Usuario y rol guardados por conexión después de `OP_LOGIN`, **revisados en cada operación**. Contraseñas con Argon2id o bcrypt (por ejemplo con libsodium) en lugar de SHA-256 sin sal; nunca se devuelven al cliente | Un mesero no puede crear usuarios | |
| 6.6 | - [ ] Transacciones y errores | `OP_CREAR_PEDIDO` dentro de `transaction()` / `commit()`, con `rollback()` si falla una comanda. El `SQLSTATE` del error de la base (`QSqlError::nativeErrorCode()`) se traduce a los códigos de la Fase 4 | Pedido con un producto sin stock: no se guarda ninguna comanda y llega `SIN_STOCK` | |
| 6.7 | - [ ] Dinero | Nada de `float`: hoy `productos_agregar` recibe el precio como `float`. Usar texto o centavos enteros (`qint64`) entre la base y el JSON | Precios exactos en todas las respuestas | |
| 6.8 | - [ ] Avisos | Al cambiar una comanda, mandar `COMANDA_CAMBIO` a cocina/bar y caja, y `COMANDA_LISTA` solo a la conexión del mesero que la levantó (C11) | El mesero recibe el aviso en el celular | |
| 6.9 | - [ ] Pruebas | Qt Test contra la base de prueba (`comandas_pruebas`) | Todas pasan | |
| 6.10 | - [ ] Arranque en la PC de caja | Que el servidor arranque solo, después de la base: un servicio de systemd en Linux, o una tarea al iniciar sesión en Windows | Al prender la PC, los celulares se pueden conectar | |

Qué pasa con cada parte del sistema en C:

| Archivo | Qué hace hoy | En el servidor nuevo |
| :-- | :-- | :-- |
| `Servidor.c` | Memoria compartida, semáforos, hilos y un `switch` por `OP_*` | **Se conserva el `switch`** como despachador. La memoria compartida y los semáforos se reemplazan por `QWebSocketServer` |
| `protocolo.h` | Los `OP_*` y los `struct` que viajan por memoria compartida | **Se conservan los nombres `OP_*`**. Los `struct` se reemplazan por JSON |
| `usuario.c`, `usuarios.c` | Usuarios en archivo; `validar_password`; SHA-256 | **Se conserva `validar_password`**. Se quitan `validar_email` y `validar_telefono` (ya no hay correo ni teléfono). Cargar y guardar → SQL. SHA-256 → Argon2id o bcrypt |
| `recuperar_password.c` | Verifica el usuario y aplica la contraseña nueva | Se conserva la lógica, pero el cambio lo autoriza un administrador |
| `productos.c` | Catálogo en archivo; verifica disponibilidad | Consultas a `producto` y `receta`. La disponibilidad sale de `v_producto` |
| `inventario.c` | Stock en archivo; `inventario_actualizar_stock` | Consultas a `ingrediente`. **Se quita el descuento de stock**: lo hace el disparador de `comanda` |
| `pedidos.c` | Pedidos en archivo, con varios productos | `pedidos_crear` → N comandas en una transacción. `pedidos_cambiar_estado` → un `UPDATE`; la base revisa la máquina de estados |
| `logger.c` | Dos hilos que escriben archivos `.log` | Se conserva la idea; el destino depende de la decisión 3.6 |
| `Cliente.c`, `interfaces.c`, `ui.c`, `sesion.c` | Interfaz en ncurses | Se reemplazan por la app en QML (Fase 7) |

Errores del sistema en C que **no** se deben repetir:
- El servidor no revisa quién llama: `OP_CREAR_USUARIO` acepta crear un administrador (`Servidor.c:168`).
- Contraseñas en SHA-256 sin sal, y al editar un usuario desde admin la contraseña se guarda en claro (`interfaces.c:3402`).
- Los listados se cortan en 50 resultados.
- Recuperar la contraseña no verifica la identidad: mejor que el cambio lo haga un administrador.

---

## Fase 7: Cliente real (Qt Quick)

**Objetivo:** la aplicación que usan meseros, cocina/bar y caja.
**Depende de:** las decisiones 4.1 y 4.2 y el contrato 4.4. No hay que esperar a las fases 2 y 3: mientras no esté el servidor, se trabaja con la `Api` simulada (`cliente/Comandas/Api.qml`). La Caja ya usa las reglas del cobro de la base (2.1–2.3) con sus mismos mensajes.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 7.1 | - [x] Proyecto `cliente/` | CMake + Qt 6.8 en C++ con `qt_add_qml_module`; el estilo Material va en `qtquickcontrols2.conf` dentro del ejecutable | Arranca en escritorio ✓ (`2134f6e`) |  @Actronix09 |
| 7.2 | - [ ] `Api` real | Una clase C++ con `QWebSocket`, registrada como singleton de QML, con la misma interfaz que `ApiSimulada.qml`. Arma los mensajes con `id` y `op`, empareja cada respuesta con su petición y convierte los avisos en señales para las pantallas. La dirección del servidor se guarda con `QSettings` | Las pantallas funcionan contra el servidor sin cambios |  @Actronix09 |
| 7.3 | - [x] Correcciones del prototipo | Ver la tabla C1–C11 abajo. Hechas las del cliente; C9 y C10 dependen de otras partes | Cada corrección revisada ✓ |  @Actronix09 |
| 7.4 | - [x] Pantalla **Caja** | Cuentas abiertas → detalle → pagar (forma de pago, monto y propina) → saldo → cerrar cuenta. Está en el menú de administración. Falta conectarla al servidor (7.2) | Cobro completo de una cuenta ✓ (`7c2a24d`) |  @Actronix09 |
| 7.5 | - [x] Pantallas adaptables | Cada pantalla tiene su `compacta` (700–760 px). Probado a 1280, 943 y 400 px | Se usa bien en tamaño de teléfono ✓ (`7ab1a8e`) |  @Actronix09 |
| 7.6 | - [ ] Pantallas pendientes | En orden: 1. Ver logs · 2. Recuperar contraseña · 3. Crear usuario · 4. Admin › Usuarios ✓ (`5c16b68`, sobre la `Api` simulada) · 5. Admin › Productos con receta | Las cinco funcionan |  @Actronix09 |
| 7.7 | - [ ] Android | El botón Atrás regresa de pantalla (`pila.pop()`). Al bloquear el teléfono se cae el WebSocket: reconectar y repetir el login al volver (`Qt.application.state`). Hace falta Qt para Android, el SDK, el NDK y el JDK (los paquetes de Arch no compilan para Android) | La app corre en un teléfono conectado al servidor de la PC |  @Actronix09 |
| 7.8 | - [ ] **Decidir:** teclado en pantalla | En escritorio táctil sin teclado. Qt Virtual Keyboard es GPLv3 o comercial, no LGPL; la otra opción es un teclado propio en QML | Decisión tomada |  @Actronix09 |

Las correcciones salen de las notas que tomamos al revisar el prototipo (el antiguo `Notas.md`, ya integrado aquí y en la nota de Obsidian "Objetivos del Sistema de Comandas"). Las del cliente se aplicaron el 1 de noviembre, una por commit, en la rama `Interfaz-grafica-profesional-V1` de `Sistema-de-Comandas`.

| # | Corrección del prototipo | Qué se pidió en las notas | Dónde | Estado |
| :--: | :-- | :-- | :-- | :-- |
| C1 | Pedidos activos en tarjetas | Los pedidos activos del mesero se ven en forma de tarjeta, no de lista | `VistaMisOrdenes.qml` | ✓ `efcbad4` |
| C2 | Lo listo va primero | Si una orden ya está lista para entregar, se muestra antes que las que todavía no lo están | `VistaMisOrdenes.qml` | ✓ `c316759`, resaltadas con "Para entregar" |
| C3 | Tres formas de organizar | Por tiempo, por cuenta y mesa, y por mesero. En mesero, cocina/bar y caja | `VistaMisOrdenes.qml`, `PantallaCocina.qml`, Caja | ✓ `7d1ac3a`; en Caja agrupa por mesa o mesero |
| C4 | Sistema de cobro | El cobro lo maneja el cajero/administrador | Pantalla Caja (7.4) | ✓ `7c2a24d` |
| C5 | **Mesa → cuenta → productos** | Al tomar la orden se elige primero la mesa, después la cuenta y al final los productos, no al revés | `VistaTomarOrden.qml`, `DialogoConfirmarOrden.qml` | ✓ `d81be05`; ahora el paso nuevo es `ElegirCuenta.qml` |
| C6 | Nombre de la cuenta | La cuenta lleva un nombre que guíe al mesero; el folio se conserva, pero al final: "Novios · 17-1-1" | Todas las tarjetas que muestran la cuenta | ✓ `f1e22ee`; las cuentas nuevas piden nombre |
| C7 | Texto que se sale de las cajas | Corregir el texto que se sale de algunas tarjetas de producto. Revisado el 1 de noviembre: con la ventana angosta, el panel "Orden actual" (370 px fijos) y el buscador (280 px) se cortan; la cuadrícula no baja a 1 columna; en cocina se corta "Cerrar sesión" y los nombres se recortan con "…" ("Pastel de choc…"). Va junto con 7.5 | `TarjetaProducto.qml`, `VistaTomarOrden.qml`, `TarjetaRonda.qml`, `PantallaCocina.qml` | ✓ `7ab1a8e` |
| C8 | Sin teclado | Quitar los números y las acciones con el teclado: la interfaz es táctil o con mouse. Botones de 48 px como mínimo | Mesero, cocina/bar y admin | ✓ `df9da85` |
| C9 | Contenedores | El sistema en contenedores; mejor Podman que Docker | Fase 5 | Pendiente (Fase 5) |
| C10 | Android | La interfaz también funciona en Android | 7.7 | Pantallas listas para teléfono; falta compilar para Android (7.7) |
| C11 | Aviso al mesero | Notificar al mesero cuando su orden está lista | 6.8 (servidor) y el cliente | ✓ en el cliente (`217c35a`, con una cocina simulada); falta el aviso real del servidor (6.8) y la notificación de Android |

---

## Fase 8: Instaladores

**Objetivo:** que el sistema se instale sin compilar nada.
**Depende de:** Fase 7.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 8.1 | - [ ] Linux | AppImage o `.deb` | Se instala en una máquina limpia | |
| 8.2 | - [ ] Windows | Inno Setup sobre la carpeta que genera `windeployqt` | Probado en una máquina virtual | |
| 8.3 | - [ ] Android | APK firmada con llave propia, instalada directamente en los teléfonos del salón | Instalada en un teléfono | |
| 8.4 | - [ ] Compilación automática | GitHub Actions en `ubuntu-latest` y `windows-latest` | Cada push genera los instaladores | |
| 8.5 | - [ ] Instalación de la PC de caja | Instalador del servidor + guía para levantar la base con Podman, abrir el puerto del servidor en el firewall y anotar la IP que usarán los celulares | Alguien más la sigue sin ayuda | |

---

## Fase 9: Funciones nuevas del modelo

**Objetivo:** lo que el modelo de la base ya permite pero el sistema en C nunca tuvo.
**Depende de:** fases 6 y 7.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 9.1 | - [ ] Eventos y mesas | Alta de eventos y de sus mesas con su mesero | | |
| 9.2 | - [ ] Cuentas y folios | Consulta de cuentas por evento y por mesa | | |
| 9.3 | - [x] Cancelación de comandas | Pantalla del administrador, dentro de la Caja; también cancela cuentas. Está sobre la `Api` simulada: falta conectarla al servidor (7.2) y las reglas de la base (3.13) | ✓ (`9df24aa`) |  @Actronix09 |
| 9.4 | - [ ] Anticipos, paquetes y acuerdos | Registro y consulta | | |
| 9.5 | - [ ] Reportes | Ventas por evento, y consumo real contra lo acordado en el paquete | | |

---

## Qué se puede hacer en paralelo

La base (fases 1–3) y las decisiones del sistema (Fase 4) no dependen una de otra. Una vez escrito el contrato de mensajes, el servidor y el cliente también avanzan por separado: el cliente usa la `Api` simulada hasta que el servidor esté listo.

```mermaid
graph LR
    F1[1. Cerrar lo en curso] --> F2[2. Reglas del cobro]
    F3[3. Reglas abiertas]
    F4[4. Decisiones y contrato]
    F2 --> F5[5. Podman]
    F5 --> F6[6. Servidor]
    F4 --> F6
    F4 --> F7[7. Cliente]
    F6 --> F8[8. Instaladores]
    F7 --> F8
    F6 --> F9[9. Funciones nuevas]
    F7 --> F9
```
