# Pruebas de restricciones de dominio

Práctica 4, ejercicio 1.5 · Sistema de Comandas

Estos diez casos documentan restricciones de columna del esquema. Los resultados y mensajes corresponden a `sql/inserts-rechazados.sql` y `sql/pruebas-validas.sql`. En el caso 10 se comparan dos operaciones para distinguir el valor por omisión de un `NULL` explícito.

| # | Operación intentada | Resultado esperado | Respuesta del gestor | Regla protegida |
| :--: | :-- | :-- | :-- | :-- |
| 1 | Insertar una mesa del evento 17 con `id_mesero = NULL` (rechazo 3). | Rechazar la fila. | `null value in column "id_mesero" of relation "mesa" violates not-null constraint` | Toda mesa debe tener un mesero responsable. |
| 2 | Insertar un usuario nuevo con el nombre de acceso `lmendez`, que ya pertenece a otra persona (rechazo 8). | Rechazar el duplicado. | `duplicate key value violates unique constraint "uq_usuario_usuario"` | Cada nombre de acceso identifica a una sola cuenta. |
| 3 | Insertar `LMENDEZ` cuando ya existe `lmendez` (rechazo 29). | Rechazarlo aunque cambien las mayúsculas. | `duplicate key value violates unique constraint "ux_usuario_usuario_minusculas"` | Los nombres de acceso son únicos sin distinguir mayúsculas y minúsculas. |
| 4 | Insertar otra mesa con el par `(numero_evento, numero_mesa) = (17, 1)` (rechazo 2). | Rechazar la clave primaria compuesta duplicada. | `duplicate key value violates unique constraint "pk_mesa"` | El número de mesa solo puede aparecer una vez dentro del mismo evento. |
| 5 | Insertar de nuevo el acuerdo `(evento 17, paquete 1, producto 1)` (rechazo 13). | Rechazar la combinación duplicada. | `duplicate key value violates unique constraint "pk_acuerdo"` | Un producto aparece una sola vez por paquete dentro del acuerdo de un evento. |
| 6 | Registrar un pago de `0.00` (rechazo 9). | Rechazar el pago. | `new row for relation "pago" violates check constraint "ck_pago_monto"` | Un pago debe ser mayor que cero. |
| 7 | Cambiar el stock de un ingrediente a `-5` (rechazo 17). | Rechazar el stock negativo. | `new row for relation "ingrediente" violates check constraint "ck_ingrediente_stock"` | El inventario nunca puede quedar por debajo de cero. |
| 8 | Registrar un pago de `10` con propina de `20` (rechazo 25). | Rechazar la propina que excede el pago. | `new row for relation "pago" violates check constraint "ck_pago_propina_limite"` | La propina no puede superar el importe total pagado. |
| 9 | Insertar el nombre de acceso `ana maria`, con un espacio (rechazo 35). | Rechazar el formato. | `new row for relation "usuario" violates check constraint "ck_usuario_formato"` | El acceso tiene de 3 a 40 caracteres: empieza con una letra ASCII y continúa solo con letras ASCII o números. |
| 10 | Crear un evento sin especificar `estado` (caso válido 15); luego intentar crear otro con `estado = NULL` (rechazo 36). | La primera fila debe quedar `programado`; la segunda debe rechazarse. | Sin error en la primera operación; en la segunda: `null value in column "estado" of relation "evento" violates not-null constraint` | El gestor asigna `programado` cuando el estado se omite; un `NULL` explícito no debe dejar un evento sin estado. |

## Cómo reproducirlos

Desde la raíz del repositorio, `make -C sql pruebas` recrea `comandas_pruebas`, aplica el esquema y las migraciones, carga los datos de ejemplo y ejecuta los casos. El resultado esperado es que cada rechazo falle por la restricción indicada y que todos los casos válidos pasen.
