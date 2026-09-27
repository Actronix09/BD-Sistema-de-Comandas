# Analisis de los Tres Articulos de los Proyecto

Para el desarrollo de este documento se investigaron de los articulos _Datos sísmicos_, _Consumo del agua en al Ciudad de México_ y _Obra pública municipal_, y se analizaron con el objetivo de obtener un panorama más amplio para el desarrollo de esta práctica, prácticas subsecuentes y nuestro proyecto final.

---

## Articulo 1: "Cuando México tiembla: la historia contada por los datos" [(Villa Vargas et al., 2026)](#ref-1)

### Problema Abordado

México es un país altamente susceptible a sismos debido a su cercanía al circulo de fuego el cual es un conjunto de puntos de estrés de placas tectónicas conformado por la Placa Norteamericana, la Placa del Pacifico, la Placa de Rivera, la Placa de Cocos y la Placa del Caribe. Debido a que a pesar de otros tipos de desastres naturales los sismos no se pueden predecir, por lo tanto lo único que se puede hacer para reducir los daños causados por los sismos es estudiando grandes cantidades de datos de sismos, y siendo estos datos la profundidad de origen del sismo, la intensidad del sismo, punto exacto de la superficie ocurrió y que tanto se movió el suelo.
#### Datos del Sistema Sismológico Nacional

Debido a que la única forma de mitigar el daño es el análisis de datos el *Sistema Sismológico Nacional* (SSN) se ah dado a la tarea de recopilar datos de sismos desde 1900 a la actualidad compilando mas de 300,000 conjuntos de datos de sismos en el país. 

El inconveniente con la compilación de datos del SSN es que los datos de los sismos son almacenados en *archivos de valores separados por comas* (CSV) los cuales tienen un volumen enorme y que contienen datos en crudo que carecen de un contexto fuera del técnico. Y la ultima barrera que tienen los datos del SSN es que para poder analizarlos en un aspecto mas profundo considerando variables como que poblaciones son expuestas a los efectos de un sismo requieren el uso de herramientas como SQL, sistemas de información geográfica especializados o scripts de análisis espacial los cuales pocos usan limitan en análisis de estos datos mas haya de únicamente lecturas, coordenadas y marcas de tiempo.

## Manejo de datos del sistema

Como ya se menciona el SSN maneja los datos en CSV entonces para poder analizarlos primero el sistema tiene que digerirlos usando un pipeline en Python, de este lo pasa a un Data Warehouse con SQL DDL y DML.

#### Funcionamiento del pipeline en Python

1. **Extracción**
	Los archivos de texto plano CSV son obtenidos del SSN, y usando conversion de `latin1`/`ISO-88580-1` a `UTF-8`.
2. **Validación y Limpieza**
   - Verifica que las coordenadas estén dentro del rectángulo definido por $\text{Latitud} \in [14.0 ^\circ N,33.0 ^\circ N]$, $\text{Longitud} \in [-118.0 ^\circ W,-86.0 ^\circ W]$ y que no estén en océano abierto, de lo contrario se descartan.
   - Si se encuentra un campo nulo o de valores ambiguos como `"en revisión"`, `"null"` o `"no disponible"` siendo registros sin magnitud o sin profundidades numéricas son descartados.
   - Los valores de `Fecha` y `Hora` se convierten en tipo `TIMESTAMP WITH TIME ZONE` o `ISO-8601`, y los valores de `Magnitud` y `Profundidad` pasan a `FLOAT8`.
3. **Transformación y Carga Directa**
   En vez de insertar datos fila por fila el script de Python genera un archivo estructurado en SQL en bloques masivos, después el script crea la DDL para instanciar tablas relacionales y ejecuta las sentencias DML directamente en el motor SQL.

#### Modelado de la Información

El Data Warehouse se organiza en un esquema en estrella dentro de PostgreSQL, donde los hechos analíticos se separan de las dimensiones y se conectan entre sí con llaves subrogadas, lo que hace que las consultas con JOIN sean más rápidas. El problema es que el catálogo del SSN cubre 125 años (1900-2025) mientras que los censos del INEGI son capturas estáticas y recientes, entonces no se puede cruzar directamente un sismo de hace décadas con el censo del año exacto en que ocurrió. Por eso la tabla de hechos, `fact_impacto_sismos_imputed`, no guarda datos censales reales sino métricas **imputadas** de población y actividad económica expuesta, calculadas según qué tan cerca está el sismo de los centros de población actuales.

