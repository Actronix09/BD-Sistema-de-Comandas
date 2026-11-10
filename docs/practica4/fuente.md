# Fuente de Datos del Sistema de Comandas

En este documento se registra de dónde salen los datos con los que se puebla la base del sistema de comandas: dónde se buscó, con qué términos, qué se encontró y qué se decidió con cada conjunto.

---

**Proyecto:** Sistema de Comandas Profesional

**Contenido:** Búsqueda de conjuntos de datos publicados, decisión tomada, catálogo del salón de eventos, recetas estimadas con FNDDS, y datos sintéticos e inventados.

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
| `producto` (122 de 214) | Menú del salón de eventos y variantes conocidas por un integrante que trabajó ahí | Real |
| `producto` (92 de 214), `ingrediente` (123 de 208) | Script de generación, para pasar de 200 renglones | **Inventados** |
| `ingrediente` (85 de 208), `receta` (292 de 681) | Estimadas a partir del menú, con los gramos de FNDDS donde el platillo coincide | Estimadas |
| `usuario` y sus subtipos, `evento`, `mesa`, `cuenta`, `comanda`, `pago`, `anticipo`, `paquete` y el resto | Script de generación, con semilla fija | **Sintéticas** |

## Catálogo del salón de eventos

| Concepto | Valor |
| :-- | :-- |
| Referencia (APA 7) | Salón de eventos del caso de estudio. (2026). *Menú de alimentos y bebidas* [Fotografías]. Fotografías tomadas el 3 de noviembre de 2026. El nombre del salón se omite en este repositorio |
| Permiso | El salón dio permiso para publicar su menú en este repositorio. No publica una licencia, así que el permiso solo cubre este uso |
| Formato original | 2 fotografías JPG: [alimentos](<../../sql/datos/salon/menu-alimentos.jpg>) y [bebidas](<../../sql/datos/salon/menu-bebidas.jpg>), 383 KB en total, con el nombre, el logotipo y los datos de contacto del salón tapados |
| Transcripción | [`sql/datos/salon/productos.csv`](<../../sql/datos/salon/productos.csv>): 122 renglones: 102 se piden y 20 solo agrupan variantes |
| Campos | `id_producto`, `nombre`, `descripcion`, `categoria`, `precio`, `id_producto_principal`, `origen_precio`, `se_pide` |

Ningún renglón trae datos personales. Tampoco se publica nada que identifique al salón.

### Correspondencia con el esquema

| Dato del menú | Tabla y columna | Cómo se tomó |
| :-- | :-- | :-- |
| Nombre del producto | `producto.nombre` | Se transcribe. Si un renglón agrupa sabores o marcas, cada uno es una variante |
| Texto entre paréntesis | `producto.descripcion` | Solo si describe el producto y no lista sus variantes |
| Sección *Alimentos* | `producto.categoria = 'alimentos'` | Botanas de la sección pasan a `dulceria`: papas, churritos, palomitas y fritura |
| Sección *Bebidas* | `producto.categoria = 'bebidas'` | Se transcribe |
| Precio | `producto.precio` | Se transcribe; `origen_precio` indica si viene del menú o lo confirmó un integrante |
| Agrupación por sabor, marca o tamaño | `producto.id_producto_principal` | Apunta al producto principal, con un solo nivel, como exige `tg_producto_variante` |
| "Aceptamos todas las tarjetas" | Ninguna | No se usa: `pago.forma_pago` ya admite `tarjeta` |
| "Recargas telefónicas $2" | Ninguna | No se usa: no es un producto de la carta |
| "Vaso escarchado $5" | `producto` | Se registra como producto aparte |

### Qué venía mal y qué se decidió

| Problema | Decisión |
| :-- | :-- |
| Las fotografías no son datos estructurados | Se transcribieron a mano a un CSV |
| Las fotografías traen el nombre, el logotipo, el teléfono y la página del salón | Se taparon con recuadros negros antes de subirlas |
| Un mismo renglón agrupa varios productos, como "Tacos (Bistec, Longaniza, Campechanos)" | Un producto principal y una variante por cada opción |
| El precio de `$35` queda entre "Jugos del Valle" y "Refrescos de 600 ml" | Son productos distintos con el mismo precio, según confirmó un integrante que trabajó en el salón |
| Los extras, como "Queso + $5", no son productos | Cada combinación es una variante con el precio ya sumado |
| El menú no indica el precio de las medias órdenes, salvo la mitad de chicharrón, ni el de la caguama preparada | Los confirmó un integrante que trabajó en el salón; `origen_precio` vale `integrante` |
| Algunos productos principales, como "Tacos", no se piden como tales | Se conservan para agrupar variantes, con `se_pide = no`, y no llevan receta. Los que tienen una media orden o Clamato, como "Alambre", sí se piden |

### Variantes que no aparecen en el menú

Las conoce un integrante que trabajó en el salón:

