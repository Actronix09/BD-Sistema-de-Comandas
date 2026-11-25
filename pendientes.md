---
tags:
  - bases-de-datos
  - proyecto
  - exposicion
---
# Proyecto Parcial 2

> [!info]+ Desarrollo del proyecto
> **Materia:** [[Bases de Datos]]
> **Proyecto:** Segundo parcial: registro desde la web, proyecto asignado montado con álgebra relacional, y artículo con mejoras
> **Fecha de exposición:** ~~la asigna el docente; hay que estar listos desde la primera sesión~~ **No exponemos en el segundo parcial.** Exponemos en la **exposición 3 (final)**, después de que hayan pasado todos los demás equipos.
> **Contenido:** Qué se muestra en cada parte de los 13 minutos, qué falta construir para poder mostrarlo y qué debe quedar al inicio del README.
> **Relacionadas:** [[Desarrollo Prácticas 6, 7 y 8]], [[Proyecto Parcial 1]], [[Análisis Técnico de los Tres Papers]], [[Propuestas de Mejora del Proyecto Asignado]]

> [!warning] Cambio de fecha (23-Noviembre-2026)
> Por cambios en el calendario, el equipo no presenta la exposición 2: pasamos hasta la **exposición 3 y final**, cuando todos los demás compañeros ya hayan expuesto. Esta nota se queda como guía de lo que hay que mostrar, pero:
> - [ ] Confirmar con el docente si la exposición final pide **lo mismo** que esta (13 minutos, las tres partes) o si cambia el contenido o el tiempo.
> - [ ] Ver las exposiciones de los demás equipos para saber qué pregunta el docente y qué observa.
> - El tiempo extra se usa para tener la **demo web funcionando de verdad** (ver Parte 1), no para dejarla al final.

---

## Enlaces

> [!abstract]+ Proyecto propio
> - **Sitio del proyecto (GitHub Pages):** <https://actronix09.github.io/BD-Sistema-de-Comandas/>
> - **Repositorio de la base:** <https://github.com/Actronix09/BD-Sistema-de-Comandas>
> - **Aplicación del sistema de comandas (interfaz Qt, servidor y contenedores):** <https://github.com/Actronix09/Sistema-de-Comandas>

> [!abstract]+ Proyecto asignado: Sismos
> - **Repositorio original del primer parcial:** <https://github.com/gabrielhuav/Seismic-Data-Visualization-System>
> - **Fork del equipo:** <https://github.com/Samuel-Hdzx07/Proyecto-Asig-Sismos>
> - **Repositorio de la versión actual del artículo:** <https://github.com/gabrielhuav/Seismic_Data_Geosciences>
> - **Sistema publicado:** <https://gabrielhuav.github.io/Seismic_Data_Geosciences/>
> - **Manuscrito R3 (el que cita el enunciado):** [Word](https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/Seismic_CG_manuscript_R3.docx) · [PDF](https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/Seismic_CG_manuscript_R3.pdf) · [iThenticate](https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/ITHENTICATE_R3_05.pdf)
> - **Archivo de datos y código (DOI):** <https://doi.org/10.5281/zenodo.24361244>

> [!warning] Ojo con el proyecto asignado
> - El enunciado pide usar **el repositorio de la versión actual del artículo**, que es `Seismic_Data_Geosciences`. Nuestro fork es del repositorio **viejo**, `Seismic-Data-Visualization-System`. Hay que hacer un **fork nuevo** de `Seismic_Data_Geosciences` o justificar por qué seguimos con el viejo.
> - Al 20-Noviembre, el README del repositorio dice que el manuscrito vigente ya es el **R4**, no el R3 que cita el enunciado. Hay que leer el R4, mencionarlo y preguntarle al docente cuál se expone.
> - El título cambió desde el primer parcial: antes era *«Cuando México tiembla: la historia contada por los datos»* y ahora es *«A browser-based seismic data observatory for detecting and comparing earthquake sequences across North American catalogues»*.

