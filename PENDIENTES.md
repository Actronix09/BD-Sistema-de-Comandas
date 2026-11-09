# Pendientes del Sistema de Comandas

Lo que falta para terminar el sistema, dividido en fases. Sirve para ponernos de acuerdo en qué sigue y quién lo hace: cada parte tiene una columna **Responsable** y una casilla para marcarla cuando esté lista.

**Actualizado:** 4 de noviembre de 2026

---

## Prioridad 1: Prácticas 4 y 5

**Entrega: jueves 5 de noviembre de 2026.** Cuenta la hora de la última confirmación en `main`. Esto va antes que todas las fases de abajo, que esperan hasta esa fecha.

- `[x]`: el requisito ya se cumple y solo hay que citarlo en el entregable.
- `[ ]`: falta algo. **Hay** dice lo que ya existe y **Falta**, lo que queda.
- Los números de ejercicio son los del documento de la práctica, no los de las fases.
- Estado revisado el 4 de noviembre contra el repo, la base de pruebas (`make -C sql pruebas`: 36 rechazos y 15 válidas, todas pasan) y el fork de Sismos.

### Quién hace qué

| Quién | Rol | Ejercicios | Por qué |
| :-- | :-- | :-- | :-- |
| @Actronix09 (Adrián) | Datos, permisos y edición de valores | Entorno, 1.3, 1.4, 1.6, 2.4 y entregable | La carga depende de los disparadores y del servidor, que ya conoce. Los permisos se cierran con la carga, y 2.4 trabaja sobre esos datos. Además, abre el PR final |
| Samy (@Samuel-Hdzx07) | Esquema, integridad y proyecto asignado | Migraciones, 1.1, 1.2, 1.5, 2.1, 2.2, 2.3, 1.7 y 2.5 | Ya lleva `sql/`, los rechazos y la numeración de los casos, y es dueño del fork de Sismos |
| Ambos | Trabajo individual | 2.6, confirmaciones propias en días distintos y revisión del PR | Lo pide la práctica a cada integrante |

### Orden de trabajo

| Día | Qué debe quedar |
| :-- | :-- |
| Martes 3 | Rama y carpetas, primeras migraciones, fuente de datos decidida, avance de 1.1, 2.1 y 2.2. **Primera confirmación de cada integrante** |
| Miércoles 4 | Script de carga, permisos, 1.5, 2.3, 2.4, y Sismos (1.7 y 2.5) |
| Jueves 5 | 2.6, evidencias y README. **Segunda confirmación de cada integrante.** PR revisado y fusionado antes de mediodía: el documento no da una hora límite |

Dependencias: migraciones → 1.3 → 1.4 → 2.3, 2.4 y 2.6. Los permisos (1.6) se cierran junto con 1.4, porque la carga debe conectarse con el rol de la aplicación. Sismos (1.7 y 2.5) no depende de lo demás.

### Lista de requisitos

- [ ] **Continuidad del entorno de trabajo** · @Actronix09
  - [x] Rama `practica4-5` creada desde `main`, con una rama por sección (`docs/EntornoPractica4y5.md`).
  - [x] Gestor levantado y `esquema.sql` ejecutado sobre una base limpia: `entorno/compose.yml` y `make -C sql pruebas`.
  - [ ] Base de Sismos levantada desde el fork (Samy). **Hay:** `levantamiento.md` del fork, de prácticas anteriores. **Falta:** levantarla para esta práctica, con su evidencia.
  - [x] Migraciones numeradas con `ALTER TABLE` (Samy): `001-dominios.sql` y `002-formato-usuario.sql`; `make cargar` y `make pruebas` las aplican después del esquema.
  - [ ] Confirmaciones propias en días distintos (ambos). **Hay:** @Actronix09 tiene muchas y Samy tiene 1 (30 de octubre). **Falta:** que cada quien confirme en al menos dos días, entre hoy y el jueves.
  - [ ] PR revisado por otro integrante y fusionado. Lo abre @Actronix09 y lo revisa Samy. **Falta:** todo.

