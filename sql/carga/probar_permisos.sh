#!/usr/bin/env bash
# =====================================================================
#  probar_permisos.sh — Prueba cada rol con operaciones permitidas y negadas
#  Práctica 4, Ejercicio 1.6 · Bases de Datos (3CV4)
#
#  Necesita la base ya cargada con poblar.sh. Cada operación entra con su
#  usuario y contraseña reales, y se revierte al terminar: no cambia ningún dato.
#  Termina con 1 si una operación no da el resultado esperado.
# =====================================================================

set -euo pipefail

POBLAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$POBLAR_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$POBLAR_DIR/.env"
    set +a
fi

MOTOR="${MOTOR:-docker}"
CONTENEDOR="${CONTENEDOR:-practica1-postgres}"
: "${PGDATABASE:?Falta la variable PGDATABASE}"
: "${ADMIN_USUARIO:?Falta la variable ADMIN_USUARIO}"
export PGDATABASE

fallos=0

# Entra por la IP del contenedor, donde el gestor sí pide la contraseña.
conectar() {
    local usuario="$1" clave="$2"
    shift 2
    PGUSER="$usuario" PGPASSWORD="$clave" "$MOTOR" exec -i -e PGDATABASE -e PGUSER -e PGPASSWORD "$CONTENEDOR" \
        sh -c 'PGHOST=$(hostname -i) exec psql -X -q -At -v ON_ERROR_STOP=1 "$@"' sh "$@"
}

admin() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -v ON_ERROR_STOP=1 -U "$ADMIN_USUARIO" -d "$PGDATABASE" "$@"; }

# $1 = se espera (permitida o negada), $2 = usuario, $3 = contraseña, $4 = descripción, $5 = sentencia
probar() {
    local esperado="$1" usuario="$2" clave="$3" descripcion="$4" sentencia="$5" salida resultado
    if salida=$(printf 'BEGIN;\n%s;\nROLLBACK;\n' "$sentencia" | conectar "$usuario" "$clave" 2>&1); then
        resultado=permitida
    else
        resultado=negada
    fi
    if [ "$resultado" = "$esperado" ]; then
        printf '  [ok] %-8s %s\n' "$resultado" "$descripcion"
    else
        printf '  [FALLO] se esperaba %s y fue %s: %s\n' "$esperado" "$resultado" "$descripcion"
        fallos=$((fallos + 1))
    fi
    printf '       %s\n' "$sentencia"
    if [ "$resultado" = negada ]; then
        printf '%s\n' "$salida" | grep -E 'ERROR|FATAL' | sed -E 's/^.*(ERROR|FATAL)/       \1/'
    fi
}

COMANDA="INSERT INTO comanda (numero_evento, secuencial, id_mesero, id_producto)
       SELECT numero_evento, secuencial, 1, 2 FROM cuenta WHERE estado = 'abierta' LIMIT 1"
ANTICIPO="INSERT INTO anticipo (monto, numero_evento) VALUES (500, 1)"

echo "==> Contraseña"
probar permitida app_comandas "$COMANDAS_APP_CLAVE" 'Entrar con la contraseña correcta' 'SELECT 1'
probar negada app_comandas 'contrasena-equivocada' 'Entrar con una contraseña equivocada' 'SELECT 1'

echo
echo "==> comandas_app (usuario app_comandas)"
probar permitida app_comandas "$COMANDAS_APP_CLAVE" 'Levantar una comanda; sus disparadores tocan cuenta, evento e ingrediente' "$COMANDA"
probar negada app_comandas "$COMANDAS_APP_CLAVE" 'Borrar una comanda: se cancela, no se borra' 'DELETE FROM comanda WHERE id_comanda = 1'
probar negada app_comandas "$COMANDAS_APP_CLAVE" 'Cambiar un pago ya recibido' 'UPDATE pago SET monto = 1 WHERE numero_pago = 1'
probar negada app_comandas "$COMANDAS_APP_CLAVE" 'Borrar una tabla' 'DROP TABLE pago'

