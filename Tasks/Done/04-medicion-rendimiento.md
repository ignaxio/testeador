# Tarea 04: Medición de Rendimiento y Tiempo de Ejecución (Profiling)

## Estado: Done
**Prioridad:** Media
**Objetivo:** Implementar un sistema de medición para conocer el tiempo exacto que tarda el robot en procesar cada tick y cada nueva vela, permitiendo identificar cuellos de botella.

## Implementación Realizada
1.  **Benchmarking Interno:**
    *   Se ha añadido la función `GetMicrosecondCount()` en el `OnTick` de `RupturaEngine.mqh`.
    *   Se calcula el tiempo de ejecución de cada tick, manteniendo el tiempo máximo y el promedio.
    *   Los resultados se muestran en el comentario del gráfico cada 100 ticks para minimizar el impacto en el rendimiento.

2.  **Control por Input:**
    *   Se ha añadido el parámetro `InpProfiling` en `UnifiedEA.mq5` para activar o desactivar la medición.

3.  **Resultados Esperados:**
    *   **Último:** Tiempo del último tick procesado (en microsegundos).
    *   **Máximo:** El tick más lento detectado desde el inicio del EA.
    *   **Promedio:** Media de todos los ticks procesados.

## Cómo usar el Profiler de MetaEditor (Análisis Externo)
Para un análisis más profundo de qué líneas de código específicas son lentas:
1.  Abre MetaEditor.
2.  Ve al menú **Debug -> Start Profiling** (o pulsa Alt+F5).
3.  Selecciona el EA y configura el Probador de Estrategias.
4.  Deja que corra unos minutos y detén la prueba.
5.  Se abrirá una pestaña "Profiler" abajo, mostrando el tiempo exacto consumido por cada función y línea de código.

## Beneficios Obtenidos
*   Ahora podemos cuantificar si una optimización (como el cacheo de filtros de la Tarea 03) realmente reduce el tiempo promedio de ejecución.
*   Detección inmediata de picos de latencia que podrían afectar la ejecución de órdenes en mercados volátiles.
