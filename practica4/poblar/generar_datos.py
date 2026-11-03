#!/usr/bin/env python3
# =====================================================================
#  generar_datos.py — Datos sintéticos del Sistema de Comandas
#  Práctica 4, Ejercicio 1.3 · Bases de Datos (3CV4)
#
#  Lee el catálogo real de practica4/datos/salon/ y genera en
#  practica4/datos/generados/ la operación que no existe publicada:
#  usuarios, eventos, mesas, cuentas, comandas, pagos y anticipos.
#
#      python3 practica4/poblar/generar_datos.py
#
#  Usa una semilla fija: dos corridas producen los mismos archivos.
#  Solo necesita la biblioteca estándar de Python.
# =====================================================================

import collections
import csv
import datetime as dt
import decimal
import pathlib
import random

SEMILLA = 22
# Fecha que se toma como "hoy": antes de ella los eventos ya terminaron.
CORTE = dt.date(2026, 11, 3)
ZONA = dt.timezone(dt.timedelta(hours=-6))

RAIZ = pathlib.Path(__file__).resolve().parents[1]
SALON = RAIZ / "datos" / "salon"
SALIDA = RAIZ / "datos" / "generados"

NUM_EVENTOS = 240
NUM_MESEROS = 130
NUM_COCINA = 25
NUM_BAR = 20
NUM_CAJEROS = 22
NUM_ADMINISTRADORES = 3

TIPOS_EVENTO = ["Boda", "XV años", "Baile", "Bautizo", "Graduación", "Posada", "Cumpleaños", "Empresarial"]
NOMBRES = ["Ana", "Luis", "María", "José", "Carmen", "Jorge", "Laura", "Miguel", "Rosa", "Pedro", "Elena", "Raúl", "Sofía",
           "Diego", "Paula", "Iván", "Julia", "Óscar", "Irene", "Hugo", "Marta", "Saúl", "Nora", "Tomás", "Alma", "Gael"]
APELLIDOS = ["García", "Hernández", "López", "Martínez", "González", "Pérez", "Rodríguez", "Sánchez", "Ramírez", "Cruz",
             "Flores", "Gómez", "Morales", "Vázquez", "Reyes", "Jiménez", "Torres", "Díaz", "Gutiérrez", "Ruiz",
             "Mendoza", "Aguilar", "Ortiz", "Castillo", "Romero", "Herrera"]
ALIAS_CUENTA = ["Novios", "Padrinos", "Familia", "Amigos", "Compañeros", "Invitados", "Primos", "Vecinos", "Tíos", "Abuelos"]
INDICACIONES = ["Sin cebolla", "Bien cocido", "Sin picante", "Extra limón", "Para llevar", "Sin hielo"]
FORMAS_PAGO = ["efectivo", "efectivo", "tarjeta", "tarjeta", "transferencia"]
PAQUETES = ["Básico", "Plata", "Oro", "Platino", "Diamante", "Infantil", "Botana", "Barra libre", "Tacos", "Antojitos",
            "Cerveza", "Sin alcohol"]


def leer(nombre):
    with open(SALON / nombre, encoding="utf-8", newline="") as archivo:
        return list(csv.DictReader(archivo))


def escribir(nombre, columnas, filas):
    with open(SALIDA / f"{nombre}.csv", "w", encoding="utf-8", newline="") as archivo:
        salida = csv.writer(archivo, lineterminator="\n")
        salida.writerow(columnas)
        salida.writerows(filas)
    return nombre, len(filas)


def nombre_persona(azar):
    return f"{azar.choice(NOMBRES)} {azar.choice(APELLIDOS)} {azar.choice(APELLIDOS)}"