echo
echo "==> comandas_consulta (usuario consulta_comandas)"
probar permitida consulta_comandas "$COMANDAS_CONSULTA_CLAVE" 'Leer el saldo de las cuentas' 'SELECT count(*) FROM v_cuenta'
probar permitida consulta_comandas "$COMANDAS_CONSULTA_CLAVE" 'Leer los datos de un usuario, sin su contraseña' 'SELECT nombre, usuario, rol FROM usuario LIMIT 1'
probar negada consulta_comandas "$COMANDAS_CONSULTA_CLAVE" 'Leer el hash de las contraseñas' 'SELECT contrasena_hash FROM usuario LIMIT 1'
probar negada consulta_comandas "$COMANDAS_CONSULTA_CLAVE" 'Cambiar un precio' 'UPDATE producto SET precio = 1 WHERE id_producto = 1'
probar negada consulta_comandas "$COMANDAS_CONSULTA_CLAVE" 'Crear una tabla temporal' 'CREATE TEMP TABLE prueba (id INTEGER)'

echo
echo "==> comandas_admin (usuario admin_comandas)"
probar permitida admin_comandas "$COMANDAS_ADMIN_CLAVE" 'Corregir un pago' 'UPDATE pago SET monto = monto WHERE numero_pago = 1'
probar permitida admin_comandas "$COMANDAS_ADMIN_CLAVE" 'Borrar la receta de un producto' 'DELETE FROM receta WHERE id_producto = 2'
probar negada admin_comandas "$COMANDAS_ADMIN_CLAVE" 'Borrar una tabla: no es su dueño' 'DROP TABLE pago'
probar negada admin_comandas "$COMANDAS_ADMIN_CLAVE" 'Crear otro rol' 'CREATE ROLE intruso'

echo
echo "==> REVOKE: la operación deja de funcionar"
trap 'admin -c "GRANT INSERT ON anticipo TO comandas_app;"' EXIT
probar permitida app_comandas "$COMANDAS_APP_CLAVE" 'Registrar un anticipo, antes del REVOKE' "$ANTICIPO"
echo "       REVOKE INSERT ON anticipo FROM comandas_app"
admin -c 'REVOKE INSERT ON anticipo FROM comandas_app;'
probar negada app_comandas "$COMANDAS_APP_CLAVE" 'Registrar un anticipo, después del REVOKE' "$ANTICIPO"
echo "       GRANT INSERT ON anticipo TO comandas_app"
admin -c 'GRANT INSERT ON anticipo TO comandas_app;'
probar permitida app_comandas "$COMANDAS_APP_CLAVE" 'Registrar un anticipo, después de devolver el permiso' "$ANTICIPO"

echo
echo "==> Matriz de permisos, leída del catálogo (S = SELECT, I = INSERT, U = UPDATE, D = DELETE; * = solo algunas columnas)"
admin <<'SQL'
\pset footer off
SELECT c.relname AS tabla, r.app AS comandas_app, r.consulta AS comandas_consulta, r.administrador AS comandas_admin
FROM pg_class c
CROSS JOIN LATERAL (
    SELECT max(p) FILTER (WHERE rol = 'comandas_app') AS app,
           max(p) FILTER (WHERE rol = 'comandas_consulta') AS consulta,
           max(p) FILTER (WHERE rol = 'comandas_admin') AS administrador
    FROM (
        SELECT rol, COALESCE(NULLIF(
                   CASE WHEN has_table_privilege(rol, c.oid, 'SELECT') THEN 'S'
                        WHEN has_any_column_privilege(rol, c.oid, 'SELECT') THEN 'S*' ELSE '' END
                   || CASE WHEN has_table_privilege(rol, c.oid, 'INSERT') THEN 'I' ELSE '' END
                   || CASE WHEN has_table_privilege(rol, c.oid, 'UPDATE') THEN 'U' ELSE '' END
                   || CASE WHEN has_table_privilege(rol, c.oid, 'DELETE') THEN 'D' ELSE '' END, ''), '-') AS p
        FROM unnest(ARRAY['comandas_app', 'comandas_consulta', 'comandas_admin']) AS rol
    ) x
) r
WHERE c.relnamespace = 'public'::regnamespace AND c.relkind = 'r'
ORDER BY c.relname;
SQL

echo
if [ "$fallos" -gt 0 ]; then
    echo "==> $fallos operaciones no dieron el resultado esperado" >&2
    exit 1
fi
echo "==> Todas las operaciones dieron el resultado esperado"
