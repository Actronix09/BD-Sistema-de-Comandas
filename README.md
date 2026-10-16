# Desarrollo de Practicas de Bases de Datos
## Práctica 3

**Sitio del proyecto:** <https://actronix09.github.io/Desarrollo-Proyecto-Final-BD/>

---

|Alumnos|Boleta|@GitHub|
|---|---|---|
|Damas Garnica Adrian|2034630785|[@Actronix09](<https://github.com/Actronix09>)|
|Esparza Ramón Fernando Adán|2025631043|[@adamighti2](<https://github.com/adamighti2>)|
|Ramos Padrón Jesus Emmanuel|2025630963|[@Chuchin2107](<https://github.com/Chuchin2107>)|
|Hernandez Barrios Samuel Rodrigo|2026630008|[@Samuel-Hdzx07](<https://github.com/Samuel-Hdzx07>)|

**Grupo:** 3CV4

**Carrera:** Ingenieria en Sistemas Computacionalesl\

**Proyecto:** Sistema de Comandas Profesional

**Proyecto Paralelo del Equipo:** [Samuel-Hdzx07/BD-Proyecto-Musica](<https://github.com/Samuel-Hdzx07/BD-Proyecto-Musica.git>)

**Proyecto Asignado:** 

- **Visualización de Impacto de Sismos**
- **Repositorio original:** [gabrielhuav/Seismic-Data-Visualization-System](<https://github.com/gabrielhuav/Seismic-Data-Visualization-System>)
- **Fork del equipo:** [Samuel-Hdzx07/Proyecto-Asig-Sismos](<https://github.com/Samuel-Hdzx07/Proyecto-Asig-Sismos>)
- **Identificador de la confirmación del fork:** `8569667cf4f46fab640dba3f82a7b324ca7efaf7`

---

En el siguiente repositorio se presenta el trabajo de investigación y desarrollo correspondiente a las prácticas de la asignatura de *Bases de Datos*.

---

## Indice

- [Control de Versiones (Git)](<docs/Control de Versiones.md>)
  - [Sistema Gestor de Versiones](<docs/Control de Versiones.md#sistema-gestor-de-versiones>)
  - [Definiciones](<docs/Control de Versiones.md#definiciones>)
  - [Flujo de Trabajo Basado en Ramas](<docs/Control de Versiones.md#flujo-de-trabajo-basado-en-ramas>)
  - [Referencias](<docs/Control de Versiones.md#referencias>)
- [Evidencias del Flujo de Git y Pull Request](<docs/Control de Versiones GIT y Pull Request.md>)
  - [Estructura de ramas del repositorio](<docs/Control de Versiones GIT y Pull Request.md#estructura-de-ramas-del-repositorio>)
  - [Pull Requests realizados](<docs/Control de Versiones GIT y Pull Request.md#pull-requests-realizados>)
  - [Historial completo del repositorio](<docs/Control de Versiones GIT y Pull Request.md#historial-completo-del-repositorio>)
- [Contenedores en Docker](<docs/Contenedores.md>)
  - [Diferencias entre contenedor y maquina virtual](<docs/Contenedores.md#diferencias-entre-contenedor-y-maquina-virtual>)
  - [Imagen](<docs/Contenedores.md#imagen>)
  - [Contenedor](<docs/Contenedores.md#contenedor>)
  - [Volumen](<docs/Contenedores.md#volumen>)
  - [Puerto publicado](<docs/Contenedores.md#puerto-publicado>)
  - [Respecto a un volumen](<docs/Contenedores.md#respecto-a-un-volumen>)
    - [¿Por qué es indispensable?](<docs/Contenedores.md#por-qué-es-indispensable>)
    - [¿Qué ocurre si no se declara?](<docs/Contenedores.md#qué-ocurre-si-no-se-declara>)
  - [Referencias](<docs/Contenedores.md#referencias>)
- [Persistencia del Volumen de Docker](<docs/Persistencia del Volumen de Docker.md>)
  - [Configuración del entorno](<docs/Persistencia del Volumen de Docker.md#configuración-del-entorno>)
  - [Creación del contenedor y la base de datos](<docs/Persistencia del Volumen de Docker.md#creación-del-contenedor-y-la-base-de-datos>)
  - [Eliminación del contenedor](<docs/Persistencia del Volumen de Docker.md#eliminación-del-contenedor>)
  - [Verificación de la persistencia](<docs/Persistencia del Volumen de Docker.md#verificación-de-la-persistencia>)
- [Entrevista con el Cliente](<docs/Entrevista.md>)
  - [Eventos y mesas](<docs/Entrevista.md#eventos-y-mesas>)
  - [Menu y productos](<docs/Entrevista.md#menu-y-productos>)
  - [Flujo de comandas](<docs/Entrevista.md#flujo-de-comandas>)
  - [Cobros y pagos](<docs/Entrevista.md#cobros-y-pagos>)
  - [Roles y permisos](<docs/Entrevista.md#roles-y-permisos>)
  - [Reportes](<docs/Entrevista.md#reportes>)
  - [Operacion y escalabilidad](<docs/Entrevista.md#operacion-y-escalabilidad>)
- [Análisis de los Tres Artículos de los Proyectos](<docs/InvestigaciónDeArticulos.md>)
  - [Artículo 1: "Cuando México tiembla: la historia contada por los datos"](<docs/InvestigaciónDeArticulos.md#articulo-1-cuando-méxico-tiembla-la-historia-contada-por-los-datos-villa-vargas-et-al-2026>)
  - [Artículo 2: "Territorial Information Retrieval from Heterogeneous Open Data..."](<docs/InvestigaciónDeArticulos.md#articulo-2-territorial-information-retrieval-from-heterogeneous-open-data-through-the-construction-of-a-data-warehouse-for-water-management-in-mexico-city-velázquez-arrieta-et-al-en-prensa>)
  - [Artículo 3: "A Dimensional Data Warehouse for Geospatial Monitoring of Municipal Public Works..."](<docs/InvestigaciónDeArticulos.md#articulo-3-a-dimensional-data-warehouse-for-geospatial-monitoring-of-municipal-public-works-with-an-evolution-path-toward-a-lakehouse-architecture-gonzález-casiano-et-al-en-prensa>)
  - [Referencias](<docs/InvestigaciónDeArticulos.md#referencias>)
- [Modelo Entidad-Relación Extendido del Sistema de Comandas](<docs/ModeloEntidadRelaciónExtendido.md>)
  - [El problema](<docs/ModeloEntidadRelaciónExtendido.md#el-problema>)
  - [Reconsideración de requisitos](<docs/ModeloEntidadRelaciónExtendido.md#reconsideración-de-requisitos>)
  - [Relaciones](<docs/ModeloEntidadRelaciónExtendido.md#relaciones>)
  - [Restricciones](<docs/ModeloEntidadRelaciónExtendido.md#restricciones>)
  - [Conceptos del modelo extendido que el caso no necesita](<docs/ModeloEntidadRelaciónExtendido.md#conceptos-del-modelo-extendido-que-el-caso-no-necesita>)
  - [Modelo en notación de Peter Chen](<docs/ModeloEntidadRelaciónExtendido.md#modelo-en-notación-de-peter-chen>)
  - [Justificación](<docs/ModeloEntidadRelaciónExtendido.md#justificación>)
- [Entorno de Trabajo de la Práctica 3](<docs/EntornoPractica3.md>)
  - [Rama de trabajo](<docs/EntornoPractica3.md#rama-de-trabajo>)
  - [Levantamiento del gestor](<docs/EntornoPractica3.md#levantamiento-del-gestor>)
  - [Base de datos vacía](<docs/EntornoPractica3.md#base-de-datos-vacía>)
- [Inventario del Modelo Entidad-Relación Extendido](<docs/InventarioModeloEER.md>)
  - [Entidades fuertes](<docs/InventarioModeloEER.md#entidades-fuertes>)
  - [Entidades débiles](<docs/InventarioModeloEER.md#entidades-débiles>)
  - [Relaciones](<docs/InventarioModeloEER.md#relaciones>)
  - [Jerarquías de generalización y especialización](<docs/InventarioModeloEER.md#jerarquías-de-generalización-y-especialización>)
  - [Atributos multivaluados, compuestos y derivados](<docs/InventarioModeloEER.md#atributos-multivaluados-compuestos-y-derivados>)
  - [Relaciones ternarias o de orden superior](<docs/InventarioModeloEER.md#relaciones-ternarias-o-de-orden-superior>)
  - [Preguntas previas a la transformación](<docs/InventarioModeloEER.md#preguntas-previas-a-la-transformación>)
  - [Resumen del inventario](<docs/InventarioModeloEER.md#resumen-del-inventario>)
- [Reglas de Transformación del Modelo EER al Modelo Relacional](<docs/ReglasDeTransformacion.md>)
  - [Notación](<docs/ReglasDeTransformacion.md#notación>)
  - [Decisiones de tipos de dato](<docs/ReglasDeTransformacion.md#decisiones-de-tipos-de-dato>)
  - [Parte 3 — Reglas de transformación básicas](<docs/ReglasDeTransformacion.md#parte-3--reglas-de-transformación-básicas>)
    - [Regla 1: entidades fuertes](<docs/ReglasDeTransformacion.md#regla-1-entidades-fuertes>)
    - [Regla 2: atributos compuestos](<docs/ReglasDeTransformacion.md#regla-2-atributos-compuestos>)
    - [Regla 3: atributos multivaluados](<docs/ReglasDeTransformacion.md#regla-3-atributos-multivaluados>)
    - [Atributos derivados](<docs/ReglasDeTransformacion.md#atributos-derivados>)
  - [Parte 4 — Transformación de relaciones](<docs/ReglasDeTransformacion.md#parte-4--transformación-de-relaciones>)
    - [Regla 4: relaciones uno a muchos](<docs/ReglasDeTransformacion.md#regla-4-relaciones-uno-a-muchos>)
    - [Regla 5: relaciones muchos a muchos](<docs/ReglasDeTransformacion.md#regla-5-relaciones-muchos-a-muchos>)
    - [Regla 6: relaciones uno a uno](<docs/ReglasDeTransformacion.md#regla-6-relaciones-uno-a-uno>)
    - [Regla 7: relaciones de orden superior](<docs/ReglasDeTransformacion.md#regla-7-relaciones-de-orden-superior>)
    - [Resumen de relaciones y regla aplicada](<docs/ReglasDeTransformacion.md#resumen-de-relaciones-y-regla-aplicada>)
    - [Acciones referenciales](<docs/ReglasDeTransformacion.md#acciones-referenciales>)
  - [Parte 5 — Entidades débiles y jerarquías](<docs/ReglasDeTransformacion.md#parte-5--entidades-débiles-y-jerarquías>)
    - [Regla 8: entidades débiles](<docs/ReglasDeTransformacion.md#regla-8-entidades-débiles>)
    - [Regla 9: jerarquías](<docs/ReglasDeTransformacion.md#regla-9-jerarquías>)
    - [Jerarquía de Usuario](<docs/ReglasDeTransformacion.md#jerarquía-de-usuario>)
    - [Lo que el esquema no puede garantizar](<docs/ReglasDeTransformacion.md#lo-que-el-esquema-no-puede-garantizar>)
    - [Tablas resultantes](<docs/ReglasDeTransformacion.md#tablas-resultantes>)
- [Esquema Relacional, DDL Ejecutado y Diccionario](<docs/EsquemaRelacional.md>)
  - [6.1 Esquema completo](<docs/EsquemaRelacional.md#61-esquema-completo>)
  - [6.2 Script de definición de datos](<docs/EsquemaRelacional.md#62-script-de-definición-de-datos>)
  - [6.3 Diagrama relacional](<docs/EsquemaRelacional.md#63-diagrama-relacional>)
  - [6.4 Diccionario de datos](<docs/EsquemaRelacional.md#64-diccionario-de-datos>)
  - [6.5 Preservación del significado](<docs/EsquemaRelacional.md#65-preservación-del-significado>)
- [Diccionario de Datos del Sistema de Comandas](<docs/DiccionarioDeDatos.md>)
  - [Convenciones](<docs/DiccionarioDeDatos.md#convenciones>)
  - [evento](<docs/DiccionarioDeDatos.md#evento>)
  - [evento_organizador](<docs/DiccionarioDeDatos.md#evento_organizador>)
  - [usuario](<docs/DiccionarioDeDatos.md#usuario>)
  - [mesero](<docs/DiccionarioDeDatos.md#mesero>)
  - [bar_cocina](<docs/DiccionarioDeDatos.md#bar_cocina>)
  - [cajero_admin](<docs/DiccionarioDeDatos.md#cajero_admin>)
  - [mesa](<docs/DiccionarioDeDatos.md#mesa>)
  - [cuenta](<docs/DiccionarioDeDatos.md#cuenta>)
  - [producto](<docs/DiccionarioDeDatos.md#producto>)
  - [ingrediente](<docs/DiccionarioDeDatos.md#ingrediente>)
  - [receta](<docs/DiccionarioDeDatos.md#receta>)
  - [paquete](<docs/DiccionarioDeDatos.md#paquete>)
  - [paquete_producto](<docs/DiccionarioDeDatos.md#paquete_producto>)
  - [acuerdo](<docs/DiccionarioDeDatos.md#acuerdo>)
  - [comanda](<docs/DiccionarioDeDatos.md#comanda>)
  - [pago](<docs/DiccionarioDeDatos.md#pago>)
  - [anticipo](<docs/DiccionarioDeDatos.md#anticipo>)
  - [Vistas de atributos derivados](<docs/DiccionarioDeDatos.md#vistas-de-atributos-derivados>)

---  
  
## Documento de Desarrollo

El reporte principal de la práctica se encuentra en:

**[Practica 1.pdf](<docs/LaTeX/Practica 1.pdf>)** (fuente LaTeX en [docs/LaTeX](<docs/LaTeX>))

1. Introducción
   - Planteamiento del problema
   - Justificación
   - Objetivo general
   - Objetivos específicos
   - Estado del arte
   - Productos esperados
2. Marco teórico
   - Dato, información y bases de datos
   - Características de una base de datos
   - Archivos contra bases de datos
   - Usuarios de una base de datos
   - Ciclo de vida de una base de datos
   - Sistema gestor de bases de datos
   - Sistema de bases de datos
   - Modelos de datos
3. Caso de estudio
   - Entrevista con el cliente
   - Requerimientos de la base de datos
   - Requerimientos del sistema en general
   - Diagrama Entidad-Relación
   - Justificación del modelo
- Referencias

## Diagramas

- [Diagrama entidad-relación (PNG)](<modelo/diagrama-er.png>)
- [Diagrama entidad-relación extendido del sistema de comandas (PNG)](<modelo/diagrama-eer.png>)
- [Diagrama relacional del sistema de comandas (PNG)](<modelo/diagrama-relacional.png>)

## Licencia

Este proyecto se distribuye bajo la [Licencia MIT](<LICENSE>).
