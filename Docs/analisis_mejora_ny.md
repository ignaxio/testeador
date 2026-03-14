# Análisis de Mejora: Estrategia NY Reversion (Sin Viernes)

Este documento analiza por qué la estrategia de reversión de Nueva York pierde eficacia al excluir los viernes y propone soluciones técnicas para recuperar la rentabilidad en los días laborables (Lunes a Jueves).

---

## 1. El Impacto de los Viernes (Contexto)

Los viernes son estadísticamente el motor de la estrategia. En el backtest original (3R), los viernes tienen un **Profit Factor de 2.11**, mientras que el resto de la semana baja a **1.28**. 

Al intentar mejorar esto bajando el ratio a **0.3R** (archivo `ny-reversion-pro-v3-modified.csv`), los resultados empeoraron:
*   **Original 3R (Sin Viernes)**: PF 1.28 | Esperanza 0.19 R.
*   **Modificado 0.3R (Sin Viernes)**: PF 1.02 | Esperanza 0.003 R.

**Conclusión 1**: Bajar el ratio a 0.3R no es la solución. El sistema necesita un ratio mayor (2R-3R) para compensar las rachas de pérdidas, incluso con un winrate del 74%.

---

## 2. El Filtro Ganador: Tamaño del Rango (OpeningRangeSize)

Hemos descubierto una diferencia crítica en el comportamiento del mercado entre los viernes y el resto de la semana:

| Segmento | Avg Range Ganadores | Avg Range Perdedores |
| :--- | :--- | :--- |
| **Viernes** | 6,712 puntos | 7,727 puntos |
| **Lunes-Jueves** | **5,414 puntos** | **6,711 puntos** |

### Hallazgo Clave:
En los días laborables normales, los rangos de apertura grandes (> 6000 puntos) tienden a ser continuaciones de tendencia fuertes y **fallan como reversiones**. Sin embargo, los viernes el mercado es más propenso a revertir incluso tras rangos grandes.

### Simulación de Mejora (Lunes-Jueves):
Si aplicamos un filtro de **OpeningRangeSize <= 6000** solo para los días Lunes-Jueves:
*   **Trades**: Baja de 184 a 104.
*   **Winrate**: Sube de 30.9% a **36.5%**.
*   **Profit Factor**: Sube de 1.28 a **1.59**.
*   **Esperanza Matemática**: Sube de 0.19R a **0.38R** (¡El doble!).

---

## 3. Análisis por Días (Ratio 3R)

No todos los días responden igual al ratio de 3R:
*   **Lunes**: PF 1.46 (Sólido).
*   **Martes**: PF 1.26 (Regular).
*   **Miércoles**: PF 1.30 (Regular).
*   **Jueves**: PF 1.12 (Débil).

**Nota sobre el Miércoles**: El Miércoles sufrió especialmente con el ratio 0.3R (PF 0.66). Esto indica que las reversiones de los miércoles suelen ser profundas o fallar totalmente; no se quedan en "pequeños beneficios".

---

## 4. Recomendaciones Estratégicas (Hoja de Ruta)

Para que la estrategia sea "buena" sin depender de los viernes, propongo los siguientes cambios en el `UnifiedEA.mq5`:

### A. Filtro de Rango Dinámico por Día
*   **Viernes**: Permitir rangos de hasta 10,000 puntos (Máxima flexibilidad).
*   **Lunes a Jueves**: Limitar el rango de apertura a un máximo de **6,000 puntos**. Esto eliminará los "falsos giros" en tendencias pesadas.

### B. Optimización del Ratio (TP)
*   Mantener el ratio **3.0R** para Lunes, Miércoles y Viernes.
*   Probar un ratio de **1.5R o 2.0R** para Martes y Jueves, ya que estos días muestran una mayor probabilidad de giros cortos pero menos recorrido total.

### C. El Filtro VWAP
Se ha detectado que algunos trades ganadores ocurren en el lado "incorrecto" del VWAP. Aunque la regla `RSQ > 0` es lógica, en días de baja volatilidad (Tues/Thu) podría ser demasiado restrictiva. 

---

## 5. Próximos Pasos (Propuesta Técnica)

1.  **Modificar `UnifiedEA.mq5`**: Para que la instancia `engineNY` (Semana) tenga un `opening_range_size_mayor_que = 6000`.
2.  **Mantener `engineNYFridays`**: Sin límite de rango (o uno muy amplio).
3.  **Backtest de Validación**: Ejecutar una prueba con estos filtros combinados para confirmar que el Profit Factor global de la semana (excluyendo viernes) se estabiliza por encima de 1.50.

¿Te gustaría que aplique el límite de rango de 6000 puntos en el UnifiedEA para los días de semana y hagamos la prueba?