Esta tabla se relaciona con cuatro dimensiones: los datos propios del sismo (magnitud, profundidad, fecha, hora), la zona territorial donde ocurrió —que ya trae integrada la población y densidad del INEGI en vez de tener una dimensión de población aparte, para no complicar los JOINs—, el tiempo desglosado en año, mes, día y trimestre, y la actividad económica de la zona según los Censos Económicos. Revisando la base de datos se confirma que solo existen esas 5 tablas: la de hechos y las cuatro dimensiones.

## Despliegue e Infraestructura

Para que cualquiera pueda instalar el sistema sin batallar con dependencias, todo corre en dos contenedores de Docker manejados con Docker Compose y conectados por una red interna: uno para la base de datos, con PostgreSQL 17 corriendo la base `datawarehouse`, y otro para la aplicación web, con Apache y PHP 8, que recibe las peticiones del frontend, consulta la base de datos y regresa los resultados en JSON. Levantar todo el sistema toma un solo comando (`docker-compose up -d`), que descarga las imágenes, crea la red, monta los volúmenes para que los datos no se pierdan al reiniciar, inicializa el esquema y arranca todo sin necesidad de instalar PHP, Apache o los drivers de PostgreSQL manualmente en la máquina.

## Interfaz Web y Visualización

El frontend combina PHP 8 sobre Apache para la lógica de negocio, HTML5 y CSS3 con Bootstrap para que se vea bien tanto en computadora como en celular, y JavaScript para pedir los datos sin recargar la página. Los mapas se generan con la librería Leaflet sobre capas de OpenStreetMap. Desde ahí el usuario puede filtrar sismos por fecha, año y magnitud mínima y ver un mapa interactivo donde los sismos se colorean según qué tan fuertes fueron —verde los leves, naranja los moderados, rojo los más peligrosos— y se marcan en azul las localidades con más de 50,000 habitantes, además de mapas de calor que muestran qué tan lejos llega el impacto de un sismo sobre zonas pobladas.

También hay un panel con cuatro gráficas —distribución de magnitudes, magnitud contra profundidad, sismos por mes y población afectada contra magnitud— que se probó con el caso de Jalisco en 2017, donde hubo 47 sismos y cerca de 5.5 millones de habitantes en zonas vulnerables. Por último, un módulo de reportes permite combinar fecha, magnitud, profundidad, localidad y datos demográficos o económicos para generar reportes exportables.

## Trabajo Futuro y Conclusiones

Con todo esto, el sistema logra convertir el catálogo del SSN, que antes solo servía para consultas técnicas, en una plataforma accesible y gratuita que cruza más de un siglo de sismos con datos demográficos y económicos del INEGI.

Como trabajo futuro se plantea agregar visualización 3D de los hipocentros, sumar capas de infraestructura crítica como hospitales y escuelas para calcular qué tan vulnerable es una zona, y conectar el sistema con redes de alerta sísmica en tiempo real para que los mapas se actualicen automáticamente después de un sismo fuerte.

---

## Articulo 2: "Territorial Information Retrieval from Heterogeneous Open Data through the Construction of a Data Warehouse for Water Management in Mexico City" [(Velázquez Arrieta et al., en prensa)](#ref-2)

### Problema Abordado

La Ciudad de México tiene problemas estructurales de agua: acuíferos sobreexplotados, muchas fugas en la red y una población que no deja de crecer. El SACMEX sí publica los datos de consumo, pero en archivos sueltos sin ningún esquema ni herramienta de consulta, lo que hace casi imposible usarlos para diagnosticar el territorio o tomar decisiones. La solución adapta la misma metodología del proyecto de datos sísmicos: un Data Warehouse en estrella, más una capa de Grafo de Conocimiento RDF, pensado para que lo usen desde ciudadanos hasta inspectores municipales e investigadores.

### Manejo de datos del sistema

