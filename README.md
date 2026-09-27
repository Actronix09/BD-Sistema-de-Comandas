# Práctica 1

---

**Alumno:** Adrian Damas Garnica

**Boleta:** 2023630785

**Grupo:** 3CV4

**Carrera:** Ingenieria en Sistemas Computacionales

**Proyecto Principal:** Sistema de Comandas Profesional

**Proyecto Asignado:** Monitoreo de Obras Públicas

- **Repositorio original:** <https://github.com/gabrielhuav/PublicMunicipalWorks_DWH>
- **Fork del equipo:** <https://github.com/Actronix09/PublicMunicipalWorks_DWH>
- **Identificador de la confirmación del fork:** `59a0f9d96f6def17b3f9cb109bc37314a48c2cb6`

---

En el siguiente repositorio se presenta el trabajo de investigación y desarrollo correspondiente a la asignatura de *Bases de Datos*.

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
  - [Anexos](<docs/Persistencia del Volumen de Docker.md#anexos>)
- [Levantamiento del Proyecto Asignado](<docs/Levantamiento.md>)
  - [Proyecto asignado](<docs/Levantamiento.md#proyecto-asignado>)
  - [Fork y clonación del repositorio](<docs/Levantamiento.md#fork-y-clonación-del-repositorio>)
  - [Instrucciones seguidas del README del proyecto](<docs/Levantamiento.md#instrucciones-seguidas-del-readme-del-proyecto>)
  - [Levantamiento de los contenedores](<docs/Levantamiento.md#levantamiento-de-los-contenedores>)
  - [Poblado de la base de datos](<docs/Levantamiento.md#poblado-de-la-base-de-datos>)
  - [Aplicación en funcionamiento](<docs/Levantamiento.md#aplicación-en-funcionamiento>)
  - [Consultas directas sobre la base de datos](<docs/Levantamiento.md#consultas-directas-sobre-la-base-de-datos>)
  - [Resultados obtenidos](<docs/Levantamiento.md#resultados-obtenidos>)
- [Entrevista con el Cliente](<docs/Entrevista.md>)
  - [Eventos y mesas](<docs/Entrevista.md#eventos-y-mesas>)
  - [Menu y productos](<docs/Entrevista.md#menu-y-productos>)
  - [Flujo de comandas](<docs/Entrevista.md#flujo-de-comandas>)
  - [Cobros y pagos](<docs/Entrevista.md#cobros-y-pagos>)
  - [Roles y permisos](<docs/Entrevista.md#roles-y-permisos>)
  - [Reportes](<docs/Entrevista.md#reportes>)
  - [Operacion y escalabilidad](<docs/Entrevista.md#operacion-y-escalabilidad>)

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

## Modelo Entidad-Relación

- [Diagrama entidad-relación (PDF)](<modelo/diagrama-er.pdf>)
- [Diagrama entidad-relación (PNG)](<modelo/diagrama-er.png>)
