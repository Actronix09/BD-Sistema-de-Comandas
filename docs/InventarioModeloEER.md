# Inventario del Modelo Entidad-Relación Extendido

En este documento se enlistan todos los elementos del modelo EER del sistema de comandas construido en la Práctica 2, antes de transformarlo en tablas. Este inventario es la lista contra la que se verifica al final, en la Parte 6.5, que ninguna entidad ni relación se perdió en el paso al modelo relacional.

---

**Cliente:** Salón de eventos — sistema de comandas

**Modelo de origen:** [Modelo Entidad-Relación Extendido del Sistema de Comandas](<ModeloEntidadRelaciónExtendido.md>)

**Contenido:** Entidades fuertes y débiles, relaciones con cardinalidades `(mín,máx)`, jerarquía de Usuario, atributos multivaluados, compuestos y derivados, relación ternaria y respuestas a las tres preguntas previas a la transformación.

---

![Diagrama entidad-relación extendido del sistema de comandas](<../modelo/diagrama-eer-chen.svg>)

## Entidades fuertes

Son las entidades que tienen identificador propio y existen por sí mismas. Los atributos se escriben con la misma notación de la Práctica 2: `(PK)` clave primaria, `(AK)` clave alternativa, `(compuesto)`, `(multivaluado)`, `(derivado)` y `(opcional)`.

| # | Entidad | Atributos | Clave primaria |
| :--: | :-- | :-- | :-- |
| 1 | **Evento** | Número de evento `(PK)`, Organizador/cliente `(multivaluado)`, Fecha `(compuesto: Día, Mes, Año)`, Tipo de evento, Número de asistentes, Número de mesas `(derivado)`, Estado del evento | Número de evento |
| 2 | **Usuario** | ID `(PK)`, Nombre, Usuario `(AK)`, Fecha de nacimiento `(compuesto: Día, Mes, Año)`, Edad `(derivado)`, Contraseña | ID |
| 3 | **Producto** | ID `(PK)`, Nombre, Descripción `(opcional)`, Categoría, Precio, Disponible `(derivado)` | ID |
| 4 | **Comanda** | ID `(PK)`, Time Stamp `(compuesto: Día, Mes, Año, Hora)`, Precio cobrado, Estado, Detalles `(opcional)`, Precio `(derivado)` | ID |
| 5 | **Pago** | Número de pago `(PK)`, Monto, Forma de pago, Time Stamp `(compuesto: Día, Mes, Año, Hora)` | Número de pago |
| 6 | **Anticipo** | ID `(PK)`, Monto, Fecha `(compuesto: Día, Mes, Año)` | ID |
| 7 | **Paquete** | Número de paquete `(PK)`, Monto, Detalles | Número de paquete |
| 8 | **Ingrediente** | ID `(PK)`, Nombre `(AK)`, Unidad de medida, Stock actual, Stock mínimo | ID |

Los tres subtipos de Usuario (Mesero, Bar/Cocina y Cajero/Administrador) no se cuentan aquí como entidades fuertes independientes: heredan la identidad de Usuario y se inventarían en la sección de jerarquías.

## Entidades débiles

| # | Entidad débil | Clave parcial | Entidad propietaria | Relación de identificación | Tipo de dependencia | Clave completa |
| :--: | :-- | :-- | :-- | :-- | :-- | :-- |
| 9 | **Mesa** | Número de mesa | Evento | *Pertenece* | Identificación | (Número de evento, Número de mesa) |
| 10 | **Cuenta** | Secuencial | Evento | *Abre* | Identificación | (Número de evento, Secuencial) |

Cuenta tiene además tres atributos propios: Folio `(derivado: [#Evento]-[#Mesa]-[#Secuencial])`, Estado (abierta/cerrada) y Total acumulado `(derivado)`. Mesa no tiene más atributos que su clave parcial.

Las dos dependencias son **de identificación**: el número de mesa y el secuencial de la cuenta se reinician en cada evento, así que por sí solos no distinguen nada. Cuenta se identifica por Evento y no por Mesa; la relación con la mesa (*Tiene*) solo registra dónde se abrió.

## Relaciones

La cardinalidad se escribe para cada participante como `(mín,máx)`: cuántas veces puede aparecer **una** ocurrencia de esa entidad en la relación.

