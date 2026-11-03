                Instituto Politécnico Nacional
               Escuela Superior de Cómputo
                                    Programa académico / Plan de estudios

                                Ingeniería en Sistemas Computacionales / 2020



                                             Unidad de aprendizaje

                                                Bases de Datos


    Prácticas 4 y 5: "Implementación de una base de datos relacional y asignación de permisos

empleando DDL", "Restricciones de dominio", "Edición de valores de una
base de datos relacional empleando DML" e "Integridad referencial"

Objetivo: Que su equipo implemente las bases de datos de sus dos
proyectos con las restricciones de dominio, la integridad referencial y
los permisos que exigen sus reglas; que las pueble con datos de una
fuente citable mediante un script automatizado, y que modifique sus
datos con sentencias DML dentro de transacciones, comprobando con datos
reales que cada restricción protege la información.

Este documento reúne lo que se pide para las prácticas 4 y 5: 1.
Práctica 4. "Implementación de una base de datos relacional y asignación
de permisos empleando DDL" y "Restricciones de dominio". Corresponde a
la primera parte. 2. Práctica 5. "Edición de valores de una base de
datos relacional empleando DML" e "Integridad referencial". Corresponde
a la segunda parte.

Se trabaja con los dos proyectos de siempre, el propio y el asignado, en
el repositorio del equipo. En la Práctica 3 las tablas quedaron creadas
y vacías; aquí se protegen, se llenan y se ponen a trabajar. Tres reglas
atraviesan el documento: 1. Cada restricción se justifica con una regla
del dominio, escrita en una línea. Una restricción que nadie sabe
explicar sobra, y una regla del negocio sin restricción es un hueco. 2.
Los datos se buscan antes de inventarse. Generarlos es el último recurso
y hay que justificarlo. 3. La carga no se hace a mano: si no puede
repetirse con un solo comando, no cuenta.

Las consultas de recuperación de datos ---combinaciones, subconsultas,
agregaciones, consultas analíticas y rendimiento--- se trabajan con SQL
a fondo en el bloque de las Prácticas 9 a 12, sobre estas mismas bases
ya pobladas.

                                     Continuidad del entorno de trabajo

    1.   Cree la rama practica4-5 a partir de la rama principal del repositorio del equipo y cierre con un Pull
         Request revisado por otro integrante y fusionado.
    2.   Levante su gestor con el archivo compose.yaml y ejecute el esquema.sql de la Práctica 3 sobre una
         base de datos limpia. Levante también la base del proyecto asignado desde su fork.
    3.   Todo cambio al esquema se hace con ALTER TABLE en archivos de migración numerados —001-
         dominios.sql, 002-referencias.sql—, nunca editando la base a mano.
    4.   Cada integrante debe tener confirmaciones propias en días distintos.

Parte 1. Práctica 4: "Implementación de una base de datos relacional y
asignación de permisos empleando DDL" y "Restricciones de dominio"

El dominio de un atributo es el conjunto de valores que puede tomar.
Declararlo en el gestor con DDL es lo que impide que entre a la base una
edad negativa, un correo sin arroba o una fecha de entrega anterior a la
del pedido.

Ejercicio 1.1. Tipos de dato y dominios En dominios.md, una tabla con
cada columna de su proyecto propio: el tipo de dato que eligió, su
longitud o precisión, y por qué. Revise en particular los montos
---nunca en punto flotante---, las fechas, los identificadores y los
textos de longitud fija. Si su gestor lo permite, defina con CREATE
DOMAIN o con tipos enumerados los dominios que se repiten en varias
tablas, y explique qué gana con eso.

Ejercicio 1.2. Restricciones de columna Declare, con su regla del
dominio al lado: 1. NOT NULL en todo atributo sin el que el renglón no
tiene sentido, y en las claves foráneas cuya cardinalidad mínima es 1.
2. DEFAULT donde exista un valor inicial natural: la fecha de registro,
un estado inicial, un contador en cero. 3. UNIQUE simples y compuestas:
una CURP, un correo, la combinación de alumno, materia y periodo. 4.
CHECK de rango, de formato, de lista de valores permitidos y entre
columnas, como una fecha final que no sea anterior a la inicial. Al
menos diez restricciones CHECK o UNIQUE que respondan a reglas reales de
su dominio.

