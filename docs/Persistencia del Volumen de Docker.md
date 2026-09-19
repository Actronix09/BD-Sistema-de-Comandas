# Persistencia del Volumen de un Contenedor de Docker

---

## Tabla de Contenidos

- [Configuración del entorno](#configuración-del-entorno)
- [Creación del contenedor y la base de datos](#creación-del-contenedor-y-la-base-de-datos)
- [Eliminación del contenedor](#eliminación-del-contenedor)
- [Verificación de la persistencia](#verificación-de-la-persistencia)
- [Anexos](#anexos)

---

## Configuración del entorno

El servicio se define en el archivo [compose.yml](<../entorno/Configuracion Adrian/compose.yml>). La declaración relevante para esta práctica es el volumen nombrado, montado sobre el directorio donde PostgreSQL guarda su cluster de datos:

```yaml
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
    name: practica1-pgdata
```

Todo lo que se escriba dentro de `/var/lib/postgresql/data` queda, en realidad, en el volumen `practica1-pgdata`, que vive fuera del contenedor.

## Creación del contenedor y la base de datos

Se levanta el contenedor en segundo plano y se verifica su estado:

```bash
docker compose up -d
docker compose ps
```

Se accede a la terminal del contenedor y, desde ella, al cliente interactivo de PostgreSQL:

```bash
docker compose exec db bash
psql -U pg-practica1 -d pg-practica1
```

Ya en `psql`, se listan las bases existentes, se crea una nueva y se vuelve a listar para confirmar su creación:

```sql
\l
CREATE DATABASE practica1;
\l
```

Finalmente se cierra la sesión de `psql` y la terminal del contenedor:

```
\q
exit
```

![Salida de la terminal mostrando la creación del contenedor y de la base de datos practica1](<../evidencias/docker/Evidencias Adrian/Creación Contenedor y Base de Datos.png>)

## Eliminación del contenedor

Se elimina el contenedor y se comprueba que el volumen permanece:

```bash
docker compose down
docker volume ls
```

El comando `docker compose down` detiene y elimina los contenedores y la red del proyecto, pero **no** elimina los volúmenes nombrados: para ello es necesario añadir la bandera `-v` de forma explícita (Docker, n.d.-a). Por eso, tras su ejecución, el volumen `practica1-pgdata` sigue apareciendo en el listado aunque el contenedor ya no exista.

![Salida de la terminal mostrando la eliminación del contenedor y el volumen practica1-pgdata aún presente](<../evidencias/docker/Evidencias Adrian/Eliminación Contenedor.png>)

## Verificación de la persistencia

Se crea un contenedor nuevo a partir de la misma imagen y se consulta de nuevo el listado de bases de datos:

```bash
docker compose up -d
docker compose exec db bash
psql -U pg-practica1 -d pg-practica1
\l
\q
exit
```

La base de datos `practica1`, creada en el contenedor anterior, aparece en el listado del contenedor nuevo. Cabe señalar que este contenedor es distinto del original —tiene otro identificador— y que los scripts de inicialización de la imagen no se ejecutaron, precisamente porque el volumen ya contenía un cluster inicializado.

![Salida de la terminal mostrando que la base de datos practica1 sigue existiendo en el contenedor nuevo](<../evidencias/docker/Evidencias Adrian/Persistencia Volumen.png>)

## Anexos

**Entorno Angel Gabriel Perez Angeles**

- [compose.yml](../entorno/Configuracion%20Angel/compose.yml)

**Evidencias Angel Gabriel Perez Angeles**

![](../evidencias/docker/Evidencias%20Angel/Evidencia%201%20-%20Configuracion%20de%20entorno.png)
![](../evidencias/docker/Evidencias%20Angel/Evidencia%202%20-%20Levantamiento%20y%20verificacion%20del%20contenedor.png)
![](../evidencias/docker/Evidencias%20Angel/Evidencia%203%20-%20Creacion%20de%20base%20de%20datos%20en%20el%20contenedor.png)
![](../evidencias/docker/Evidencias%20Angel/Evidencia%203.5%20-%20Se%20detiene%20el%20contenedor.png)
![](../evidencias/docker/Evidencias%20Angel/Evidencia%204%20-%20Persistencia%20de%20la%20base%20de%20datos.png)