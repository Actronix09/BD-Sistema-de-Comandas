#!/usr/bin/env bash
# =====================================================================
#  experimento-2.6-adrian.sh — Corre el experimento individual sobre una copia
#  Práctica 5, Ejercicio 2.6 · Bases de Datos (3CV4)
#
#  Necesita la base ya cargada con sql/carga/poblar.sh y usa el mismo .env.
#  Solo la copia comandas_experimento_adrian cambia de acción, y se borra al
#  terminar. Al final se revisa que la base cargada siga con RESTRICT.
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

EVIDENCIA="$RAIZ/evidencias/practica5/experimento-2.6-adrian.txt"

psql_admin() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -U "$ADMIN_USUARIO" "$@"; }

terminar() { psql_admin -d postgres -c 'DROP DATABASE IF EXISTS comandas_experimento_adrian WITH (FORCE);' 2>/dev/null; }
trap terminar EXIT

terminar
psql_admin -d postgres -c "CREATE DATABASE comandas_experimento_adrian TEMPLATE \"$PGDATABASE\";"

# El 2>&1 va dentro del contenedor para que los errores queden junto a su sentencia.
"$MOTOR" exec -i "$CONTENEDOR" sh -c "psql -X -q -e -U '$ADMIN_USUARIO' -d comandas_experimento_adrian 2>&1" \
    < "$SQL_DIR/experimento-2.6-adrian.sql" | tee "$EVIDENCIA"

accion="$(psql_admin -d "$PGDATABASE" -Atc "SELECT confdeltype FROM pg_constraint WHERE conname = 'fk_comanda_cuenta';")"
if [ "$accion" != "r" ]; then
    echo "La base $PGDATABASE ya no tiene RESTRICT en fk_comanda_cuenta" >&2
    exit 1
fi
{
    echo
    echo "La base $PGDATABASE no cambió: fk_comanda_cuenta sigue con RESTRICT."
} | tee -a "$EVIDENCIA"
