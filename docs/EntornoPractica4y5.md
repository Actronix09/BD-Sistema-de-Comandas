# Entorno de Trabajo de las Prácticas 4 y 5

En este documento se registra cómo se preparó el entorno para las Prácticas 4 y 5: la rama de trabajo, la estructura de carpetas de la entrega y el gestor de bases de datos con el esquema de la Práctica 3 ejecutado sobre una base limpia.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Rama `practica4-5` y ramas por sección, estructura de carpetas y levantamiento de PostgreSQL con `entorno/compose.yml`.

---

## Rama de trabajo

Las dos prácticas se desarrollan en la rama `practica4-5`, creada a partir de `main`. Igual que en las prácticas anteriores, cada sección se trabaja en su propia rama, que sale de `practica4-5` y regresa a ella por *pull request*. Al terminar, `practica4-5` entra a `main` con un *pull request* revisado por otro integrante.

| Rama | Sale de | Contenido |
| :-- | :-- | :-- |
| `Practica4-Entorno` | `practica4-5` | Este documento y la estructura de carpetas |
| `Practica4-Ejercicio1.3-Fuente` | `practica4-5` | `practica4/fuente.md`, los datos y su generador |
| `Practica4-Ejercicio1.4-Carga` | `practica4-5` | `practica4/poblar/poblar.sh` y su evidencia |
| `Practica4-Ejercicio1.6-Permisos` | `practica4-5` | `practica4/permisos.md` y los roles |
| `Practica5-Ejercicio2.4-Edicion` | `practica4-5` | `practica5/edicion-de-valores.md` y sus sentencias |
| `Practica5-Ejercicio2.6-Adrian` | `practica4-5` | El trabajo individual en `practica5/integrantes/` |
| `Practica4y5-Entregable` | `practica4-5` | README e índice de documentos |

Estas son las ramas de las secciones de Adrian. Samy agrega las suyas con el mismo formato.

```bash
git switch practica4-5
git switch -c Practica4-Entorno
```

## Estructura de carpetas

Se sigue la estructura sugerida por la práctica. Las evidencias van en la carpeta `evidencias/`, igual que las de la Práctica 3.

```
practica4/
├── migraciones/         Cambios al esquema numerados (001-dominios.sql, ...)
├── datos/               Archivos crudos, si el tamaño lo permite
├── poblar/              Script de carga
└── proyecto-asignado/   Carga y dominios de Sismos
practica5/
├── integrantes/         Trabajo individual de cada integrante
└── sql/                 Sentencias en archivos que se pueden ejecutar
evidencias/
├── practica4/
└── practica5/
```

Los documentos de cada práctica van en la raíz de su carpeta. Desde esta práctica, todo cambio al esquema se hace con `ALTER TABLE` en una migración numerada, sin editar `sql/esquema.sql` ni la base a mano.

## Levantamiento del gestor

Se reutiliza la definición de contenedores de las prácticas anteriores, [`entorno/compose.yml`](<../entorno/compose.yml>), sin cambios. `make -C sql pruebas` levanta el contenedor si hace falta, recrea la base `comandas_pruebas`, ejecuta `sql/esquema.sql` y `sql/datos-ejemplo.sql`, y corre las pruebas.

```bash
make -C sql pruebas
docker ps --filter name=practica1-postgres
```

El esquema se ejecuta completo sobre la base limpia y todos los casos pasan:

```
==> Rechazados: 34 de 34
==> Válidas: 13 de 13
==> Todas las pruebas pasaron sobre comandas_pruebas

NAMES                IMAGE                  STATUS       PORTS
practica1-postgres   postgres:16.4-alpine   Up 7 hours   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
```

| Concepto | Valor |
| :-- | :-- |
| Gestor | PostgreSQL 16.4 (Alpine) |
| Contenedor | `practica1-postgres` |
| Puerto en el anfitrión | `5432` |
| Base de pruebas | `comandas_pruebas` |
| Zona horaria del servidor | `America/Mexico_City` |

La base del proyecto asignado se levanta desde su fork y se documenta en `practica4/proyecto-asignado/`.
