# Usuarios y Permisos del Sistema de Comandas

En este documento se registran los roles de la base, los permisos de cada uno y la prueba de que funcionan: una base que siempre se usa con el usuario administrador no está protegida, porque cualquier error del programa puede borrar lo que sea.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Roles y usuarios, permisos con mínimo privilegio, conexión del script de carga, pruebas con mensajes del gestor, `REVOKE` y matriz de permisos.

**Archivos:** [`sql/migraciones/099-permisos.sql`](<../../sql/migraciones/099-permisos.sql>), [`sql/carga/crear_usuarios.sql`](<../../sql/carga/crear_usuarios.sql>) y [`sql/carga/probar_permisos.sh`](<../../sql/carga/probar_permisos.sh>)

---

## Roles y usuarios

Los roles agrupan permisos y no pueden entrar a la base. Cada uno tiene un usuario que sí entra y que solo hereda los permisos de su rol.

| Rol | Usuario | Para qué existe |
| :-- | :-- | :-- |
| `comandas_app` | `app_comandas` | Lo usan el servidor y el script de carga. Opera el salón, pero no borra comandas ni edita el dinero recibido, ni toca la estructura |
| `comandas_consulta` | `consulta_comandas` | Para reportes: solo lee, y nunca ve el hash de las contraseñas |
| `comandas_admin` | `admin_comandas` | Corrige datos a mano: todo sobre las tablas, pero no es dueño de ellas, así que no puede borrarlas ni crear roles |

La migración y los cambios de estructura siguen en manos de `pg-practica1`, el dueño de las tablas.

## Contraseñas

Las contraseñas salen de `COMANDAS_APP_CLAVE`, `COMANDAS_CONSULTA_CLAVE` y `COMANDAS_ADMIN_CLAVE`, que se definen en `sql/carga/.env`. Ese archivo no se sube al repositorio; [`.env.example`](<../../sql/carga/.env.example>) muestra qué variables lleva. `crear_usuarios.sql` las lee con `\getenv`.

En la imagen de PostgreSQL, las conexiones locales y las de `127.0.0.1` entran sin contraseña (`trust` en `pg_hba.conf`), así que probar por ahí no demostraría nada. Por eso los scripts se conectan a la IP del contenedor, donde el gestor exige la contraseña (`scram-sha-256`).

## Decisiones de mínimo privilegio

| Decisión | Por qué |
| :-- | :-- |
| `REVOKE ALL ON DATABASE ... FROM PUBLIC` y en el esquema `public` | Por omisión, cualquier usuario puede conectarse y crear tablas temporales. Así solo entran estos roles |
| `comandas_app` no puede hacer `DELETE` en `comanda`, `evento`, `mesa` ni `cuenta` | No se borran, cambian de estado: una comanda se cancela y queda registrado quién la canceló |
| `comandas_app` solo puede hacer `INSERT` en `pago` y `anticipo` | El dinero recibido no se edita ni se borra desde la aplicación |
| `comandas_app` sí puede leer `usuario.contrasena_hash` | El servidor valida las contraseñas contra ese hash |
| `comandas_consulta` lee `usuario` por columnas | Es la única forma de dejar fuera `contrasena_hash` y seguir leyendo el resto |
| `comandas_consulta` no recibe `TEMPORARY` | Un rol de lectura no necesita crear nada |
| `comandas_app` recibe `USAGE, UPDATE` en las secuencias | La carga ajusta las secuencias con `setval` después de poner los identificadores |
| La migración lleva el número 099 | Corre al final, para alcanzar lo que agreguen las demás migraciones |

### Los disparadores corren con los permisos de quien opera

Levantar una comanda dispara `tg_comanda_cuenta_abierta` (hace `FOR UPDATE` sobre `cuenta`), `tg_comanda_evento` (`FOR SHARE` sobre `evento`) y `tg_comanda_stock` (`UPDATE` sobre `ingrediente`). Con solo `SELECT` e `INSERT`, el gestor rechaza la operación:

```
ERROR:  permission denied for table cuenta
```

Había dos opciones: conceder esos permisos o declarar las funciones `SECURITY DEFINER`. Se concedieron, porque el rol de la aplicación ya los necesita de todos modos: es quien cierra cuentas, cambia el estado de los eventos y resurte ingredientes. `SECURITY DEFINER` habría dado a esas funciones los permisos del dueño de las tablas, sin ganar ninguna protección.

## El script de carga

`poblar.sh` entra como `app_comandas`, como se ve en la salida. Crear la base, correr las migraciones y crear los usuarios sigue siendo del administrador; `ADMIN_USUARIO` solo se usa para eso.

