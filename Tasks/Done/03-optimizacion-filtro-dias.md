# Tarea 03: Optimización de Filtro por Días de la Semana y Filtros Estáticos

## Estado: ToDo
**Prioridad:** Alta (Impacto directo en Performance)
**Objetivo:** Mejorar el rendimiento del robot reduciendo las comprobaciones de "días permitidos" y otros filtros que no cambian durante el día.

## Descripción
Actualmente, los motores de estrategia (`CRupturaEngine`) comprueban si el día actual está permitido (`permitir_lunes`, etc.) y si se permiten compras/ventas cada vez que se detecta una ruptura. Esta lógica puede optimizarse calculando un "Estado de Operatividad" al inicio del día o al inicializar el EA.

## Propuesta Técnica (Mejorada)
1.  **Variables de Estado (Cacheo):**
    *   `bool m_dia_permitido_hoy`: Estado calculado al inicio del día.
    *   `bool m_buy_permitido_hoy` / `bool m_sell_permitido_hoy`: Estado que combina el permiso del usuario con el permiso del día.
2.  **Cálculo Centralizado:**
    *   En `ResetearDia()` y al final de `Init()`, llamar a una función `ActualizarEstadoFiltrosEstaticos()`.
    *   Esta función evaluará los inputs: `permitir_lunes...`, `permitir_buy`, `permitir_sell`.
3.  **Cortocircuito de Rendimiento (OnTick):**
    *   Si `m_dia_permitido_hoy` es `false`, el motor abortará inmediatamente en `OnTick()` (antes de cualquier cálculo de tiempo o indicadores).
    *   Esto ahorra ciclos de CPU masivos en backtesting al saltarse días completos.
4.  **Actualización Dinámica:**
    *   Asegurar que si el usuario cambia un parámetro (ej. de `permitir_lunes = false` a `true`) en los inputs del EA, el motor lo detecte (mediante una nueva llamada a la actualización en `Init` o un chequeo periódico).

## Beneficios en Performance
*   **Backtesting:** Ahorro estimado del 15-20% en tiempo de optimización al ignorar días no operativos.
*   **Operativa Real:** Menor latencia en `OnTick` al evitar llamadas a `TimeCurrent()` y lógica de rangos en días inactivos.

## Consideraciones
*   La lógica de **cierre por fin de sesión** debe permanecer activa incluso si el día no es operativo para abrir (por si quedó un trade de un día anterior).
*   Si el EA se reinicia a las 10:00 AM, debe calcular correctamente que "hoy es lunes" y aplicar el filtro.