> [!success]- Revisión de los sitios publicados (20-Noviembre-2026, Chromium headless)
> - **Landing** (`actronix09.github.io/BD-Sistema-de-Comandas`): carga sin errores de JavaScript y todos sus enlaces responden. Pendiente: el título y la etiqueta siguen diciendo «Prácticas 4 y 5», y **no tiene formulario de registro**.
> - **Fork viejo** (`samuel-hdzx07.github.io/Proyecto-Asig-Sismos`): las tres vistas (Sismos, Población y Economía) abren con su mapa y sus filtros, sin errores. Es el sistema **del primer parcial**, no el del artículo actual.
> - **Observatorio actual** (`gabrielhuav.github.io/Seismic_Data_Geosciences`): carga los 4 catálogos (287,936 registros). En **SQL explorer → Advanced SQL editor** se ejecutan consultas propias (solo `SELECT` o `WITH`) en SQLite dentro del navegador, sin servidor ni Docker.
> 	- Tablas: `records`, `catalogs` y `exact_membership`. La **reunión** para la consulta 2.3 puede ser `records ⋈ catalogs` por el catálogo. `records` usa `catalogue_id`; el nombre de la columna en `catalogs` hay que verificarlo en «Explore the data schema».
> 	- El editor respeta los filtros activos del mapa, así que antes de comparar resultados con RelaX hay que fijar la misma selección.
> - El único 404 en los tres sitios es el `favicon.ico`, que no afecta en nada.

---

## Reparto del tiempo: 13 minutos

> [!warning] Cada minuto de más descuenta un punto
> Participan **todos**. Hay que ensayar con reloj y recortar antes, no durante la exposición.
>
> | Parte | Qué se muestra | Tiempo | Quién (propuesta) |
> | :-- | :-- | :--: | :-- |
> | **Proyecto propio** | Registro desde la web, verificación en la BD y práctica integrada | 6 min | Adrian |
> | **Proyecto asignado** | Sistema montado y consultas en álgebra relacional y SQL | 5 min | Samy |
> | **Artículo** | Resultados del manuscrito y mejoras propuestas | 2 min | Los dos |

---

## Parte 1 - El proyecto propio (6 min)

> [!danger] Lo que falta construir: el registro desde la web
> **Estado (24-Noviembre-2026): la demo ya funciona de punta a punta.** La app completa (cliente QML compilado a WebAssembly) está en <https://actronix09.github.io/Sistema-de-Comandas/>. Se conecta por `wss://lilyth.tail2ed638.ts.net` al servidor en C de la PC de casa (Fedora CoreOS), que tiene 39 operaciones, avisos en vivo y modo demo. La base de la demo se reinicia cada noche a las 3:30 con `db/demo/datos-demo.sql`.
>
> **Plan decidido (23-Noviembre-2026):** el docente pide que **cualquiera** (nosotros, el profe o un compañero) haga un cambio en la base desde el salón **sin instalar nada**, y que el cambio se vea. El sistema final funciona solo en red local, pero la demo es otra cosa:
>
> ```
> Navegador en clase → página de la demo en GitHub Pages (HTTPS)
>   → wss://<pc-fija>.ts.net  (Tailscale Funnel, TLS automático, sin abrir puertos del router)
>   → servidor-c en la PC fija de casa (contenedor, puerto 9000)
>   → PostgreSQL de demostración (contenedor, nunca expuesto)
> ```
>
> - [x] **1.** Servidor en C: todas las operaciones del cliente, con el rol de la aplicación (`app_comandas`).
> - [x] **2.** Página de la demo en Pages: no un formulario, sino la app completa en modo demo (letrero, botones de acceso rápido, admin limitado).
> - [x] **3.** PC fija: reinstalada con Fedora CoreOS (repo privado `servidor-lilyth`), con Tailscale en contenedor.
> - [x] **4.** Base de demostración que se reinicia cada noche y revisión del `Origin` (solo `https://actronix09.github.io`). Falta el límite de peticiones.
> - [x] La demo carga **los datos de la Práctica 4** (`sql/carga/poblar.sql`, ~62 mil renglones, todas las tablas principales con más de 200) y encima las cuentas de prueba. Así cumple con lo de las prácticas: el evento en curso (la posada) es de hoy y tiene los paquetes Oro y Plata incluidos.
> - [x] **5.** Funnel abierto al puerto 9000; probado desde internet (17 de 17).
> - [x] La landing (`web/`) termina con la sección **Demo en línea**: 8 capturas de la app de escritorio contra la demo (inicio, mesero, cocina, caja y administración, en `web/imagenes/demo/`) y el botón **Abrir la demo** con las cuentas de prueba (24-Noviembre-2026).
> - [ ] Probar desde el celular con datos móviles y revisar las pantallas en tamaño teléfono.
> - [x] Desactivar la expiración de la llave de `lilyth` en la consola de Tailscale.
> - [ ] **Plan B:** el mismo contenedor en la laptop, por si se va la luz o el internet en casa.
> - [ ] Preguntarle al docente si le parece bien Tailscale Funnel.

