#!/usr/bin/env bash
# =====================================================================
#  comparar_tiempos.sh — Carga masiva contra un INSERT por renglón
#  Práctica 4, Ejercicio 1.4 · Bases de Datos (3CV4)
#
#  Carga comanda.csv de tres formas en una base temporal, en una tabla sin
#  restricciones ni disparadores, para medir solo la forma de cargar.
#  Al terminar borra la base temporal. Usa ADMIN_USUARIO, igual que poblar.sh.
# =====================================================================

set -euo pipefail

POBLAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$POBLAR_DIR/../.." && pwd)"

if [ -f "$POBLAR_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$POBLAR_DIR/.env"
    set +a
fi

MOTOR="${MOTOR:-docker}"
CONTENEDOR="${CONTENEDOR:-practica1-postgres}"
BASE=comandas_tiempos
: "${ADMIN_USUARIO:?Falta la variable ADMIN_USUARIO}"

psql_base() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -v ON_ERROR_STOP=1 -U "$ADMIN_USUARIO" -d "$BASE" "$@"; }
psql_admin() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -v ON_ERROR_STOP=1 -U "$ADMIN_USUARIO" -d postgres "$@"; }

terminar() {
    psql_admin -c "DROP DATABASE IF EXISTS $BASE WITH (FORCE);" 2> /dev/null || true
    "$MOTOR" exec "$CONTENEDOR" rm -rf /tmp/tiempos
}
trap terminar EXIT

# Corre el comando, muestra los segundos y deja la tabla vacía para la siguiente forma.
medir() {
    local etiqueta="$1"
    shift
    local inicio fin
    inicio=$(date +%s%N)
    "$@" > /dev/null
    fin=$(date +%s%N)
    printf '%-38s %8s s\n' "$etiqueta" "$(awk "BEGIN { printf \"%.2f\", ($fin - $inicio) / 1000000000 }")"
    psql_base -c 'TRUNCATE prueba;'
}

psql_admin -c "DROP DATABASE IF EXISTS $BASE WITH (FORCE);" 2> /dev/null
psql_admin -c "CREATE DATABASE $BASE ENCODING 'UTF8';"
"$MOTOR" exec "$CONTENEDOR" mkdir -p /tmp/tiempos
"$MOTOR" cp "$RAIZ/practica4/datos/generados/comanda.csv" "$CONTENEDOR:/tmp/tiempos/comanda.csv" > /dev/null

psql_base <<'SQL'
CREATE TABLE prueba (
    id_comanda INTEGER, fecha_hora TIMESTAMPTZ, precio_cobrado NUMERIC(10,2), estado TEXT, detalles TEXT, numero_evento INTEGER,
    secuencial SMALLINT, id_mesero INTEGER, id_producto INTEGER, id_bar_cocina INTEGER, id_cajero_cancela INTEGER
);
\copy prueba FROM '/tmp/tiempos/comanda.csv' CSV HEADER
\pset tuples_only on
\pset format unaligned
\o /tmp/tiempos/inserts.sql
SELECT format('INSERT INTO prueba VALUES (%L, %L, %L, %L, %L, %L, %L, %L, %L, %L, %L);', id_comanda, fecha_hora, precio_cobrado, estado,
              detalles, numero_evento, secuencial, id_mesero, id_producto, id_bar_cocina, id_cajero_cancela) FROM prueba;
\o
TRUNCATE prueba;
SQL

renglones=$("$MOTOR" exec "$CONTENEDOR" sh -c 'wc -l < /tmp/tiempos/inserts.sql')
echo "==> $renglones renglones de comanda.csv"
medir '\copy' psql_base -c "\\copy prueba FROM '/tmp/tiempos/comanda.csv' CSV HEADER"
medir 'INSERT por renglón, una transacción' psql_base -1 -f /tmp/tiempos/inserts.sql
medir 'INSERT por renglón, con autocommit' psql_base -f /tmp/tiempos/inserts.sql
