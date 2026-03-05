# Especificación: Generación de CSV para análisis de estrategia ORB

## Objetivo

El Expert Advisor debe generar automáticamente un archivo **CSV de investigación** que registre información detallada de cada operación cerrada.
Este archivo se utilizará posteriormente para realizar **análisis estadístico del comportamiento de la estrategia de ruptura de rango (ORB)** y poder detectar patrones que expliquen pérdidas o mejoras potenciales.

El objetivo del archivo es permitir estudiar:

* Winrate según tamaño del rango
* Winrate según volatilidad del mercado
* Rendimiento por día de la semana
* Rendimiento por mes
* Impacto de la distancia de ruptura
* Contexto de volatilidad previo

El archivo se utilizará para **investigación cuantitativa y optimización del robot**.

---

# Organización del código

Toda la lógica de generación y escritura del CSV debe estar **en un fichero independiente del EA principal**, con el objetivo de mantener el código organizado y modular.

Ejemplo de estructura:

```
EA_Principal.mq5
csv_trade_logger.mqh
```

El archivo `csv_trade_logger.mqh` contendrá toda la lógica relacionada con:

* creación del CSV
* escritura de encabezados
* escritura de filas de datos
* gestión de archivos

El EA principal únicamente llamará a las funciones necesarias cuando una operación se cierre.

---

# Ubicación del archivo CSV

El archivo CSV debe guardarse en la siguiente ruta:

```
MQL5\Experts\custom\probadorEstrategiasRupturaRango\tests
```

---

# Nombre del archivo

El nombre del archivo debe depender de un **parámetro configurable del EA**.

Parámetro:

```
nombre_estrategia
```

El archivo generado será:

```
<nombre_estrategia>.csv
```

Ejemplo:

```
ORB_NASDAQ_v1.csv
```

Esto permite que múltiples versiones de la estrategia generen **datasets independientes**.

---

# Creación del archivo

Si el archivo **no existe**, el sistema debe:

1. Crear el archivo
2. Escribir la primera línea con los encabezados

Si el archivo **ya existe**, el sistema debe:

* abrir el archivo
* añadir nuevas filas al final
* **sin borrar datos anteriores**

---

# Momento de registro del trade

El robot debe registrar los datos **cuando una operación se cierre** (TP o SL).

Esto asegura que cada fila contenga:

* resultado final
* puntos ganados o perdidos
* resultado en múltiplos de riesgo (R)

Cada fila representa **una operación cerrada**.

---

# Estructura del CSV

La primera línea del archivo debe contener los encabezados:

```
Date,Time,Direction,EntryPrice,StopLoss,TakeProfit,ResultPoints,ResultR,OpeningRangeSize,ATR,YesterdayRange,DistanceBreakout,DayOfWeek,Month
```

---

# Descripción de los campos

## Date

Fecha en la que se abrió la operación.

Formato:

```
YYYY.MM.DD
```

Ejemplo:

```
2024.03.05
```

---

## Time

Hora de entrada de la operación.

Formato:

```
HH:MM
```

Ejemplo:

```
09:35
```

---

## Direction

Dirección de la operación.

Valores posibles:

```
LONG
SHORT
```

---

## EntryPrice

Precio exacto de entrada de la operación.

Ejemplo:

```
18350.25
```

---

## StopLoss

Precio del Stop Loss.

---

## TakeProfit

Precio del Take Profit.

---

## ResultPoints

Resultado final de la operación expresado en puntos.

Ejemplos:

```
+30
-30
```

Cálculo:

Para largos:

```
ExitPrice - EntryPrice
```

Para cortos:

```
EntryPrice - ExitPrice
```

---

## ResultR

Resultado expresado en múltiplos de riesgo (R).

Ejemplo:

```
+1
-1
```

Cálculo:

```
ResultPoints / StopDistance
```

donde

```
StopDistance = abs(EntryPrice - StopLoss)
```

---

## OpeningRangeSize

Tamaño del rango de apertura utilizado por la estrategia.

Cálculo:

```
OpeningRangeHigh - OpeningRangeLow
```

Este valor es clave para analizar si determinados tamaños de rango generan más pérdidas.

---

## ATR

Valor del ATR del mercado en el momento de la entrada.

Recomendado:

```
ATR(14)
```

Timeframe recomendado:

```
M5 o M15
```

Esto permite analizar el impacto de la volatilidad.

---

## YesterdayRange

Rango total del día anterior.

Cálculo:

```
HighYesterday - LowYesterday
```

Sirve para identificar si el mercado viene de un día con alta o baja volatilidad.

---

## DistanceBreakout

Distancia entre el precio de entrada y el nivel de ruptura del rango.

Cálculo:

Para largos:

```
EntryPrice - OpeningRangeHigh
```

Para cortos:

```
OpeningRangeLow - EntryPrice
```

Esto permite analizar si entrar demasiado lejos del rango provoca más pérdidas.

---

## DayOfWeek

Día de la semana.

Valores posibles:

```
Monday
Tuesday
Wednesday
Thursday
Friday
```

Esto permite detectar si la estrategia funciona peor en determinados días.

---

## Month

Mes del año.

Valores:

```
January
February
March
April
May
June
July
August
September
October
November
December
```

Esto permitirá identificar periodos largos negativos.

---

# Ejemplo de filas del CSV

```
Date,Time,Direction,EntryPrice,StopLoss,TakeProfit,ResultPoints,ResultR,OpeningRangeSize,ATR,YesterdayRange,DistanceBreakout,DayOfWeek,Month
2024.03.05,09:35,LONG,18350,18320,18380,30,1,12,35,120,1.5,Tuesday,March
2024.03.06,09:35,SHORT,18410,18440,18380,-30,-1,6,28,90,0.8,Wednesday,March
2024.03.07,09:35,LONG,18290,18260,18320,30,1,18,40,150,2.1,Thursday,March
```

---

# Uso del dataset

Una vez generados suficientes datos (idealmente **200-500 trades**), el archivo permitirá analizar:

* Winrate según tamaño del rango
* Impacto de la volatilidad (ATR)
* Rendimiento por día de la semana
* Rendimiento por mes
* Condiciones de mercado que generan rachas negativas

Este dataset se utilizará para **diseñar filtros estadísticos que mejoren el sistema sin modificar su lógica principal**.