| # | Relación | Participante A | Participante B | Tipo | Atributos de la relación |
| :--: | :-- | :-- | :-- | :-- | :-- |
| R1 | *Pertenece* `(identificadora)` | Mesa (1,1) | Evento (1,N) | 1:N | — |
| R2 | *Abre* `(identificadora)` | Cuenta (1,1) | Evento (0,N) | 1:N | — |
| R3 | *Atiende* | Mesa (1,1) | Mesero (0,N) | 1:N | — |
| R4 | *Tiene* | Cuenta (1,1) | Mesa (0,N) | 1:N | — |
| R5 | *Genera* | Comanda (1,1) | Cuenta (0,N) | 1:N | — |
| R6 | *Levanta* | Comanda (1,1) | Mesero (0,N) | 1:N | — |
| R7 | *Referencia* | Comanda (1,1) | Producto (1,N) | 1:N | — |
| R8 | *Prepara* | Comanda (0,1) | Bar/Cocina (0,N) | 1:N | — |
| R9 | *Cancela* | Comanda (0,1) | Cajero/Administrador (0,N) | 1:N | — |
| R10 | *Recibe* | Pago (1,1) | Cuenta (0,N) | 1:N | — |
| R11 | *Maneja* | Pago (1,1) | Cajero/Administrador (0,N) | 1:N | — |
| R12 | *Recibe propina* | Pago (0,1) | Mesero (0,N) | 1:N | Monto de propina |
| R13 | *Recibe* | Anticipo (1,1) | Evento (0,N) | 1:N | — |
| R14 | *Variante* `(recursiva)` | Producto como variante (0,1) | Producto como principal (0,N) | 1:N | — |
| R15 | *Incluye* | Paquete (1,N) | Producto (0,N) | M:N | — |
| R16 | *Acuerda* `(ternaria)` | Evento (0,N) · Paquete (0,N) · Producto (0,N) | | Ternaria | Cantidad acordada |
| R17 | *Receta* | Producto (1,N) | Ingrediente (0,N) | M:N | Cantidad por porción |

| Tipo | Cantidad | Relaciones |
| :-- | :--: | :-- |
| Uno a muchos | 14 | R1 a R14 (dos identificadoras y una recursiva) |
| Muchos a muchos | 2 | R15 y R17 |
| Uno a uno | 0 | — |
| Ternaria | 1 | R16 |

El modelo no tiene relaciones uno a uno: el caso más parecido, *Referencia*, es uno a muchos porque un mismo producto aparece en muchas comandas.

## Jerarquías de generalización y especialización

| Supertipo | Subtipos | Disyunción | Completitud | Atributos propios de cada subtipo | Relaciones propias de cada subtipo |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Usuario** | Mesero | Disjunta | Total | Propinas acumuladas `(derivado)`, Turno asignado | *Atiende*, *Levanta*, *Recibe propina* |
| | Bar/Cocina | | | Estado (ocupado/desocupado), Estación asignada | *Prepara* |
| | Cajero/Administrador | | | Nivel de acceso, Caja asignada | *Maneja*, *Cancela* |

Es la única jerarquía del modelo. Es **disjunta** porque una persona tiene un solo rol a la vez, y **total** porque todo usuario del sistema es personal del salón con un rol asignado.

## Atributos multivaluados, compuestos y derivados

### Multivaluados

| Entidad | Atributo | Por qué tiene varios valores |
| :-- | :-- | :-- |
| Evento | Organizador/cliente | Un evento puede tener varios organizadores (los novios, los padres de la quinceañera) |

### Compuestos

| Entidad | Atributo | Componentes |
| :-- | :-- | :-- |
| Evento | Fecha | Día, Mes, Año |
| Usuario | Fecha de nacimiento | Día, Mes, Año |
| Comanda | Time Stamp | Día, Mes, Año, Hora |
| Pago | Time Stamp | Día, Mes, Año, Hora |
| Anticipo | Fecha | Día, Mes, Año |

### Derivados

| Entidad | Atributo | De dónde se obtiene |
| :-- | :-- | :-- |
| Evento | Número de mesas | Conteo de las mesas del evento |
| Cuenta | Folio | Número de evento, número de mesa y secuencial de la propia cuenta |
| Cuenta | Total acumulado | Suma del precio cobrado de sus comandas no canceladas |
| Usuario | Edad | Fecha de nacimiento contra la fecha actual |
| Mesero | Propinas acumuladas | Suma del Monto de propina de sus pagos |
| Comanda | Precio | Precio vigente del producto al que hace referencia |
| Producto | Disponible | Stock actual de cada ingrediente de su receta contra la cantidad por porción |

### Otros atributos que piden una decisión

| Elemento | Atributo | Observación |
| :-- | :-- | :-- |
| Comanda | Detalles | Opcional: admite nulos |
| Producto | Descripción | Opcional: admite nulos; no todos los productos llevan texto en la carta |
| Usuario | Usuario | Clave alternativa: tiene que ser único aunque no sea la clave primaria |
| Ingrediente | Nombre | Clave alternativa: dos ingredientes con el mismo nombre partirían el stock en dos |
| *Recibe propina* | Monto de propina | Atributo de relación |
| *Acuerda* | Cantidad acordada | Atributo de relación |
| *Receta* | Cantidad por porción | Atributo de relación |

## Relaciones ternarias o de orden superior

| Relación | Participantes | Atributo propio | Por qué no se puede partir en binarias |
| :-- | :-- | :-- | :-- |
| *Acuerda* | Evento, Paquete, Producto | Cantidad acordada | Si un evento contrata dos paquetes que comparten un producto, conocer el evento y el producto no dice cuánto se acordó por cada paquete. La cantidad depende de los tres a la vez |

No hay relaciones de orden mayor a tres.

---

## Preguntas previas a la transformación

