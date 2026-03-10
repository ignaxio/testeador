# Documentación Técnica: Sistema de Trading ORB (Opening Range Breakout)

Este documento describe la arquitectura técnica, la estructura de datos y el funcionamiento del sistema de trading de ruptura de rango. El objetivo principal del sistema es la ejecución automatizada y la recolección de datos masiva para investigación cuantitativa.

---

## 1. Arquitectura del Proyecto

El proyecto está organizado de forma modular para separar la lógica de ejecución del análisis de datos y las pruebas:

- **`Include/`**: Contiene el motor lógico y servicios comunes.
  - `RupturaEngine.mqh`: Motor principal de la estrategia.
  - `TimeService.mqh`: Gestión dinámica de horarios y DST (Summer/Winter time).
  - `csv_trade_logger.mqh`: Servicio de registro de operaciones en formato CSV.
  - `GestionRiesgo.mqh`: Cálculos de lotaje y gestión dinámica de Stop Loss.
  - `Filtros.mqh`: Validaciones de entrada (tamaño de rango, volatilidad, etc.).
- **Raíz del Proyecto**:
  - `EstrategiaRupturaGenerica.mq5`: EA base parametrizable para nuevas investigaciones.
  - `london-10-am-.../`: Carpeta con implementaciones específicas (ej. Estrategia Institucional).
- **`tests/`**: Scripts de validación.
  - `TestTimeService.mq5`: Validador de cambios de hora históricos.

---

## 2. Gestión de Tiempos y Horarios

El sistema utiliza un motor de tiempo avanzado (`CTimeService`) que permite dos modos de operación:

1.  **MODO_MERCADO**: El robot se sincroniza con una zona horaria específica (ej. `ZONE_LONDON`). Detecta automáticamente los cambios de horario de verano/invierno (DST) usando una tabla interna, evitando ajustes manuales del usuario.
2.  **MODO_BROKER**: El robot utiliza la hora del terminal de MetaTrader tal cual se muestra, sin ajustes automáticos.

**Importante:** En los registros de auditoría y archivos CSV, las horas (`TimeOpen`, `TimeClose`) se guardan siempre en **Hora del Broker** para facilitar la correlación directa con el gráfico del terminal.

---

## 3. Registro de Datos (Auditoría CSV)

El sistema genera automáticamente un archivo de investigación para análisis estadístico.

### Ubicación del archivo
Los archivos CSV se guardan en la carpeta **Common de MetaQuotes**. Esto permite que el archivo sea accesible desde cualquier terminal instalado en el PC y facilita su apertura en herramientas externas como Excel o Python sin conflictos de permisos.

**Ruta típica:**
`C:\Users\<Usuario>\AppData\Roaming\MetaQuotes\Terminal\Common\Files\`

### Estructura del CSV (Campos)
El archivo contiene los siguientes campos para cada operación cerrada:

| Campo | Descripción |
| :--- | :--- |
| **Date** | Fecha de apertura (YYYY.MM.DD) |
| **TimeOpen** | Hora exacta de entrada (HH:MM:SS) |
| **TimeClose** | Hora exacta de salida (HH:MM:SS) |
| **Direction** | LONG o SHORT |
| **EntryPrice** | Precio de ejecución de la entrada |
| **ResultPoints** | Puntos netos ganados o perdidos |
| **ResultR** | Resultado en múltiplos de riesgo (Profit / Riesgo Inicial) |
| **MAE_Points** | Máxima Excursión Adversa (cuánto estuvo en negativo) |
| **MFE_Points** | Máxima Excursión Favorable (cuánto estuvo en positivo) |
| **SMA200_Trend** | Tendencia en H1 según Media Móvil Simple de 200 periodos |
| **Breakout_Volume**| Volumen de la vela de ruptura |
| **Duration_Minutes**| Tiempo que la operación estuvo abierta |
| **OpeningRangeSize**| Tamaño total del rango de apertura en puntos |
| **ATR** | Volatilidad del mercado (ATR 14) al momento de entrar |
| **DistanceBreakout**| Distancia entre el nivel de ruptura y la entrada real |
| **DayOfWeek / Month**| Metadatos temporales para análisis estacional |

---

## 4. Guía de Análisis y Optimización

Basado en los datos recolectados, se recomiendan los siguientes puntos de análisis para mejorar la estrategia:

1.  **Filtro de Agotamiento:** Analizar el campo `OpeningRangeSize`. Si el rango es excesivamente grande (ej. > 8000 puntos), el precio suele estar agotado y el ratio 1:3 es estadísticamente menos probable.
2.  **Sweet Spot de Volatilidad:** Usar el `ATR` y `OpeningRangeSize` para encontrar el rango de volatilidad donde la estrategia tiene mayor "Follow-through". (Actualmente el "sweet spot" detectado está entre 2000 y 3300 puntos).
3.  **Análisis de Calidad (MAE/MFE):** Si el `MAE_Points` suele ser bajo en las operaciones ganadoras, indica que las entradas son precisas. Si el `MFE_Points` alcanza 2.5R pero termina en 1R, sugiere ajustar la gestión dinámica de beneficios.
4.  **Filtro de Tendencia Mayor:** Utilizar el campo `SMA200_Trend` para determinar si operar a favor de la tendencia de H1 aumenta significativamente el Winrate.

---

## 5. Mantenimiento del Sistema

- **Actualización de DST:** La tabla de fechas de cambio de hora en `Include/DSTData.mqh` debe revisarse anualmente (actualmente cubre hasta 2027).
- **Limpieza de Logs:** Si el archivo CSV crece demasiado, puede moverse o renombrarse; el robot creará uno nuevo automáticamente con los encabezados correspondientes.
