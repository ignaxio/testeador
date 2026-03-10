# Guía de Usuario y Resumen de Cambios (v3.0) - Gestión Unificada

Este documento resume los cambios estructurales realizados en el proyecto y proporciona las instrucciones necesarias para operar el nuevo sistema de trading unificado.

---

### 1. Resumen de Cambios Principales

#### A. Refactorización a Objetos (POO)
El motor de la estrategia (`RupturaEngine.mqh`) ha sido transformado de un script procedimental a una clase orientada a objetos (`CRupturaEngine`).
*   **Impacto**: Ahora es posible cargar múltiples estrategias (ej. Londres y Nueva York) en el mismo gráfico sin que sus configuraciones interfieran entre sí.
*   **Encapsulación**: Cada instancia mantiene su propio rastro de trades, horarios y filtros.

#### B. Módulo de Gestión de Riesgo Unified (`CGestionRiesgoUnified`)
Se ha implementado un nuevo módulo avanzado en `GestionRiesgo.mqh` diseñado específicamente para superar cuentas de fondeo (Prop Firms).
*   **Límites Globales**: Control automático de `Daily Max Loss`, `Max Total Loss` y `Profit Target`.
*   **Riesgo Dinámico**: El robot ajusta el tamaño de la posición automáticamente:
    *   **Modo Safety**: Reduce el riesgo si nos acercamos al límite de pérdida diaria.
    *   **Modo Finish**: Ajusta el riesgo para asegurar que el último trade ganador nos lleve exactamente al objetivo del 10%.

#### C. EA Maestro: `UnifiedEA.mq5`
Este es el nuevo centro de mando. Ejecuta simultáneamente:
1.  **Londres Continuación** (Rango 10).
2.  **Nueva York Reversión**.
Ambas bajo una misma política de riesgo y balance de cuenta.

---

### 2. Organización del Proyecto

Para mantener un entorno profesional, se ha reorganizado la estructura de carpetas:
*   **`/Docs`**: Centraliza toda la documentación técnica, bitácoras de investigación y especificaciones.
*   **`/Include`**: Contiene los motores y utilidades compartidas (Filtros, Riesgo, Tiempo).
*   **`/setups`**: Contiene los EAs listos para usar y los análisis de resultados.

---

### 3. Lo que el Usuario debe saber

#### Configuración de Inputs en `UnifiedEA.mq5`
Al cargar el EA, verás tres grupos de parámetros críticos:
1.  **Gestión de Riesgo (Fondeo)**: Define aquí el % de pérdida máxima diaria y el objetivo de la cuenta.
    *   **Importante**: Si dejas `InpBalance = 0`, el robot detectará automáticamente tu balance actual. 
    *   **Auto-Ajuste**: En el Probador de Estrategias (Backtest), el robot detectará si tu balance de prueba coincide con el configurado y se ajustará automáticamente para evitar bloqueos por seguridad.
2.  **Estrategias**: Puedes activar o desactivar cada setup individualmente (`InpLndEnable`, `InpNYEnable`) y asignarles un riesgo base diferente.
3.  **Riesgo Dinámico**: Por defecto, el robot multiplicará el riesgo base por el estado de la cuenta (si estás en drawdown, operará más pequeño; si estás cerca del objetivo, ajustará el lote para "cerrar" la cuenta).

#### Diagnóstico de Errores (Logs)
Si el robot no realiza entradas, revisa la pestaña "Expertos":
*   **"GESTIÓN RIESGO STATUS"**: Te mostrará el balance inicial detectado y el drawdown actual permitido.
*   **"Límite de pérdida TOTAL alcanzado"**: Indica que el equity actual ha bajado del límite configurado (normalmente el 10% del balance inicial). Ahora el mensaje muestra el Equity actual y el Límite exacto para facilitar el diagnóstico.

#### Análisis de Resultados
El nuevo logger CSV ahora incluye una columna `Strategy`. Esto te permite usar una sola tabla dinámica en Excel o PowerBI para ver qué estrategia está aportando más beneficio al portafolio unificado.

#### Archivos Importantes en `/Docs`
*   `posibles-filtros.md`: Tu diario de investigación. Consúltalo para ver por qué elegimos ciertos filtros y no otros.
*   `gestion_riesgo_unificada.md`: Especificación técnica del algoritmo de riesgo dinámico.

---

### 4. Recomendaciones de Operación

1.  **Magic Numbers**: Cada estrategia en el `UnifiedEA` tiene su propio `MagicNumber`. Asegúrate de no duplicarlos si decides añadir más setups en el futuro.
2.  **Backtesting**: Para probar el portafolio completo, usa el "Probador de Estrategias" con el archivo `UnifiedEA.mq5`. Podrás ver cómo se compensan las curvas de equidad de Londres y NY.
3.  **Riesgo por Trade**: Se recomienda un riesgo total combinado de entre **0.5% y 1.0%** por día para cuentas de fondeo estándar.

---
*Documento generado el 10 de Marzo de 2026.*