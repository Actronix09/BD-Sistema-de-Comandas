# Tipos de dato y dominios

Práctica 4, ejercicio 1.1 · Sistema de Comandas

Este documento registra el tipo elegido, su longitud o precisión y la razón de cada columna de las 17 tablas (97 columnas). No incluye las columnas calculadas de las vistas, porque no se almacenan en las tablas.

## Dominios reutilizables

PostgreSQL permite definir un dominio para dar un nombre común a un tipo que se repite. La migración [`001-dominios.sql`](migraciones/001-dominios.sql) crea estos dos dominios y los asigna a las columnas indicadas:

| Dominio | Tipo base | Columnas | Qué aporta |
| :-- | :-- | :-- | :-- |
| `dinero` | `NUMERIC(10,2)` | `producto.precio`, `paquete.monto`, `comanda.precio_cobrado`, `pago.monto`, `pago.monto_propina`, `anticipo.monto` | Mantiene importes exactos a centavos y da el mismo nombre y precisión a los seis importes. Evita usar punto flotante, que puede introducir errores al sumar dinero. |
| `cantidad` | `NUMERIC(10,3)` | `ingrediente.stock_actual`, `ingrediente.stock_minimo`, `receta.cantidad_por_porcion` | Mantiene cantidades decimales exactas hasta milésimas con la misma precisión en inventario y recetas. |

Los dominios fijan el tipo y la precisión comunes. Las reglas de negocio (por ejemplo, que el stock no sea negativo) siguen en los `CHECK` de cada columna, donde ya están declaradas.

## Criterios usados

- `INTEGER` ocupa 4 bytes y admite enteros hasta aproximadamente ±2,147 millones. Sirve para identificadores y claves foráneas con el mismo tipo, y para conteos enteros.
- `SMALLINT` ocupa 2 bytes. Basta para días, meses, años actuales, horas, números de mesa, secuenciales y números pequeños de caja.
- `VARCHAR(n)` guarda texto de longitud variable y limita la entrada a `n` caracteres. Se usa para nombres, descripciones y códigos; los códigos con una lista cerrada además se limitan mediante `CHECK`.
- `DATE` representa un día calendario y rechaza fechas imposibles. `TIMESTAMPTZ` representa un instante y permite interpretarlo correctamente entre zonas horarias.
- `TIME` representa una hora del día. Las columnas de hora derivadas se calculan en la hora local de Ciudad de México y se truncan a segundos (`TIME(0)`).
- `NUMERIC(10,2)` permite ocho dígitos enteros y dos decimales exactos; `NUMERIC(10,3)` permite siete enteros y tres decimales exactos.

## Tipos por columna