Ejercicio 1.3. La fuente de datos del proyecto propio Busque un conjunto
de datos ya publicado que sirva para su dominio: portales de datos
abiertos del gobierno federal, de la Ciudad de México o del INEGI,
organismos internacionales, repositorios académicos, interfaces de
programación públicas, o los datos del propio caso de estudio si quien
lo planteó puede compartirlos. Documente en fuente.md: 1. La referencia
en formato APA séptima edición: institución o autor, año, título del
conjunto, versión o fecha de consulta y dirección. Agregue la licencia y
qué permite hacer con los datos. 2. El formato original, el tamaño,
cuántos registros trae y qué campos tiene. 3. Una tabla de
correspondencia: cada campo del conjunto contra la tabla y la columna de
su esquema que lo recibe, incluidos los que no va a usar y por qué. 4.
Qué venía mal ---duplicados, campos vacíos, fechas en varios formatos,
acentos rotos, valores fuera de rango--- y qué decidió hacer con cada
problema. Solo si después de buscar concluye que no existe un conjunto
publicado para su caso, genere los datos con un script. Antes, escriba
dónde buscó, con qué términos y por qué concluye que no hay datos; sin
esa justificación no se acepta. Los datos generados deben respetar sus
restricciones y variar lo suficiente para que una consulta devuelva algo
interesante: al menos doscientos renglones en cada tabla principal. Deje
claro en el README que son sintéticos. Si un conjunto real trae datos
personales, anonimícelos antes de subirlos.

Ejercicio 1.4. El script de carga La base se puebla con un solo comando
documentado en el README: un archivo de órdenes, un objetivo de Makefile
o un programa en el lenguaje que eligieron en la Práctica 3.1. El script
tiene que ser: 1. Repetible: ejecutarlo dos veces no duplica renglones
ni termina en error. 2. Ordenado: primero las tablas de las que dependen
las demás. 3. Todo o nada: si un renglón falla, la carga se revierte y
el mensaje dice cuál falló y por qué. 4. Con cuentas: al terminar
informa cuántos renglones insertó y cuántos rechazó en cada tabla. 5.
Sin credenciales adentro: la conexión se arma con variables de entorno.
6. Eficiente: para volúmenes grandes use la carga masiva del gestor
---COPY, `\copy `{=tex}o LOAD DATA INFILE--- en lugar de un INSERT por
renglón, y reporte la diferencia de tiempo. Lo que rechazaron sus
restricciones. Los datos reales casi nunca respetan todas las reglas.
Registre qué renglones rechazó cada restricción y decida, caso por caso,
si el error estaba en el dato ---y se limpia antes de cargar--- o en la
restricción ---y se corrige con una migración---. Entregue la salida de
la terminal al ejecutar el script y al ejecutarlo por segunda vez.
Ejercicio 1.5. Pruebas de restricciones de dominio En
pruebas-dominio.md, diez casos que intenten violar sus restricciones:
NOT NULL, DEFAULT, UNIQUE simple y compuesta, CHECK de rango, de formato
y entre columnas. De cada uno: la operación intentada, el resultado
esperado, el mensaje que devolvió el gestor y la regla del dominio que
quedó protegida.

Ejercicio 1.6. Usuarios y permisos Una base que siempre se usa con el
usuario administrador no está protegida. Sobre el proyecto propio, y
documentado en permisos.md: 1. Cree al menos tres roles ---uno para la
aplicación, que lee y escribe solo en las tablas que necesita; uno de
consulta, que solo lee; y uno de administración--- y diga para qué
existe cada uno. 2. Otorgue los permisos con GRANT siguiendo el
principio de mínimo privilegio y cree un usuario para cada rol. Las
contraseñas van en variables de entorno, no en el repositorio. 3. Haga
que el script de carga se conecte con el rol de la aplicación, no con el
administrador. 4. Pruebe cada rol con una operación permitida y una
negada, mostrando el mensaje del gestor. Retire un permiso con REVOKE y
muestre que la operación deja de funcionar. 5. Cierre con una matriz de
permisos en Markdown: cada rol contra cada tabla, con lo que puede hacer
en ella.

Ejercicio 1.7. El proyecto asignado: sus datos y sus dominios El
artículo y el repositorio dicen de dónde salieron sus datos. Dos de los
tres proyectos tienen fuente pública y el tercero no, se deben obtener
datos de fuentes verificables:

                Proyecto asignado                            De dónde salen sus datos
         Sismos                               Catálogo público del Servicio Sismológico Nacional
         Consumo de agua en la Ciudad de
                                              Datos abiertos de la Ciudad de México y de SACMEX
         México
                                              Actualmente no hay conjunto publicado: aquí sí se
         Obra pública municipal               generan los datos. Consultar con el docente, para verificar
                                              si ya se tienen los datos o aún no.

    1.    Cargue el conjunto en la base de su fork con un script que cumpla los requisitos del ejercicio 1.4. Si le
          tocó obra pública municipal, genere los datos respetando el esquema del almacén y lo que describe el
          artículo.
    2.    Compare lo que obtuvo con lo que reporta el artículo. Si sus números no se parecen, explique por qué:
          el periodo de los datos, el recorte que consiguió o un problema en la carga.
    3.    Revise las restricciones de dominio que declara su esquema y las que le faltan. Proponga tres que
          agregaría y pruébelas en una copia: ¿los datos reales las cumplen?