def generar_usuarios(azar):
    """Reparte a los usuarios en sus subtipos: la especialización es total."""
    usuarios, meseros, cocina_bar, cajeros = [], [], [], []
    usados = set()

    def alta(rol):
        id_usuario = len(usuarios) + 1
        nombre = nombre_persona(azar)
        partes = nombre.lower().split()
        acceso = f"{partes[0][0]}{partes[1]}{id_usuario}".translate(str.maketrans("áéíóúñ", "aeioun"))
        assert acceso not in usados
        usados.add(acceso)
        nacimiento = dt.date(azar.randint(1965, 2006), azar.randint(1, 12), azar.randint(1, 28))
        # El hash no corresponde a ninguna contraseña: estos usuarios no pueden entrar.
        usuarios.append([id_usuario, nombre, acceso, nacimiento, "sintetico-sin-acceso", rol])
        return id_usuario

    for _ in range(NUM_MESEROS):
        meseros.append([alta("mesero"), azar.choice(["matutino", "vespertino", "nocturno"])])
    for estacion, cuantos in (("cocina", NUM_COCINA), ("bar", NUM_BAR)):
        for _ in range(cuantos):
            cocina_bar.append([alta("bar_cocina"), azar.choice(["ocupado", "desocupado"]), estacion])
    for i in range(NUM_CAJEROS + NUM_ADMINISTRADORES):
        nivel = "administrador" if i < NUM_ADMINISTRADORES else "cajero"
        cajeros.append([alta("cajero_admin"), nivel, azar.randint(1, 5)])
    return usuarios, meseros, cocina_bar, cajeros


def generar_paquetes(azar, pedibles):
    paquetes, contenido = [], []
    for numero, nombre in enumerate(PAQUETES, start=1):
        paquetes.append([numero, f"{azar.randint(4, 40) * 1000}.00", f"Paquete {nombre}"])
        for producto in azar.sample(pedibles, azar.randint(6, 12)):
            contenido.append([numero, producto["id_producto"]])
    return paquetes, contenido