> [!todo]+ 1. Registro
> - [ ] Capturar y enviar un registro de prueba desde el formulario de la aplicación web.
> - [ ] En el gestor, encontrar la fila con un `SELECT` por su clave o por un valor identificable.
> - [ ] Comprobar en vivo que los datos coinciden con los capturados.
> - [ ] Guardar la **evidencia del registro**: capturas del formulario y de la consulta.

> [!todo]+ 2. Conexión con la base de datos
> - [ ] Explicar el camino del dato: formulario en Pages → `wss://` por Tailscale Funnel con JSON `{id, op, datos}` → servidor en C (civetweb, cJSON, libpq) en la PC fija → PostgreSQL → respuesta `{id, ok, datos|error}`.
> - [ ] Mostrar que las credenciales están en el servidor (`.env`), no en el navegador.

> [!todo]+ 3. Esquema y reglas de integridad
> - [ ] Mostrar el **modelo relacional actualizado** ya normalizado (`modelo/diagrama-relacional.*` regenerado tras la migración de la Práctica 6) y las tablas del registro.
> - [ ] Explicar las **claves** y las restricciones de **dominio** e **integridad referencial** de esas tablas.
> - [ ] Señalar dónde están los scripts: `sql/esquema.sql`, `sql/migraciones/`, `sql/carga/poblar.sh` y la migración de normalización.
> - [ ] Justificar los **permisos** (rol de la aplicación con mínimo privilegio, de la Práctica 4), las **acciones referenciales** y las **transacciones**, si el registro toca más de una tabla.