- [ ] **Práctica 4: DDL, permisos y restricciones de dominio**
  - [x] **Ejercicio 1.1. Tipos de dato y dominios** (`practica4/dominios.md`) · Samy
    - [x] Tabla con las 97 columnas: tipo, longitud o precisión y por qué.
    - [x] Montos, fechas, identificadores y textos con el tipo correcto: `NUMERIC(10,2)`, `DATE`, `TIMESTAMPTZ` e `INTEGER` con identidad. Ninguna columna usa punto flotante.
    - [x] `CREATE DOMAIN` para `dinero` (6 columnas) y `cantidad` (3), con su beneficio explicado en `practica4/dominios.md` y los objetos dependientes recreados en `001-dominios.sql`.
  - [x] **Ejercicio 1.2. Restricciones de columna** · Samy
    - [x] `NOT NULL` donde hace falta: 21 de las 25 claves foráneas. Las otras 4 tienen cardinalidad mínima 0.
    - [x] `DEFAULT` con valor inicial natural: 13 columnas (estados iniciales, `now()`, stock en 0).
    - [x] `UNIQUE` simples y compuestas: 4 `UNIQUE` y 3 índices únicos (por ejemplo, `uq_usuario_id_rol` y `ux_cuenta_nombre_abierta`).
    - [x] `CHECK` de rango, de lista de valores y entre columnas (por ejemplo, `ck_pago_monto`, `ck_comanda_estado` y `ck_pago_propina_limite`).
    - [x] `CHECK` de formato en `usuario.usuario`, con rechazo 35, caso válido 14 y migración `002-formato-usuario.sql`.
    - [x] Al menos diez `CHECK` o `UNIQUE`: hay 36 `CHECK` y 4 `UNIQUE`.
    - [x] Regla del dominio junto a las restricciones en `practica4/dominios.md`.
  - [x] **Ejercicio 1.3. Fuente de datos** (`fuente.md`) · @Actronix09
    - [x] Buscar un conjunto publicado y decidir (`practica4/fuente.md`): menú real del salón de eventos, recetas estimadas con FNDDS, operación sintética, y productos e ingredientes inventados hasta pasar de 200.
    - [x] Referencia en APA 7 con su licencia y lo que permite hacer con los datos: CC0 en FNDDS y permiso del salón para publicar su menú, sin sus datos.
    - [x] Formato original, tamaño, número de registros y campos.
    - [x] Tabla de correspondencia: cada campo contra su tabla y columna, incluidos los que no se usan y por qué.
    - [x] Qué venía mal en los datos y qué se decidió con cada problema.
    - [x] Lo que se genere: dónde se buscó, con qué términos y por qué no hay datos; que respete las restricciones; al menos 200 renglones en cada tabla principal; y aviso de datos sintéticos en el README. Hecho con `practica4/poblar/generar_datos.py`.
    - [x] Anonimizar los datos personales: ninguna fuente trae datos personales y los nombres generados no son de personas reales.
  - [x] **Ejercicio 1.4. Script de carga** (`practica4/poblar/`, explicado en `practica4/carga.md`) · @Actronix09
    - [x] Un solo comando, documentado en el README: `practica4/poblar/poblar.sh`.
    - [x] Repetible: la segunda ejecución inserta 0 renglones, sin errores. Filtra con `NOT EXISTS`, porque `ON CONFLICT` falla por los disparadores `BEFORE INSERT`.
    - [x] Ordenado: primero lo que piden las claves foráneas y además los disparadores. Las cuentas se cierran y los eventos se finalizan al final.
    - [x] Todo o nada, con un mensaje que dice qué renglón falló y por qué (`probar_rechazos.sh`).
    - [x] Con cuentas: leídos, insertados, ya existentes y rechazados por tabla.
    - [x] Sin credenciales adentro: `poblar.sh` usa variables de entorno y `.env.example`.
    - [x] Eficiente: `\copy` tarda 0.13 s, contra 2.13 s y 11.76 s de un `INSERT` por renglón (`comparar_tiempos.sh`).
    - [x] Registro de lo que rechazó cada restricción, con la decisión de cada caso (`practica4/carga.md`).
    - [x] Salida de la terminal de la primera y la segunda ejecución (`evidencias/practica4/`).
  - [x] **Ejercicio 1.5. Pruebas de dominio** (`pruebas-dominio.md`) · Samy
    - [x] Diez casos con operación, resultado esperado, mensaje del gestor y regla protegida, documentados en `practica4/pruebas-dominio.md`; `make -C sql pruebas` confirmó los mensajes y resultados.
    - [x] Casos de `NOT NULL` (3), `UNIQUE` simple (8), `UNIQUE` compuesta (2, 13 y 20), `CHECK` de rango (9 y 17) y entre columnas (10 y 25).
    - [x] Caso de `DEFAULT`: el caso válido 15 comprueba que un evento sin `estado` queda `programado`; el rechazo 36 confirma que un `NULL` explícito se rechaza.
    - [x] Caso de `CHECK` de formato: rechazo 35 y caso válido 14 para el formato de usuario, documentados en `pruebas-dominio.md`.
  - [x] **Ejercicio 1.6. Usuarios y permisos** (`practica4/permisos.md`) · @Actronix09
    - [x] Tres roles (aplicación, consulta y administración), diciendo para qué existe cada uno: `migraciones/099-permisos.sql`.
    - [x] `GRANT` con mínimo privilegio y un usuario por rol, con las contraseñas en variables de entorno. Los disparadores corren con los permisos de quien opera; se concedieron en lugar de usar `SECURITY DEFINER`.
    - [x] El script de carga se conecta con el rol de la aplicación: `app_comandas`.
    - [x] Una operación permitida y una negada por rol, con el mensaje del gestor: `poblar/probar_permisos.sh`.
    - [x] Un `REVOKE` que muestra que la operación deja de funcionar.
    - [x] Matriz de permisos: 3 roles contra 17 tablas, leída del catálogo.
  - [ ] **Ejercicio 1.7. Sismos: datos y dominios** (`practica4/proyecto-asignado/`) · Samy
    - [ ] Cargar el catálogo en la base del fork con un script que cumpla 1.4. **Hay:** volcados del repo original (168 MB) en `fuentes-alternas/sismos-usgs/datos/original/ssn` y JSON en `data/` del fork. **Falta:** el script. También hay que decidir si se parte del catálogo público del SSN, que es lo que pide la práctica, o de los volcados, y justificarlo.
    - [ ] Comparar con el artículo y explicar las diferencias. **Hay:** 319,592 sismos y 196,576 hechos (`data/README.md` del fork); el artículo habla de más de 300,000; y `fuentes-alternas` encontró 74,927 sismos con un día de menos. **Falta:** repetir los números con la carga nueva y escribir la comparación.
    - [ ] Revisar las restricciones que tiene y las que le faltan. **Hay:** el DDL declara claves primarias y 4 foráneas, sin ningún `CHECK`. **Falta:** escribir la revisión.
    - [ ] Proponer tres restricciones y probarlas en una copia. **Falta:** todo. Por revisar: rango de `magnitud`, de `latitud` y `longitud`, y `profundidad`, que vale 33 en muchos renglones (`levantamiento.md`).

