# Propuesta de Mejora de Rendimiento: Caché de Posiciones Gestionadas

## Descripción de la Tarea
Implementar un sistema de caché en memoria para las posiciones abiertas con el objetivo de reducir drásticamente las llamadas a las funciones de gestión de posiciones de MQL5 (`PositionGetDouble`, `PositionGetInteger`, etc.) y enriquecer los datos de auditoría en el CSV final con métricas de "recorrido" (MFE, MAE, R-Max) y filtros de entrada.

## 1. Estructura del Caché (`SPositionState`)
Para cada posición abierta por el EA, se mantendrá un objeto o estructura en memoria RAM:
- **Identificación**: `ticket` (Clave única).
- **Estado de Ejecución**: `gestionado_sl` (bool) para el Early Exit.
- **Datos de Apertura (Snapshots)**:
    - `precio_ent`, `sl_inicial`, `tp_inicial`.
    - **Filtros**: `sma200_val`, `vwap_val`, `atr_val`, `volumen_entrada`, `spread_entrada`.
- **Métricas de Recorrido (Live)**:
    - `r_maximo`: Ratio R:R máximo alcanzado.
    - `precio_max`: El precio más alto tocado durante la vida del trade.
    - `precio_min`: El precio más bajo tocado durante la vida del trade.

## 2. Optimización de Rendimiento
- **Early Exit**: Si `gestionado_sl == true`, saltamos la lógica de `AplicarGestionSLDinamico` inmediatamente.
- **Reducción de API**: Se usan los datos cacheados (`precio_ent`, `sl_inicial`) para cálculos de ratios en lugar de pedirlos al terminal en cada tick.
- **Cálculo Diferido**: El `mfe_pts` y `mae_pts` se calculan **solo una vez** al cerrar, usando el `precio_max` y `precio_min` registrados.

## 3. Trabajo Realizado
- [x] Definición del problema de rendimiento en `AplicarGestionSLDinamico`.
- [x] Decisión técnica: Usar un array de estructuras en memoria RAM.
- [x] Decisión analítica: Capturar filtros en el momento de la entrada para el CSV.
- [x] Optimización de métricas: R-Máximo se actualiza en vivo (comparación simple), MFE/MAE se calculan al cierre.
- [x] Implementación de la clase `CPositionCache` e integración en `CRupturaEngine`.
- [x] Integración con `CCSVTradeLogger` para volcar datos avanzados al CSV.
- [x] Aplicación de la lógica de Early Exit en `AplicarGestionSLDinamico`.

## 4. Siguientes Pasos (Finalizados)
1. **Definición de la Clase `CPositionCache`**: ✓
2. **Integración en `CRupturaEngine`**: ✓
3. **Integración con `CCSVTradeLogger`**: ✓
4. **Pruebas de Rendimiento**: Pendiente de ejecución por el usuario en backtest real.

## Beneficios Esperados
- **Velocidad**: >90% de ahorro en lógica de gestión de posiciones por tick.
- **Analítica**: Posibilidad de saber qué filtros (SMA, VWAP) funcionan mejor basándose en el R-Máximo y no solo en el resultado final.
