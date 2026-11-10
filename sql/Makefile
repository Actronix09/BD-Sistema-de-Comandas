# =====================================================================
#  Makefile — Base de datos del Sistema de Comandas
#
#  Levanta el contenedor de PostgreSQL y corre la secuencia de pruebas:
#  esquema → migraciones numeradas → datos de ejemplo → rechazos → válidas.
#
#      make                 lista los objetivos
#      make pruebas         corrida completa sobre la base de pruebas
#      make cargar          deja la base `comandas` recién cargada
#
#  Se puede llamar desde la raíz del repositorio con `make -C sql pruebas`.
#  Cualquier variable se cambia en la línea de comandos:
#      make pruebas MOTOR=podman
# =====================================================================

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Carpeta de los scripts. Es la carpeta donde corre make, así que se usa
# desde sql/ o con `make -C sql`. No se calcula con $(dir …): make parte
# las rutas en los espacios, y "Bases de Datos" tiene espacios.
SQL_DIR      ?= $(CURDIR)
COMPOSE_FILE ?= $(SQL_DIR)/../entorno/compose.yml
MIGRACIONES_DIR ?= $(SQL_DIR)/migraciones

MOTOR        ?= docker
CONTENEDOR   ?= practica1-postgres
USUARIO      ?= pg-practica1
BASE         ?= comandas
BASE_PRUEBAS ?= comandas_pruebas

COMPOSE := $(MOTOR) compose -f "$(COMPOSE_FILE)"
# -X: no lee ~/.psqlrc · -q: sin las etiquetas CREATE TABLE, INSERT 0 1…
PSQL    := $(MOTOR) exec -i $(CONTENEDOR) psql -X -q -U $(USUARIO)

.DEFAULT_GOAL := help
.PHONY: help levantar detener estado cargar pruebas rechazados validas referenciales experimento-samy psql limpiar

help:
	@echo "Objetivos:"
	@echo "  levantar     Levanta el contenedor $(CONTENEDOR) y espera a que acepte conexiones"
	@echo "  detener      Detiene el contenedor (el volumen y los datos se conservan)"
	@echo "  estado       Muestra el contenedor y las bases que existen"
	@echo "  cargar       Recrea $(BASE): esquema.sql, migraciones y datos-ejemplo.sql"
	@echo "  pruebas      Recrea $(BASE_PRUEBAS) y corre toda la secuencia de pruebas"
	@echo "  rechazados   Corre inserts-rechazados.sql y exige que cada caso falle"
	@echo "  validas      Corre pruebas-validas.sql y verifica todos sus casos"
	@echo "  referenciales Corre pruebas-referenciales.sql sobre $(BASE_PRUEBAS)"
	@echo "  experimento-samy Recrea una copia y prueba el caso 2.6 de receta/ingrediente"
	@echo "  psql         Abre una consola sobre $(BASE)"
	@echo "  limpiar      Borra la base $(BASE_PRUEBAS)"
	@echo
	@echo "Variables: MOTOR=$(MOTOR) CONTENEDOR=$(CONTENEDOR) USUARIO=$(USUARIO)"
	@echo "           BASE=$(BASE) BASE_PRUEBAS=$(BASE_PRUEBAS)"
	@echo "           MIGRACIONES_DIR=$(MIGRACIONES_DIR)"

levantar:
	@$(COMPOSE) up -d
	@echo "==> Esperando a PostgreSQL..."
	@for i in $$(seq 30); do \
		if $(MOTOR) exec $(CONTENEDOR) pg_isready -q -U $(USUARIO); then \
			echo "==> PostgreSQL listo"; exit 0; \
		fi; \
		sleep 1; \
	done; \
	echo "PostgreSQL no respondió en 30 s" >&2; exit 1

# `stop` y no `down -v`: down -v borraría el volumen con todos los datos.
detener:
	@$(COMPOSE) stop

estado:
	@$(MOTOR) ps --filter name=$(CONTENEDOR)
	@echo
	@$(PSQL) -d postgres -c '\l'

# Recetas reutilizables. Se usan con $(call …) dentro de los objetivos, en
# lugar de llamar a make de nuevo, para que funcionen igual con -C y con -f.

# $(1) = base. Recrea la base y carga esquema, migraciones y datos.
# ON_ERROR_STOP detiene cada archivo en el primer error; cada migración debe
# usar BEGIN…COMMIT para que el error deshaga ese archivo.
define cargar_base
@echo "==> Recreando la base $(1)"
@$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS "$(1)" WITH (FORCE);'
@$(PSQL) -d postgres -c "CREATE DATABASE \"$(1)\" ENCODING 'UTF8';"
@echo "==> esquema.sql"
@$(PSQL) -v ON_ERROR_STOP=1 -d $(1) < "$(SQL_DIR)/esquema.sql" > /dev/null
@hay_migraciones=0; \
for archivo in "$(MIGRACIONES_DIR)"/[0-9][0-9][0-9]-*.sql; do \
	[ -f "$$archivo" ] || continue; \
	hay_migraciones=1; \
	echo "==> Migración $${archivo##*/}"; \
	$(PSQL) -v ON_ERROR_STOP=1 -d $(1) < "$$archivo" > /dev/null; \
