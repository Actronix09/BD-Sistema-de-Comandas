# Caso de Estudio

---

Problemática del proyecto, requerimientos de la base de datos y del sistema, diagrama entidad-relación y justificación del modelo. Su contenido viene del documento de la Práctica 1, escrito en LaTeX ([`docs/LaTeX/`](<../LaTeX>)).

---

Aquí se abarca la problemática a trabajar a lo largo del semestre para culminarlo en el proyecto final de la materia de Bases de Datos. La problemática que abarcaremos será un sistema de comandas, siendo nuestro primer cliente un salón de eventos enfocándose en el control del flujo de trabajo y el inventario de la mercancía durante los evento, ademas de mantener controlado pagos y estados de pedidos; por lo tanto, la primera instancia del diseño de nuestro sistema estará enfocada en atender las necesidades de este primer cliente.

Además, se ha de aclarar que este proyecto ya tiene un sistema inicial de apoyo, siendo una *interfaz de usuario en terminal* (TUI) hecha con `ncurses`, la cual se desarrolló en la materia de Sistemas Operativos.

## Entrevista con el Cliente

Las preguntas y las respuestas de la entrevista están en [Entrevista con el Cliente](<Entrevista.md>), agrupadas en eventos y mesas, menú y productos, flujo de comandas, cobros y pagos, roles y permisos, reportes, y operación y escalabilidad.

## Requerimientos de la base de datos

### Entidades y atributos

- **Evento**: organizador/cliente, fecha, tipo de evento, número de mesas, paquete contratado, estado del evento.

- **Mesa**: número de mesa.

- **Cuenta**: identificador, nombre (alias que la distingue de las demás cuentas de su mesa), estado (abierta/cerrada), total acumulado.

- **Mesero / Usuario**: nombre, rol (mesero, cocina, bar, cajero/administrador).

- **Producto**: nombre, descripción, categoría (alimentos, bebidas con alcohol, bebidas sin alcohol, dulcería), precio, variantes (tamaño o preparación distinta).

- **Ingrediente**: nombre, unidad de medida, stock actual, stock mínimo.

- **Comanda** (pedido): fecha/hora, estado (pendiente, en preparación, lista, entregada, cancelada), detalles.

- **Pago**: monto, forma de pago (efectivo, transferencia, tarjeta), fecha.

- **Anticipo**: monto, fecha.

- **Paquete del evento**: monto presupuestado, productos incluidos.

### Relaciones

- **Mesa — Mesero/Usuario**: un mesero atiende una o varias mesas; una mesa puede ser atendida por más de un mesero.

- **Mesa — Cuenta**: una mesa puede tener varias cuentas (grupos de invitados).

- **Cuenta — Comanda**: una cuenta genera varias comandas (rondas) durante el evento.

- **Mesero/Usuario — Comanda**: un mesero levanta varias comandas; cada comanda la levanta un solo mesero, pero más usuarios la atienden.

- **Comanda — Producto**: cada comanda hace referencia a un producto.

- **Producto — Ingrediente** (receta): un producto lleva uno o varios ingredientes y un ingrediente se usa en varios productos; de cada par se guarda la cantidad que lleva una porción.

- **Cuenta — Pago**: una cuenta puede recibir uno o varios pagos.

- **Evento — Anticipo**: un evento puede tener uno o varios anticipos.

- **Paquete del evento — Evento**: un paquete puede estar en varios eventos y cada evento puede tener uno o varios paquetes.

- **Paquete del evento — Producto**: el paquete incluye uno o varios productos.

## Requerimientos del sistema en general

- Registrar un evento junto con sus mesas y asignar mesero(s) a cada una (un solo mesero si el evento es pequeño, varios repartidos por grupos de mesas si es grande).

- Permitir que una misma mesa tenga varias cuentas independientes (grupos de invitados), cada una con su propio consumo y cobro.

- Centralizar la toma de pedidos en caja: el cajero recibe la comanda (hoy en papel) y la envía a cocina/bar.

- Actualizar el estado de cada comanda (pendiente → en preparación → lista → entregada) y permitir su cancelación o modificación aun después de enviada.

- Permitir múltiples rondas de pedidos por cuenta durante el mismo evento.

- Registrar notas especiales por producto dentro de un pedido cuando sea necesario.

- Registrar la receta de cada producto (qué ingredientes lleva y en qué cantidad) y descontar del stock de ingredientes lo que se consume al preparar cada comanda.

- Avisar cuando un ingrediente baje de su stock mínimo y marcar como no disponibles los productos que ya no se pueden preparar.

- Registrar qué mesero levantó cada comanda y qué cuentas lleva, para control de responsabilidad y propinas.

- Diferenciar accesos por rol: mesero, cocina, bar y cajero/administrador, cada uno con las funciones que le corresponden.

- Registrar anticipos/depósitos del evento antes de la fecha, y aplicarlos al cobro final.

- Registrar pagos por cuenta con su forma de pago (efectivo, transferencia o tarjeta); no se requiere generar factura fiscal (CFDI), solo un recibo interno.

