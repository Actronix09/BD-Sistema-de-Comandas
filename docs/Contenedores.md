# Contenedores en Docker

---

## Tabla de Contenidos

- [Diferencias entre contenedor y maquina virtual](#diferencias-entre-contenedor-y-maquina-virtual)
- [Imagen](#imagen)
- [Contenedor](#contenedor)
- [Volumen](#volumen)
- [Respecto a un volumen](#respecto-a-un-volumen)
- [Puerto publicado](#puerto-publicado)
- [Respecto a un volumen](#respecto-a-un-volumen)
- [Referencias](#referencias)

---

Los contenedores son "recipientes" donde hay una o multiples instacias instaladas, en estos contenedores nos permiten compartir proyectos entre equipos evitando la incompatibilidad de sistemas, ya que los contenedores ya tienen las configuraciones necesarias para cada proyecto y estas pueden ser compartidas entre usuarios.

## Diferencias entre contenedor y maquina virtual

|Caracteristica|Maquina Virtual|Contenedor|
|---|:---:|:---:|
|Velocidad de Arranque|$~30s-2m$|$~50ms-2s$|
|Tamaño|$1GB-20+ GB$|$~5MB-200MB$|
|Tipo de Aislamiento|A nivel de hardware|A nivel de sistema operativo|
|Comparte kernel con el host|✘|✔|
|Bajo consumo de recursos|✘|✔|
|Portabilidad entre entornos|✘|✔|
|Seguridad por separación total del hardware|✔|✘|
|Puede correr distintos SO en el host|✔|✘|
|Escalable|✘|✔|

## Imagen

Una imagen es una plantilla de solo lectura con instrucciones para crear un contenedor Docker. Suele partir de otra imagen base a la que se le agregan personalizaciones, y se construye mediante un Dockerfile (Docker, n.d.-b).

## Contenedor

Es un proceso aislado para cada componente de una aplicación, ejecutado a partir de una imagen. Es una instancia ejecutable de una imagen, definida tanto por la imagen como por las opciones de configuración que se le indiquen al crearlo o iniciarlo (Docker, n.d.-a).

## Volumen

Mecanismo de almacenamiento gestionado por Docker que vive fuera del ciclo de vida del contenedor, usado para persistir datos (bases de datos, archivos de usuario, etc.) que deben sobrevivir aunque el contenedor se elimine o recree (Docker, n.d.-c).

## Respecto a un volumen

### ¿Por qué es indispensable?

Cuando un contenedor se ejecuta, Docker agrega sobre las capas de solo lectura de la imagen una capa de escritura propia del contenedor. Todo lo que el proceso escriba en el sistema de archivos del contenedor queda en esa capa, y esa capa se elimina junto con el contenedor (Docker, n.d.-f). Por eso, sin un volumen, un gestor de bases de datos como PostgreSQL estaría guardando sus archivos en un medio efímero. El volumen resulta indispensable por cuatro motivos:

- **Persistencia independiente del ciclo de vida del contenedor.** El volumen lo administra el daemon de Docker y existe fuera del contenedor, de modo que los datos sobreviven a `docker rm`, a `docker compose down` o a la recreación del servicio (Docker, n.d.-c; Docker, n.d.-e). En el archivo `entorno/compose.yml` de esta práctica, el volumen `pgdata` montado en `/var/lib/postgresql/data` cumple precisamente esa función.
- **Actualización de la imagen sin pérdida de información.** Al no estar el dato dentro del contenedor, se puede cambiar la versión de la imagen (por ejemplo, de `postgres:16.4-alpine` a una versión posterior) y levantar de nuevo el servicio conservando la base. Esta separación entre la aplicación y sus datos es la recomendación explícita para entornos de contenedores: los datos deben almacenarse fuera de los contenedores, en almacenes persistentes, para que sigan disponibles cuando la nueva versión reemplace a los contenedores existentes (Souppaya et al., 2017).
- **Rendimiento en cargas con escritura intensiva.** Escribir en la capa del contenedor implica el sobrecosto del controlador de almacenamiento y de la estrategia de copia en escritura (*copy-on-write*); la propia documentación señala que las aplicaciones con escritura intensiva, como el almacenamiento de una base de datos, se ven afectadas por ese sobrecosto y recomienda usar volúmenes para ese tipo de datos (Docker, n.d.-h).
- **Operación: respaldo, restauración y uso compartido.** El volumen tiene su propio ciclo de vida y puede listarse, inspeccionarse, respaldarse o montarse en varios contenedores a la vez, lo que permite tareas como copias de seguridad o agregación de datos sin depender del contenedor que los generó (Docker, n.d.-c).

### ¿Qué ocurre si no se declara?

El efecto depende de si la imagen declara por su cuenta un punto de montaje con la instrucción `VOLUME` del Dockerfile, la cual marca esa ruta como contenedora de volúmenes montados externamente (Docker, n.d.-g).

- **Si la imagen no declara `VOLUME`:** los datos se escriben en la capa de escritura del contenedor y se pierden en cuanto el contenedor se elimina o se recrea (Docker, n.d.-f). En un servicio de base de datos esto significa empezar con una base vacía después de cada `docker compose down`.
- **Si la imagen sí declara `VOLUME` (caso de PostgreSQL):** la imagen oficial de PostgreSQL incluye la instrucción `VOLUME /var/lib/postgresql/data` (Docker Official Images, 2026), por lo que Docker crea automáticamente un **volumen anónimo**, es decir, un volumen con un nombre aleatorio asignado por el motor. Los datos no se pierden de inmediato, pero el manejo se vuelve problemático:
  - Los volúmenes anónimos no se reutilizan ni se comparten automáticamente entre contenedores: cada contenedor nuevo crea el suyo (Docker, n.d.-c). Compose lo advierte de forma directa: al no tener un nombre estable, un volumen anónimo no se vuelve a montar en un `up` posterior, y para datos que deben persistir entre actualizaciones se deben usar montajes por ruta explícita o volúmenes con nombre (Docker, n.d.-i).
  - En la práctica, cada `docker compose down` seguido de `docker compose up` arrancaría con una base vacía (PostgreSQL vuelve a inicializar el directorio de datos), mientras que el contenido anterior queda huérfano ocupando espacio en disco.
  - Ese volumen huérfano es difícil de identificar por su nombre aleatorio y desaparece con una limpieza rutinaria como `docker volume prune`; además, si el contenedor se ejecutó con la opción `--rm`, el volumen anónimo asociado se destruye al terminar el contenedor (Docker, n.d.-c).

Declarar el volumen con nombre, como se hace en esta práctica, es entonces lo que convierte la persistencia en un comportamiento explícito, predecible y reproducible. Como contraparte, conviene tener presente que `docker compose down -v` sí elimina los volúmenes con nombre declarados en la sección `volumes` del archivo Compose, por lo que esa bandera debe usarse solo cuando se desea descartar los datos (Docker, n.d.-i).

## Puerto publicado

Al lanzar un contenedor se puede exponer uno de sus puertos hacia la máquina host, creando un mapeo (por ejemplo -p 8080:80) que permite acceder desde fuera del contenedor a un servicio que corre dentro de él (Docker, n.d.-d).

## Respecto a un volumen

### ¿Por qué es indispensable?

Cuando un contenedor se ejecuta, Docker agrega sobre las capas de solo lectura de la imagen una capa de escritura propia del contenedor. Todo lo que el proceso escriba en el sistema de archivos del contenedor queda en esa capa, y esa capa se elimina junto con el contenedor (Docker, n.d.-f). Por eso, sin un volumen, un gestor de bases de datos como PostgreSQL estaría guardando sus archivos en un medio efímero. El volumen resulta indispensable por cuatro motivos:

- **Persistencia independiente del ciclo de vida del contenedor.** El volumen lo administra el daemon de Docker y existe fuera del contenedor, de modo que los datos sobreviven a `docker rm`, a `docker compose down` o a la recreación del servicio (Docker, n.d.-c; Docker, n.d.-e). En el archivo `entorno/compose.yml` de esta práctica, el volumen `pgdata` montado en `/var/lib/postgresql/data` cumple precisamente esa función.
- **Actualización de la imagen sin pérdida de información.** Al no estar el dato dentro del contenedor, se puede cambiar la versión de la imagen (por ejemplo, de `postgres:16.4-alpine` a una versión posterior) y levantar de nuevo el servicio conservando la base. Esta separación entre la aplicación y sus datos es la recomendación explícita para entornos de contenedores: los datos deben almacenarse fuera de los contenedores, en almacenes persistentes, para que sigan disponibles cuando la nueva versión reemplace a los contenedores existentes (Souppaya et al., 2017).
- **Rendimiento en cargas con escritura intensiva.** Escribir en la capa del contenedor implica el sobrecosto del controlador de almacenamiento y de la estrategia de copia en escritura (*copy-on-write*); la propia documentación señala que las aplicaciones con escritura intensiva, como el almacenamiento de una base de datos, se ven afectadas por ese sobrecosto y recomienda usar volúmenes para ese tipo de datos (Docker, n.d.-h).
- **Operación: respaldo, restauración y uso compartido.** El volumen tiene su propio ciclo de vida y puede listarse, inspeccionarse, respaldarse o montarse en varios contenedores a la vez, lo que permite tareas como copias de seguridad o agregación de datos sin depender del contenedor que los generó (Docker, n.d.-c).

### ¿Qué ocurre si no se declara?

El efecto depende de si la imagen declara por su cuenta un punto de montaje con la instrucción `VOLUME` del Dockerfile, la cual marca esa ruta como contenedora de volúmenes montados externamente (Docker, n.d.-g).

- **Si la imagen no declara `VOLUME`:** los datos se escriben en la capa de escritura del contenedor y se pierden en cuanto el contenedor se elimina o se recrea (Docker, n.d.-f). En un servicio de base de datos esto significa empezar con una base vacía después de cada `docker compose down`.
- **Si la imagen sí declara `VOLUME` (caso de PostgreSQL):** la imagen oficial de PostgreSQL incluye la instrucción `VOLUME /var/lib/postgresql/data` (Docker Official Images, 2026), por lo que Docker crea automáticamente un **volumen anónimo**, es decir, un volumen con un nombre aleatorio asignado por el motor. Los datos no se pierden de inmediato, pero el manejo se vuelve problemático:
  - Los volúmenes anónimos no se reutilizan ni se comparten automáticamente entre contenedores: cada contenedor nuevo crea el suyo (Docker, n.d.-c). Compose lo advierte de forma directa: al no tener un nombre estable, un volumen anónimo no se vuelve a montar en un `up` posterior, y para datos que deben persistir entre actualizaciones se deben usar montajes por ruta explícita o volúmenes con nombre (Docker, n.d.-i).
  - En la práctica, cada `docker compose down` seguido de `docker compose up` arrancaría con una base vacía (PostgreSQL vuelve a inicializar el directorio de datos), mientras que el contenido anterior queda huérfano ocupando espacio en disco.
  - Ese volumen huérfano es difícil de identificar por su nombre aleatorio y desaparece con una limpieza rutinaria como `docker volume prune`; además, si el contenedor se ejecutó con la opción `--rm`, el volumen anónimo asociado se destruye al terminar el contenedor (Docker, n.d.-c).

Declarar el volumen con nombre, como se hace en esta práctica, es entonces lo que convierte la persistencia en un comportamiento explícito, predecible y reproducible. Como contraparte, conviene tener presente que `docker compose down -v` sí elimina los volúmenes con nombre declarados en la sección `volumes` del archivo Compose, por lo que esa bandera debe usarse solo cuando se desea descartar los datos (Docker, n.d.-i).

## Referencias

- Docker. (n.d.-a). *What is a container?* Docker Docs. Recuperado el 16 de septiembre de 2026, de https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/
- Docker. (n.d.-b). *Docker overview.* Docker Docs. Recuperado el 16 de septiembre de 2026, de https://docs.docker.com/get-started/overview/
- Docker. (n.d.-c). *Volumes.* Docker Docs. Recuperado el 16 de septiembre de 2026, de https://docs.docker.com/engine/storage/volumes/
- Docker. (n.d.-d). *Publishing and exposing ports.* Docker Docs. Recuperado el 16 de septiembre de 2026, de https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/
- Docker. (n.d.-e). *Persisting container data.* Docker Docs. Recuperado el 17 de septiembre de 2026, de https://docs.docker.com/get-started/docker-concepts/running-containers/persisting-container-data/
- Docker. (n.d.-f). *Storage.* Docker Docs. Recuperado el 17 de septiembre de 2026, de https://docs.docker.com/engine/storage/
- Docker. (n.d.-g). *Dockerfile reference.* Docker Docs. Recuperado el 17 de septiembre de 2026, de https://docs.docker.com/reference/dockerfile/
- Docker. (n.d.-h). *Storage drivers.* Docker Docs. Recuperado el 17 de septiembre de 2026, de https://docs.docker.com/engine/storage/drivers/
- Docker. (n.d.-i). *docker compose down.* Docker Docs. Recuperado el 17 de septiembre de 2026, de https://docs.docker.com/reference/cli/docker/compose/down/
- Docker Official Images. (2026). *postgres/16/bookworm/Dockerfile* [Código fuente]. GitHub. Recuperado el 17 de septiembre de 2026, de https://github.com/docker-library/postgres/blob/master/16/bookworm/Dockerfile
- Souppaya, M., Morello, J., & Scarfone, K. (2017). *Application container security guide* (NIST Special Publication 800-190). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-190
