#!/usr/bin/env bash
# =====================================================================
#  poblar.sh — Puebla la base del Sistema de Comandas con un solo comando
#  Práctica 4, Ejercicio 1.4 · Bases de Datos (3CV4)
#
#      practica4/poblar/poblar.sh              carga los datos
#      practica4/poblar/poblar.sh --recrear    borra la base y la carga desde cero
#
#  La conexión se arma con variables de entorno o con practica4/poblar/.env,
#  que no se sube al repositorio. Ver .env.example.
#
#  Si la base no existe, la crea con sql/esquema.sql y las migraciones de
#  practica4/migraciones/. Termina con 0 si la carga se confirmó y con 1 si se
#  revirtió; los rechazos quedan en practica4/poblar/rechazos.csv.
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
DATOS="${DATOS:-$RAIZ/practica4/datos/generados}"

for variable in PGDATABASE PGUSER PGPASSWORD ADMIN_USUARIO; do
    if [ -z "${!variable:-}" ]; then
        echo "Falta la variable $variable. Copie practica4/poblar/.env.example a practica4/poblar/.env y llénela." >&2
        exit 2
    fi
done

if ! [[ "$PGDATABASE" =~ ^[a-z_][a-z0-9_]*$ ]]; then
    echo "PGDATABASE no es un nombre válido: $PGDATABASE" >&2
    exit 2
fi

# Se pasa el nombre de la variable y no su valor, para que la contraseña no
# aparezca en la lista de procesos.
psql_app() { "$MOTOR" exec -i -e PGDATABASE -e PGUSER -e PGPASSWORD "$CONTENEDOR" psql -X -q -v ON_ERROR_STOP=1 "$@"; }
psql_admin() { "$MOTOR" exec -i "$CONTENEDOR" psql -X -q -v ON_ERROR_STOP=1 -U "$ADMIN_USUARIO" "$@"; }

if ! "$MOTOR" exec "$CONTENEDOR" pg_isready -q > /dev/null 2>&1; then
    echo "El contenedor $CONTENEDOR no está listo. Levántelo con: make -C sql levantar" >&2
    exit 2
fi

if [ "${1:-}" = "--recrear" ]; then
    # `comandas` y `comandas_pruebas` son de sql/Makefile: esta opción no las toca.
    case "$PGDATABASE" in
        postgres|comandas|comandas_pruebas)
            echo "--recrear no borra la base $PGDATABASE. Use otra en PGDATABASE." >&2
            exit 2
            ;;
    esac
    echo "==> Borrando la base $PGDATABASE"
    psql_admin -d postgres -c "DROP DATABASE IF EXISTS \"$PGDATABASE\" WITH (FORCE);" 2>/dev/null
fi

if [ -z "$(psql_admin -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$PGDATABASE';")" ]; then
    echo "==> Creando la base $PGDATABASE con el esquema y las migraciones"
    psql_admin -d postgres -c "CREATE DATABASE \"$PGDATABASE\" ENCODING 'UTF8';"
    psql_admin -d "$PGDATABASE" < "$RAIZ/sql/esquema.sql" > /dev/null
    for migracion in "$RAIZ"/practica4/migraciones/*.sql; do
        [ -e "$migracion" ] || continue
        echo "    $(basename "$migracion")"
        psql_admin -d "$PGDATABASE" < "$migracion" > /dev/null
    done
fi

"$MOTOR" exec "$CONTENEDOR" rm -rf /tmp/poblar
"$MOTOR" exec "$CONTENEDOR" mkdir -p /tmp/poblar
"$MOTOR" cp "$DATOS" "$CONTENEDOR:/tmp/poblar/datos" > /dev/null
"$MOTOR" cp "$POBLAR_DIR/poblar.sql" "$CONTENEDOR:/tmp/poblar/poblar.sql" > /dev/null

echo "==> Base $PGDATABASE, usuario $PGUSER"
inicio=$SECONDS
psql_app -f /tmp/poblar/poblar.sql
echo "==> Tiempo total: $((SECONDS - inicio)) s"

"$MOTOR" cp "$CONTENEDOR:/tmp/poblar/rechazos.csv" "$POBLAR_DIR/rechazos.csv" > /dev/null
"$MOTOR" exec "$CONTENEDOR" rm -rf /tmp/poblar

# El archivo siempre trae su encabezado: más de una línea significa rechazos.
if [ "$(wc -l < "$POBLAR_DIR/rechazos.csv")" -gt 1 ]; then
    echo "==> Ver los rechazos en practica4/poblar/rechazos.csv" >&2
    exit 1
fi