- Distinguir entre consumo incluido en el paquete del evento (comida preparada con antelación, no se cobra aparte) y consumo extra a la carta (sí se cobra).

- Generar reportes de ventas e ingresos por evento.

- Generar un reporte comparativo entre el consumo real y lo presupuestado en el paquete del evento.

- Permitir consultar los reportes tanto en vivo durante el evento como al cierre.

- Operar preferentemente sin conexión a internet dentro del salón.

- Soportar el volumen operativo actual: ~15 eventos al mes, hasta ~20 mesas por evento, 2–3 cuentas por mesa y de 1 a 3 pedidos por cuenta (con posibilidad de más rondas).

## Diagrama Entidad-Relación

![Diagrama entidad-relación del sistema de comandas](<../../modelo/diagrama-er.png>)

*Figura 1. Diagrama entidad-relación*

## Justificación del modelo

El modelo entidad-relación de la Figura 1 se construyó a partir de las respuestas obtenidas en la entrevista con el cliente y de los requerimientos que se derivaron de ella. Cada entidad representa un objeto del negocio sobre el cual el salón necesita guardar información de forma permanente, y cada relación representa una regla de operación que el cliente describió. En esta sección se explica por qué se definieron así y de qué manera el diagrama atiende la problemática planteada.

### Justificación de las entidades

- **Evento**: es el punto de partida de la operación del salón, ya que el cliente atiende un único evento a la vez y alrededor de quince al mes. Se modela como entidad porque cada evento tiene datos propios (organizador, fecha, tipo, número de mesas y estado) y porque a él se asocian los anticipos y los paquetes contratados. El atributo *estado* permite distinguir un evento programado de uno en curso o ya cerrado.

- **Mesa**: el cliente indicó que las mesas están numeradas y que su cantidad varía entre eventos. Se define como entidad, y no como un simple atributo, porque sobre ella recaen dos reglas del negocio: la asignación de meseros y la división de la cuenta en grupos de invitados.

- **Cuenta**: surge de la respuesta más relevante sobre cobros: lo más común es cobrar por grupo de invitados, con dos o tres cuentas por mesa. Separar la cuenta de la mesa permite que cada grupo tenga su propio consumo, un *nombre* que lo identifica dentro de la mesa, su propio *total* y su propio *estado* (abierta o cerrada), sin mezclarse con el de otros grupos sentados en la misma mesa.

- **Usuario**: agrupa en una sola entidad a todas las personas que operan el sistema. En lugar de crear una entidad distinta para meseros, cocina, bar y caja, se utiliza el atributo *rol*, ya que todos comparten los mismos datos (código y nombre) y solo difieren en las funciones que pueden realizar. Esto simplifica el modelo y facilita agregar roles en el futuro.

- **Producto**: representa los artículos del menú, que el cliente clasificó en alimentos, bebidas con y sin alcohol, y dulcería. Los atributos *categoría* y *variante* responden a que algunos platillos y bebidas se ofrecen en distintos tamaños o preparaciones. Como el menú es fijo durante todo el año, el producto funciona como catálogo estable al que hacen referencia las comandas y los paquetes. Se agrega una *descripción* breve para mostrarla en la carta.

- **Ingrediente**: el cliente pidió saber cuánto queda de cada ingrediente y cuándo resurtir. Se modela como entidad, y no como un atributo de Producto, porque tiene datos propios (*unidad de medida*, *stock actual* y *stock mínimo*) y porque un mismo ingrediente, como el hielo, se usa en muchos productos: como atributo se repetiría en cada uno y no habría un solo stock del cual descontar.

- **Comanda**: es la entidad central del sistema y sustituye a la comanda de papel que hoy se entrega en caja. Registra *fecha*, *hora*, *detalles* (las notas especiales que el cliente pidió conservar) y *estado*, con el cual se da seguimiento al ciclo pendiente, en preparación, lista, entregada o cancelada. Además guarda el *precio* al momento del pedido: como los precios cambian por temporada, conservarlo en la comanda evita que un cambio posterior en el catálogo altere los totales de eventos ya cobrados, se ah de aclarar que el sistema va a manejar cada producto de pedido como una comanda individual para mejorar el flujo de trabajo del sistema.

- **Pago**: el cliente acepta efectivo, transferencia y tarjeta, y necesita que quede registrado. La entidad guarda *monto*, *método de pago*, *fecha* y *hora*, lo que permite saber cómo y cuándo se liquidó cada cuenta. No se incluyen datos fiscales porque el cliente indicó que no requiere factura (CFDI).

- **Anticipo**: se separa del pago porque tiene un origen distinto: se recibe antes del evento y está ligado al evento completo, no a una cuenta de invitados. Mantenerlo aparte evita confundir los depósitos del organizador con los cobros realizados durante el evento.

- **Paquete de evento**: modela la comida preparada con antelación que el organizador contrata y que no se cobra aparte. Registra su *precio* y los *productos incluidos*, lo que establece lo presupuestado para el evento y lo distingue del consumo a la carta.

