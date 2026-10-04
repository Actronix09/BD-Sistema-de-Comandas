# Control de Versiones (Git)

---

## Sistema Gestor de Versiones

Un sistema de control de versiones es una herramienta que almacena las diferentes versiones de un trabajo o proyecto. Lo que lo distingue del historial de acciones (deshacer/rehacer) de una aplicación convencional es que cada versión no solo guarda el archivo actual, sino todos los archivos del proyecto y los cambios realizados en ellos. Esto permite al usuario regresar a versiones anteriores, compararlas o simplemente consultar qué había en alguna de ellas (Chacon & Straub, 2014).

Por ejemplo, supongamos que estamos trabajando en un proyecto y decidimos hacer un cambio en un módulo que, a su vez, nos obliga a modificar otros módulos para mantener la compatibilidad. Al final llegamos a la conclusión de que el nuevo sistema que hemos estado diseñando no funciona en absoluto. Sin un sistema de control de versiones, lo mejor que podríamos hacer es esperar que el historial de nuestro editor haya guardado lo suficiente, lo cual casi nunca ocurre. Con un sistema de control de versiones no tenemos que preocuparnos por eso: simplemente restauramos la última versión funcional y podemos empezar de nuevo con una idea distinta, o dejar el sistema como estaba.

Otro escenario es querer recuperar una función que implementamos hace meses pero que ya borramos. En ese caso basta con consultar la versión en la que aún existía dicha función y copiarla.

### Git y GitHub

Git y GitHub, aunque están relacionados, no son lo mismo. Git es un sistema de control de versiones distribuido, creado por Linus Torvalds para el desarrollo del kernel de Linux; funciona de manera local en nuestra computadora y no necesita internet (Chacon & Straub, 2014). GitHub, en cambio, es una plataforma web que aloja repositorios de Git en la nube, lo que facilita compartir proyectos y colaborar con otras personas (GitHub, n.d.-d). Además, permite ver el trabajo y los proyectos de otros usuarios, por lo que funciona en parte como una red social para desarrolladores.

## Definiciones

### Repositorio

Un repositorio es el espacio donde se almacenan los archivos de un proyecto junto con todo su historial de versiones. Puede existir de forma local en nuestra computadora o alojarse en una plataforma como GitHub, lo que permite compartir el proyecto con otros usuarios para que puedan consultarlo o trabajar a partir de él (GitHub, n.d.-d).

### Confirmación (commit)

Es la acción, realizada desde la línea de comandos (CLI) o una interfaz gráfica (GUI), de registrar en el historial un conjunto de cambios del proyecto. Cada confirmación funciona como una "fotografía" del estado de los archivos en ese momento, acompañada de un mensaje que describe lo que se modificó. Las confirmaciones se guardan de forma local y, posteriormente, pueden enviarse (push) a un repositorio remoto (Chacon & Straub, 2014).

### Rama (branch)

Una rama es una línea de trabajo que nace a partir de otra, usualmente la rama principal (`main`). A partir de ella se desarrolla una línea nueva, paralela a la original, en la que se pueden hacer cambios sin afectar a esta última (Chacon & Straub, 2014).

### Fusión (merge)

Es la acción de unir dos ramas, incorporando los cambios de una en la otra. A partir del punto de unión, ambas ramas comparten la misma información (Git, n.d.-a).

### Conflicto de fusión

Ocurre cuando, al fusionar dos ramas, un mismo fragmento de un archivo fue modificado de forma distinta en cada una. Git no puede decidir por sí solo qué versión conservar, por lo que es necesario intervenir manualmente para elegir qué información guardar y cuál descartar (Git, n.d.-a).

### Solicitud de extracción (Pull Request)

Es una solicitud para fusionar los cambios de una rama en otra, generalmente en la rama principal. Se utiliza sobre todo al trabajar en equipo, ya que permite que otros integrantes revisen, comenten y aprueben los cambios antes de integrarlos. Dependiendo de los permisos del repositorio, la fusión puede requerir la autorización de otros colaboradores (GitHub, n.d.-b).