Los datos vienen del CSV oficial de SACMEX (71,102 registros del primer semestre de 2019) y de observaciones climáticas diarias de Open-Meteo. El pipeline corre en cuatro fases: extracción del CSV, validación y limpieza (descarta los registros con la colonia o alcaldía marcada como `NA`, apenas 216 de 71,102), carga masiva a tablas temporales y llenado de las dimensiones, y por último el llenado de las tablas de hechos cruzando esas dimensiones con la información temporal — todo con scripts SQL propios, sin depender de un proceso externo.

### Modelado de la Información

El esquema en estrella tiene dos tablas de hechos: una de consumo (un registro por manzana urbana por bimestre, 70,886 en total) y otra de clima, ambas conectadas por la dimensión de tiempo. También hay una dimensión de ubicación (par alcaldía-colonia) y una de nivel socioeconómico del predio. Como los datos originales traen más de 22,000 coordenadas puntuales que se agrupan en solo 1,553 pares alcaldía-colonia, cualquier consulta a nivel de colonia ya es en realidad un resumen de manzanas individuales. Sobre ese mismo esquema se proyecta un Grafo de Conocimiento en RDF, útil para preguntas de vecindad territorial que el modelo relacional no resuelve bien —como las colonias solo tienen un punto de coordenadas y no un polígono real, en vez de usar la relación estándar de "colindancia" se define una propia basada en qué tan cerca están sus centroides.

### Detección y preguntas que responde

Como no hay reportes reales de fugas, el sistema no entrena un modelo de machine learning: calcula qué tan alejado está el consumo de una colonia respecto al promedio de su alcaldía, y así prioriza a cuáles hay que mandarles una inspección. Este método simple rinde casi igual que algoritmos más complejos, pero tiene la ventaja de que un inspector puede entender exactamente por qué se marcó una colonia. Con todo esto, el sistema permite responder qué colonias consumen más de lo esperado, cómo se reparte el consumo entre uso doméstico y no doméstico —por ejemplo, Cuauhtémoc y Miguel Hidalgo concentran el mayor consumo total de la ciudad— y cómo varía el consumo entre bimestres.

### Despliegue e Infraestructura

Todo se apoya en PostgreSQL, con un esquema de despliegue doble: una versión dinámica respaldada en la base de datos, y una demostración totalmente estática que exporta los datos a JSON y GeoJSON para que el navegador los lea directamente con Leaflet y Plotly, publicada en GitHub Pages. Así el proyecto se puede revisar indefinidamente sin necesidad de mantener un servidor corriendo.

### Trabajo Futuro y Conclusiones

Los autores reconocen que la fuente solo cubre medio año (2019), que la detección de consumo atípico se probó con anomalías simuladas en vez de datos reales de fugas, y que representar las colonias como un punto en vez de su polígono real limita el tipo de consultas espaciales que se pueden hacer. Como trabajo futuro proponen exponer el grafo RDF en un servicio público, usar los polígonos oficiales de las colonias, validar la detección de atipicidad con datos reales de campo, y reutilizar el mismo patrón de pipeline y despliegue dual en otros dominios urbanos como transporte o monitoreo ambiental.

---

## Articulo 3: "A Dimensional Data Warehouse for Geospatial Monitoring of Municipal Public Works, with an Evolution Path Toward a Lakehouse Architecture" [(González Casiano et al., en prensa)](#ref-3)

### Problema Abordado

Temascaltepec, en el Estado de México, tiene cerca de 65,000 habitantes repartidos en 55 comunidades muy dispersas, y su gestión de obra pública dependía de hojas de cálculo y sistemas sueltos que no permitían darle seguimiento real al ciclo de vida de una obra ni detectar a tiempo retrasos o desviaciones de presupuesto. Para probar el sistema sin exponer datos reales sensibles, se validó con un volumen sintético que imita la escala del municipio: 1,247 obras, 127.4 millones de pesos de presupuesto, miles de eventos de auditoría, fotos de campo, propuestas y votos ciudadanos.

### Manejo de datos del sistema

En vez de montar una plataforma de Big Data cara de mantener, el sistema se apoya en infraestructura más sencilla: PostgreSQL (sobre Supabase) para todo lo transaccional y analítico, y Cloudflare R2 para guardar fotos y PDFs de evidencia sin pagar por sacar esos archivos de ahí. La arquitectura tiene cuatro capas: una aplicación web donde directores, supervisores y ciudadanos capturan la información; una API en Flask con más de 50 rutas que valida y autoriza cada operación; el almacenamiento dividido entre la base de datos y el repositorio de archivos; y la capa de mapas con Leaflet. A diferencia de los otros dos proyectos, aquí no hay un pipeline en Python corriendo aparte: son triggers de SQL los que sincronizan automáticamente el esquema operativo con el Data Warehouse en el momento en que se inserta o modifica un dato.

