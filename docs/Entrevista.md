# Entrevista con el Cliente

---

## Tabla de Contenidos

- [Eventos y mesas](#eventos-y-mesas)
- [Menu y productos](#menu-y-productos)
- [Flujo de comandas](#flujo-de-comandas)
- [Cobros y pagos](#cobros-y-pagos)
- [Roles y permisos](#roles-y-permisos)
- [Reportes](#reportes)
- [Operacion y escalabilidad](#operacion-y-escalabilidad)

---

Documento de trabajo para levantar los requerimientos del primer cliente del sistema de comandas: un salon de eventos. Las respuestas capturadas aqui se vaciaron despues en `docs/LaTeX/Secciones/CasoDeEstudio.tex`.

---

## Eventos y mesas

- ¿El salón atiende uno o varios eventos simultáneamente?
  - **R:** Se suele atender un único evento a la vez.
- ¿Cuántas mesas suelen usar por evento?
  - **R:** El número varia pero suelen ser alrededor de 20 mesas.
- ¿Esa cantidad varía entre eventos?
  - **R:** Si
- ¿Las mesas están numeradas?
  - **R:** Si cada mesa tiene su número
- ¿Todos los meseros atienden todas las mesas o se le asigna a cada mesero un número de mesas?
  - **R:** Dependiendo del evento aveces solo hay un mesero pero de ser multiples se asignan a cada mesero un grupo de mesas.

## Menu y productos

- ¿El menú es un todo incluido por evento o se atiende a la carta?
  - **R:** La carta es aparte, en los eventos se puede pedir comida preparada con antelación pero siempre esta la opción de la carta.
- ¿Qué categorías de productos manejan?
  - **R:** Alimentos, bebidas con y sin alcohol y dulcería.
- ¿Los productos tienen precio fijo?
  - **R:** Durante el evento si pero tienen tendencia a cambiar por temporada.
- ¿Se manejan variantes de platillos?
  - **R:** Si, algunas bebidas o platillos tienen tamaños distintos o preparación distintas
- ¿Se necesitan registrar ingredientes o alérgenos por producto, o solo nombre y precio?
  - **R:** Únicamente manejamos nombre y precio.
- ¿El menú cambia por temporada o es fijo todo el año?
  - **R:** Tenemos un menu fijo. 

## Flujo de comandas

- ¿Cómo levantan hoy en día una comanda? (papel, apps sueltas, ninguno)
  - **R:** Los meseros usan comandas de papel y las entregan con el responsable en caja.
- ¿Quién toma la orden: el mesero en la mesa o se centraliza en un punto?
  - **R:** Se centraliza en la barra donde esta el responsable de caja.
- ¿La comanda va directo a cocina o bar, o pasa por un supervisor?
  - **R:** Para por el responsable en caja.
- ¿Se necesita un estado para la comida? (pendiente, en preparación, lista, entregada, cancelada)
  - **R:** Si
- ¿Puede una mesa hacer varias rondas de pedidos durante un evento?
  - **R:** Si un cliente puede pedir varias veces durante un evento.
- ¿Se registran notas especiales por pedido?
  - **R:** De ser necesario si.
- ¿Quién puede cancelar o modificar una comanda ya enviada a cocina o bar?
  - **R:** El encargado de caja.

## Cobros y pagos

- ¿El cobro se hace al organizador del evento en una sola cuenta, o se divide por mesa, por invitado o por grupo de invitados?
  - **R:** Se puede manejar tanto como un solo cobro al organizador, un cobro por mesa, por invitado o por grupo de invitados. Aunque lo mas común es cobrar por grupo de invitados los cuales suele haber 2 o 3 por mesa (2 - 3 cuentas por mesa).
- ¿Manejan anticipos o depósitos antes del evento?
  - **R:** Si
- ¿Qué formas de pago se aceptan y necesitan quedar registradas?
  - **R:** Se aceptan pagos en efectivo, transferencia o tarjeta.
- ¿Se requiere factura fiscal (CFDI) o solo un recibo interno?
  - **R:** No
- ¿Hay productos incluidos en el paquete que no se cobren aparte?
  - **R:** Únicamente la comida preparada con antelación.
- De ser así, ¿el consumo extra sí se cobra?
  - **R:** Si el consumo extra a carta se cobra.

## Roles y permisos

- ¿Qué roles existen y qué debe poder hacer cada uno en el sistema? (mesero, cocina, bar, cajero, administrador)
  - **R:** Hay mesero, cocina, bar, y cajero/administradod.
- ¿Se necesita saber qué mesero levantó cada comanda?
  - **R:** Si es necesario saber que mesero hizo que orden y que cuentas lleva.

## Reportes

- ¿Qué reportes necesita el negocio? (ventas por evento, estadísticas por producto, tiempo promedio de preparación, ingresos por periodo)
  - **R:** Seria de utilidad aunque no necesario las ventas por evento y ingresos por evento.
- ¿Necesita comparar el consumo real contra lo presupuestado en el paquete del evento?
  - **R:** Si
- ¿Con qué frecuencia se consultan estos reportes? (durante el evento en vivo o solo en el cierre)
  - **R:** En su mayoría en el cierre pero también en el evento en vivo. 

## Operacion y escalabilidad

- ¿Cuántos eventos atienden en promedio al mes y cuántas comandas por evento?
  - **R:** Al rededor de quince eventos mensuales, y en un evento normal suelen ser entre 1 a 3 pedidos por cuenta pero esto se puede llegar a extender.
- ¿El sistema debe funcionar sin internet dentro del salón, o siempre tienen conexión?
  - **R:** Preferentemente que fusionase sin internet. 
- ¿Planean usar el sistema en otra sucursal a futuro?
  - **R:** No por el momento.