| Tabla | Columna | Tipo elegido | Longitud o precisión | Por qué |
| :-- | :-- | :-- | :-- | :-- |
| evento | `numero_evento` | `INTEGER` | 4 bytes | Identificador entero generado; su rango alcanza para el historial previsto y coincide con sus claves foráneas. |
| evento | `fecha` | `DATE` | Día calendario | Un evento tiene fecha, no hora; el tipo valida fechas reales. |
| evento | `fecha_dia` | `SMALLINT` | 2 bytes; 1–31 | Componente generado de la fecha; el rango pequeño cubre todos los días del mes. |
| evento | `fecha_mes` | `SMALLINT` | 2 bytes; 1–12 | Componente generado de la fecha; solo representa los doce meses. |
| evento | `fecha_anio` | `SMALLINT` | 2 bytes | Componente generado; alcanza para los años de operación previstos. |
| evento | `tipo_evento` | `VARCHAR(40)` | Máximo 40 caracteres | Nombre variable del tipo de evento; el límite evita etiquetas desproporcionadas. |
| evento | `numero_asistentes` | `INTEGER` | 4 bytes; entero | Es un conteo de personas, sin fracciones, que puede ser mayor que el rango de `SMALLINT`. |
| evento | `estado` | `VARCHAR(12)` | Máximo 12 caracteres | Código corto de una lista cerrada; el `CHECK` define los estados permitidos. |
| evento_organizador | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea con el mismo tipo que `evento.numero_evento`. |
| evento_organizador | `organizador` | `VARCHAR(120)` | Máximo 120 caracteres | Permite guardar nombres de personas u organizaciones de longitud variable. |
| usuario | `id_usuario` | `INTEGER` | 4 bytes | Identificador generado y referenciado por las tablas de subtipos y relaciones. |
| usuario | `nombre` | `VARCHAR(120)` | Máximo 120 caracteres | Admite nombres completos de longitud variable, con un límite razonable. |
| usuario | `usuario` | `VARCHAR(40)` | Máximo 40 caracteres | Nombre de acceso de longitud variable; el límite evita identificadores excesivos. |
| usuario | `fecha_nacimiento` | `DATE` | Día calendario | La fecha de nacimiento no necesita hora y debe ser una fecha válida. |
| usuario | `fecha_nacimiento_dia` | `SMALLINT` | 2 bytes; 1–31 | Componente generado de la fecha de nacimiento. |
| usuario | `fecha_nacimiento_mes` | `SMALLINT` | 2 bytes; 1–12 | Componente generado de la fecha de nacimiento. |
| usuario | `fecha_nacimiento_anio` | `SMALLINT` | 2 bytes | Componente generado; el límite inferior de la fecha se restringe en la fecha original. |
| usuario | `contrasena_hash` | `VARCHAR(255)` | Máximo 255 caracteres | Guarda hashes, no contraseñas en claro; deja espacio para formatos de hash actuales. |
| usuario | `rol` | `VARCHAR(12)` | Máximo 12 caracteres | Código corto de la jerarquía de usuarios; el `CHECK` restringe sus valores. |
| mesero | `id_usuario` | `INTEGER` | 4 bytes | Clave primaria y foránea que debe coincidir con el identificador de `usuario`. |
| mesero | `rol` | `VARCHAR(12)` | Máximo 12 caracteres | Copia el discriminador del supertipo; admite el valor fijo `mesero`. |
| mesero | `turno_asignado` | `VARCHAR(12)` | Máximo 12 caracteres | Código corto de turno; el `CHECK` define las opciones. |
| bar_cocina | `id_usuario` | `INTEGER` | 4 bytes | Clave primaria y foránea compatible con `usuario.id_usuario`. |
| bar_cocina | `rol` | `VARCHAR(12)` | Máximo 12 caracteres | Copia el discriminador del supertipo; admite el valor fijo `bar_cocina`. |
| bar_cocina | `estado` | `VARCHAR(10)` | Máximo 10 caracteres | Código de disponibilidad; el máximo alcanza para `desocupado` y el `CHECK` limita la lista. |
| bar_cocina | `estacion_asignada` | `VARCHAR(6)` | Máximo 6 caracteres | Código de estación; seis caracteres alcanzan para `cocina`. |
| cajero_admin | `id_usuario` | `INTEGER` | 4 bytes | Clave primaria y foránea compatible con `usuario.id_usuario`. |
| cajero_admin | `rol` | `VARCHAR(12)` | Máximo 12 caracteres | Copia el discriminador del supertipo; admite el valor fijo `cajero_admin`. |
| cajero_admin | `nivel_acceso` | `VARCHAR(13)` | Máximo 13 caracteres | Código de acceso; alcanza para `administrador` y el `CHECK` limita la lista. |
| cajero_admin | `caja_asignada` | `SMALLINT` | 2 bytes | Número entero pequeño de caja; no requiere el rango de `INTEGER`. |
| mesa | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con el identificador del evento. |
| mesa | `numero_mesa` | `SMALLINT` | 2 bytes | Número local de mesa; el salón tiene pocas decenas por evento. |
| mesa | `id_mesero` | `INTEGER` | 4 bytes | Clave foránea compatible con `usuario.id_usuario`. |
| cuenta | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con `evento.numero_evento`. |
| cuenta | `secuencial` | `SMALLINT` | 2 bytes | Número de cuenta local a un evento; se esperan decenas por evento. |
| cuenta | `numero_mesa` | `SMALLINT` | 2 bytes | Clave foránea compuesta compatible con el número local de mesa. |
| cuenta | `nombre` | `VARCHAR(60)` | Máximo 60 caracteres | Nombre corto elegido para distinguir cuentas, como “Novios”. |
| cuenta | `folio` | `VARCHAR(30)` | Máximo 30 caracteres | Folio generado que combina identificadores; el texto es fácil de mostrar y copiar. |
| cuenta | `estado` | `VARCHAR(8)` | Máximo 8 caracteres | Código corto para abierta/cerrada; el `CHECK` limita los estados. |
| producto | `id_producto` | `INTEGER` | 4 bytes | Identificador generado y referenciado en comandas, recetas y paquetes. |
| producto | `nombre` | `VARCHAR(80)` | Máximo 80 caracteres | Nombre variable para mostrar en el catálogo, con límite de captura. |
| producto | `descripcion` | `VARCHAR(255)` | Máximo 255 caracteres | Texto opcional de catálogo; un límite corto basta para una descripción de producto. |
| producto | `categoria` | `VARCHAR(10)` | Máximo 10 caracteres | Código de lista cerrada; alcanza para `alimentos` y el `CHECK` define categorías. |
| producto | `precio` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Precio exacto a centavos; evita errores de redondeo de punto flotante. |
| producto | `id_producto_principal` | `INTEGER` | 4 bytes | Clave foránea opcional al producto principal de una variante. |
| ingrediente | `id_ingrediente` | `INTEGER` | 4 bytes | Identificador generado y referenciado por las recetas. |
| ingrediente | `nombre` | `VARCHAR(60)` | Máximo 60 caracteres | Nombre variable del ingrediente, con límite para evitar texto excesivo. |
| ingrediente | `unidad_medida` | `VARCHAR(5)` | Máximo 5 caracteres | Código corto de unidad; alcanza para `pieza` y el `CHECK` limita los valores. |
| ingrediente | `stock_actual` | `cantidad` | `NUMERIC(10,3)`; 3 decimales | Existencia exacta; admite fracciones de gramo o mililitro sin errores binarios. |
| ingrediente | `stock_minimo` | `cantidad` | `NUMERIC(10,3)`; 3 decimales | Umbral de resurtido con la misma unidad y precisión del stock actual. |
| receta | `id_producto` | `INTEGER` | 4 bytes | Clave foránea compatible con el producto de la receta. |
| receta | `id_ingrediente` | `INTEGER` | 4 bytes | Clave foránea compatible con el ingrediente de la receta. |
| receta | `cantidad_por_porcion` | `cantidad` | `NUMERIC(10,3)`; 3 decimales | Cantidad exacta del ingrediente por porción, en gramos, mililitros o piezas. |
| paquete | `numero_paquete` | `INTEGER` | 4 bytes | Identificador generado y referenciado por productos y acuerdos. |
| paquete | `monto` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Precio exacto del paquete a centavos. |
| paquete | `detalles` | `VARCHAR(255)` | Máximo 255 caracteres | Descripción variable del paquete; el límite evita textos excesivos. |
| paquete_producto | `numero_paquete` | `INTEGER` | 4 bytes | Clave foránea compatible con `paquete.numero_paquete`. |
| paquete_producto | `id_producto` | `INTEGER` | 4 bytes | Clave foránea compatible con `producto.id_producto`. |
| acuerdo | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con el evento del acuerdo. |
| acuerdo | `numero_paquete` | `INTEGER` | 4 bytes | Clave foránea compatible con el paquete acordado. |
| acuerdo | `id_producto` | `INTEGER` | 4 bytes | Clave foránea compatible con el producto acordado. |
| acuerdo | `cantidad_acordada` | `INTEGER` | 4 bytes; entero | Número de unidades pactadas; no se contratan fracciones de producto. |
| comanda | `id_comanda` | `INTEGER` | 4 bytes | Identificador generado para cada comanda. |
| comanda | `fecha_hora` | `TIMESTAMPTZ` | Precisión predeterminada: microsegundos | Guarda el instante exacto y permite convertirlo a la zona local al mostrarlo. |
| comanda | `fecha_hora_dia` | `SMALLINT` | 2 bytes; 1–31 | Componente generado en hora de Ciudad de México. |
| comanda | `fecha_hora_mes` | `SMALLINT` | 2 bytes; 1–12 | Componente generado en hora de Ciudad de México. |
| comanda | `fecha_hora_anio` | `SMALLINT` | 2 bytes | Componente generado; cubre los años de operación previstos. |
| comanda | `fecha_hora_hora` | `TIME` | Precisión de valor: 0 decimales | Hora local generada; se conserva hasta el segundo para las consultas por hora. |
| comanda | `precio_cobrado` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Copia el precio exacto del catálogo al levantar la comanda. |
| comanda | `estado` | `VARCHAR(14)` | Máximo 14 caracteres | Código de estado; alcanza para `en_preparacion` y el `CHECK` define el flujo. |
| comanda | `detalles` | `VARCHAR(255)` | Máximo 255 caracteres | Nota opcional para cocina/bar; limita la longitud de captura. |
| comanda | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con el evento de la cuenta. |
| comanda | `secuencial` | `SMALLINT` | 2 bytes | Clave foránea compatible con el número local de cuenta. |
| comanda | `id_mesero` | `INTEGER` | 4 bytes | Clave foránea compatible con el usuario que tomó la comanda. |
| comanda | `id_producto` | `INTEGER` | 4 bytes | Clave foránea compatible con el producto solicitado. |
| comanda | `id_bar_cocina` | `INTEGER` | 4 bytes | Clave foránea opcional al usuario de la estación que prepara la comanda. |
| comanda | `id_cajero_cancela` | `INTEGER` | 4 bytes | Clave foránea opcional al cajero que cancela la comanda. |
| pago | `numero_pago` | `INTEGER` | 4 bytes | Identificador generado para cada pago. |
| pago | `monto` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Importe exacto cobrado, incluida la propina. |
| pago | `forma_pago` | `VARCHAR(13)` | Máximo 13 caracteres | Código corto; alcanza para `transferencia` y el `CHECK` limita las opciones. |
| pago | `fecha_hora` | `TIMESTAMPTZ` | Precisión predeterminada: microsegundos | Guarda el instante exacto del pago para ordenar y auditar operaciones. |
| pago | `fecha_hora_dia` | `SMALLINT` | 2 bytes; 1–31 | Componente generado en hora de Ciudad de México. |
| pago | `fecha_hora_mes` | `SMALLINT` | 2 bytes; 1–12 | Componente generado en hora de Ciudad de México. |
| pago | `fecha_hora_anio` | `SMALLINT` | 2 bytes | Componente generado; cubre los años de operación previstos. |
| pago | `fecha_hora_hora` | `TIME` | Precisión de valor: 0 decimales | Hora local generada; se conserva hasta el segundo. |
| pago | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con el evento de la cuenta pagada. |
| pago | `secuencial` | `SMALLINT` | 2 bytes | Clave foránea compatible con el número local de cuenta. |
| pago | `id_cajero` | `INTEGER` | 4 bytes | Clave foránea compatible con el usuario que registra el pago. |
| pago | `id_mesero_propina` | `INTEGER` | 4 bytes | Clave foránea opcional al mesero que recibe la propina. |
| pago | `monto_propina` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Propina exacta a centavos; comparte tipo con los demás importes. |
| anticipo | `id_anticipo` | `INTEGER` | 4 bytes | Identificador generado para cada anticipo. |
| anticipo | `monto` | `dinero` | `NUMERIC(10,2)`; 2 decimales | Importe exacto del anticipo a centavos. |
| anticipo | `fecha` | `DATE` | Día calendario | El anticipo se registra por fecha, sin requerir una hora específica. |
| anticipo | `fecha_dia` | `SMALLINT` | 2 bytes; 1–31 | Componente generado de la fecha del anticipo. |
| anticipo | `fecha_mes` | `SMALLINT` | 2 bytes; 1–12 | Componente generado de la fecha del anticipo. |
| anticipo | `fecha_anio` | `SMALLINT` | 2 bytes | Componente generado; cubre los años de operación previstos. |
| anticipo | `numero_evento` | `INTEGER` | 4 bytes | Clave foránea compatible con el evento al que se aplica. |