### ¿Qué elementos van a requerir una tabla adicional?

Una tabla por entidad es lo esperado: 8 fuertes y 2 débiles dan 10 tablas. Además de esas, el modelo necesita tablas que no corresponden a ninguna entidad:

| Elemento | Tabla adicional | Por qué |
| :-- | :-- | :-- |
| Organizador/cliente de Evento | Una tabla de organizadores | Una columna solo guarda un valor (Regla 3) |
| *Incluye* (Paquete–Producto) | Una tabla de la relación | Muchos a muchos: ninguno de los dos lados puede guardar la clave del otro (Regla 5) |
| *Receta* (Producto–Ingrediente) | Una tabla de la relación | Muchos a muchos con atributo propio (Regla 5) |
| *Acuerda* (Evento–Paquete–Producto) | Una tabla de la relación | Ternaria con atributo propio (Regla 7) |
| Subtipos de Usuario | Hasta tres tablas, según la estrategia | Depende de la decisión de la jerarquía (Regla 9) |

Las relaciones uno a muchos no generan tabla: se resuelven con una clave foránea en el lado muchos (Regla 4).

### ¿Qué atributos se convertirán en claves foráneas?

Ninguno de los atributos dibujados en el EER se convierte en clave foránea: las claves foráneas aparecen al transformar las relaciones, como copia del identificador de la entidad del otro lado.

| Tabla que la recibe | Clave foránea (identificador que se copia) | Relación que la origina | ¿Admite nulos? |
| :-- | :-- | :-- | :-- |
| Mesa | Número de evento | *Pertenece* (identificadora) | No, y es parte de la clave primaria |
| Mesa | ID del mesero | *Atiende* | No, mínimo 1 |
| Cuenta | Número de evento | *Abre* (identificadora) | No, y es parte de la clave primaria |
| Cuenta | Número de mesa (junto con el número de evento) | *Tiene* | No, mínimo 1 |
| Comanda | Número de evento y secuencial de la cuenta | *Genera* | No, mínimo 1 |
| Comanda | ID del mesero | *Levanta* | No, mínimo 1 |
| Comanda | ID del producto | *Referencia* | No, mínimo 1 |
| Comanda | ID del usuario de bar/cocina | *Prepara* | Sí, mínimo 0 |
| Comanda | ID del cajero/administrador | *Cancela* | Sí, mínimo 0 |
| Pago | Número de evento y secuencial de la cuenta | *Recibe* | No, mínimo 1 |
| Pago | ID del cajero/administrador | *Maneja* | No, mínimo 1 |
| Pago | ID del mesero | *Recibe propina* | Sí, mínimo 0 |
| Anticipo | Número de evento | *Recibe* | No, mínimo 1 |
| Producto | ID del producto principal | *Variante* | Sí, mínimo 0 |
| Tabla de organizadores | Número de evento | Atributo multivaluado | No, y es parte de la clave primaria |
| Tabla de *Incluye* | Número de paquete e ID del producto | *Incluye* | No, forman la clave primaria |
| Tabla de *Receta* | ID del producto e ID del ingrediente | *Receta* | No, forman la clave primaria |
| Tabla de *Acuerda* | Número de evento, número de paquete e ID del producto | *Acuerda* | No, forman la clave primaria |

### ¿Qué decisión tendrá que tomar cada jerarquía?

El modelo tiene una sola jerarquía, la de Usuario, y la decisión es cuál de las tres estrategias de la Regla 9 usar:

| Estrategia | Qué implicaría para Usuario |
| :-- | :-- |
| Tabla por supertipo y por subtipo | Una tabla Usuario con lo común y una por subtipo. Las relaciones propias de cada subtipo pueden apuntar directo a su tabla |
| Tabla única con discriminador | Una sola tabla con un campo de rol. Cada subtipo tiene solo dos atributos, así que habría pocos nulos, pero las relaciones de los subtipos tendrían que apuntar a la tabla completa |
| Tabla por subtipo, sin supertipo | Tres tablas que repiten nombre, usuario, contraseña y fecha de nacimiento. La jerarquía es total y disjunta, así que es válida, pero la clave alternativa Usuario tendría que ser única entre tres tablas distintas |

Lo que inclina la decisión no son los atributos, sino que **cada subtipo tiene sus propias relaciones**: que una propina solo pueda ir a un mesero o una cancelación solo a un cajero depende de que exista una tabla a la cual apuntar. La decisión y su justificación están en la Parte 5, en [Reglas de Transformación](<ReglasDeTransformacion.md#jerarquía-de-usuario>).

## Resumen del inventario

| Elemento | Cantidad |
| :-- | :--: |
| Entidades fuertes | 8 |
| Entidades débiles | 2 |
| Subtipos en jerarquías | 3 (una jerarquía) |
| Relaciones binarias | 16 (14 uno a muchos, 2 muchos a muchos) |
| Relaciones ternarias | 1 |
| Atributos multivaluados | 1 |
| Atributos compuestos | 5 |
| Atributos derivados | 7 |
| Atributos de relación | 3 |
