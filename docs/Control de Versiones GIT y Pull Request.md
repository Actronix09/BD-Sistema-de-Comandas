# Evidencias del Flujo de Git y Pull Request de la Práctica 1

---

## Tabla de Contenidos

- [Estructura de ramas del repositorio](#estructura-de-ramas-del-repositorio)
- [Pull Requests realizados](#pull-requests-realizados)
  - [Pull Request #1 — Desarrollo-Parte-2](#pull-request-1--desarrollo-parte-2)
  - [Pull Request #3 — Caso-de-Estudio](#pull-request-3--caso-de-estudio)
  - [Pull Request #4 - Desarrollo-Parte-4](#pull-request-4--desarrollo-parte-4)
  - [Pull Request #5 — ejercicio3](#pull-request-5--ejercicio3)
  - [Pull Request #6 — Desarrollo-Practico-Parte-1](#pull-request-6--desarrollo-practico-parte-1)
- [Historial completo del repositorio](#historial-completo-del-repositorio)

---

## Estructura de ramas del repositorio

El trabajo se dividió en ramas independientes creadas a partir de `main`, siguiendo el flujo de trabajo basado en ramas descrito en [Control de Versiones (Git)](<Control de Versiones.md#flujo-de-trabajo-basado-en-ramas>). Cada rama concentra una parte de la práctica y se integra a `main` mediante un Pull Request, nunca con una fusión directa.

| Rama | Contenido | Pull Request |
| --- | --- | --- |
| `Desarrollo-Parte-2` | Entorno Docker y evidencias de persistencia del volumen | #1 |
| `Caso-de-Estudio` | Entrevista con el cliente, analisis del caso de  estudio y diagrama entidad-relación | #3 |
| `Desarrollo-Parte-4` | Estado del arte donde se comparan tres articulos que se relaciónan con la Unidad Tematica I de la materia | #4 |
| `ejerccio3` | Investigación de ¿Qué es una base de datos? | #5 |
| `Desarrollo-Practico-Parte-1` | Evidencia de todos los pull request de del desarrollo de practica | #6 |

La rama de trabajo se crea y se publica en el repositorio remoto con:

```bash
git switch -c Desarrollo-Parte-2
git push -u origin Desarrollo-Parte-2
```

Una vez terminados los cambios, se confirman y se suben para poder abrir el Pull Request:

```bash
git add .
git commit -m "Finalización de la parte 2 de la investigación"
git push
```

## Pull Requests realizados

Para cada rama se abrió un Pull Request hacia `main` desde la interfaz de GitHub. En él se revisan los cambios archivo por archivo antes de aprobar la fusión, tal como se explica en [¿Por qué se revisa el código entre pares antes de fusionar?](<Control de Versiones.md#por-qué-se-revisa-el-código-entre-pares-antes-de-fusionar>).

### Pull Request #1 — Desarrollo-Parte-2

Integra el contenedor de PostgresSQl integrado por: el archivo [compose.yml](<../entorno/compose.yml>), la documentación de [Persistencia del Volumen de Docker](<Persistencia del Volumen de Docker.md>) y sus evidencias.

![Pull Request #1 fusionado en GitHub, mostrando la rama Desarrollo-Parte-2 integrada a main](<../evidencias/git/Pull Request Fusionado de la Parte 2.png>)

### Pull Request #3 — Caso-de-Estudio

Integra el desarrollo del caso de estudio consistiendo de: el archivo markdown [Entrevista.md](./Entrevista.md), el archivo [CasoDeEstudio.tex](<./LaTeX/Secciones/CasoDeEstudio.tex>), el diagrama [diagrama-er.png](../modelo/diagrama-er.png) y [Practica 1.pdf](./LaTeX/Practica 1.pdf) siendo el archivo completo donde se incluye la Seccion 5.

![Pull Request #3 fusionado en GitHub, mostrando la rama Caso-de-Estudio integrada a main](<../evidencias/git/Pull Request Fusionado del Caso de Estudio.png>)

### Pull Request #4 - Desarrollo-Parte-4

Se integra el Estado del Arte consistiendo unicamente del archivo [Introducción.tex](./LaTeX/Secciones/Introduccion.tex) consistiendo unicamente de la ultima seccion de dicho documento, y el archivo compilado [Practica 1.pdf](./LaTeX/Practica 1.pdf).

![Pull Request #3 fusionado en GitHub, mostrando la rama Desarrollo-Parte-4 integrada a main](<../evidencias/git/Pull Request Fusionado de la Parte 4.png>)

### Pull Request #5 — ejercicio3

En la rama ejerccio3 se desarrollo la investigación principal incluida en  [Introducción.tex](./LaTeX/Secciones/Introduccion.tex), y con esta seccion concretando el desarrollo de [Practica 1.pdf](./LaTeX/Practica 1.pdf).

![Pull Request #3 fusionado en GitHub, mostrando la rama ejercicio3 integrada a main](<../evidencias/git/Pull Request Fusionado del Ejercicio 3.png>)

### Pull Request #6 — Desarrollo-Practico-Parte-1

Integra la compilación de evidencias de la fusión de las ramas y el uso de git durante la practica en el archivo [Control de Versiones GIT y Pull Request.md](<./Control de Versiones GIT y Pull Request.md>).

![Pull Request #4 fusionado en GitHub, mostrando la rama Desarrollo-Practico-Parte-1 integrada a main](<../evidencias/git/Pull Request Fusionado de la Parte 1.png>)

## Historial completo del repositorio

Una vez integradas todas las ramas, se consulta el historial completo del repositorio en forma de grafo:

```bash
git log --oneline --graph --all
```

Cada línea corresponde a un commit y las bifurcaciones del grafo muestran el punto en que se creó cada rama y el commit de merge donde volvió a `main`.

![Salida de git log --oneline --graph --all](<../evidencias/git/Historial de Ramas.png>)