### Modelado de la Información

El esquema en estrella tiene dos tablas de hechos: una de eventos de auditoría (un registro por cada acción sobre una obra, dividida por año para no tener que revisar toda la tabla en cada consulta) y otra de fotos mensuales del avance de cada obra —por diseño, estos montos no se deben sumar entre meses porque no son transacciones nuevas sino un acumulado—. Se conectan con diez dimensiones que se manejan distinto según qué tan seguido cambian: las que necesitan conservar su historial completo (la obra, la región, el contratista, el personal, el presupuesto) guardan cada versión anterior en vez de sobrescribirla; las que solo importa su estado actual (la fuente de financiamiento, el ciudadano, una propuesta) se sobrescriben directamente —los datos de un ciudadano, por ejemplo, no se versionan para no acumular información personal de más—; y los catálogos fijos, como el tiempo, nunca cambian. Encima de esas tablas hay vistas ya armadas para las consultas más comunes: obras retrasadas, alertas de auditoría, historial de una obra, participación ciudadana y presupuesto ejecutado.

### Detección y preguntas que responde

El sistema marca una obra como sospechosa con tres reglas simples: que su costo se aleje mucho del promedio, que lleve más de 120 días de retraso, o que el avance financiero sea mucho mayor que el físico. Estas reglas responden bien para detectar contratistas improductivos u obras fantasma, pero les cuesta encontrar sobreprecios en obras pequeñas o pagos adelantados, porque comparan contra un promedio general en vez de contra el promedio de ese tipo de obra en particular. Aun así, el sistema permite responder qué obras van retrasadas o con sobrecostos, cómo cambió el presupuesto o el contratista de una obra a lo largo del tiempo, y qué tanto participa la ciudadanía con propuestas y votos.

### Despliegue e Interfaz

El visor en Leaflet muestra las obras sobre el mapa coloreadas según su estado —verde completada, ámbar en proceso, rojo retrasada— y al seleccionar una obra se abre una ficha que compara el avance físico contra el financiero y muestra las fotos guardadas en Cloudflare R2. El motor de base de datos responde en milisegundos, pero la API tiene un cuello de botella cuando manda el catálogo completo de obras sin dividirlo en páginas.

### Trabajo Futuro y Conclusiones

Los autores reconocen que el sistema se probó con datos sintéticos y no reales, y que el control de acceso del personal municipal es todavía simple, sin expiración de sesión, algo que habría que reforzar antes de usarlo en producción. Como trabajo futuro plantean migrar hacia una arquitectura tipo Lakehouse para poder escalar a varios municipios, validar el avance físico de las obras con visión por computadora sobre las fotos subidas, predecir retrasos con modelos de series de tiempo, adoptar el estándar internacional de transparencia OC4IDS, y ajustar el criterio de sobreprecio para que compare por tipo de obra en vez de con un promedio general.

---

## Referencias

<a id="ref-3"></a>
González Casiano, U., Maldonado Mejía, M. T., y Hurtado Avilés, G. (en prensa). A dimensional data warehouse for geospatial monitoring of municipal public works, with an evolution path toward a lakehouse architecture. En *Advances in Computer Science Applications and Research*. Springer.

<a id="ref-2"></a>
Velázquez Arrieta, E. U., Pulido Morales, O. F., García López, E., Hernández Martínez, C. A., y Hurtado Avilés, G. (en prensa). Territorial information retrieval from heterogeneous open data through the construction of a data warehouse for water management in Mexico City. En *Advances in Computer Science Applications and Research*. Springer.

<a id="ref-1"></a>
Villa Vargas, J. M., Hurtado Avilés, G., y Climent Hernández, J. A. (2026). Cuando México tiembla: la historia contada por los datos. *AZCATL Revista de Divulgación de la Ciencia, la Ingeniería y la Innovación*, *4*(6), 28–33. https://doi.org/10.24275/AZC2026E1004