```
==> Creando la base comandas_carga con el esquema y las migraciones
    001-dominios.sql
    002-formato-usuario.sql
    099-permisos.sql
==> Base comandas_carga, usuario app_comandas
```

## Pruebas

`probar_permisos.sh` entra con el usuario y la contraseña reales de cada rol. Cada operación se revierte al terminar, así que no cambia ningún dato ([salida completa](<../../evidencias/practica4/permisos.txt>)).

| Usuario | Operación | Resultado | Mensaje del gestor |
| :-- | :-- | :-- | :-- |
| `app_comandas` | Entrar con una contraseña equivocada | Negada | `FATAL: password authentication failed for user "app_comandas"` |
| `app_comandas` | Levantar una comanda | Permitida | |
| `app_comandas` | Borrar una comanda | Negada | `ERROR: permission denied for table comanda` |
| `app_comandas` | Cambiar un pago ya recibido | Negada | `ERROR: permission denied for table pago` |
| `app_comandas` | Borrar la tabla `pago` | Negada | `ERROR: must be owner of table pago` |
| `consulta_comandas` | Leer el saldo de las cuentas (`v_cuenta`) | Permitida | |
| `consulta_comandas` | Leer nombre, usuario y rol de `usuario` | Permitida | |
| `consulta_comandas` | Leer `contrasena_hash` | Negada | `ERROR: permission denied for table usuario` |
| `consulta_comandas` | Cambiar un precio | Negada | `ERROR: permission denied for table producto` |
| `consulta_comandas` | Crear una tabla temporal | Negada | `ERROR: permission denied to create temporary tables in database "comandas_carga"` |
| `admin_comandas` | Corregir un pago | Permitida | |
| `admin_comandas` | Borrar la receta de un producto | Permitida | |
| `admin_comandas` | Borrar la tabla `pago` | Negada | `ERROR: must be owner of table pago` |
| `admin_comandas` | Crear otro rol | Negada | `ERROR: permission denied to create role` |

## `REVOKE`

Se retira un permiso y la misma operación deja de funcionar. Al devolverlo, vuelve a funcionar:

```
  [ok] permitida Registrar un anticipo, antes del REVOKE
       INSERT INTO anticipo (monto, numero_evento) VALUES (500, 1)
       REVOKE INSERT ON anticipo FROM comandas_app
  [ok] negada   Registrar un anticipo, después del REVOKE
       INSERT INTO anticipo (monto, numero_evento) VALUES (500, 1)
       ERROR:  permission denied for table anticipo
       GRANT INSERT ON anticipo TO comandas_app
  [ok] permitida Registrar un anticipo, después de devolver el permiso
       INSERT INTO anticipo (monto, numero_evento) VALUES (500, 1)
```

## Matriz de permisos

Se leyó del catálogo con `has_table_privilege`, no se escribió a mano. `S` es `SELECT`, `I` es `INSERT`, `U` es `UPDATE` y `D` es `DELETE`. El asterisco significa que solo tiene permiso en algunas columnas.

| Tabla | `comandas_app` | `comandas_consulta` | `comandas_admin` |
| :-- | :--: | :--: | :--: |
| `acuerdo` | SIUD | S | SIUD |
| `anticipo` | SI | S | SIUD |
| `bar_cocina` | SIUD | S | SIUD |
| `cajero_admin` | SIUD | S | SIUD |
| `comanda` | SIU | S | SIUD |
| `cuenta` | SIU | S | SIUD |
| `evento` | SIU | S | SIUD |
| `evento_organizador` | SIUD | S | SIUD |
| `ingrediente` | SIUD | S | SIUD |
| `mesa` | SIU | S | SIUD |
| `mesero` | SIUD | S | SIUD |
| `pago` | SI | S | SIUD |
| `paquete` | SIUD | S | SIUD |
| `paquete_producto` | SIUD | S | SIUD |
| `producto` | SIUD | S | SIUD |
| `receta` | SIUD | S | SIUD |
| `usuario` | SIUD | S* | SIUD |

`comandas_consulta` puede leer todo `usuario` salvo `contrasena_hash`. Los tres roles también pueden leer las vistas (`v_evento`, `v_cuenta`, `v_usuario`, `v_mesero`, `v_producto` y `v_comanda`).

## Lo que queda después de esta práctica

El servidor de `Sistema-de-Comandas` todavía se conecta con el usuario administrador. Debe pasar a `app_comandas` cuando se retome su desarrollo, junto con las migraciones.
