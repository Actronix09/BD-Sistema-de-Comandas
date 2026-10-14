# Entorno de Trabajo de la Práctica 3

En este documento se registra cómo se preparó el entorno para la Práctica 3: la rama de trabajo, el gestor de bases de datos levantado con el `compose.yml` del repositorio y la base de datos vacía donde se ejecuta el esquema relacional.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Rama `practica3` y ramas por sección, levantamiento de PostgreSQL con `entorno/compose.yml` y creación de la base vacía `comandas`.

---

## Rama de trabajo

La práctica se desarrolla en la rama `practica3`, creada a partir de `main` después de fusionar la Práctica 2. Igual que en la práctica anterior, cada sección se trabaja en su propia rama, que sale de `practica3` y regresa a ella por *pull request*:

| Rama | Sale de | Contenido |
| :-- | :-- | :-- |
| `Practica3-Parte1-Entorno` | `practica3` | Este documento y las salidas del levantamiento |
| `Practica3-Parte2-Inventario` | `practica3` | [Inventario del Modelo EER](<InventarioModeloEER.md>) |
| `Practica3-Parte3a5-Transformacion` | `practica3` | [Reglas de Transformación](<ReglasDeTransformacion.md>): entidades, atributos, relaciones, entidades débiles y jerarquías |
| `Practica3-Parte6-EsquemaRelacional` | `practica3` | [Esquema Relacional](<EsquemaRelacional.md>), `sql/esquema.sql`, diagrama y [Diccionario de Datos](<DiccionarioDeDatos.md>) |

```bash
git switch practica3
git switch -c Practica3-Parte1-Entorno
```

## Levantamiento del gestor

Se reutiliza la definición de contenedores de la Práctica 1, [`entorno/compose.yml`](<../entorno/compose.yml>), sin cambios. Define un solo servicio `db` con la imagen `postgres:16.4-alpine`, el contenedor `practica1-postgres`, el puerto `5432` publicado en el anfitrión, la zona horaria `America/Mexico_City` y el volumen nombrado `practica1-pgdata`, que es el que conserva los datos aunque el contenedor se elimine (ver [Persistencia del Volumen de Docker](<Persistencia del Volumen de Docker.md>)).

```bash
docker compose -f entorno/compose.yml up -d
docker ps --filter name=practica1-postgres
```

Como el volumen ya existía desde la Práctica 1, `compose` no recrea nada y solo confirma que el contenedor está en ejecución:

```
 Container practica1-postgres Running

NAMES                IMAGE                  STATUS         PORTS
practica1-postgres   postgres:16.4-alpine   Up 7 minutes   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
```

Salida completa: [`01-levantar-sgbd.txt`](<../evidencias/practica3/parte1/01-levantar-sgbd.txt>)

| Concepto | Valor |
| :-- | :-- |
| Gestor | PostgreSQL 16.4 (Alpine) |
| Contenedor | `practica1-postgres` |
| Puerto en el anfitrión | `5432` |
| Usuario | `pg-practica1` |
| Codificación | UTF8 |
| Zona horaria del servidor | `America/Mexico_City` |

## Base de datos vacía

El esquema del sistema de comandas no se mezcla con las bases de las prácticas anteriores (`pg-practica1` y `practica1`): se crea una base nueva, `comandas`, dentro del mismo servidor.

```bash
docker exec practica1-postgres createdb -U pg-practica1 -E UTF8 comandas
docker exec practica1-postgres psql -U pg-practica1 -d comandas -c '\l comandas' -c '\dt'
```

La base aparece en el listado y `\dt` confirma que no tiene ninguna tabla todavía:

```
   Name   |    Owner     | Encoding | Locale Provider | Collate | Ctype | ICU Locale | ICU Rules | Access privileges
----------+--------------+----------+-----------------+---------+-------+------------+-----------+-------------------
 comandas | pg-practica1 | UTF8     | libc            | C       | C     |            |           |
(1 row)

Did not find any relations.
```

Salida completa: [`02-crear-base-vacia.txt`](<../evidencias/practica3/parte1/02-crear-base-vacia.txt>)

Sobre esta base se ejecuta `sql/esquema.sql`. La ejecución, el listado de tablas y los `INSERT` rechazados están documentados en la Parte 6, [Esquema Relacional](<EsquemaRelacional.md>).
