# Análisis, Desarrollo e Implementación del Modelo Entidad-Relación Extendido para el Sistema de Comandas

En este documento se encuentra documentado el proceso para el desarrollo del modelo entidad-relación extendido de nuestro proyecto trabajando a partir del modelo entidad-relación de la práctica 1.

---

## Tabla de Contenidos

- [El problema](#el-problema)
- [Reconsideración de requisitos](#reconsideración-de-requisitos)
  - [Notación](#notación)
  - [Entidades y atributos](#entidades-y-atributos)
- [Relaciones](#relaciones)
  - [Por qué *Acuerda* es ternaria y *Prepara* no](#por-qué-acuerda-es-ternaria-y-prepara-no)
  - [Atributos de relación](#atributos-de-relación)
- [Restricciones](#restricciones)
  - [Cardinalidades y su regla de negocio](#cardinalidades-y-su-regla-de-negocio)
  - [Entidades débiles y de qué dependen](#entidades-débiles-y-de-qué-dependen)
  - [Jerarquía de Usuario](#jerarquía-de-usuario)
  - [Lo que el diagrama no puede mostrar](#lo-que-el-diagrama-no-puede-mostrar)
- [Conceptos del modelo extendido que el caso no necesita](#conceptos-del-modelo-extendido-que-el-caso-no-necesita)
- [Modelo en notación de Peter Chen](#modelo-en-notación-de-peter-chen)
- [Justificación](#justificación)
  - [Por qué las entidades débiles no pueden existir solas](#por-qué-las-entidades-débiles-no-pueden-existir-solas)
  - [Por qué se eligió esa especialización](#por-qué-se-eligió-esa-especialización)
  - [Cómo reflejan las cardinalidades las reglas del negocio](#cómo-reflejan-las-cardinalidades-las-reglas-del-negocio)
  - [Tres consultas que este modelo responde y uno sin extensiones no](#tres-consultas-que-este-modelo-responde-y-uno-sin-extensiones-no)

---

**Cliente:** Salón de eventos — sistema de comandas

**Contenido:** Requisitos ampliados del caso, entidades y atributos revisados, tabla de relaciones con cardinalidades `(mín,máx)`, entidades débiles, jerarquía de Usuario y restricciones del modelo.

---

## El problema

Un salón de eventos lleva sus comandas en papel. Los meseros levantan los pedidos y los entregan al responsable en caja, que los reenvía a cocina o a bar. Se atiende un evento a la vez, con alrededor de 20 mesas, 2 o 3 cuentas por mesa y de 1 a 3 pedidos por cuenta. Se manejan anticipos, paquetes contratados y consumo extra a la carta. La entrevista completa está en [Entrevista con el Cliente](<Entrevista.md>).

El problema del negocio es el mismo de la Práctica 1: digitalizar el flujo de comandas, cuentas y cobros del salón. Lo que cambia en esta práctica son las herramientas del modelo. El E-R básico obligaba a aplanar o a dejar fuera varias reglas que el cliente sí mencionó en la entrevista, y el modelo extendido permite expresarlas:

| Regla del negocio | Cómo quedaba en el E-R básico | Cómo queda en el EER |
| :-- | :-- | :-- |
| Los números de mesa y los folios de cuenta se reinician en cada evento | Mesa y Cuenta con clave propia, como si existieran por su cuenta | Entidades débiles con dependencia de identificación |
| Mesero, cocina/bar y cajero guardan datos distintos y hacen cosas distintas | Un solo atributo `Rol` dentro de Usuario | Jerarquía de especialización, con atributos y relaciones propias por subtipo |
| Ninguna mesa se queda sin mesero, pero un mesero puede no traer mesas | Solo `1:N`, sin decir qué es obligatorio | Cardinalidades con mínimo y máximo `(mín,máx)` |
| Lo acordado de cada producto cambia de un evento a otro, aunque sea el mismo paquete | Solo se podía decir qué trae el paquete en general | Relación ternaria *Acuerda*, con `Cantidad acordada` |
| Un evento puede tener varios organizadores; un producto, varios ingredientes | Un solo valor por campo | Atributos multivaluados |
| La fecha y la hora se consultan por día, mes y año por separado | Campos sueltos | Atributos compuestos |

El modelo del que se parte es el de la práctica anterior:

![Diagrama Entidad-Relación de la Práctica 1](<../modelo/diagrama-er.png>)

---

## Reconsideración de requisitos

### Notación

En el diagrama cada marca se dibuja con un color distinto. Aquí se expresa con una etiqueta entre paréntesis después del nombre del atributo o de la entidad:

| Etiqueta | Significado | Color en el diagrama |
| :-- | :-- | :-- |
| `(entidad débil)` | Entidad débil | Azul |
| `(PK)` | Clave primaria | Morado |
| `(AK)` | Clave alternativa | Naranja |
| `(clave parcial)` | Clave parcial | Rojo |
| `(derivado)` | Atributo derivado | Rosa |
| `(multivaluado)` | Atributo multivaluado | Amarillo |
| `(opcional)` | Atributo opcional | Verde |
| `(identificadora)` | Relación identificadora | Cian |

### Entidades y atributos

- **Evento:**
  - Número de evento `(PK)`
  - Organizador/cliente `(multivaluado)`
  - Fecha
    - Día
    - Mes
    - Año
  - Tipo de evento
  - Número de asistentes
  - Número de mesas `(derivado)`
  - Estado del evento
- **Mesa:** `(entidad débil)`
  - Número de mesa `(clave parcial)`
- **Cuenta:** `(entidad débil)`
  - Secuencial `(clave parcial)`
  - Folio ([#Evento]-[#Mesa]-[#Secuencial]) `(derivado)`
  - Estado (abierta/cerrada)
  - Total acumulado `(derivado)`
- **Usuario:**
  - ID `(PK)`
  - Nombre
  - Usuario `(AK)`
  - Fecha de nacimiento
    - Día
    - Mes
    - Año
  - Edad `(derivado)`
  - Contraseña
  - **Mesero:**
    - Propinas acumuladas `(derivado)`
    - Turno asignado
  - **Bar/Cocina:**
    - Estado (ocupado/desocupado)
    - Estación asignada
  - **Cajero/Administrador:**
    - Nivel de acceso
    - Caja asignada
- **Producto:**
  - ID `(PK)`
  - Nombre
  - Categoría
  - Precio
  - Ingredientes `(multivaluado)`
- **Comanda:**
  - ID `(PK)`
  - Time Stamp
    - Día
    - Mes
    - Año
    - Hora
  - Precio cobrado
  - Estado
  - Detalles `(opcional)`
  - Precio `(derivado)`
- **Pago:**
  - Número de pago `(PK)`
  - Monto
  - Forma de pago
  - Time Stamp
    - Día
    - Mes
    - Año
    - Hora
- **Anticipo:**
  - ID `(PK)`
  - Monto
  - Fecha
    - Día
    - Mes
    - Año
- **Paquete:**
  - Número de paquete `(PK)`
  - Monto
  - Detalles

---

## Relaciones

| Relación | Acción | Descripción | Cardinalidad |
| :-- | :-- | :-- | :-- |
| **Mesa - Mesero** | *Atiende* | Un mesero atiende una o varias mesas; una mesa es atendida por un mesero. | (1,1):(0,N) |
| **Mesa - Cuenta** | *Tiene* | Una mesa puede tener varias cuentas (grupos de invitados). Esta relación solo dice en qué mesa se abrió la cuenta; quien le da identidad a la cuenta es el evento, no la mesa. | (0,N):(1,1) |
| **Cuenta - Comanda** | *Genera* | Una cuenta genera varias comandas (rondas) durante el evento. | (0,N):(1,1) |
| **Mesero - Comanda** | *Levanta* | Un mesero levanta varias comandas; cada comanda la levanta un solo mesero. | (0,N):(1,1) |
| **Comanda - Producto** | *Referencia* | Cada comanda hace referencia a un producto. | (1,1):(1,N) |
| **Cuenta - Pago** | *Recibe* | Una cuenta puede recibir uno o varios pagos. | (0,N):(1,1) |
| **Evento - Anticipo** | *Recibe* | Un evento puede tener uno o varios anticipos. | (0,N):(1,1) |
| **Paquete - Producto** | *Incluye* | Contenido base del paquete en el catálogo: qué productos trae en general, sin cantidades. Un paquete incluye uno o varios productos, y un producto puede estar en varios paquetes. No es una lista cerrada: lo que de verdad se pacta en cada evento va en la ternaria *Acuerda*, que puede agregar productos o cambiar cantidades. | (1,N):(0,N) |
| **Producto - Producto** | *Variante* | Un producto principal puede o no tener una o más variantes; una variante no puede tener más variantes ni tampoco tener más de un producto principal. | (0,N):(0,1)<br>Principal / Variante |
| **Cajero / Administrador - Pago** | *Maneja* | Un cajero maneja múltiples pagos; un pago solo es manejado por un cajero. | (0,N):(1,1) |
| **Mesero - Pago** | *Recibe Propina* | Un mesero recibe una propina a partir de un pago, un mesero puede recibir múltiples propinas. | (0,N):(0,1) |
| **Cocina / Bar - Comanda** | *Prepara* | El bar o la cocina prepara lo que pide una comanda. Una estación prepara de cero a muchas comandas; una comanda la prepara una sola estación, o ninguna si todavía está pendiente o se canceló. El producto no entra en la relación porque la comanda ya apunta a uno solo. | (0,N):(0,1) |
| **Evento - Paquete - Producto** | *Acuerda* | Cuánto se acordó de cada producto, de cada paquete, para un evento concreto. Es lo que permite comparar después el consumo real contra lo presupuestado. Un evento puede acordar productos de varios paquetes, y el mismo producto puede venir de dos paquetes distintos con cantidades distintas. | Evento (0,N)<br>Paquete (0,N)<br>Producto (0,N) |
| **Cajero / Administrador - Comanda** | *Cancela* | Un administrador puede cancelar múltiples comandas, una comanda puede ser o no cancelada por un administrador. | (0,N):(0,1) |
| **Mesa - Evento** | *Pertenece* `(identificadora)` | Cada mesa queda ligada a un evento, cada mesa tiene un evento, y cada evento tiene múltiples mesas. | (1,1):(1,N) |
| **Evento - Cuenta** | *Abre* `(identificadora)` | Cada cuenta se abre dentro de un evento y de ahí saca su identidad; un evento puede no tener cuentas todavía, o tener varias. | (0,N):(1,1) |

### Por qué *Acuerda* es ternaria y *Prepara* no

Una relación entre tres entidades se justifica solo si el trío **no se puede reconstruir a partir de los pares**, es decir, si ninguna de las tres queda determinada por las otras dos.

- *Acuerda* **sí** la necesita: si el evento 17 contrata dos paquetes y los dos incluyen refresco, saber el evento y el producto no te dice cuántos refrescos van por cada paquete. Hacen falta los tres.
- *Prepara* **no**: cada comanda apunta a un solo producto, así que el producto queda determinado por la comanda y se obtiene navegando hasta ella. Meterlo en la relación no agregaba información, por eso quedó binaria.

### Atributos de relación

Hay datos que no pertenecen a ninguna de las entidades que la relación conecta, sino a la relación misma. En Chen se dibujan como óvalos colgados del rombo.

| Relación | Atributo | Por qué va ahí |
| :-- | :-- | :-- |
| *Evento-Acuerda-Paquete-Producto* | `Cantidad acordada` | No es un dato del paquete (el catálogo no trae cantidades) ni del evento ni del producto por separado: solo tiene sentido con los tres juntos. Es la base del reporte de presupuestado contra real |
| *Mesero-Recibe Propina-Pago* | `Monto de propina` | No es el `Monto` del pago (eso es lo que pagó el cliente) ni un dato fijo del mesero: es cuánto le tocó de ese cobro en concreto. Se registra al cerrar la cuenta y el cajero lo verifica. De aquí se calcula `Propinas acumuladas` |

---

## Restricciones

### Cardinalidades y su regla de negocio

**1. Mesa-Pertenece-Evento (1,1):(1,N)**

- *Por qué:* las mesas se ponen según cuánta gente va a ir, y se numeran cuando se monta el salón. O sea que una mesa solo existe dentro del evento para el que se puso.
- *Se lee así:* cada mesa es de un solo evento, y cada evento tiene al menos una mesa (como máximo, las que caben en el salón).

**2. Mesa-Atiende-Mesero (1,1):(0,N)**

- *Por qué:* si hay varios meseros, a cada uno le toca un grupo de mesas. Ninguna mesa se queda sin mesero, pero un mesero puede estar registrado y no traer mesas en ese evento.
- *Se lee así:* cada mesa la atiende un solo mesero; un mesero puede traer de cero a muchas mesas.

**3. Cuenta-Recibe-Pago (0,N):(1,1)**

- *Por qué:* se cobra por grupo de invitados (unas 2 o 3 cuentas por mesa) y la cuenta se queda abierta hasta que la pagan. Por eso puede no tener ningún pago todavía, o tener varios si la dividen.
- *Se lee así:* una cuenta puede tener de cero a varios pagos; cada pago es de una sola cuenta.

### Entidades débiles y de qué dependen

| Entidad débil | Depende de | Relación que la identifica | Tipo de dependencia | Clave parcial | Clave completa |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Mesa** | Evento | *Mesa-Pertenece-Evento* | Identificación | Número de mesa | (Número de evento, Número de mesa) |
| **Cuenta** | Evento | *Evento-Abre-Cuenta* | Identificación | Secuencial | (Número de evento, Secuencial) |

Las dos son **de identificación**: el número se reinicia en cada evento, así que decir "mesa 3" o "cuenta 10" no significa nada si no dices de qué evento estás hablando. Y si algo necesita a otra cosa para poder identificarse, tampoco puede existir sin ella.

### Jerarquía de Usuario

**Usuario → {Mesero, Bar/Cocina, Cajero/Administrador}**

| Restricción | Valor |
| :-- | :-- |
| Disyunción | Disjunta |
| Completitud | Total |

- *Por qué disjunta:* una persona hace un solo trabajo a la vez. Puede cambiar de rol más adelante (un mesero se puede pasar a caja), pero no es las dos cosas al mismo tiempo. La restricción habla del rol que tiene ahora, no le prohíbe cambiarse después.
- *Qué se gana con eso:* que no se crucen las responsabilidades. El que cobra no puede ser el que se lleva la propina de ese cobro, y el que cancela una comanda no puede ser el que la levantó. En la entrevista los pedidos pasan por caja justo para tener ese control, y eso solo sirve si el cajero y el mesero son personas distintas.
- *Por qué total:* todos los usuarios del sistema son personal del salón y todos tienen un rol (mesero, cocina, bar o cajero/administrador). Un usuario sin rol no podría hacer nada. El organizador del evento no cuenta aquí, porque no es usuario del sistema: es un dato del evento.
- *Por qué Bar y Cocina van juntos:* en la entrevista los mencionan aparte, pero en el modelo tienen los mismos atributos y hacen lo mismo (los dos preparan comandas), y `Estación asignada` ya dice cuál es cuál. Separarlos daría dos subtipos idénticos, y eso no aporta nada.
- *Por qué sí hace falta la jerarquía:* cada subtipo tiene sus propios atributos y además sus propias relaciones (el mesero con las mesas, bar/cocina con *Prepara*, el cajero con los pagos). Si lo único distinto fueran los atributos, bastaría con un campo "rol" y la jerarquía estaría de más.

### Lo que el diagrama no puede mostrar

- Cuántas mesas caben en el salón como máximo.
- Que el `Total acumulado` de una cuenta tiene que dar lo mismo que la suma de sus comandas.
- Que solo el cajero/administrador puede cancelar comandas.
- Que el rol que guardamos es el de ahora, no el historial. Si un mesero se pasa a caja, las comandas y los pagos que ya registró se quedan a su nombre aunque ya no sea mesero.
- Que el `Precio cobrado` de una comanda se copia del producto al momento de levantarla y ya no cambia, aunque después suba el precio del catálogo.
- Que la propina siempre la tiene que verificar el cajero antes de quedar registrada.
- Que el contenido de catálogo de un paquete es una base y no una lista cerrada: en un evento se pueden acordar productos que el paquete no traía, o cantidades distintas a las de catálogo. El diagrama no puede obligar a que lo acordado salga del catálogo, justo porque no debe.

---

## Conceptos del modelo extendido que el caso no necesita

Dejar dicho por qué no se usaron también es parte del análisis.

**Categoría o unión**

Una **categoría** es un tipo cuyos miembros salen de la **unión** de varios tipos de entidad distintos: `PROPIETARIO ⊆ PERSONA ∪ EMPRESA`, donde unos propietarios son personas y otros empresas, y cada uno se queda con los atributos de donde vino. No tiene nada que ver con el atributo `Categoría` de Producto, que es solo una etiqueta (alimentos, bebidas, dulcería).

Aquí **no se identifica ninguna categoría**: cada entidad del modelo viene de un solo tipo. Lo más parecido sería juntar Anticipo y Pago en un "ingreso del evento", pero las dos ya se relacionan directo con Evento y con Cuenta, así que unirlas no agregaría información, solo un nivel de indirección de más.

**Agregación**

La **agregación** sirve para relacionar una relación completa con una tercera entidad. Aquí no hace falta: el único caso que la pediría —que la estación prepare el producto que registra la comanda— ya se resuelve con la binaria *Prepara*, porque cada comanda apunta a un solo producto y ese producto se obtiene navegando hasta ella. No hace falta tratar a la relación *Comanda-Referencia-Producto* como un bloque para colgarle la estación.

**Caracterización**

No se ocupa en este caso. Conviene confirmar con el profesor la definición exacta que usa, porque no es un término que aparezca igual en todas las bibliografías.

---

## Modelo en notación de Peter Chen

![Diagrama entidad-relación extendido en notación de Peter Chen](<../modelo/diagrama-eer.png>)

---

## Justificación

### Por qué las entidades débiles no pueden existir solas

Las dos entidades débiles del modelo son Mesa y Cuenta, y las dos dependen de Evento por identificación, que es una dependencia más fuerte que la de existencia.

El número de mesa no está asignado de forma permanente al mobiliario, sino que se decide cuando se monta el salón, y la cantidad de mesas cambia según cuánta gente va a ir a cada evento, entonces la mesa 3 del evento 17 y la mesa 3 del evento 22 no son la misma mesa ni tienen nada que ver entre ellas. Con la cuenta pasa lo mismo porque el secuencial se reinicia en cada evento, entonces decir "la cuenta 10" no identifica nada si no se dice de qué evento se está hablando.

Por eso en los dos casos la clave parcial *el número de mesa y el secuencial* no alcanza por sí sola y hay que completarla con el número de evento, y de ahí sale la clave compuesta (Número de evento, Número de mesa) y (Número de evento, Secuencial). Como la identidad de las dos sale del evento, si se borrara un evento no quedarían mesas ni cuentas huérfanas sino registros que ya no significan nada, y toda dependencia de identificación arrastra también la de existencia.

Vale aclarar que Cuenta se identifica directamente por Evento y no por Mesa, aunque el folio que ve el usuario incluya la mesa. El secuencial cuenta las cuentas de todo el evento sin importar en qué mesa se abrieron, entonces la mesa no aporta nada para distinguir una cuenta de otra y la relación *Tiene* queda como una relación normal que solo registra dónde se abrió la cuenta.

### Por qué se eligió esa especialización

La jerarquía de Usuario quedó **disjunta y total**, y cada restricción responde a una regla distinta del salón.

Es disjunta porque una persona hace un solo trabajo a la vez. Sí puede cambiar de rol con el tiempo, por ejemplo un mesero que después se pasa a caja, pero nunca está en los dos puestos al mismo tiempo, y la restricción de disyunción habla del rol vigente y no impide que alguien migre de un subtipo a otro más adelante.

Además la disyunción sostiene la separación de responsabilidades que ya traía el negocio. Si un usuario pudiera ser mesero y cajero al mismo tiempo, estaría manejando el pago del que sale su propia propina, y podría cancelar las comandas que él mismo levantó. En la entrevista los pedidos se centralizan en caja justamente para tener ese punto de control, entonces ese control solo funciona si el cajero y el mesero son personas distintas, y modelarlo como solapada abriría el hueco que el negocio ya cerró.

Es total porque todos los usuarios del sistema son personal del salón y todos tienen un rol asignado, ya sea mesero, cocina, bar o cajero. Un usuario sin subtipo no tendría permisos ni función en un sistema que separa los accesos por rol, entonces no existe el caso que obligaría a dejarla parcial. El organizador del evento tampoco cuenta aquí porque no es usuario del sistema sino un atributo de Evento.

También conviene aclarar por qué bar y cocina quedaron en un solo subtipo aunque la entrevista los nombre por separado. Los dos tienen exactamente los mismos atributos y participan en las mismas relaciones *los dos preparan comandas*, entonces separarlos daría dos subtipos idénticos, y el atributo `Estación asignada` ya alcanza para distinguir cuál es cuál.

### Cómo reflejan las cardinalidades las reglas del negocio

Lo que de verdad carga la regla de negocio es el **mínimo**, porque el máximo casi siempre es obvio y el mínimo es el que dice si algo es obligatorio u opcional. En el modelo básico de la Práctica 1 solo se podía decir 1:N, entonces no había forma de distinguir entre "tiene que haber uno" y "puede no haber ninguno", y varias reglas del cliente se quedaban fuera.

En **Mesa-Pertenece-Evento (1,1):(1,N)** el (1,1) del lado de la mesa es el que obliga a que toda mesa esté dentro de un evento, que es la regla que sostiene la dependencia de identificación, y el mínimo 1 del lado del evento dice que no hay eventos sin mesas.

En **Mesa-Atiende-Mesero (1,1):(0,N)** el (1,1) dice que ninguna mesa se queda sin responsable, que es lo que permite saber a quién reclamarle y a quién darle la propina, y el 0 del lado del mesero es igual de importante porque un mesero registrado en el sistema puede no traer mesas en un evento determinado. Si ahí se pusiera (1,N) el modelo estaría prohibiendo que exista un mesero que no esté trabajando ese día.

En **Cuenta-Recibe-Pago (0,N):(1,1)** el 0 del lado de la cuenta es el que permite que exista una cuenta abierta todavía sin pagos, que es justo el estado normal durante el evento, y el máximo N permite que la cuenta se liquide con varios pagos cuando los invitados la dividen. Si el mínimo fuera 1 el modelo no podría representar una cuenta abierta, que es la mitad de la operación.

### Tres consultas que este modelo responde y uno sin extensiones no

**1. ¿Cuánto se desvió el consumo real del evento 17 respecto a lo que se acordó de cada producto en cada paquete?**

Esta consulta necesita la relación ternaria *Acuerda*, porque la cantidad pactada no es un dato del paquete ni del evento ni del producto por separado sino de los tres juntos. Con solo las relaciones binarias se sabría qué paquetes contrató el evento y qué productos trae cada paquete en el catálogo, pero no cuántas porciones se acordaron de cada producto para ese evento en concreto, y si el evento contrató dos paquetes que comparten un producto tampoco se sabría cuánto corresponde a cada uno. Es justo el reporte de consumo real contra lo presupuestado que el cliente pidió en la entrevista.

**2. ¿Cuánto acumuló de propinas cada mesero y cuántos pagos manejó cada cajero, sin que se mezclen entre ellos?**

Esta necesita la jerarquía de especialización. Sin ella Usuario sería una sola entidad con un atributo `Rol`, y todas las relaciones colgarían de esa entidad única, entonces nada en el modelo impediría que una propina quedara asignada a alguien de cocina o que una comanda apareciera cancelada por un mesero. El atributo `Rol` sirve para filtrar al consultar, pero no impide que el dato incorrecto se guarde. Al tener *Recibe propina* colgando de Mesero y *Maneja* colgando de Cajero, la separación queda en la estructura y no en la disciplina de quien captura.

**3. ¿Cuántas cuentas se abrieron en la mesa 3 del evento 17 y cuánto consumió cada una?**

Esta depende de las entidades débiles. Si Mesa y Cuenta tuvieran clave propia e independiente, la mesa 3 sería una sola fila compartida por todos los eventos del salón y la pregunta no se podría acotar a un evento, o habría que inventar una numeración global que el salón no usa. Con la dependencia de identificación la mesa 3 del evento 17 es un registro distinto de la mesa 3 de cualquier otro evento, entonces la consulta se puede hacer directo y además queda garantizado que no se mezclan cuentas de eventos distintos.
