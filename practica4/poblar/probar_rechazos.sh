#!/usr/bin/env bash
# =====================================================================
#  probar_rechazos.sh — Comprueba que la carga rechace los datos malos
#  Práctica 4, Ejercicio 1.4 · Bases de Datos (3CV4)
#
#  Agrega a una copia de los CSV renglones que violan una restricción, corre
#  poblar.sh en una base temporal y revisa que la base quede vacía.
#  Los renglones malos son de prueba: no están en practica4/datos/.
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
: "${ADMIN_USUARIO:?Falta la variable ADMIN_USUARIO}"
export PGDATABASE=comandas_carga_rechazos

COPIA="$(mktemp -d)/datos"
terminar() {
    "$MOTOR" exec "$CONTENEDOR" psql -X -q -U "$ADMIN_USUARIO" -d postgres -c "DROP DATABASE IF EXISTS $PGDATABASE WITH (FORCE);" 2> /dev/null || true
    rm -rf "$(dirname "$COPIA")"
}
trap terminar EXIT

cp -r "$RAIZ/practica4/datos/generados" "$COPIA"

echo '900,Harina de prueba,kg,10,1,prueba'                                            >> "$COPIA/ingrediente.csv"
{
    echo '900,Producto con precio negativo,,alimentos,-5.00,,prueba'
    echo '901,Producto de otra categoría,,postres,10.00,,prueba'
    echo '902,Tacos,,alimentos,10.00,,prueba'
    echo '903,Producto sin precio,,alimentos,,,prueba'
} >> "$COPIA/producto.csv"
{
    echo '900,Usuario Con Otro Rol,urolmalo,1990-01-01,x,gerente'
    echo '901,Usuario Fecha Imposible,ufechamala,31/02/1990,x,mesero'
} >> "$COPIA/usuario.csv"
echo '900,2026-12-01,Boda,0,programado'                                                >> "$COPIA/evento.csv"
echo '9999,1,1'                                                                        >> "$COPIA/mesa.csv"
echo '99001,2026-01-01T20:00:00-06:00,10.00,entregada,,1,1,1,2,1,'                     >> "$COPIA/comanda.csv"
echo '99001,999999.00,efectivo,2026-01-01T23:00:00-06:00,1,1,176,,'                    >> "$COPIA/pago.csv"

if DATOS="$COPIA" "$POBLAR_DIR/poblar.sh" --recrear; then
    echo "==> ERROR: la carga se confirmó con datos malos" >&2
    exit 1
fi

echo
echo "==> Renglones que quedaron en la base después de revertir"
for tabla in ingrediente producto usuario evento mesa comanda pago; do
    printf '%-12s %s\n' "$tabla" "$("$MOTOR" exec "$CONTENEDOR" psql -X -At -U "$ADMIN_USUARIO" -d "$PGDATABASE" -c "SELECT count(*) FROM $tabla;")"
done