No debe confundirse con el comando `git pull`, que sirve para descargar e integrar en nuestra copia local los cambios más recientes de un repositorio remoto.

### Archivo `.gitignore`

Si trabajamos con algún programa que genera archivos innecesarios (por ejemplo, archivos de compilación) o queremos mantener ciertos archivos fuera del control de versiones, usamos el archivo `.gitignore`. En él especificamos las rutas o patrones de los archivos que queremos que Git ignore (Git, n.d.-b).

### Archivo `README.md`

El archivo `README.md` funciona como la presentación de nuestro repositorio. En él podemos dar una breve explicación del proyecto, incluir la documentación completa del sistema o un conjunto de instrucciones para los demás usuarios. Su contenido depende del desarrollador, pero su propósito es compartir la información más importante sobre el proyecto (GitHub, n.d.-c).

## Flujo de Trabajo Basado en Ramas

Un flujo de trabajo basado en ramas consiste en crear múltiples líneas de desarrollo a partir de un punto común del proyecto, permitiendo que distintos equipos o personas trabajen en paralelo sin interferir entre sí (Atlassian, n.d.).

Por ejemplo, si estamos desarrollando un proyecto en equipo y ya contamos con una base funcional, es común dividir el trabajo por áreas: interfaz gráfica (GUI), base de datos, protocolos de red, lógica del programa, entre otras. En lugar de que todos trabajen directamente sobre la misma línea de código, lo que generaría conflictos constantes y saturaría el historial de versiones con los cambios de todos los equipos mezclados, cada equipo crea su propia rama a partir del sistema funcional y trabaja de forma independiente en su parte.

Cuando dos equipos necesitan integrar y probar sus avances juntos (por ejemplo, el equipo de lógica del programa y el de protocolos de red), fusionan (hacen merge) sus ramas para obtener una versión prototipo. Esta versión combinada se prueba hasta que ambos equipos consideran que su integración funciona correctamente, antes de continuar avanzando o de integrarla al resto del proyecto.

### ¿Por qué se revisa el código entre pares antes de fusionar?

Antes de fusionar una rama con otra se debe pasar por un proceso de revisión de código entre pares, en el que uno o más integrantes del equipo, distintos al autor de los cambios, leen y analizan el código antes de aprobar su integración. Normalmente esta revisión se realiza a través de un Pull Request, donde los revisores pueden dejar comentarios, sugerir modificaciones o solicitar correcciones (GitHub, n.d.-a).

Con este proceso se busca:

- Detección de errores
- Proteger la rama principal
- Calidad y consistencia del código
- Detección de conflictos de integración
- Compartir conocimiento entre ramas
- Detectar vulnerabilidades o datos sensibles






## Referencias

- Atlassian. (n.d.). *Git feature branch workflow.* Atlassian Git Tutorials. Recuperado el 16 de septiembre de 2026, de https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow
- Chacon, S., & Straub, B. (2014). *Pro Git* (2.ª ed.). Apress. Recuperado el 16 de septiembre de 2026, de https://git-scm.com/book/en/v2
- Git. (n.d.-a). *git-merge.* Git Documentation. Recuperado el 16 de septiembre de 2026, de https://git-scm.com/docs/git-merge
- Git. (n.d.-b). *gitignore.* Git Documentation. Recuperado el 16 de septiembre de 2026, de https://git-scm.com/docs/gitignore
- GitHub. (n.d.-a). *About pull request reviews.* GitHub Docs. Recuperado el 16 de septiembre de 2026, de https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews
- GitHub. (n.d.-b). *About pull requests.* GitHub Docs. Recuperado el 16 de septiembre de 2026, de https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- GitHub. (n.d.-c). *About READMEs.* GitHub Docs. Recuperado el 16 de septiembre de 2026, de https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes
- GitHub. (n.d.-d). *About repositories.* GitHub Docs. Recuperado el 16 de septiembre de 2026, de https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories
