# Propuesta de Mejora

En el siguiente documento se presenta propuestas de mejora sobre el proyecto asignado.

---

## Propuesta 1 — Trazabilidad de la propuesta ciudadana a la obra

**Problema que atiende.** El sistema permite que los pobladores registren propuestas de obra y que la comunidad vote por ellas, pero una vez que una propuesta gana y el municipio la construye, no queda registrado en ningún lado que esa obra salió de esa propuesta. La tabla `propuestas_obras` no tiene ninguna columna que apunte a `obra`, entonces la participación ciudadana se queda como un buzón de sugerencias del que nadie puede comprobar el resultado.

**Cómo se usaría.** Un poblador entra al visor, abre la propuesta que votó el año pasado y ve el estado de la obra que se construyó a partir de ella, con su avance y sus fotos. Del lado del municipio, el director puede sacar un reporte de cuántas de las obras del año nacieron de una petición ciudadana y cuántas no, que es justamente el indicador que justifica tener un módulo de participación.

**Cambios en el modelo de datos.** La relación *Da origen a* entre PROPUESTA DE OBRA y OBRA ya está dibujada en el modelo de la Parte 5 con cardinalidad (0,1):(0,1) y marcada como ausente del esquema publicado, entonces esta propuesta consiste en materializarla: agregar `id_obra` como llave foránea opcional en `propuestas_obras`, con restricción `UNIQUE` para que una obra no pueda atribuirse a dos propuestas distintas. De paso conviene cambiar `propuestas_obras.region` de texto libre a llave foránea hacia `region`, porque hoy las propuestas y las obras no se pueden agrupar por el mismo criterio territorial.

**En qué se apoya.** En un hallazgo del equipo al revisar el esquema operativo del repositorio, no en el artículo. Es una relación que el dominio tiene y que las dos versiones del esquema perdieron.

**Dificultad: baja.** Es una llave foránea opcional sobre una tabla que ya existe y no obliga a migrar datos previos, porque las propuestas viejas simplemente quedan con el campo en nulo.

---

## Propuesta 2 — Criterio de sobreprecio comparado por tipo de obra

**Problema que atiende.** El sistema marca una obra como sospechosa cuando su costo se aleja mucho del promedio, pero compara contra el promedio general de todas las obras del municipio. Como en Temascaltepec conviven obras muy distintas, un camino rural con una red de drenaje y una remodelación pequeña, el promedio general no significa gran cosa, entonces las obras pequeñas con sobreprecio pasan desapercibidas porque siguen estando muy por debajo de ese promedio.

**Cómo se usaría.** El director abre el panel de alertas y ve el sobreprecio expresado contra obras comparables en lugar de contra todas, por ejemplo "esta obra está 40% arriba del promedio de pavimentaciones de su tamaño", lo cual es un dato que sí se puede llevar a una reunión. También puede filtrar las alertas por tipo de obra para revisar un rubro a la vez.

**Cambios en el modelo de datos.** Hace falta una entidad nueva **TIPO DE OBRA** con sus atributos de clave, nombre y descripción, relacionada con OBRA mediante una relación *Se clasifica como* con cardinalidad (1,1) del lado de la obra y (0,N) del lado del tipo, porque toda obra tiene exactamente un tipo y un tipo agrupa muchas obras. Hoy `obra` solo tiene `etapa` y `estado`, que describen en qué momento va, no qué clase de obra es. Sobre esa entidad se puede además guardar el rango de costo esperado por unidad, que es lo que vuelve comparable el cálculo.

**En qué se apoya.** En una limitación que los propios autores declaran: reconocen que el criterio de sobreprecio compara contra un promedio general y que por eso les cuesta detectar sobreprecios en obras pequeñas, y plantean como trabajo futuro ajustarlo para que compare por tipo de obra.

**Dificultad: media.** La entidad y la relación son sencillas, pero hay que clasificar las obras que ya están cargadas y recalibrar las tres reglas de detección con el nuevo criterio.

---

## Propuesta 3 — Verificación del avance físico contra la evidencia fotográfica

**Problema que atiende.** El porcentaje de avance físico lo captura a mano el mismo supervisor que levanta el informe, y el sistema lo da por bueno sin contrastarlo con nada. Como una de las tres reglas de alerta compara el avance financiero contra el físico, basta con que alguien infle el avance físico para que la obra deje de aparecer como sospechosa, entonces el control depende de la honestidad de quien captura.

**Cómo se usaría.** Al subir las fotos del mes, el sistema propone un avance físico estimado a partir de ellas y lo muestra junto al que capturó el supervisor. Si los dos números se separan más de cierto margen, el informe queda marcado para revisión y le aparece al director en el panel de alertas, sin bloquear la captura. El supervisor puede sostener su número, pero tiene que escribir por qué.

**Cambios en el modelo de datos.** Se agregan a EVIDENCIA FOTOGRÁFICA los atributos `avance_estimado` y `fecha_de_proceso`, para guardar el resultado de analizar cada imagen. Sobre INFORME DE AVANCE se agregan `avance_estimado_consolidado`, `discrepancia` *que es derivado, la diferencia contra el avance declarado* y `estado_de_verificacion`. Y entra una entidad débil nueva, **REVISIÓN DE DISCREPANCIA**, dependiente del informe por identificación, con el personal que la atendió, la fecha y la justificación escrita, que es lo que deja el rastro de quién validó un número que no cuadraba.

**En qué se apoya.** En trabajo futuro declarado por los autores, que plantean validar el avance físico de las obras con visión por computadora sobre las fotos subidas. La propuesta no se queda en eso sino que define dónde vive el resultado y qué pasa cuando los dos números no coinciden, que es la parte que el artículo no desarrolla.

**Dificultad: alta.** El cambio en el modelo es acotado, pero depende de un componente de visión por computadora que hay que entrenar y afinar para obra civil, y de definir el margen de tolerancia junto con el municipio para que las alertas no se vuelvan ruido.



