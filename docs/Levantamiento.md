# Levantamiento del Proyecto Asignado

---

## Proyecto asignado

El proyecto asignado es **A Dimensional Data Warehouse for Geospatial Monitoring of Municipal Public Works**, un almacén de datos dimensional para el monitoreo geoespacial de obras públicas municipales, acompañado de una API REST de referencia escrita en Flask sobre PostgreSQL.

| Concepto | Valor |
| --- | --- |
| Repositorio original | <https://github.com/gabrielhuav/PublicMunicipalWorks_DWH> |
| Fork del equipo | <https://github.com/Actronix09/PublicMunicipalWorks_DWH> |
| Rama utilizada | `TestDefinitivo` |
| Confirmación que se puso en funcionamiento | `59a0f9d96f6def17b3f9cb109bc37314a48c2cb6` |

El repositorio publica también una demostración estática en GitHub Pages, pero —como indica la práctica— esa demostración **no** se considera evidencia: todo lo documentado aquí se ejecutó localmente sobre los contenedores del propio repositorio.

## Fork y clonación del repositorio

Desde la interfaz de GitHub se creó el fork del repositorio asignado hacia la cuenta `Actronix09`, conservando el nombre original y copiando únicamente la rama `TestDefinitivo`, que es la rama de trabajo del proyecto.

![Formulario de creación del fork en GitHub](<../evidencias/levantamiento/01 - Creacion del fork.png>)

Una vez creado, el fork queda como `Actronix09/PublicMunicipalWorks_DWH`, indicando su procedencia (*forked from gabrielhuav/PublicMunicipalWorks_DWH*) y situado en la confirmación `59a0f9d`, que es la que se puso en funcionamiento.

![Fork creado, mostrando la rama TestDefinitivo y la confirmación 59a0f9d](<../evidencias/levantamiento/02 - Fork creado en GitHub.png>)

El fork se clonó por SSH en el equipo local y se verificó que el remoto `origin` apuntara al fork y no al repositorio original:

```bash
git clone git@github.com:Actronix09/PublicMunicipalWorks_DWH.git
cd PublicMunicipalWorks_DWH
git remote -v
```

![Salida de git remote -v apuntando al fork de Actronix09](<../evidencias/levantamiento/03 - Clonacion del fork.png>)

## Instrucciones seguidas del README del proyecto

El `README.md` del proyecto, en su sección *Running the reference API*, indica que la API de referencia se levanta con la definición de contenedores incluida en el directorio `docker/`. Dado que el repositorio **sí contiene definición de contenedores**, se usó esa vía en lugar de cualquier instalación manual:

```bash
docker compose -f docker/compose.yml up -d --build          # PostgreSQL + API
docker compose -f docker/compose.yml --profile tools run --rm seed
curl http://localhost:5000/api/health
```

