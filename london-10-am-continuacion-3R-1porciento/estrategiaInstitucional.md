# Estrategia Institucional - London 10 AM (Continuación)

Esta estrategia opera la ruptura del rango de apertura de Londres con parámetros optimizados para una gestión profesional del riesgo y filtros avanzados de entrada.

### Gestión del Tiempo
- **Modo Horario:** `MODO_BROKER` (Usa la hora exacta que muestra el terminal de MT5, sin ajustes automáticos).
- **Referencia de Mercado:** Si se cambia a `MODO_MERCADO`, la zona de referencia es `ZONE_LONDON` (ajusta automáticamente el horario de verano/invierno).

### Configuración del Rango (M2)
- **Temporalidad:** 2 Minutos (M2).
- **Hora Inicio Rango:** 09:00 (Hora del Broker).
- **Hora Fin Rango:** 09:30 (Hora del Broker).
- **Tamaño Mínimo:** 100 puntos.

### Configuración Operativa
- **Horario de Entrada:** De 09:31 a 12:00.
- **Dirección:** Continuación (compra si rompe por arriba, venta si rompe por abajo).
- **Cierre de Sesión:** Cierre forzoso de posiciones a las **20:30** (ajustado para coincidir con el código).

### Gestión de Riesgo
- **Riesgo por Operación:** 1% fijo del balance de la cuenta.
- **Ratio Objetivo (TP):** 1:3 (3.0).
- **Stop Loss Máximo:** 10,000 puntos (Funciona como protección de seguridad, el lote se calcula según el riesgo).
- **Gestión Dinámica (Breakeven):** Al alcanzar un ratio de **2.0R**, el Stop Loss se mueve automáticamente para cubrir el **50%** del riesgo inicial.

### Filtros de Entrada Aplicados
Para aumentar la probabilidad de éxito, se aplican los siguientes filtros:

1. **Filtro de Tamaño de Rango (Opening Range Size):**
   - **Mínimo:** 2000 puntos.
   - **Propósito:** Evitar operar en rangos excesivamente pequeños con baja volatilidad.

2. **Filtro de Exclusión de Rango (Zona Muerta):**
   - **Rango excluido:** Entre 3300 y 4700 puntos.
   - **Propósito:** Evitar zonas de volatilidad errática identificadas estadísticamente.

3. **Filtros Desactivados:**
   - Filtro de Volumen (Real Volume).
   - Filtro de Distancia de Ruptura Máxima.