- [ ] **Práctica 5: DML e integridad referencial**
  - [x] **Ejercicio 2.1. Claves foráneas** (`practica5/referencias.md`) · Samy
    - [x] Tabla con las 25 claves: relación del EER, tabla y columna referenciada, y si admite nulos.
    - [x] Toda relación del modelo quedó como clave foránea: las 17 relaciones del inventario más la jerarquía y el atributo multivaluado dan las 25.
  - [x] **Ejercicio 2.2. Acciones referenciales** (en `practica5/referencias.md`) · Samy
    - [x] Cada clave declara qué hacer al borrar y al actualizar. Al borrar: 9 `CASCADE` y 16 `RESTRICT`. Al actualizar: 14 `CASCADE` y 11 `RESTRICT`.
    - [x] Justificación individual para las 25 claves, incluidas las cuatro relaciones opcionales que usan `RESTRICT`.
  - [ ] **Ejercicio 2.3. Pruebas de integridad** (`practica5/pruebas-referenciales.md`) · Samy
    - [x] **Comandas:** una prueba para cada acción referencial, con conteos antes/después; `make -C sql pruebas` pasó el 4 de noviembre y la salida está en `evidencias/practica5/pruebas-referenciales.txt`.
    - [x] `INSERT` con FK inexistente y su mensaje; el script también demuestra que cargar primero la hija falla y cargar primero el padre funciona.
    - [x] **Comandas:** auditorías de huérfanos, duplicados únicos y nulos indebidos; las tres devolvieron cero filas.
    - [ ] **Sismos:** repetir las auditorías en la base del proyecto asignado; queda para esa parte.
  - [x] **Ejercicio 2.4. Edición de valores y transacciones** (`practica5/edicion-de-valores.md`) · @Actronix09
    - [x] `INSERT` desde una consulta: el evento 233 agrega el paquete 12 a `acuerdo`. Inserción con `ON CONFLICT`: el resurtido suma al stock o da de alta el ingrediente.
    - [x] `UPDATE` que depende de otra tabla: `stock_minimo` según lo acordado con el evento 232. `UPDATE` con `CASE`: `bar_cocina.estado` según sus comandas en preparación.
    - [x] `DELETE` con subconsulta: los paquetes que ningún acuerdo usa; se muestran el `CASCADE` de su contenido y el `RESTRICT` de un paquete contratado.
    - [x] Borrado lógico: cancelar la comanda con `estado` y `id_cajero_cancela`, sin migración, porque el modelo ya lo tiene. Se explica cuándo conviene cada uno y qué se pierde al borrar de verdad.
    - [x] Transacción sobre `comanda`, `pago` y `cuenta` con `SAVEPOINT`, reversión parcial y confirmación final.
    - [x] Transacción que falla a la mitad por falta de stock, con el mensaje del gestor y la comprobación de que la base quedó igual. Salida en `evidencias/practica5/edicion-de-valores.txt`.
  - [ ] **Ejercicio 2.5. Integridad en el almacén de Sismos** (`integridad-almacen.md`) · Samy
    - [ ] Tabla de hechos, dimensiones y granularidad. **Hay:** `fact_impacto_sismos_imputed` con 4 dimensiones. **Falta:** escribir qué representa exactamente un renglón.
    - [x] Revisar si el esquema declara las claves: declara las 4 (`00-datawarehouse_tables.sql:53-56` del repo original). La tabla de hechos no tiene clave primaria.
    - [ ] Buscar con consultas hechos que apunten a dimensiones inexistentes. **Falta:** todo.
    - [ ] Explicar por qué un almacén a veces las omite y qué riesgo corre. **Hay:** un buen ejemplo en `data/README.md` del fork: los identificadores de `dim_zonas` y `dim_economia` no coinciden (la zona 4 es Coahuila y la economía 4 es Chiapas). **Falta:** escribirlo. Como las claves ya están declaradas, agregarlas en una copia no aplica; hay que decirlo así.
  - [ ] **Ejercicio 2.6. Trabajo por integrante** (`practica5/integrantes/`, firmado con su nombre) · Ambos
    - [ ] @Actronix09: `comanda → cuenta`, de `RESTRICT` a `CASCADE` (sugerida). **Falta:** todo.
    - [x] Samy: `receta → ingrediente`, de `RESTRICT` a `CASCADE`. Ejecutado en la copia `comandas_experimento_samy`; `CASCADE` eliminó 1 fila de `receta`, el producto y las comandas siguieron presentes y `ROLLBACK` restauró los datos y `RESTRICT`. Documento firmado: `practica5/integrantes/Hernandez_Barrios_Samuel_Rodrigo.md`; salida: `evidencias/practica5/experimento-2.6-samy.txt`.
    - Cada quien puede elegir otra, sin repetir. Se hace en una copia y muestra qué se pierde, qué se conserva y cuál opción es la correcta. **Se preguntará en clase.**