## Restricciones y reglas del dominio

Las reglas siguientes explican por qué se exige cada `NOT NULL`, valor inicial, unicidad y `CHECK` del esquema. Las claves foráneas se documentan por separado en el ejercicio 2.1.

### `NOT NULL`

| Columna | Regla del dominio |
| :-- | :-- |
| `evento.fecha` | Todo evento debe tener fecha para poder programarlo. |
| `evento.tipo_evento` | Todo evento debe indicar qué tipo de celebración se atenderá. |
| `evento.numero_asistentes` | Todo evento debe tener un número esperado de asistentes. |
| `evento.estado` | Todo evento debe tener un estado para saber si está programado, en curso o terminado. |
| `evento_organizador.numero_evento` | Todo organizador registrado debe pertenecer a un evento. |
| `evento_organizador.organizador` | La relación debe identificar a la persona u organización registrada. |
| `usuario.nombre` | El personal debe tener un nombre para identificarlo en la operación. |
| `usuario.usuario` | Todo usuario debe tener un nombre de acceso para iniciar sesión. |
| `usuario.fecha_nacimiento` | La fecha de nacimiento permite identificar al usuario y calcular su edad. |
| `usuario.contrasena_hash` | Toda cuenta debe guardar el hash necesario para verificar el acceso. |
| `usuario.rol` | Todo usuario debe pertenecer a un rol del sistema. |
| `mesero.id_usuario` | Toda fila de mesero debe corresponder a un usuario. |
| `mesero.rol` | El subtipo debe conservar el discriminador que acredita que la persona es mesero. |
| `mesero.turno_asignado` | El salón debe saber en qué turno trabaja cada mesero. |
| `bar_cocina.id_usuario` | Toda fila de bar/cocina debe corresponder a un usuario. |
| `bar_cocina.rol` | El subtipo debe conservar el discriminador de bar/cocina. |
| `bar_cocina.estado` | La estación debe indicar si está ocupada o disponible. |
| `bar_cocina.estacion_asignada` | Cada integrante debe tener asignada una estación de trabajo. |
| `cajero_admin.id_usuario` | Toda fila de caja debe corresponder a un usuario. |
| `cajero_admin.rol` | El subtipo debe conservar el discriminador de cajero/administrador. |
| `cajero_admin.nivel_acceso` | El sistema debe saber qué permisos tiene el usuario de caja. |
| `cajero_admin.caja_asignada` | Cada cajero debe tener una caja identificada. |
| `mesa.numero_evento` | Toda mesa debe pertenecer a un evento. |
| `mesa.numero_mesa` | Toda mesa debe tener número dentro de su evento. |
| `mesa.id_mesero` | Toda mesa debe tener un mesero responsable. |
| `cuenta.numero_evento` | Toda cuenta debe pertenecer a un evento. |
| `cuenta.secuencial` | Toda cuenta debe tener su número dentro del evento. |
| `cuenta.numero_mesa` | Toda cuenta debe estar asociada a una mesa. |
| `cuenta.nombre` | El personal necesita identificar la cuenta con un nombre. |
| `cuenta.estado` | Toda cuenta debe indicar si sigue abierta o ya se cerró. |
| `producto.nombre` | Todo producto debe tener un nombre para aparecer en el catálogo. |
| `producto.categoria` | Todo producto debe pertenecer a una categoría para enviarse a bar o cocina. |
| `producto.precio` | El catálogo debe indicar el precio, aunque sea cero para una cortesía. |
| `ingrediente.nombre` | Todo ingrediente debe poder identificarse en inventario. |
| `ingrediente.unidad_medida` | El stock debe declarar la unidad en que se mide. |
| `ingrediente.stock_actual` | El inventario debe conocer la existencia, aunque sea cero. |
| `ingrediente.stock_minimo` | El inventario debe conocer el umbral de resurtido, aunque sea cero. |
| `receta.id_producto` | Toda receta debe corresponder a un producto. |
| `receta.id_ingrediente` | Toda receta debe identificar el ingrediente que consume. |
| `receta.cantidad_por_porcion` | La receta debe indicar cuánto ingrediente requiere cada porción. |
| `paquete.monto` | Todo paquete debe tener un precio, aunque sea gratuito. |
| `paquete.detalles` | Todo paquete debe describir qué incluye. |
| `paquete_producto.numero_paquete` | Toda asociación debe identificar el paquete. |
| `paquete_producto.id_producto` | Toda asociación debe identificar el producto incluido. |
| `acuerdo.numero_evento` | Todo acuerdo debe corresponder a un evento. |
| `acuerdo.numero_paquete` | Todo acuerdo debe identificar el paquete pactado. |
| `acuerdo.id_producto` | Todo acuerdo debe identificar el producto pactado. |
| `acuerdo.cantidad_acordada` | Todo acuerdo debe indicar cuántas unidades se pactaron. |
| `comanda.fecha_hora` | Toda comanda debe quedar fechada para ordenar y auditar la atención. |
| `comanda.precio_cobrado` | Toda comanda debe conservar el precio aplicado al pedir el producto. |
| `comanda.estado` | Toda comanda debe tener estado para controlar su preparación y entrega. |
| `comanda.numero_evento` | Toda comanda debe pertenecer a una cuenta de un evento. |
| `comanda.secuencial` | Toda comanda debe identificar la cuenta dentro del evento. |
| `comanda.id_mesero` | Toda comanda debe registrar qué mesero la levantó. |
| `comanda.id_producto` | Toda comanda debe indicar qué producto se pidió. |
| `pago.monto` | Todo pago debe registrar cuánto dinero se recibió. |
| `pago.forma_pago` | Todo pago debe indicar cómo se recibió el dinero. |
| `pago.fecha_hora` | Todo pago debe quedar fechado para el historial de caja. |
| `pago.numero_evento` | Todo pago debe aplicarse a una cuenta de un evento. |
| `pago.secuencial` | Todo pago debe identificar la cuenta dentro del evento. |
| `pago.id_cajero` | Todo pago debe registrar quién lo recibió. |
| `anticipo.monto` | Todo anticipo debe indicar cuánto dinero se recibió. |
| `anticipo.fecha` | Todo anticipo debe registrar el día en que se recibió. |
| `anticipo.numero_evento` | Todo anticipo debe aplicarse a un evento. |