En todas las entidades se definió un identificador (código, número o identificador, subrayado en el diagrama) como clave primaria, de modo que cada registro pueda distinguirse de manera única aunque otros atributos, como el nombre o la fecha, se repitan.

### Justificación de las relaciones

- **Usuario — Atiende — Mesa** (1:N): un mesero puede atender varias mesas. Refleja que, cuando hay varios meseros, a cada uno se le asigna un grupo de mesas, y que en eventos pequeños un solo mesero puede cubrirlas todas.

- **Mesa — Tiene — Cuenta** (1:N): una mesa puede tener varias cuentas, mientras que cada cuenta pertenece a una sola mesa. Es la relación que permite dividir el cobro por grupo de invitados, que es la forma de cobro más común en el salón.

- **Cuenta — Genera — Comanda** (1:N): una cuenta genera varias comandas y cada comanda pertenece a una sola cuenta. Así se representan las distintas rondas de pedidos que un mismo grupo realiza durante el evento, y el total de la cuenta puede obtenerse a partir de sus comandas.

- **Usuario — Atiende — Comanda** (M:N): en una comanda intervienen varios usuarios (el mesero que la levanta, el cajero que la recibe y la cocina o el bar que la preparan), y cada usuario participa en muchas comandas. Esta relación responde a la necesidad expresa del cliente de saber qué mesero hizo cada orden.

- **Comanda — Referencia — Producto** (M:1): cada comanda hace referencia a un producto del catálogo y el precio pedidos quedan registrados en la propia comanda. Con ello se evita escribir a mano el nombre y el precio del producto en cada pedido.

- **Cuenta — Recibe — Pago** (1:N): una cuenta puede liquidarse con uno o varios pagos, por ejemplo cuando parte se paga en efectivo y parte con tarjeta; cada pago corresponde a una sola cuenta.

- **Evento — Recibe — Anticipo** (1:N): un evento puede recibir uno o varios anticipos antes de su fecha, y cada anticipo pertenece a un único evento.

- **Evento — Incluye — Paquete de evento** (M:N): un evento puede contratar uno o varios paquetes y un mismo paquete puede ofrecerse en muchos eventos, por lo que los paquetes se definen una sola vez y se reutilizan.

- **Producto — Receta — Ingrediente** (M:N): un producto lleva varios ingredientes y un ingrediente se usa en varios productos. La relación guarda como atributo la *cantidad* que lleva una porción, que no pertenece ni al producto ni al ingrediente sino a la pareja; con ella se descuenta el stock cada vez que se prepara una comanda.

- **Paquete de evento — Incluye — Producto** (M:N): un paquete agrupa varios productos y un producto puede formar parte de varios paquetes. Esta relación deja registrado qué productos están incluidos en cada paquete.

### Cómo resuelve el modelo la problemática planteada

La problemática descrita en la introducción se origina en la gestión manual de las comandas y en un sistema anterior basado en unicamente papeles y tablas, sin relaciones bien definidas ni reglas de integridad. El modelo propuesto atiende estos problemas de la siguiente manera:

- **Pérdida y duplicación de pedidos entre meseros, cocina y caja**: la comanda deja de ser una hoja de papel y se convierte en un registro único, con un código propio, que todos los roles consultan. Su atributo *estado* permite a caja, cocina y bar saber en qué punto se encuentra cada pedido sin depender de mensajes verbales.

- **Falta de un registro histórico confiable**: cada comanda queda ligada a la cuenta que la generó, al producto que se pidió y a los usuarios que la atendieron, con fecha, hora y el precio vigente en ese momento. Esto permite reconstruir qué se sirvió, a quién y a qué costo.

- **Cuenta final lenta y propensa a errores**: al separar las cuentas por grupo de invitados y ligar a cada cuenta sus comandas y sus pagos, el total de cada grupo se obtiene directamente de los datos registrados, sin conciliar manualmente varias comandas en papel. Los anticipos, al estar ligados al evento, quedan registrados para descontarse del cobro final.

- **Control de responsabilidad del personal**: la relación entre usuario y comanda deja constancia de qué mesero levantó cada orden y quién más intervino en ella, lo que el cliente señaló como necesario.

- **Diferencia entre lo contratado y lo consumido a la carta**: los paquetes de evento y sus productos incluidos documentan lo que el organizador contrató con antelación, separado de las comandas a la carta que sí se cobran.

- **Deficiencias del sistema anterior**: a diferencia de los archivos ASCII del proyecto previo, cada entidad cuenta con una clave primaria y cada relación tiene una cardinalidad explícita. Esto permite, en la implementación en PostgreSQL, aplicar atributos fuertes y restricciones de integridad que impidan, por ejemplo, registrar un pago sin cuenta o una comanda que haga referencia a un producto inexistente.

En conjunto, el modelo traslada a una estructura formal las reglas de operación que el cliente describió en la entrevista, y constituye la base sobre la cual se implementará la base de datos del proyecto final.