- [ ] **Entregable** · @Actronix09
  - [ ] Estructura `practica4/` y `practica5/` del documento. **Falta:** no existe ninguna de las dos.
  - [ ] Sentencias en bloques de código y también en archivos `.sql` ejecutables. **Falta:** todo.
  - [ ] README al día. **Hay:** sigue titulado "Práctica 3". **Falta:** el comando de carga, el índice de los documentos nuevos y el aviso si hay datos sintéticos.
  - [ ] Evidencias de cada ejercicio. **Falta:** todo.

### Lo que esto cambia en las fases

- **Todo cambio al esquema va ahora en una migración numerada.** `sql/esquema.sql` ya no se edita. Esto incluye las reglas pendientes de la Fase 2 y la Fase 3, como 2.6, 3.9 y 3.13.
- **Todas las fases de abajo, incluida 3.12, se retoman después de la entrega.**
- **Al retomar `Sistema-de-Comandas`:** su base monta `sql/`, así que también debe recibir las migraciones, y su servidor debe usar el rol de la aplicación (se revisa con 6.5).

---

## Hacia dónde va el sistema

El programa en C (memoria compartida, ncurses y archivos de texto) pasa a ser una aplicación con interfaz gráfica para Windows, Linux y Android, **toda en C++ con Qt**.

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
| Servidor en C++/Qt conectado a la base: login, logout y lista de productos. Usa `validar_password` y `protocolo.h` del sistema en C | Repo `Sistema-de-Comandas`, `servidor/` |
| Base, servidor, cliente y pruebas de Android, cada uno en su contenedor de Podman | Repo `Sistema-de-Comandas`, `compose.yaml` y `android/` |