Las columnas que no aparecen en esta tabla admiten `NULL` porque el dato es opcional en el modelo (por ejemplo, descripción, detalles o la persona y el monto de una propina). Las claves primarias son `NOT NULL` por definición del gestor.

### Valores iniciales (`DEFAULT`)

| Columna | Valor inicial | Regla del dominio |
| :-- | :-- | :-- |
| `evento.estado` | `'programado'` | Un evento nuevo todavía no ha comenzado. |
| `mesero.rol` | `'mesero'` | Una fila creada en el subtipo mesero debe llevar ese discriminador. |
| `bar_cocina.rol` | `'bar_cocina'` | Una fila creada en el subtipo bar/cocina debe llevar ese discriminador. |
| `bar_cocina.estado` | `'desocupado'` | Una estación nueva inicia disponible hasta que una comanda la ocupe. |
| `cajero_admin.rol` | `'cajero_admin'` | Una fila del subtipo de caja debe llevar ese discriminador. |
| `cajero_admin.nivel_acceso` | `'cajero'` | Se concede el acceso mínimo de caja por defecto. |
| `cuenta.estado` | `'abierta'` | Una cuenta nueva recibe pedidos hasta que se cierre. |
| `ingrediente.stock_actual` | `0` | Un ingrediente nuevo no debe suponerse disponible si no se capturó existencia. |
| `ingrediente.stock_minimo` | `0` | Si no se define umbral de resurtido, se inicia en cero. |
| `comanda.fecha_hora` | `now()` | Se registra el instante de creación si el cliente no lo envía. |
| `comanda.estado` | `'pendiente'` | Una comanda nueva todavía no ha empezado a prepararse. |
| `pago.fecha_hora` | `now()` | Se registra el instante del cobro si no se envía uno. |
| `anticipo.fecha` | `CURRENT_DATE` | Si no se indica el día, se usa el día de registro. |