- Media orden de sincronizadas, chilaquiles, mini ensalada, tenders y alambre.
- Agua y refrescos fríos o al tiempo.
- Micheladas con Clamato, por `$10` más.
- Caguama preparada, con salsas y Clamato.

Estos 122 productos son los únicos reales. Los demás del catálogo son inventados y se explican en [Productos e ingredientes inventados](#productos-e-ingredientes-inventados).

## Recetas e ingredientes

El salón no tiene recetas fijas, así que las 292 filas de [`sql/datos/salon/recetas.csv`](<../../sql/datos/salon/recetas.csv>) y los 85 renglones de [`sql/datos/salon/ingredientes.csv`](<../../sql/datos/salon/ingredientes.csv>) **son una estimación**, no las recetas reales del salón. La columna `origen` dice de dónde sale cada fila:

| `origen` | Qué significa | Filas |
| :-- | :-- | :--: |
| `menu` | El menú o la variante nombra el ingrediente o da la cantidad (arrachera de 150 g, 3 piezas de hot dog, una botella de 355 ml). Si el menú solo nombra el ingrediente, la cantidad se estimó | 81 |
| `fndds:<código>` | La cantidad sale de la composición y la porción de ese alimento en FNDDS | 41 |
| `estimada` | Cantidad razonable para el platillo, sin una fuente publicada | 170 |

Las medias órdenes llevan la mitad de cada ingrediente. Los 20 productos que solo agrupan variantes no tienen receta. Los nombres de los ingredientes están en español para que coincidan con el menú.

### Conjunto de referencia: FNDDS

| Concepto | Valor |
| :-- | :-- |
| Referencia (APA 7) | U.S. Department of Agriculture, Agricultural Research Service. (2024). *FoodData Central: Food and Nutrient Database for Dietary Studies 2021-2023* (versión de octubre de 2024) [Conjunto de datos]. Consultado el 3 de noviembre de 2026, de <https://fdc.nal.usda.gov/download-datasets/> |
| Licencia | CC0 1.0: "USDA FoodData Central data are in the public domain and they are not copyrighted". No hace falta permiso, pero se pide citar la fuente |
| Formato original | ZIP con 12 archivos CSV y 1 XLSX |
| Tamaño | 3.3 MB comprimido y 25.5 MB sin comprimir: [`sql/datos/fndds/`](<../../sql/datos/fndds>) |
| Registros | 5,432 alimentos, 18,584 renglones de ingredientes y 22,046 porciones |

### Correspondencia con el esquema

El conjunto no se carga a la base. Solo se usan sus proporciones en las filas marcadas con `fndds:`.

| Archivo y campo | Tabla y columna | Cómo se usa |
| :-- | :-- | :-- |
| `food.description` | Ninguna | Para encontrar el platillo equivalente |
| `survey_fndds_food.food_code` | `recetas.csv`, columna `origen` | Es el código que se cita |
| `input_food.sr_description` | `ingrediente.nombre` | Se traduce a mano al ingrediente equivalente |
| `input_food.gram_weight` | `receta.cantidad_por_porcion` | Da el porcentaje de cada ingrediente en el platillo |
| `food_portion.gram_weight` | `receta.cantidad_por_porcion` | Da el peso de una porción; se multiplica por el porcentaje |
| `input_food.amount`, `unit`, `portion_code`, `portion_description` | Ninguna | No se usan: `gram_weight` ya trae la cantidad en gramos |
| `input_food.retention_code`, `food_nutrient`, `nutrient` y demás archivos | Ninguna | No se usan: son datos de nutrición |

| Platillo del menú | Código FNDDS | Alimento | Porción usada |
| :-- | :-- | :-- | :-- |
| Tacos de bistec y con queso | 58102010 | Taco, corn tortilla, beef, cheese | 105 g |
| Tacos de longaniza | 58102030 | Taco, corn tortilla, pork, cheese | 105 g |
| Sincronizadas | 58104710 | Quesadilla, cheese only | 120 g |
| Chilaquiles con bistec | 58100360 | Chilaquiles | 170 g, sin el huevo |
| Tenders de pollo | 24198731 | Chicken nuggets, from fast food | 140 g |
| Nachos | 58104120 | Nachos, cheese only | 250 g |
| Chicharrón preparado | 22709010 | Pork skin rinds | 2 tazas de 30 g |

### Qué venía mal y qué se decidió

| Problema | Decisión |
| :-- | :-- |
| Las cantidades vienen en varias unidades: 14,137 renglones en gramos, el resto en tazas, cucharadas, libras y otras, o sin unidad (1,125) | Se usa `gram_weight`, que no tiene vacíos ni valores menores o iguales a 0 |
| La suma de gramos de una receta va de 3 a 7,729 g porque unas son por tanda | Se convierte a porcentaje y se multiplica por la porción |
| 1,602 alimentos tienen un solo ingrediente, a veces otro alimento preparado | Solo se eligieron alimentos con su composición completa, salvo tenders y chicharrón, que se toman como ingrediente único |
| 38 pares de alimento e ingrediente se repiten | No afecta: ninguno está entre los 7 códigos usados |
| 1 alimento no tiene ingredientes | No se usa |
| Los alimentos son de la dieta de Estados Unidos | Se usa la composición aproximada; `jitomate`, `queso` y demás son el equivalente local |

## Datos sintéticos

Los datos de operación y una parte del catálogo **son sintéticos**. Se generan porque, como consta en [Dónde se buscó](#dónde-se-buscó), no existe un conjunto publicado con comandas de un salón de eventos, y el salón no tiene registros que compartir. Se generan con un solo comando y una semilla fija, así que dos corridas producen los mismos archivos:

```bash
python3 sql/carga/generar_datos.py
```

Las **tablas principales** son las que registran el catálogo, a las personas y la operación. Todas superan los 200 renglones. Las demás acompañan a estas.

| Tabla | Renglones | Principal |
| :-- | :--: | :-- |
| `producto` | 214 (122 reales y 92 inventados) | Sí |
| `ingrediente` | 208 (85 del menú y 123 inventados) | Sí |
| `receta` | 681 (292 del menú y 389 inventadas) | Sí |
| `usuario` | 200 | Sí |
| `evento` | 240 | Sí |
| `anticipo` | 343 | Sí |
| `mesa` | 3,943 | Sí |
| `cuenta` | 7,515 | Sí |
| `comanda` | 37,528 | Sí |
| `pago` | 9,640 | Sí |
| `mesero`, `bar_cocina`, `cajero_admin` | 130, 45 y 25 | Subtipos de `usuario` |
| `evento_organizador`, `acuerdo` | 360 y 625 | Dependen de `evento` |
| `paquete`, `paquete_producto` | 12 y 100 | Catálogo de paquetes |

### Productos e ingredientes inventados

El menú real tiene 122 productos y sus recetas llegan a 85 ingredientes. Para pasar de 200 renglones en esas tablas, el generador agrega **92 productos y 123 ingredientes inventados, que no existen en el salón de eventos**. Sus recetas también son inventadas: sirven para probar la base, no describen ningún platillo real.

| Cómo distinguirlos | Dónde |
| :-- | :-- |
| Columna `origen`: `salon` o `inventado` | `sql/datos/generados/producto.csv` e `ingrediente.csv` |
| Columna `origen`: `inventada` | `sql/datos/generados/receta.csv` |
| Texto "Producto inventado, no está en el menú del salón" | `producto.descripcion`, ya dentro de la base |
| Número de identificador: los productos inventados van del 123 al 214, y los ingredientes, del 86 al 208 | `id_producto`, `id_ingrediente` |

Los ingredientes no tienen columna de descripción en el esquema, así que dentro de la base solo se distinguen por su identificador. De los productos inventados, 60 son alimentos, 20 son bebidas y 12 son de dulcería. En la generación, los productos reales se piden el doble: 26,933 de las 37,528 comandas son de productos reales.

Para que las restricciones los acepten y una consulta devuelva algo interesante, el generador cuida lo siguiente:

| Regla del esquema | Qué hace el generador |
| :-- | :-- |
| `tg_comanda_estacion` | Las bebidas las prepara el bar; los alimentos y la dulcería, la cocina |
| `tg_pago_saldo`, `tg_cuenta_cierre` | Cada cuenta de un evento finalizado se paga exacta, en uno o dos pagos, y queda en saldo 0 |
| `ck_pago_propina_limite`, `ck_pago_propina_completa` | La mitad de los pagos lleva una propina de 5 % a 15 %, con su mesero |
| `ck_comanda_cancelacion`, `ck_comanda_preparacion` | El 3 % de las comandas se cancela, con su cajero; solo una parte llegó a prepararse |
| `tg_comanda_stock`, `ck_ingrediente_stock` | El stock inicial es lo que se consume más un remanente; 67 ingredientes terminan por debajo de su mínimo |
| `ux_cuenta_nombre_abierta` | Las cuentas de una mesa tienen nombres distintos |
| `ct_usuario_total` | Cada usuario tiene su fila en el subtipo de su rol |

Los eventos van de enero de 2023 a diciembre de 2026, tomando como hoy el 3 de noviembre de 2026: 224 finalizados, 6 cancelados, 1 en curso y 9 programados. Los nombres de personas se forman al azar con listas comunes y **no corresponden a personas reales**. Las contraseñas tampoco: el campo `contrasena_hash` lleva un texto fijo, así que estos usuarios no pueden entrar al sistema.

### Comprobación

Los archivos se cargaron con los disparadores activos en una base temporal, con `sql/esquema.sql` recién ejecutado y una sola transacción. Se aceptaron todos los renglones:

| Comprobación | Resultado |
| :-- | :--: |
| Ingredientes con stock negativo | 0 |
| Cuentas cerradas con saldo distinto de 0 | 0 |
| Comandas con un precio distinto al del catálogo | 0 |
| Ingredientes por debajo de su mínimo | 67 |
| Pagos con propina | 4,823 |
