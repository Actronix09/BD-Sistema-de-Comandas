#!/usr/bin/env bash
# =====================================================================
#  edicion-de-valores.sh — Corre el ejercicio 2.4 sobre una copia de la base
#  Práctica 5, Ejercicio 2.4 · Bases de Datos (3CV4)
#
#  Necesita la base ya cargada con sql/carga/poblar.sh y usa el mismo .env.
#  Los cambios quedan en la copia comandas_edicion, que se borra al terminar: se
#  puede repetir cuantas veces se quiera y la base cargada no cambia.
# =====================================================================

set -euo pipefail

SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$SQL_DIR/../.." && pwd)"

if [ -f "$RAIZ/sql/carga/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$RAIZ/sql/carga/.env"
    set +a
fi

MOTOR="${MOTOR:-docker}"
CONTENEDOR="${CONTENEDOR:-practica1-postgres}"
: "${PGDATABASE:?Falta la variable PGDATABASE}"
: "${ADMIN_USUARIO:?Falta la variable ADMIN_USUARIO}"

psql_admin() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -U "$ADMIN_USUARIO" "$@"; }

terminar() { psql_admin -d postgres -c 'DROP DATABASE IF EXISTS comandas_edicion WITH (FORCE);' 2>/dev/null; }
trap terminar EXIT

terminar
psql_admin -d postgres -c "CREATE DATABASE comandas_edicion TEMPLATE \"$PGDATABASE\";"

# El 2>&1 va dentro del contenedor para que los errores queden junto a su sentencia.
"$MOTOR" exec -i "$CONTENEDOR" sh -c "psql -X -q -e -U '$ADMIN_USUARIO' -d comandas_edicion 2>&1" \
    < "$SQL_DIR/edicion-de-valores.sql" | tee "$RAIZ/evidencias/practica5/edicion-de-valores.txt"