> [!todo]+ 4. Práctica integrada 6, 7 y 8 (como una sola)
> - [ ] Una **decisión de normalización** con sus dependencias funcionales y claves candidatas, el paso a 3FN y la comprobación de FNBC.
> - [ ] Una **consulta representativa en RelaX** con su SQL equivalente, comparando que salgan las mismas filas.
> - [ ] Que en el repositorio quede el conjunto completo: selección, proyección, conjuntos, producto, reuniones, agrupación y división (ver [[Desarrollo Prácticas 6, 7 y 8#Parte 3 - Álgebra relacional (ISC 7 y 8 · IIA 6)|Parte 3]]).

---

## Parte 2 - El proyecto asignado (5 min)

> [!todo]+ 1. Sistema en funcionamiento
> - [ ] Abrir la **versión estática publicada** y mostrar el sistema desde **nuestro propio entorno**, desde el fork.
> - [ ] Identificar la base y los datos cargados.
> - [ ] Si tiene backend, levantarlo localmente. En Sismos se puede usar el **entorno SQL de SQLite** integrado en la aplicación.

> [!todo]+ 2. Qué hace el sistema y una incidencia del montaje
> - [ ] Explicar qué hace el sistema: explorar catálogos sísmicos, trazar los registros de origen y comparar familias de sismos.
> - [ ] Contar **cómo se resolvió una incidencia** del montaje. En el fork viejo está documentado el fallo del 16-Octubre y la ejecución del 18 (`levantamiento.md`).
> - [ ] Si algo quedó pendiente: qué se intentó, en qué punto falló y el mensaje exacto.

> [!todo]+ 3. Las tres consultas de la práctica integrada (ejercicio 2.3)
> Para cada una:
> - [ ] La pregunta.
> - [ ] La expresión en álgebra relacional.
> - [ ] El **árbol de operadores**.
> - [ ] El **operador principal**.
> - [ ] Entre las tres: **selección, proyección y al menos una reunión**.

> [!todo]+ 4. SQL equivalente
> - [ ] Ejecutar el SQL de cada consulta sobre la base montada y mostrar los resultados.
> - [ ] Explicar cómo corresponde cada resultado a la expresión algebraica.
> - [ ] Mostrarlo en **RelaX** cuando los operadores y los datos lo permitan.

---

## Parte 3 - El artículo y las mejoras (2 min)

> [!todo]+ 1. Resumen
> - [ ] El **problema**.
> - [ ] Los **datos** y el **método**.
> - [ ] El **resultado principal**.
> - [ ] El **avance respecto al primer parcial**. Por ejemplo: pasó de un visualizador de México a un observatorio de catálogos de Norteamérica con cuatro catálogos, comparación de secuencias, auditoría de revisiones de productos de origen (piloto de 36 eventos y 236 versiones) y SQL en el navegador.

> [!todo]+ 2. Dos propuestas de mejora
> Para cada una:
> - [ ] Qué **limitación** se observó en el manuscrito o en el sistema.
> - [ ] Qué se **cambiaría**.
> - [ ] Cómo se **comprobaría** que la mejora funciona (métrica o prueba concreta).
> - Como punto de partida: [[Propuestas de Mejora del Proyecto Asignado]] (del primer parcial; hay que revisar si siguen aplicando al R3/R4).

> [!example]- Borrador de la referencia en APA 7 (verificar autores, año y versión antes de usarla)
> Villa Vargas, J. M., & Hurtado Avilés, G. (2026). *A browser-based seismic data observatory for detecting and comparing earthquake sequences across North American catalogues* [Manuscrito R3, en revisión]. GitHub. https://github.com/gabrielhuav/Seismic_Data_Geosciences/blob/main/paper/manuscript/out/Seismic_CG_manuscript_R3.pdf

---

## Qué se entrega: inicio del README

> [!todo]+ Antes del turno, visibles **al inicio** del README del repositorio
> **1. Proyecto propio**
> - [ ] Enlace a la aplicación web o instrucciones para ejecutarla localmente.
> - [ ] Esquema, scripts y **evidencia del registro**.
> - [ ] Archivos de la práctica integrada: `normalizacion.md`, `algebra.md` y el grupo de RelaX.
>
> **2. Proyecto asignado**
> - [ ] Enlace al **fork** y a su **versión publicada**.
> - [ ] Instrucciones de montaje.
> - [ ] Archivo con las tres consultas, sus árboles, el SQL y los resultados.
>
> **3. Artículo y exposición**
> - [ ] Referencia en **APA 7** con enlace directo al manuscrito y DOI si está disponible.
> - [ ] Las dos propuestas de mejora.
> - [ ] La **presentación** utilizada.
> - [ ] Las **aportaciones de cada integrante**.

> [!note] El README actual (25-Noviembre-2026)
> El README es lo que el profesor revisa para calificar las prácticas, así que ya está ordenado **por práctica** (1, 2, 3, 4 y 5), cada una con sus documentos, scripts, evidencias y diagramas. También tiene la sección de las **Prácticas 6, 7 y 8** con sus entregables en «Pendiente».
> - [ ] Decidir cómo quedan los tres bloques de la exposición «al inicio del README» sin tapar la documentación de las prácticas. Se agregan cuando se acerque la exposición final.

---

## Cómo exponer

> [!todo]+ Antes del turno
> - [ ] Dejar **abiertos y probados** los sitios, los gestores y las consultas (los contenedores ya levantados).
> - [ ] Grabar un **video corto de respaldo** por si falla la red del laboratorio: el registro web, el `SELECT`, RelaX y el sistema de Sismos.
> - [ ] Mostrar los sitios **desde su dirección publicada** y explicar los resultados en vivo.
> - [ ] Preparar la presentación (diapositivas) y subirla al repositorio.
> - [ ] **Ensayo cronometrado** completo, por lo menos una vez.
> - [ ] Cualquiera de los dos debe poder contestar preguntas de cualquier parte.

---

[[Bases de Datos|← Índice]] | [[Desarrollo Prácticas 6, 7 y 8|← Prácticas 6, 7 y 8]]

> [!todo]+ Migración 003: cobro de los paquetes (24-Noviembre-2026)
> Lo que incluye el paquete de un evento cuesta 0 hasta la cantidad acordada. Al acabarse, cada producto hace lo que decidió el organizador:
> - `cobrar`: se cobra en su cuenta.
> - `bloquear`: ya no se vende.
> - `anfitrion`: se carga a la cuenta del anfitrión.
>
> Los acuerdos que ya existían quedan en `aparte` y no cambian. Están en `sql/migraciones/003-cobro-paquetes.sql`, con la prueba válida 16 y los rechazos 37 a 39. Ya se documentaron en `docs/practica3/DiccionarioDeDatos.md`, `ModeloRelacional.md`, `docs/practica4/dominios.md` y `docs/practica5/referencias.md`.
> - [x] Correr `make -C sql pruebas` con la migración (39 rechazos y 16 válidas).
> - [x] Regenerar `modelo/diagrama-relacional.svg` y `.png` con las columnas nuevas: `evento.secuencial_anfitrion`, `acuerdo.modo_cobro` y `comanda.tipo_cobro` (24-Noviembre-2026; también muestra los dominios `dinero` y `cantidad` de la migración 001).
> - [ ] Que Samy revise el disparador `fijar_precio_cobrado` y la vista `v_cuenta`.
