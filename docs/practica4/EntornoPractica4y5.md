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
| `Practica4-Ejercicio1.3-Fuente` | `practica4-5` | `docs/practica4/fuente.md`, los datos y su generador |
| `Practica4-Ejercicio1.4-Carga` | `practica4-5` | `sql/carga/poblar.sh` y su evidencia |
| `Practica4-Ejercicio1.6-Permisos` | `practica4-5` | `docs/practica4/permisos.md` y los roles |
| `Practica5-Ejercicio2.4-Edicion` | `practica4-5` | `docs/practica5/edicion-de-valores.md` y sus sentencias |
| `Practica5-Ejercicio2.6-Adrian` | `practica4-5` | El trabajo individual en `docs/practica5/integrantes/` |
| `Practica4y5-Entregable` | `practica4-5` | README, índice de documentos y página web |
| `Practica4y5-Correcciones` | `practica4-5` | Este documento al día y las evidencias de la carga regeneradas |

Estas son las ramas de las secciones de Adrian. Samy hizo sus secciones (migraciones, 1.1, 1.2, 1.5, 2.1, 2.2, 2.3 y su 2.6) con confirmaciones directas en `practica4-5`.

Tres *pull requests* se fusionaron por error directo a `main`, porque GitHub propone `main` como base:

| *Pull request* | Rama | Cómo se corrigió |
| :-- | :-- | :-- |
| #32 y #33 | 1.3 y 1.4 | Los mismos commits entraron a `practica4-5` con los *pull requests* #34 y #35 |
| #39 | 2.6 de Adrian | Como la rama salió de `practica4-5`, llevó a `main` todo lo que había ahí, menos 2.4. Se volvió a fusionar en `practica4-5` con el #41 |

Ninguno se revirtió. Al revertir una fusión, Git da sus commits por ya fusionados, y el *pull request* final de `practica4-5` a `main` no los volvería a meter.

```bash
git switch practica4-5
git switch -c Practica4-Entorno
```

## Estructura de carpetas

Al principio se siguió la estructura sugerida por la práctica, con las carpetas `practica4/` y `practica5/` en la raíz. Después se reorganizó el repositorio para que cada tipo de archivo tenga un solo lugar: los documentos en `docs/`, separados por práctica, y todo lo que se ejecuta en `sql/`. Cada documento de la sugerencia sigue existiendo con el mismo nombre, solo cambió de carpeta.

```
docs/
├── practica1/ … practica3/   Documentos de las prácticas anteriores
├── practica4/                dominios, fuente, carga, pruebas-dominio, permisos y este documento
│   └── proyecto-asignado/    Carga y dominios de Sismos
├── practica5/                referencias, pruebas-referenciales y edicion-de-valores
│   └── integrantes/          Trabajo individual de cada integrante
└── enunciados/               Enunciado de las Prácticas 4 y 5
sql/
├── migraciones/              Cambios al esquema numerados (001-dominios.sql, ...)
├── carga/                    Script de carga, sus pruebas y el generador de datos
├── datos/                    Archivos crudos: menú del salón, FNDDS y datos generados
└── practica5/                Sentencias de la Práctica 5 en archivos que se pueden ejecutar
evidencias/
├── practica4/
└── practica5/
```

| Sugerencia de la práctica | En este repositorio |
| :-- | :-- |
| `practica4/*.md` | `docs/practica4/` |
| `practica4/migraciones/` | `sql/migraciones/` |
| `practica4/datos/` | `sql/datos/` |
| `practica4/poblar/` | `sql/carga/` |
| `practica4/proyecto-asignado/` | `docs/practica4/proyecto-asignado/` |
| `practica5/*.md` e `integrantes/` | `docs/practica5/` |
| `practica5/sql/` | `sql/practica5/` |

Desde esta práctica, todo cambio al esquema se hace con `ALTER TABLE` en una migración numerada, sin editar `sql/esquema.sql` ni la base a mano.

## Levantamiento del gestor

Se reutiliza la definición de contenedores de las prácticas anteriores, [`entorno/compose.yml`](<../../entorno/compose.yml>), sin cambios. `make -C sql pruebas` levanta el contenedor si hace falta, recrea la base `comandas_pruebas`, ejecuta `sql/esquema.sql`, las migraciones de `sql/migraciones/` y `sql/datos-ejemplo.sql`, y corre los rechazos, los casos válidos y las pruebas referenciales.

```bash
make -C sql pruebas
docker ps --filter name=practica1-postgres
```

El esquema se ejecuta completo sobre la base limpia y todos los casos pasan:

```
==> Rechazados: 36 de 36
==> Válidas: 15 de 15
Todas las pruebas referenciales pasaron; los datos de ejemplo quedaron restaurados.
==> Todas las pruebas pasaron sobre comandas_pruebas

NAMES                IMAGE                  STATUS       PORTS
practica1-postgres   postgres:16.4-alpine   Up 6 hours   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
```

| Concepto | Valor |
| :-- | :-- |
| Gestor | PostgreSQL 16.4 (Alpine) |
| Contenedor | `practica1-postgres` |
| Puerto en el anfitrión | `5432` |
| Base de pruebas | `comandas_pruebas` |
| Zona horaria del servidor | `America/Mexico_City` |

La base del proyecto asignado se levanta desde su fork y se documenta en `docs/practica4/proyecto-asignado/`.