done; \
if [ "$$hay_migraciones" -eq 0 ]; then echo "==> Sin migraciones numeradas"; fi
@echo "==> datos-ejemplo.sql"
@$(PSQL) -v ON_ERROR_STOP=1 -d $(1) < "$(SQL_DIR)/datos-ejemplo.sql" > /dev/null
endef

define correr_referenciales
@echo "==> pruebas-referenciales.sql"
@$(PSQL) -v ON_ERROR_STOP=1 -d $(BASE_PRUEBAS) < "$(SQL_DIR)/practica5/pruebas-referenciales.sql"
endef

# Sin ON_ERROR_STOP: cada INSERT debe fallar y seguir con el siguiente.
# Cada caso empieza con un \warn '--- N. …'; awk revisa que entre un
# marcador y el siguiente haya al menos un ERROR. Necesita los datos recién
# cargados, así que lo normal es correrlo dentro de `make pruebas`.
define correr_rechazados
@echo "==> inserts-rechazados.sql"
@$(PSQL) -d $(BASE_PRUEBAS) < "$(SQL_DIR)/inserts-rechazados.sql" 2>&1 >/dev/null | awk ' \
	function cerrar() { \
		if (caso == "") return; \
		if (!hubo_error) { print "      ✗ NO SE RECHAZÓ: la fila se guardó"; malos++ } \
	} \
	/^--- [0-9]+\./ { cerrar(); caso = $$0; hubo_error = 0; total++; print "  " caso; next } \
	/ERROR:/ { hubo_error = 1; sub(/^.*ERROR: */, ""); print "      ✓ " $$0; next } \
	END { \
		cerrar(); \
		printf "==> Rechazados: %d de %d\n", total - malos, total; \
		exit (malos > 0 || total == 0) \
	}'
endef

# Con ON_ERROR_STOP: el primer ASSERT que falla detiene el archivo. Cada caso
# empieza con un \warn '=== N. …'; un caso pasó si se llegó al siguiente
# marcador (o al final) sin un ERROR. El total se cuenta en el archivo, así
# que los casos que no alcanzaron a correr también cuentan como faltantes.
define correr_validas
@if [ -f "$(SQL_DIR)/pruebas-validas.sql" ]; then \
	echo "==> pruebas-validas.sql"; \
	total=$$(grep -cE "^[[:space:]]*.warn '=== [0-9]+\." "$(SQL_DIR)/pruebas-validas.sql" || true); \
	$(PSQL) -v ON_ERROR_STOP=1 -d $(BASE_PRUEBAS) < "$(SQL_DIR)/pruebas-validas.sql" 2>&1 >/dev/null | awk -v total="$$total" ' \
		function cerrar() { \
			if (caso != "" && !hubo_error) { print "      ✓ pasó"; bien++ } \
		} \
		/^=== [0-9]+\./ { cerrar(); caso = $$0; print "  " caso; next } \
		/ERROR:/ { hubo_error = 1; sub(/^.*ERROR: */, ""); print "      ✗ " $$0; next } \
		hubo_error { print "        " $$0 } \
		END { \
			cerrar(); \
			printf "==> Válidas: %d de %d\n", bien, total; \
			exit (hubo_error || bien != total) \
		}'; \
else \
	echo "==> Falta pruebas-validas.sql" >&2; exit 1; \
fi
endef

cargar: levantar
	$(call cargar_base,$(BASE))

pruebas: levantar
	$(call cargar_base,$(BASE_PRUEBAS))
	$(correr_rechazados)
	$(correr_validas)
	$(correr_referenciales)
	@echo
	@echo "==> Todas las pruebas pasaron sobre $(BASE_PRUEBAS)"

rechazados:
	$(correr_rechazados)

validas:
	$(correr_validas)

referenciales:
	$(correr_referenciales)

# El ejercicio 2.6 cambia una acción referencial solo en una copia aislada.
# La salida se guarda como evidencia y comandas/comandas_pruebas no se modifican.
experimento-samy: pruebas
	@echo "==> Recreando la copia comandas_experimento_samy desde $(BASE_PRUEBAS)"
	@$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS comandas_experimento_samy WITH (FORCE);'
	@$(PSQL) -d postgres -c 'CREATE DATABASE comandas_experimento_samy TEMPLATE $(BASE_PRUEBAS);'
	@$(PSQL) -v ON_ERROR_STOP=1 -d comandas_experimento_samy < "$(SQL_DIR)/practica5/experimento-2.6-samy.sql" 2>&1 | tee "$(SQL_DIR)/../evidencias/practica5/experimento-2.6-samy.txt"

psql:
	@$(MOTOR) exec -it $(CONTENEDOR) psql -U $(USUARIO) -d $(BASE)

limpiar:
	@$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS "$(BASE_PRUEBAS)" WITH (FORCE);'
	@echo "==> Base $(BASE_PRUEBAS) borrada"