## Cómo trabajamos

- **Solo el servidor toca la base.** Ninguna pantalla lee ni escribe en la base directamente.
- **Lo que la base ya protege no se repite en el servidor.** El descuento de stock, la máquina de estados y las reglas del cobro viven en disparadores. Si el servidor también los hace, se hacen dos veces.
- Cada regla nueva de la base lleva tres cosas: su disparador o `CHECK` en una migración numerada de `practica4/migraciones/`, un caso en `inserts-rechazados.sql` y un caso en `pruebas-validas.sql`. **Primero el disparador** y después los casos. Si no, el Makefile marca el rechazo como fallido.
- Antes de cada commit, `make -C sql pruebas` debe terminar en `Todas las pruebas pasaron`.
- Numeración: el siguiente rechazo es el **37** y el siguiente caso válido es el **16**.
- Los disparadores lanzan `RAISE EXCEPTION … USING ERRCODE = 'check_violation'`, igual que `fijar_precio_cobrado()`.

## Reparto

Este es el reparto de las fases del sistema. El de las Prácticas 4 y 5 está en [Quién hace qué](#quién-hace-qué).

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
| 3.12 | - [ ] Perfiles en `datos-ejemplo.sql` | El cliente ya separa los niveles de 4.5: `mrivas` es `cajero` y hay una administradora nueva, `dcampos` (id 6, "Daniela Campos Vega", nacida el 1982-03-15, caja 2). En `datos-ejemplo.sql`, `mrivas` sigue como `administrador` y no existe `dcampos`. La comanda cancelada de ejemplo la cancela el usuario 5; en el cliente ya la cancela el 6. Los hashes de ejemplo (`$2b$12$hashDeEjemplo…`) tampoco sirven para entrar, porque el servidor usa Argon2id: mientras tanto, `db/init/03-contrasenas-desarrollo.sql` del repo `Sistema-de-Comandas` pone a todos la contraseña de desarrollo `Demo_123.` | Los datos coinciden con el cliente y `make -C sql pruebas` sigue en verde |  Samy |
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
| 5.1 | - [x] Instalar Podman | `sudo pacman -S podman`; convive con Docker. `podman compose` usa el `docker-compose` que ya estaba instalado y necesita `systemctl --user enable --now podman.socket` | `podman --version` ✓ (6.1.4) |  @Actronix09 |
| 5.2 | - [x] `compose.yaml` con el servicio `db` | En la raíz del repo `Sistema-de-Comandas`. Imagen `docker.io/library/postgres:16.4-alpine`. Proyecto `comandas`, volumen `comandas-pgdata` y puerto `5433:5432`, para no chocar con `practica1-postgres`. `healthcheck` con `pg_isready` | `podman compose up -d` y la base responde en el 5433 ✓ (`618acc6`) |  @Actronix09 |
| 5.3 | - [x] Carga inicial | `esquema.sql` y `datos-ejemplo.sql` se montan desde la carpeta `sql/` de este repo (`COMANDAS_SQL` en `.env`) en `/docker-entrypoint-initdb.d`, para no tener dos copias. Solo corre con el volumen vacío | La base arranca con datos ✓ (`618acc6`) |  @Actronix09 |
| 5.4 | - [x] Credenciales | `.env` fuera de git y `.env.example` de muestra | `.env` en `.gitignore` ✓ (`618acc6`) |  @Actronix09 |
| 5.5 | - [ ] Pruebas con Podman | `make -C sql pruebas MOTOR=podman`. Sin correr: el Makefile usa `entorno/compose.yml` y su contenedor `practica1-postgres`, que hoy corre en Docker con el mismo nombre y puerto | Todas pasan | |
| 5.6 | - [ ] Arranque automático | Quadlet (systemd) en la PC de caja con Linux, o Podman Desktop en Windows | La base arranca al prender la PC | |

Ojo: `podman compose down -v` borra el volumen con todos los datos.

---

## Fase 6: Servidor (C++ con Qt)

**Objetivo:** el servidor del contrato de la Fase 4, en la PC de caja. Es lo único que toca la base.
**Depende de:** fases 4 y 5.

| # | Parte | Qué hay que concretar | Hecho cuando | Responsable |
| :--: | :-- | :-- | :-- | :-- |
| 6.1 | - [x] Proyecto | `servidor/` con CMake y Qt 6 (`Core`, `WebSockets`, `Sql`) y su contenedor. Compila `validaciones.c` y usa `protocolo.h` del sistema en C | Compila y arranca ✓ (`e230562`) |  @Actronix09 |
| 6.2 | - [x] Conexión con la base | `QSqlDatabase` con el driver `QPSQL`. Los datos de conexión van en variables de entorno, no en el código. Al arrancar consulta `v_cuenta`, y si la base se reinicia se reconecta. Fuera del contenedor, este equipo aún no carga el driver | El servidor consulta `v_cuenta` ✓ (`e230562`) |  @Actronix09 |
| 6.3 | - [x] `QWebSocketServer` | Escucha en la red local (`QHostAddress::Any`), puerto 9000. Por cada mensaje: leer el JSON, revisar la sesión de la conexión y mandarlo a la función de su `op`. Es el `switch` de `Servidor.c`, pero leyendo JSON en lugar de la memoria compartida. Por ahora: `OP_LOGIN`, `OP_LOGOUT` y `OP_LISTAR_PRODUCTOS`; las demás responden `NO_IMPLEMENTADA` | Un cliente de prueba hace login y lista productos ✓ (`e230562`) |  @Actronix09 |
| 6.4 | - [ ] Lógica en C → PostgreSQL | Pasar cada módulo según la tabla de abajo: lo que leía o escribía archivos ahora hace consultas | Cada operación del contrato funciona | |
| 6.5 | - [ ] Sesión y permisos | Usuario y rol guardados por conexión después de `OP_LOGIN`, **revisados en cada operación**. Contraseñas con Argon2id o bcrypt (por ejemplo con libsodium) en lugar de SHA-256 sin sal; nunca se devuelven al cliente. Ya está la sesión por conexión y Argon2id con libsodium (`e230562`); falta revisar el rol en cada operación (4.5) | Un mesero no puede crear usuarios | |
| 6.6 | - [ ] Transacciones y errores | `OP_CREAR_PEDIDO` dentro de `transaction()` / `commit()`, con `rollback()` si falla una comanda. El `SQLSTATE` del error de la base (`QSqlError::nativeErrorCode()`) se traduce a los códigos de la Fase 4 | Pedido con un producto sin stock: no se guarda ninguna comanda y llega `SIN_STOCK` | |
| 6.7 | - [ ] Dinero | Nada de `float`: hoy `productos_agregar` recibe el precio como `float`. Usar texto o centavos enteros (`qint64`) entre la base y el JSON | Precios exactos en todas las respuestas | |
| 6.8 | - [ ] Avisos | Al cambiar una comanda, mandar `COMANDA_CAMBIO` a cocina/bar y caja, y `COMANDA_LISTA` solo a la conexión del mesero que la levantó (C11) | El mesero recibe el aviso en el celular | |
| 6.9 | - [ ] Pruebas | Qt Test contra la base de prueba (`comandas_pruebas`) | Todas pasan | |
| 6.10 | - [ ] Arranque en la PC de caja | Que el servidor arranque solo, después de la base: un servicio de systemd en Linux, o una tarea al iniciar sesión en Windows | Al prender la PC, los celulares se pueden conectar | |
| 6.11 | - [ ] Cifrar la conexión | Hoy el servidor usa `ws://`, así que las contraseñas viajan sin cifrar por la WiFi. Pasar a `wss://` con un certificado que acepten los clientes | Un cliente se conecta con `wss://` y `ws://` queda rechazado | |

Qué pasa con cada parte del sistema en C:

| Archivo | Qué hace hoy | En el servidor nuevo |
| :-- | :-- | :-- |
| `Servidor.c` | Memoria compartida, semáforos, hilos y un `switch` por `OP_*` | **Se conserva el `switch`** como despachador. La memoria compartida y los semáforos se reemplazan por `QWebSocketServer` |
| `protocolo.h` | Los `OP_*` y los `struct` que viajan por memoria compartida | **Se conservan los nombres `OP_*`**. Los `struct` se reemplazan por JSON |
| `usuario.c`, `usuarios.c` | Usuarios en archivo; `validar_password`; SHA-256 | **Se conserva `validar_password`**, ya en `validaciones.c` (`1a89621`): la usan el sistema en C, el cliente (`1bf7aee`) y el servidor (`e230562`). Se quitan `validar_email` y `validar_telefono` (ya no hay correo ni teléfono). Cargar y guardar → SQL. SHA-256 → Argon2id o bcrypt |
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
| 7.2 | - [ ] `Api` real | Una clase C++ con `QWebSocket`, registrada como singleton de QML, con la misma interfaz que `Api.qml`. Arma los mensajes con `id` y `op`, empareja cada respuesta con su petición y convierte los avisos en señales para las pantallas. La dirección del servidor se guarda con `QSettings` | Las pantallas funcionan contra el servidor sin cambios |  @Actronix09 |
| 7.3 | - [x] Correcciones del prototipo | Ver la tabla C1–C11 abajo. Hechas las del cliente; C9 y C10 dependen de otras partes | Cada corrección revisada ✓ |  @Actronix09 |
| 7.4 | - [x] Pantalla **Caja** | Cuentas abiertas → detalle → pagar (forma de pago, monto y propina) → saldo → cerrar cuenta. El cajero entra directo a ella; el administrador la abre desde su menú, junto con las demás secciones. Falta conectarla al servidor (7.2) | Cobro completo de una cuenta ✓ (`7c2a24d`) |  @Actronix09 |
| 7.5 | - [x] Pantallas adaptables | Cada pantalla tiene su `compacta` (700–760 px). Probado a 1280, 943 y 400 px. En teléfono, la orden actual del mesero es un botón desplegable (`51866e4`) y el teclado ya no se abre solo en el login (`ee96323`). *(Falta)* Al tocar un campo del login, el teclado tapa el acceso rápido y no se puede desplazar | Se usa bien en tamaño de teléfono ✓ (`7ab1a8e`) |  @Actronix09 |
| 7.6 | - [ ] Pantallas pendientes | En orden: 1. Ver logs · 2. Recuperar contraseña · 3. Crear usuario · 4. Admin › Usuarios ✓ (`5c16b68`, sobre la `Api` simulada) · 5. Admin › Productos con receta | Las cinco funcionan |  @Actronix09 |
| 7.7 | - [ ] Android | Compila para ARM64 en el contenedor `android/` (`47ca72b`, `b964a9a`) y el botón Atrás regresa de pantalla (`ee96323`). En una PC x86 el emulador no arranca imágenes ARM64, así que la app corre como ARM64 con la traducción de `google_apis`; el APK ya se probó en un teléfono. Falta: al bloquear el teléfono se cae el WebSocket, hay que reconectar y repetir el login al volver (`Qt.application.state`), junto con 7.2 | La app corre en un teléfono conectado al servidor de la PC |  @Actronix09 |
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
| C10 | Android | La interfaz también funciona en Android | 7.7 | APK para ARM64 ya probado en un teléfono (`b964a9a`); falta conectarlo al servidor (7.7) |
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
