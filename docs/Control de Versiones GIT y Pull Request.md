# Evidencias del Flujo de Git y Pull Request de la Práctica 1

---

## Tabla de Contenidos

- [Estructura de ramas del repositorio](#estructura-de-ramas-del-repositorio)
- [Pull Requests realizados](#pull-requests-realizados)
  - [Pull Request #1 — Desarrollo-Parte-2](#pull-request-1--desarrollo-parte-2)
  - [Pull Request #2 — Caso-de-Estudio](#pull-request-2--caso-de-estudio)
  - [Pull Request #3 — ejercicio3](#pull-request-3--ejercicio3)
  - [Pull Request #4 — Desarrollo-Practico-Parte-1](#pull-request-4--desarrollo-practico-parte-1)
- [Historial completo del repositorio](#historial-completo-del-repositorio)

---

## Estructura de ramas del repositorio

El trabajo se dividió en ramas independientes creadas a partir de `main`, siguiendo el flujo de trabajo basado en ramas descrito en [Control de Versiones (Git)](<Control de Versiones.md#flujo-de-trabajo-basado-en-ramas>). Cada rama concentra una parte de la práctica y se integra a `main` mediante un Pull Request, nunca con una fusión directa.

| Rama | Contenido | Pull Request |
| --- | --- | --- |
| `Desarrollo-Parte-2` | Entorno Docker y evidencias de persistencia del volumen | #1 |
| `Caso-de-Estudio` | Preguntas y análisis del caso de estudio | #2 |
| `ejercicio3` | Conceptos de dato, información y bases de datos | #3 |
| `Desarrollo-Practico-Parte-1` | Evidencias de la parte 1 del desarrollo práctico | #4 |

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

Integra a `main` el archivo [compose.yml](<../entorno/compose.yml>), la documentación de [Persistencia del Volumen de Docker](<Persistencia del Volumen de Docker.md>) y sus evidencias.

![Pull Request #1 fusionado en GitHub, mostrando la rama Desarrollo-Parte-2 integrada a main](<../evidencias/git/Pull Request Fusionado de la Parte 2.png>)

### Pull Request #2 — Caso-de-Estudio

<!-- Descripción breve: qué archivos integra y qué commits abarca. -->

![Pull Request #2 fusionado en GitHub, mostrando la rama Caso-de-Estudio integrada a main](<../evidencias/git/Pull Request Fusionado del Caso de Estudio.png>)

### Pull Request #3 — ejercicio3

<!-- Descripción breve: qué archivos integra y qué commits abarca. -->

![Pull Request #3 fusionado en GitHub, mostrando la rama ejercicio3 integrada a main](<../evidencias/git/Pull Request Fusionado del Ejercicio 3.png>)

### Pull Request #4 — Desarrollo-Practico-Parte-1

<!-- Descripción breve: qué archivos integra y qué commits abarca. -->

![Pull Request #4 fusionado en GitHub, mostrando la rama Desarrollo-Practico-Parte-1 integrada a main](<../evidencias/git/Pull Request Fusionado de la Parte 1.png>)

## Historial completo del repositorio

Una vez integradas todas las ramas, se consulta el historial completo del repositorio en forma de grafo:

```bash
git log --oneline --graph --all
```

Cada línea corresponde a un commit y las bifurcaciones del grafo muestran el punto en que se creó cada rama y el commit de merge donde volvió a `main`.

![Salida de git log --oneline --graph --all](<../evidencias/git/Historial de Ramas.png>)