def fecha_evento(azar, indice):
    """Reparte los eventos de 2023 a 2026; los últimos quedan en el futuro."""
    inicio = dt.date(2023, 1, 7)
    dias = (dt.date(2026, 12, 31) - inicio).days
    return inicio + dt.timedelta(days=dias * indice // NUM_EVENTOS + azar.randint(0, 3))


def estado_evento(azar, fecha):
    if fecha == CORTE:
        return "en_curso"
    if fecha > CORTE:
        return "programado"
    return "cancelado" if azar.random() < 0.04 else "finalizado"


def elegir_producto(azar, productos, pesos):
    return azar.choices(productos, weights=pesos, k=1)[0]


def generar_comandas_de_cuenta(azar, datos, evento, cuenta, mesero, inicio, consumo):
    """Levanta las comandas de una cuenta y va sumando lo que consumen."""
    estado_final = evento["estado"]
    total = 0
    hora = inicio
    for _ in range(azar.randint(2, 8)):
        datos["id_comanda"] += 1
        producto = elegir_producto(azar, datos["pedibles"], datos["pesos"])
        hora += dt.timedelta(minutes=azar.randint(2, 25))
        if azar.random() < 0.03:
            estado = "cancelada"
        elif estado_final == "en_curso":
            estado = azar.choice(["pendiente", "en_preparacion", "lista", "entregada"])
        else:
            estado = "entregada"

        estacion = "bar" if producto["categoria"] == "bebidas" else "cocina"
        prepara = ""
        if estado in ("en_preparacion", "lista", "entregada") or (estado == "cancelada" and azar.random() < 0.5):
            prepara = azar.choice(datos[estacion])
        cancela = azar.choice(datos["cajeros"]) if estado == "cancelada" else ""
        precio = decimal.Decimal(producto["precio"])

        datos["comandas"].append([
            datos["id_comanda"], hora.isoformat(), precio, estado,
            azar.choice(INDICACIONES) if azar.random() < 0.08 else "",
            evento["numero"], cuenta, mesero, producto["id_producto"], prepara, cancela,
        ])
        if estado != "cancelada":
            total += int(precio * 100)
        if estado in ("en_preparacion", "lista", "entregada"):
            consumo[producto["id_producto"]] += 1
    return total, hora


def generar_pagos(azar, datos, evento, cuenta, mesero, total, hora):
    """Paga el consumo exacto: la cuenta debe quedar en saldo 0 para cerrarse."""
    partes = [total]
    if total > 10000 and azar.random() < 0.3:
        primera = azar.randint(total // 4, total // 2) // 100 * 100
        partes = [primera, total - primera]
    for parte in partes:
        datos["id_pago"] += 1
        propina = azar.randint(5, 15) * parte // 100 if azar.random() < 0.5 else 0
        hora += dt.timedelta(minutes=azar.randint(5, 40))
        datos["pagos"].append([
            datos["id_pago"], f"{(parte + propina) / 100:.2f}", azar.choice(FORMAS_PAGO), hora.isoformat(),
            evento["numero"], cuenta, azar.choice(datos["cajeros"]),
            mesero if propina else "", f"{propina / 100:.2f}" if propina else "",
        ])


def generar_operacion(azar, pedibles, meseros, cocina_bar, cajeros, paquetes):
    datos = {
        "id_comanda": 0, "id_pago": 0, "comandas": [], "pagos": [], "pedibles": pedibles,
        # Las bebidas se piden más que los alimentos, como en un evento.
        "pesos": [3 if p["categoria"] == "bebidas" else 2 for p in pedibles],
        "cocina": [c[0] for c in cocina_bar if c[2] == "cocina"],
        "bar": [c[0] for c in cocina_bar if c[2] == "bar"],
        "cajeros": [c[0] for c in cajeros],
    }
    eventos, organizadores, acuerdos, anticipos, mesas, cuentas = [], [], [], [], [], []
    consumo = collections.Counter()
    ids_meseros = [m[0] for m in meseros]

    for indice in range(NUM_EVENTOS):
        numero = indice + 1
        fecha = fecha_evento(azar, indice)
        if indice == NUM_EVENTOS * (CORTE - dt.date(2023, 1, 7)).days // (dt.date(2026, 12, 31) - dt.date(2023, 1, 7)).days:
            fecha = CORTE  # Un solo evento en curso.
        estado = estado_evento(azar, fecha)
        asistentes = azar.randint(40, 300)
        eventos.append([numero, fecha, azar.choice(TIPOS_EVENTO), asistentes, estado])
        for _ in range(azar.randint(1, 2)):
            organizador = nombre_persona(azar)
            if [numero, organizador] not in organizadores:
                organizadores.append([numero, organizador])

        paquete = azar.choice(paquetes)
        if azar.random() < 0.6:
            for producto in azar.sample(pedibles, azar.randint(3, 6)):
                acuerdos.append([numero, paquete[0], producto["id_producto"], azar.randint(5, 80)])
        for _ in range(azar.randint(1, 2)):
            pago_previo = fecha - dt.timedelta(days=azar.randint(7, 60))
            anticipos.append([len(anticipos) + 1, f"{azar.randint(5, 40) * 100}.00", pago_previo, numero])

        if estado == "cancelado":
            continue

        evento = {"numero": numero, "estado": estado}
        num_mesas = max(4, asistentes // 10)
        secuencial = 0
        for numero_mesa in range(1, num_mesas + 1):
            mesero = azar.choice(ids_meseros)
            mesas.append([numero, numero_mesa, mesero])
            if estado == "programado":
                continue
            for alias in azar.sample(ALIAS_CUENTA, azar.randint(1, 3)):
                secuencial += 1
                inicio = dt.datetime(fecha.year, fecha.month, fecha.day, azar.randint(18, 21), azar.randint(0, 59), tzinfo=ZONA)
                total, hora = generar_comandas_de_cuenta(azar, datos, evento, secuencial, mesero, inicio, consumo)
                cerrar = estado == "finalizado"
                cuentas.append([numero, secuencial, numero_mesa, alias, "cerrada" if cerrar else "abierta"])
                if cerrar and total:
                    generar_pagos(azar, datos, evento, secuencial, mesero, total, hora)

    return eventos, organizadores, acuerdos, anticipos, mesas, cuentas, datos["comandas"], datos["pagos"], consumo


def generar_ingredientes(azar, ingredientes, recetas, consumo):
    """El stock inicial alcanza para todo lo preparado y deja un remanente."""
    gastado = collections.defaultdict(decimal.Decimal)
    for fila in recetas:
        gastado[fila["id_ingrediente"]] += decimal.Decimal(fila["cantidad_por_porcion"]) * consumo[fila["id_producto"]]
    filas = []
    for ingrediente in ingredientes:
        total = gastado[ingrediente["id_ingrediente"]]
        minimo = (total * azar.randint(2, 8) / 100).quantize(decimal.Decimal("0.001"))
        # Algunos quedan por debajo de su mínimo, para que haya que resurtirlos.
        remanente = minimo * azar.choice([decimal.Decimal("0.5"), 2, 3])
        filas.append([ingrediente["id_ingrediente"], ingrediente["nombre"], ingrediente["unidad_medida"],
                      (total + remanente).quantize(decimal.Decimal("0.001")), minimo])
    return filas


def main():
    azar = random.Random(SEMILLA)
    SALIDA.mkdir(parents=True, exist_ok=True)

    productos = leer("productos.csv")
    ingredientes = leer("ingredientes.csv")
    recetas = leer("recetas.csv")
    pedibles = [p for p in productos if p["se_pide"] == "si"]

    usuarios, meseros, cocina_bar, cajeros = generar_usuarios(azar)
    paquetes, contenido = generar_paquetes(azar, pedibles)
    eventos, organizadores, acuerdos, anticipos, mesas, cuentas, comandas, pagos, consumo = generar_operacion(
        azar, pedibles, meseros, cocina_bar, cajeros, paquetes)
    stock = generar_ingredientes(azar, ingredientes, recetas, consumo)

    conteos = [
        escribir("usuario", ["id_usuario", "nombre", "usuario", "fecha_nacimiento", "contrasena_hash", "rol"], usuarios),
        escribir("mesero", ["id_usuario", "turno_asignado"], meseros),
        escribir("bar_cocina", ["id_usuario", "estado", "estacion_asignada"], cocina_bar),
        escribir("cajero_admin", ["id_usuario", "nivel_acceso", "caja_asignada"], cajeros),
        escribir("ingrediente", ["id_ingrediente", "nombre", "unidad_medida", "stock_actual", "stock_minimo"], stock),
        escribir("paquete", ["numero_paquete", "monto", "detalles"], paquetes),
        escribir("paquete_producto", ["numero_paquete", "id_producto"], contenido),
        escribir("evento", ["numero_evento", "fecha", "tipo_evento", "numero_asistentes", "estado"], eventos),
        escribir("evento_organizador", ["numero_evento", "organizador"], organizadores),
        escribir("acuerdo", ["numero_evento", "numero_paquete", "id_producto", "cantidad_acordada"], acuerdos),
        escribir("anticipo", ["id_anticipo", "monto", "fecha", "numero_evento"], anticipos),
        escribir("mesa", ["numero_evento", "numero_mesa", "id_mesero"], mesas),
        escribir("cuenta", ["numero_evento", "secuencial", "numero_mesa", "nombre", "estado"], cuentas),
        escribir("comanda", ["id_comanda", "fecha_hora", "precio_cobrado", "estado", "detalles", "numero_evento",
                             "secuencial", "id_mesero", "id_producto", "id_bar_cocina", "id_cajero_cancela"], comandas),
        escribir("pago", ["numero_pago", "monto", "forma_pago", "fecha_hora", "numero_evento", "secuencial", "id_cajero",
                          "id_mesero_propina", "monto_propina"], pagos),
    ]
    for nombre, cuantos in conteos:
        print(f"{nombre:<20} {cuantos:>7}")


if __name__ == "__main__":
    main()