Los identificadores `IDENTITY` se generan con una secuencia para que cada alta reciba un número nuevo; se permite insertar números conocidos durante la carga inicial.

### Unicidad (`UNIQUE` e índices únicos)

| Restricción | Regla del dominio |
| :-- | :-- |
| `uq_usuario_usuario` | Dos personas no pueden iniciar sesión con el mismo nombre de acceso. |
| `uq_usuario_id_rol` | El par identificador/rol debe ser único para que las claves de los subtipos señalen un solo usuario con ese rol. |
| `uq_producto_nombre` | El nombre del producto debe identificar una sola opción del catálogo. |
| `uq_ingrediente_nombre` | Un ingrediente debe tener una sola fila de inventario; duplicarlo dividiría el stock. |
| `ux_usuario_usuario_minusculas` | El mismo nombre de acceso no puede repetirse cambiando mayúsculas y minúsculas. |
| `ux_ingrediente_nombre_minusculas` | El mismo ingrediente no puede duplicarse cambiando mayúsculas y minúsculas. |
| `ux_cuenta_nombre_abierta` | En una mesa y evento no puede haber dos cuentas abiertas con el mismo nombre; al cerrar una, el nombre se puede reutilizar. |

### Reglas `CHECK`

| Restricción | Regla del dominio |
| :-- | :-- |
| `ck_evento_asistentes` | Un evento debe esperar al menos un asistente. |
| `ck_evento_estado` | El evento solo puede estar programado, en curso, finalizado o cancelado. |
| `ck_usuario_rol` | El usuario debe pertenecer a uno de los tres subtipos definidos. |
| `ck_usuario_nacimiento` | Se rechazan fechas de nacimiento anteriores a 1900 para evitar capturas evidentemente erróneas. |
| `ck_usuario_formato` | El nombre de acceso debe tener de 3 a 40 caracteres, empezar con una letra ASCII y continuar solo con letras ASCII o números; así se evita guardar accesos con espacios o signos. Se implementa en [`002-formato-usuario.sql`](migraciones/002-formato-usuario.sql), con rechazo 35 y caso válido 14. |
| `ck_mesero_rol` | Una fila de `mesero` solo puede tener el rol `mesero`. |
| `ck_mesero_turno` | El turno debe ser matutino, vespertino o nocturno. |
| `ck_bar_cocina_rol` | Una fila de `bar_cocina` solo puede tener el rol `bar_cocina`. |
| `ck_bar_cocina_estado` | La estación solo puede estar ocupada o desocupada. |
| `ck_bar_cocina_estacion` | La persona debe estar asignada a bar o cocina. |
| `ck_cajero_admin_rol` | Una fila de `cajero_admin` solo puede tener el rol `cajero_admin`. |
| `ck_cajero_admin_nivel` | El acceso de caja solo puede ser cajero o administrador. |
| `ck_cajero_admin_caja` | El número de caja debe ser positivo. |
| `ck_mesa_numero` | Los números de mesa comienzan en uno. |
| `ck_cuenta_secuencial` | El secuencial de cuenta debe ser positivo. |
| `ck_cuenta_estado` | La cuenta solo puede estar abierta o cerrada. |
| `ck_cuenta_nombre` | El nombre de cuenta no puede estar vacío ni contener solo espacios. |
| `ck_producto_categoria` | Cada producto pertenece a alimentos, bebidas o dulcería. |
| `ck_producto_precio` | Un producto no puede tener precio negativo; cero permite cortesías. |
| `ck_producto_no_autovariante` | Un producto no puede ser su propia variante. |
| `ck_ingrediente_unidad` | La unidad debe ser gramos, mililitros o piezas para que stock y receta sean comparables. |
| `ck_ingrediente_stock` | La existencia nunca puede quedar por debajo de cero. |
| `ck_ingrediente_minimo` | El mínimo de resurtido nunca puede ser negativo. |
| `ck_receta_cantidad` | Cada receta debe consumir una cantidad positiva del ingrediente. |
| `ck_paquete_monto` | El monto del paquete no puede ser negativo; cero permite un paquete de cortesía. |
| `ck_acuerdo_cantidad` | Un acuerdo debe incluir al menos una unidad del producto. |
| `ck_comanda_precio` | El precio cobrado no puede ser negativo. |
| `ck_comanda_estado` | La comanda solo puede recorrer los estados definidos para su preparación y entrega. |
| `ck_comanda_cancelacion` | Una comanda cancelada debe indicar el cajero que la canceló, y una comanda activa no debe indicar uno. |
| `ck_comanda_preparacion` | Las comandas en preparación, listas o entregadas deben tener una estación asignada; las pendientes o canceladas pueden no tenerla. |
| `ck_pago_monto` | Un pago debe ser mayor que cero. |
| `ck_pago_propina_limite` | La propina no puede ser mayor que el importe total del pago. |
| `ck_pago_forma` | La forma de pago debe ser efectivo, tarjeta o transferencia. |
| `ck_pago_propina_completa` | La propina debe registrar juntos el monto y el mesero, o dejar ambos vacíos. |
| `ck_pago_propina_monto` | La propina no puede ser negativa. |
| `ck_anticipo_monto` | Un anticipo debe ser mayor que cero. |

## Alcance y correspondencia con el esquema

Las seis columnas monetarias y las tres cantidades repetidas se definen primero como `NUMERIC` en el esquema original de la Práctica 3. Al reconstruir la base, `001-dominios.sql` cambia esas columnas a `dinero` y `cantidad` mediante `ALTER TABLE`; el tipo base y la precisión no cambian. Por eso aquí se muestra el tipo reutilizable que queda aplicado después de la migración.
