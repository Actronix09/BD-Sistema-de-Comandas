# Fuente de Datos del Sistema de Comandas

En este documento se registra de dónde salen los datos con los que se puebla la base del sistema de comandas: dónde se buscó, con qué términos, qué se encontró y qué se decidió con cada conjunto.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Búsqueda de conjuntos de datos publicados, decisión tomada y el catálogo del salón de eventos.

**Fecha de consulta:** 3 de noviembre de 2026

---

## Qué se necesita

Las tablas de la base se dividen en dos grupos, y cada uno se buscó por separado:

| Grupo | Tablas | Qué tendría que traer el conjunto |
| :-- | :-- | :-- |
| Catálogo | `producto`, `ingrediente`, `receta` | Platillos y bebidas, con sus ingredientes y la cantidad de cada uno |
| Operación | `evento`, `mesa`, `cuenta`, `comanda`, `pago`, `anticipo` | Pedidos renglón por renglón de un salón o restaurante, con mesa, mesero, estado y pago |

## Dónde se buscó

| Dónde | Términos | Resultado |
| :-- | :-- | :-- |
| [Datos Abiertos de la Ciudad de México](<https://datos.cdmx.gob.mx/>), por su API | restaurantes, comandas, recetas, menu, banquetes | 0 conjuntos en cada término |
| Datos Abiertos de la Ciudad de México, por su API | alimentos, salones de eventos | 4 y 6 conjuntos; ninguno trata de pedidos ni de recetas (apoyos económicos, comedores sociales, hechos de tránsito) |
| [DataMX](<https://datamx.io/>), por su API | comandas | 0 conjuntos |
| DataMX, por su API | recetas | 4 conjuntos; los que se revisaron son recetas de medicamentos y encuestas de salud, no de cocina |
| DataMX, por su API | restaurantes, alimentos | 26 y 65 conjuntos; los primeros resultados son directorios de negocios, como el DENUE del INEGI, encuestas y programas de apoyo. Traen establecimientos o estadísticas, no pedidos |
| [datos.gob.mx](<https://www.datos.gob.mx/>) | recetas | No se pudo consultar: la API respondió `Access Denied` y la dirección de búsqueda, 404 |
| Buscador web | restaurant orders point of sale open dataset; banquet hall event catering orders dataset; datos abiertos México recetas platillos ingredientes cantidades | Los conjuntos de las tablas siguientes |

## Conjuntos para la operación

| Conjunto | Qué trae | Licencia | Decisión |
| :-- | :-- | :-- | :-- |
| [Restaurant Orders](<https://mavenanalytics.io/data-playground/restaurant-orders>), Maven Analytics | Pedidos de un restaurante **ficticio**; la ficha indica 499 registros y 25 campos | GPL 3 | No sirve: también son inventados y no traen mesa, mesero ni pago |
| [Number of Orders of Clients and Restaurants from a Delivery Food Application](<https://data.mendeley.com/datasets/2h5v92w5hm>), Sanchez et al. | Ventas reales de una plataforma de Aguascalientes, de enero de 2019 a junio de 2021 | CC BY 4.0 | No sirve: es una matriz de ventas mensuales por cliente y restaurante, sin pedidos ni productos |
| [Restaurant Orders Data](<https://vizhub.com/Charan12-prog/70cca2a9db3d4967a423e01e7088fa97>), VizHub | Pedidos que su ficha declara sintéticos, sin mesa ni mesero | No se revisó | No sirve: son sintéticos |
| [Principal Statistics of Event Catering Services](<https://archive.data.gov.my/data/dataset/principal-statistics-of-event-catering-services-by-industry>), gobierno de Malasia | Estadísticas agregadas de la industria | No se revisó | No sirve: no trae transacciones |

No se encontró ningún conjunto publicado con comandas renglón por renglón de un salón de eventos. Tiene sentido: son datos internos de cada negocio y traen información de sus clientes y empleados.

## Conjuntos para el catálogo

| Conjunto | Qué trae | Licencia | Decisión |
| :-- | :-- | :-- | :-- |
| [FoodData Central, FNDDS 2021-2023](<https://fdc.nal.usda.gov/download-datasets/>), USDA | 5,432 alimentos preparados y bebidas, con 18,584 renglones de ingredientes y sus gramos | CC0 1.0 | **Candidato**: es el único que trae recetas con cantidades y una licencia clara |
| [TheMealDB](<https://www.themealdb.com/api.php>) | Recetas con medidas en texto libre | La página de la API no la indica; la llave de prueba es para desarrollo o uso educativo | Descartado: sin licencia clara y con un límite de 100 elementos al listar en la versión gratuita |
| [Open Food Facts](<https://world.openfoodfacts.org/data>) | Productos empacados; el archivo CSV pesa cerca de 9 GB al descomprimirlo | ODbL | Descartado: la página no ofrece recetas con cantidades |
| [Quién es Quién en los Precios](<https://datamx.io/dataset/quien-es-quien-en-los-precios>), PROFECO | Precios diarios de más de 2,000 productos en tiendas | La copia en DataMX dice "No License Provided" | Descartado: son precios de tienda, sin recetas |
| What's on the Menu?, New York Public Library | Menús históricos con platillos y precios | [ClickHouse](<https://clickhouse.com/docs/get-started/sample-datasets/menus>) lo describe como dominio público; no se pudo confirmar, porque `menus.nypl.org/data` respondió 404 | Descartado: son menús históricos, sin ingredientes |

`FNDDS` son las siglas de *Food and Nutrient Database for Dietary Studies*.

## Decisión

Los datos se buscaron primero en el propio caso de estudio, como pide la práctica. Del salón de eventos se obtuvo su menú vigente; el salón no tiene recetas fijas ni registros de pedidos que compartir. Por eso cada tabla sale de donde hay datos:

| Tablas | De dónde salen | Tipo |
| :-- | :-- | :-- |
| `producto` | Menú del salón de eventos y variantes conocidas por un integrante que trabajó ahí | Real, con 10 precios estimados |
| `ingrediente`, `receta` | Estimadas a partir del menú, con los gramos de FNDDS donde el platillo coincide | Estimadas |
| `usuario` y sus subtipos, `evento`, `mesa`, `cuenta`, `comanda`, `pago`, `anticipo`, `paquete` y el resto | Script de generación, con semilla fija | **Sintéticas** |

## Catálogo del salón de eventos

| Concepto | Valor |
| :-- | :-- |
| Referencia (APA 7) | salón de eventos. (2026). *Menú de alimentos y bebidas* [Fotografías]. Fotografías tomadas el 3 de noviembre de 2026 |
| Permiso | El menú no publica una licencia. **Falta confirmar con el salón** que se puede publicar en este repositorio |
| Formato original | 2 fotografías JPG: [alimentos](<datos/salon/menu-alimentos.jpg>) y [bebidas](<datos/salon/menu-bebidas.jpg>), 354 KB en total |
| Transcripción | [`datos/salon/productos.csv`](<datos/salon/productos.csv>): 122 renglones, de los que 28 son productos principales con variantes |
| Campos | `id_producto`, `nombre`, `descripcion`, `categoria`, `precio`, `id_producto_principal`, `origen_precio` |

Ningún renglón trae datos personales. La línea de contacto de las fotografías es la del negocio.

### Correspondencia con el esquema

| Dato del menú | Tabla y columna | Cómo se tomó |
| :-- | :-- | :-- |
| Nombre del producto | `producto.nombre` | Se transcribe. Si un renglón agrupa sabores o marcas, cada uno es una variante |
| Texto entre paréntesis | `producto.descripcion` | Solo si describe el producto y no lista sus variantes |
| Sección *Alimentos* | `producto.categoria = 'alimentos'` | Botanas de la sección pasan a `dulceria`: papas, churritos, palomitas y fritura |
| Sección *Bebidas* | `producto.categoria = 'bebidas'` | Se transcribe |
| Precio | `producto.precio` | Se transcribe; `origen_precio` indica si viene del menú o se estimó |
| Agrupación por sabor, marca o tamaño | `producto.id_producto_principal` | Apunta al producto principal, con un solo nivel, como exige `tg_producto_variante` |
| "Aceptamos todas las tarjetas" | Ninguna | No se usa: `pago.forma_pago` ya admite `tarjeta` |
| "Recargas telefónicas $2" | Ninguna | No se usa: no es un producto de la carta |
| "Vaso escarchado $5" | `producto` | Se registra como producto aparte |

### Qué venía mal y qué se decidió

| Problema | Decisión |
| :-- | :-- |
| Las fotografías no son datos estructurados | Se transcribieron a mano a un CSV |
| Un mismo renglón agrupa varios productos, como "Tacos (Bistec, Longaniza, Campechanos)" | Un producto principal y una variante por cada opción |
| El precio de `$35` queda entre "Jugos del Valle" y "Refrescos de 600 ml" | Se toma como el precio de los dos renglones |
| Los extras, como "Queso + $5", no son productos | Cada combinación es una variante con el precio ya sumado |
| El menú no indica el precio de las medias órdenes, salvo la mitad de chicharrón (`$30` de `$50`) | Se estiman con esa misma proporción, 60 %, redondeada a múltiplos de 5, y se marcan como `estimado` |
| No se recuerda el precio extra de la caguama preparada | Se estima en `$10`, igual que el Clamato de la michelada, y se marca como `estimado` |
| Los productos principales, como "Tacos", no se piden como tales | Se conservan para agrupar variantes; la generación solo pide productos sin variantes |

### Variantes que no aparecen en el menú

Las conoce un integrante que trabajó en el salón:

- Media orden de sincronizadas, chilaquiles, mini ensalada, tenders y alambre.
- Agua y refrescos fríos o al tiempo.
- Micheladas con Clamato, por `$10` más.
- Caguama preparada, con salsas y Clamato.

El catálogo tiene menos de 200 renglones porque ese es el tamaño real del menú. Inflarlo con productos inventados haría falsa la fuente.
