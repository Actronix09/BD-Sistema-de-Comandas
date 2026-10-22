# =====================================================================
#  Makefile — Base de datos del Sistema de Comandas
#
#  Levanta el contenedor de PostgreSQL y corre la secuencia de pruebas:
#  esquema → datos de ejemplo → inserts rechazados → pruebas válidas.
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

MOTOR        ?= docker
CONTENEDOR   ?= practica1-postgres
USUARIO      ?= pg-practica1
BASE         ?= comandas
BASE_PRUEBAS ?= comandas_pruebas

COMPOSE := $(MOTOR) compose -f "$(COMPOSE_FILE)"
# -X: no lee ~/.psqlrc · -q: sin las etiquetas CREATE TABLE, INSERT 0 1…
PSQL    := $(MOTOR) exec -i $(CONTENEDOR) psql -X -q -U $(USUARIO)

.DEFAULT_GOAL := help
.PHONY: help levantar detener estado cargar pruebas rechazados validas psql limpiar

help:
	@echo "Objetivos:"
	@echo "  levantar     Levanta el contenedor $(CONTENEDOR) y espera a que acepte conexiones"
	@echo "  detener      Detiene el contenedor (el volumen y los datos se conservan)"
	@echo "  estado       Muestra el contenedor y las bases que existen"
	@echo "  cargar       Recrea la base $(BASE) con esquema.sql y datos-ejemplo.sql"
	@echo "  pruebas      Recrea $(BASE_PRUEBAS) y corre toda la secuencia de pruebas"
	@echo "  rechazados   Corre inserts-rechazados.sql y exige que cada caso falle"
	@echo "  validas      Corre pruebas-validas.sql (si existe)"
	@echo "  psql         Abre una consola sobre $(BASE)"
	@echo "  limpiar      Borra la base $(BASE_PRUEBAS)"
	@echo
	@echo "Variables: MOTOR=$(MOTOR) CONTENEDOR=$(CONTENEDOR) USUARIO=$(USUARIO)"
	@echo "           BASE=$(BASE) BASE_PRUEBAS=$(BASE_PRUEBAS)"

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

# $(1) = base. Recrea la base y carga esquema y datos. ON_ERROR_STOP detiene
# el script en el primer error; como cada archivo va en BEGIN…COMMIT, un
# error deshace todo el archivo y make se detiene con el mensaje de psql.
define cargar_base
@echo "==> Recreando la base $(1)"
@$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS "$(1)" WITH (FORCE);'
@$(PSQL) -d postgres -c "CREATE DATABASE \"$(1)\" ENCODING 'UTF8';"
@echo "==> esquema.sql"
@$(PSQL) -v ON_ERROR_STOP=1 -d $(1) < "$(SQL_DIR)/esquema.sql" > /dev/null
@echo "==> datos-ejemplo.sql"
@$(PSQL) -v ON_ERROR_STOP=1 -d $(1) < "$(SQL_DIR)/datos-ejemplo.sql" > /dev/null
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

define correr_validas
@if [ -f "$(SQL_DIR)/pruebas-validas.sql" ]; then \
	echo "==> pruebas-validas.sql"; \
	$(PSQL) -v ON_ERROR_STOP=1 -d $(BASE_PRUEBAS) < "$(SQL_DIR)/pruebas-validas.sql"; \
else \
	echo "==> pruebas-validas.sql no existe todavía; se omite"; \
fi
endef

cargar: levantar
	$(call cargar_base,$(BASE))

pruebas: levantar
	$(call cargar_base,$(BASE_PRUEBAS))
	$(correr_rechazados)
	$(correr_validas)
	@echo
	@echo "==> Todas las pruebas pasaron sobre $(BASE_PRUEBAS)"

rechazados:
	$(correr_rechazados)

validas:
	$(correr_validas)

psql:
	@$(MOTOR) exec -it $(CONTENEDOR) psql -U $(USUARIO) -d $(BASE)

limpiar:
	@$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS "$(BASE_PRUEBAS)" WITH (FORCE);'
	@echo "==> Base $(BASE_PRUEBAS) borrada"