El archivo [`docker/compose.yml`](https://github.com/Actronix09/PublicMunicipalWorks_DWH/blob/TestDefinitivo/docker/compose.yml) define tres servicios:

- **`db`** — PostgreSQL 16 Alpine, con la base `obras_publicas`, el usuario `obras` y el puerto `5432` publicado en el `55432` del anfitrión. Monta un volumen nombrado `datos` sobre `/var/lib/postgresql/data` y monta como scripts de inicialización el esquema operacional, el esquema del almacén y sus funciones y disparadores, que se cargan solos la primera vez que se crea el volumen.
- **`api`** — la API Flask construida desde `docker/Dockerfile.api`, servida con Gunicorn en el puerto `5000`. Depende de que `db` esté saludable.
- **`seed`** — servicio bajo el perfil `tools`, que se ejecuta a demanda para crear las cuentas de demostración y generar el conjunto sintético de datos.

## Levantamiento de los contenedores

El primer comando construyó la imagen de la API (once pasos del `Dockerfile`, incluida la instalación de Flask, Flask-SQLAlchemy, Flask-Cors, `psycopg2-binary`, Gunicorn y boto3), descargó la imagen `postgres:16-alpine`, creó la red y el volumen `obras-publicas_datos`, y arrancó ambos contenedores:

```bash
docker compose -f docker/compose.yml up -d --build
```

![Construcción de la imagen y arranque de los contenedores obras-publicas-db-1 y obras-publicas-api-1](<../evidencias/levantamiento/04 - Construccion y arranque de los contenedores.png>)

Se comprobó el estado de los contenedores con `docker ps`. Ambos aparecen en estado `healthy`: la base de datos publicando el puerto `55432→5432` y la API el `5000→5000`.

```bash
docker ps
```

![Salida de docker ps con los contenedores de la API y de PostgreSQL saludables](<../evidencias/levantamiento/05 - Contenedores en ejecucion.png>)

## Poblado de la base de datos

El esquema se carga solo al crear el volumen, pero las tablas quedan vacías. Para poblarlas se ejecutó el servicio `seed`, que crea las cuentas de demostración y genera el conjunto de datos sintético descrito en el artículo:

```bash
docker compose -f docker/compose.yml --profile tools run --rm seed
```

El proceso pobló el esquema operacional y las dimensiones, y generó la población completa que el proyecto declara: 1,247 obras públicas, 8,934 eventos de auditoría, 2,341 ciudadanos, 2,156 propuestas ciudadanas, 8,723 votos y los snapshots mensuales del periodo 2024-2025.

![Salida del proceso de poblado, con el resumen de los datos generados](<../evidencias/levantamiento/06 - Poblado de la base de datos.png>)

## Aplicación en funcionamiento

Con los contenedores levantados, la API quedó disponible en `http://localhost:5000`. Se consultó primero el endpoint de salud que indica el `README`:

```bash
curl http://localhost:5000/api/health
```

La respuesta confirma que el servicio responde correctamente:

![Respuesta del endpoint /api/health con status ok](<../evidencias/levantamiento/07 - Estado de salud de la API.png>)

Después se consultaron los endpoints públicos de lectura, que son los que consumen los tableros del sistema. El endpoint de resumen devuelve los indicadores agregados del portafolio —inversión total, obras activas, obras completadas, avance promedio, comunidades impactadas, el desglose por estatus y las obras más recientes— todos ellos calculados sobre los datos recién cargados:

```
http://localhost:5000/api/public/resumen
```

![Respuesta del endpoint /api/public/resumen con los indicadores del portafolio](<../evidencias/levantamiento/08 - Resumen publico desde la API.png>)

El endpoint del listado de obras devuelve los 1,247 registros generados, con `success: true`, lo que confirma que la API está leyendo efectivamente de la base de datos del contenedor y no de datos estáticos:

```
http://localhost:5000/api/public/obras
```

![Respuesta del endpoint de obras con los 1,247 registros](<../evidencias/levantamiento/09 - Listado de obras desde la API.png>)

## Consultas directas sobre la base de datos

Además de consumir la API, se abrió una sesión interactiva de `psql` **directamente sobre el contenedor de PostgreSQL** para ejecutar consultas contra el almacén de datos:

```bash
docker compose -f docker/compose.yml exec db psql -U obras -d obras_publicas
```

### Obras con retraso

La primera consulta se hizo sobre `warehouse.v_obras_retraso`, una de las seis vistas analíticas del almacén, que cruza la dimensión de obra con sus presupuestos, costos e informes para exponer los días de retraso y el porcentaje de presupuesto ejercido:

```sql
SELECT * FROM warehouse.v_obras_retraso LIMIT 10;
```

![Resultado de la consulta SELECT * FROM warehouse.v_obras_retraso LIMIT 10](<../evidencias/levantamiento/10 - Consulta de obras con retraso.png>)

### Conteos del almacén y consultas analíticas

Enseguida se verificó el volumen cargado en las dimensiones y las tablas de hechos, y se ordenaron las obras por días de retraso y las fuentes de financiamiento por presupuesto asignado:

```sql
SELECT (SELECT COUNT(*) FROM warehouse.dim_obra   WHERE es_actual) AS obras,
       (SELECT COUNT(*) FROM warehouse.dim_region WHERE es_actual) AS regiones,
       (SELECT COUNT(*) FROM warehouse.fact_eventos_auditoria)     AS eventos_auditoria,
       (SELECT COUNT(*) FROM warehouse.fact_obra_mensual)          AS registros_mensuales;

SELECT obra_id, nombre_obra, comunidad, dias_retraso, porcentaje_ejercido
FROM warehouse.v_obras_retraso
ORDER BY dias_retraso DESC
LIMIT 10;

SELECT fuente_id, programa, obras_financiadas, presupuesto_asignado, monto_ejercido, porcentaje_ejercicio
FROM warehouse.v_ejercicio_presupuestario
ORDER BY presupuesto_asignado DESC
LIMIT 10;
```

![Resultados de los conteos del almacén, las obras con mayor retraso y el ejercicio presupuestario](<../evidencias/levantamiento/11 - Consultas sobre el almacen de datos.png>)

### Anomalías detectadas

Por último se consultó `warehouse.v_anomalias_deteccion`, la vista que evalúa por obra y mes los tres criterios de detección que plantea el proyecto —desviación de costo (C1), retraso (C2) e inconsistencia (C3)—:

```sql
SELECT COUNT(*) FILTER (WHERE c1_desviacion_costo) AS c1_costo,
       COUNT(*) FILTER (WHERE c2_retraso)          AS c2_retraso,
       COUNT(*) FILTER (WHERE c3_inconsistencia)   AS c3_inconsistencia,
       COUNT(*)                                     AS total_filas
FROM warehouse.v_anomalias_deteccion;
```

![Resultado de la consulta de anomalías detectadas: 519, 2481 y 24 sobre 29,928 filas](<../evidencias/levantamiento/12 - Consulta de anomalias detectadas.png>)