Parte 2. Práctica 5: "Edición de valores de una base de datos relacional
empleando DML" e "Integridad referencial"

La integridad referencial garantiza que toda clave foránea apunte a un
renglón que existe; las sentencias DML son las que la ponen a prueba,
porque cada INSERT, UPDATE o DELETE puede romperla. Por eso esta parte
las trabaja juntas.

Ejercicio 2.1. Las claves foráneas del proyecto propio En
referencias.md, una tabla con cada clave foránea: qué relación del
modelo EER implementa, qué tabla y columna referencia, y si admite nulos
según la cardinalidad mínima de la relación. Si alguna relación del
modelo no quedó como clave foránea, explique por qué o agréguela con una
migración. Ejercicio 2.2. Acciones referenciales Para cada clave
foránea, elija qué ocurre al borrar o al actualizar el renglón
referenciado, y justifíquelo con una regla del dominio:

            Acción referencial                                 Cuándo corresponde
                                         El hijo no tiene sentido sin el padre: entidad débil, tabla de una
       ON DELETE CASCADE
                                         relación muchos a muchos
       ON DELETE RESTRICT                El padre no debe desaparecer mientras algo dependa de él
       ON DELETE SET NULL                La relación es opcional: el hijo sobrevive sin padre
       ON DELETE SET DEFAULT             El hijo pasa a un valor por omisión que sí existe
       ON UPDATE CASCADE                 La clave del padre puede cambiar y los hijos deben seguirla

Ejercicio 2.3. Pruebas de integridad referencial 1. Una prueba por cada
acción que usó, con datos reales: cuántos renglones había en cada tabla
antes, la sentencia DML, y cuántos quedaron después. 2. Un INSERT con
una clave foránea que no existe, y el mensaje con que el gestor lo
rechaza. 3. El orden de carga: muestre qué ocurre si su script intenta
cargar las tablas hijas antes que las padres, y cómo lo resuelve. 4. Las
comprobaciones que deben salir vacías sobre las dos bases: claves
foráneas huérfanas, duplicados en columnas únicas y nulos en columnas
que no los admiten.

Ejercicio 2.4. Edición de valores y transacciones Sobre el proyecto
propio, siempre a partir de una situación real de su dominio: 1. Un
INSERT que tome sus valores de una consulta, y una inserción que
resuelva el caso de que el renglón ya exista. 2. Un UPDATE que dependa
de otra tabla y otro que clasifique con CASE. 3. Un DELETE con
subconsulta y un borrado lógico. Explique cuándo conviene cada uno y qué
se pierde al borrar de verdad, considerando las acciones referenciales
del ejercicio 2.2. 4. Una transacción que toque dos o más tablas y deba
quedar entera o no quedar, con un punto de recuperación, una reversión
parcial y la confirmación final. 5. Una transacción que falle a la mitad
por violar una restricción: el mensaje del gestor y la comprobación de
que la base quedó como estaba.

Ejercicio 2.5. Integridad referencial en el almacén asignado 1.
Identifique la tabla de hechos, las dimensiones y la granularidad: qué
representa exactamente un renglón de hechos. 2. Revise si el esquema
declara las claves foráneas entre hechos y dimensiones, y busque con
consultas hechos que apunten a dimensiones que no existen. 3. Si las
claves no están declaradas, agréguelas en una copia y vea si los datos
las cumplen. Explique por qué un almacén a veces las omite a propósito y
qué riesgo corre al hacerlo.

Ejercicio 2.6. Trabajo por integrante Individual, en un archivo firmado
con su nombre. Cada integrante elige una relación distinta del proyecto
propio, cambia su acción referencial en una copia de la base ---por
ejemplo, de RESTRICT a CASCADE--- y muestra con datos qué cambia al
borrar un renglón padre: qué se pierde, qué se conserva y cuál de las
dos opciones es la correcta para su dominio. Se preguntará en clase. 
Entregable

Todo va en el repositorio del equipo, escrito en Markdown, con las
sentencias en bloques de código y también en archivos .sql que puedan
ejecutarse. El README se mantiene al día. Estructura sugerida:
practica4/ dominios.md fuente.md pruebas-dominio.md permisos.md
migraciones/ datos/ (los archivos crudos, si el tamaño lo permite)
poblar/ poblar.sh (o Makefile, o el programa equivalente)
proyecto-asignado/ practica5/ referencias.md pruebas-referenciales.md
edicion-de-valores.md integridad-almacen.md integrantes/ sql/
evidencias/

                                            Fecha de entrega

La fecha límite para la entrega de las dos prácticas es el jueves 5 de
noviembre de 2026. Se tomará como hora de entrega la de la última
confirmación en la rama principal del repositorio del equipo. 
