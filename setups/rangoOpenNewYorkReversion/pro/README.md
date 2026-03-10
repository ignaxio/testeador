# Rango Open New York Reversión (PRO) - 14:30 (Broker) / 09:15 (NY)

Este robot de trading automatizado opera la reversión de la ruptura del rango de apertura de Nueva York. Está diseñado para operar en la temporalidad de 2 minutos (M2) sobre el NASDAQ (US100), aprovechando el agotamiento de los movimientos iniciales de apertura para buscar una vuelta al promedio.

### Información del Proyecto
- **Autor:** Ignasi Farré
- **Copyright:** 2026
- **Estrategia:** Reversión de Ruptura de Rango de Apertura (Opening Range Reversion)
- **Activo:** US100
- **Versión:** 3.0 (Producción)

### Configuración del Rango (M2)
- **Temporalidad:** 2 Minutos (M2).
- **Referencia Horaria:** Mercado Nueva York (New York Session).
- **Hora Inicio Rango:** 09:15 (NY Time) / 14:15 (Broker standard).
- **Hora Fin Rango:** 09:30 (NY Time) / 14:30 (Broker standard).

### Parámetros Operativos
- **Horario de Entrada:** De 09:31 a 11:00 (NY Time).
- **Dirección:** Reversión (vende si rompe por arriba, compra si rompe por abajo).
- **Cierre de Sesión:** Cierre forzoso a las 14:30 (NY Time) si el trade sigue abierto.
- **Identificación de Logs:** `ny-reversion-pro-v3`

### Gestión de Riesgo (Optimizado)
- **Riesgo por Operación:** 1% fijo del balance (o lote fijo 0.1 configurable).
- **Ratio Objetivo (TP):** 1:3 (3.0).
- **Stop Loss:** 6000 puntos (fijo).
- **Take Profit:** 18000 puntos (fijo).

### Filtros y Optimización (v3.0)
Tras un análisis exhaustivo de más de 300 operaciones, se han aplicado los siguientes filtros de alta probabilidad:
1. **Filtro de Exclusión de Rango:** No se opera si el rango de apertura tiene un tamaño entre **3100 y 4500 puntos**, ya que estadísticamente en esa zona la probabilidad de continuación es mayor que la de reversión.
2. **Descarte de Filtros Ineficientes:** Se han eliminado los filtros de VWAP y Londres por reducir el volumen de operaciones sin mejorar la esperanza matemática.

### Variantes Incluidas
- `rangoOpenNewYorkReversion.mq5`: Versión general para toda la semana.
- `rangoOpenNewYorkReversionFridays.mq5`: Versión especializada solo para los viernes (día con mejor desempeño estadístico: Winrate 42%, PF 2.0).

### Análisis de Datos
El proceso de investigación completo se encuentra documentado en:
- `setups/rangoOpenNewYorkReversion/test/posibles-filtros.md`
- Datos brutos en la carpeta `csv/`.
