# Especificación: Gestión de Riesgo Unificada y EA Multi-Estrategia (v1.0)

Este documento detalla el plan para unificar los robots de producción en un solo Expert Advisor (EA) y dotarlo de una gestión de riesgo avanzada y dinámica, optimizada para cuentas de fondeo (Prop Firms).

---

## 1. Objetivos de la Unificación

### 1.1 Beneficios Técnicos
*   **Mantenimiento Centralizado**: Cualquier mejora en el motor o en la lógica de entrada se aplica a todas las estrategias instantáneamente.
*   **Control de Riesgo Global**: El EA conoce el beneficio/pérdida total del día sumando todas las estrategias, permitiendo detener la operativa si se alcanza el `Daily Max Loss`.
*   **Optimización de Margen**: Mejor gestión de la equidad disponible al no tener múltiples EAs compitiendo de forma independiente.

### 1.2 Estrategias a Unificar
1.  **Rango 10 Continuación (Londres)**
2.  **NY Reversion (Nueva York)**
3.  **Variante NY Reversion Fridays**

---

## 2. Parámetros de Cuentas de Fondeo (Inputs)

Se añadirán nuevos parámetros globales para el control estricto de la cuenta:

*   `inp_balance_inicial`: Capital inicial de la cuenta (ej. 100,000 USD).
*   `inp_daily_max_loss_perc`: % máximo de pérdida diaria permitido (ej. 4%).
*   `inp_max_loss_total_perc`: % máximo de pérdida total permitido (ej. 8% o 10%).
*   `inp_profit_target_perc`: % de objetivo de beneficio para pasar la prueba (ej. 10%).
*   `inp_hard_stop_global`: Si es `true`, el EA cierra todas las posiciones y deja de operar si se toca algún límite.

---

## 3. Gestión de Riesgo Dinámica

El riesgo por operación ya no será estático (ej. 0.5% fijo), sino que se ajustará según la situación de la cuenta:

### 3.1 Proximidad al Target (Modo "Finish")
*   Si la cuenta está a menos de 2R de pasar el objetivo, el EA reducirá el riesgo (ej. de 0.5% a 0.25%) para asegurar el pase con baja volatilidad.
*   *Lógica*: "Prefiero tardar 3 días más en pasar la cuenta que arriesgarme a un drawdown fuerte justo antes de la meta".

### 3.2 Proximidad al Max Loss (Modo "Safety")
*   Si el drawdown acumulado se acerca al límite (ej. estamos al 6% de un 8% permitido), el riesgo se reduce drásticamente para evitar la quiebra de la cuenta.
*   *Fórmula Sugerida*: `Riesgo Actual = Riesgo Base * (Distancia al Max Loss / Distancia Inicial)`.

---

## 4. Clasificación de Estrategias por Puntuación (Scoring)

Dividiremos los trades en 3 grupos de probabilidad basados en los filtros analizados previamente. Cada grupo tendrá un multiplicador de riesgo:

| Grupo | Calificación | Criterios (Ejemplo) | Riesgo Sugerido |
| :--- | :--- | :--- | :--- |
| **Grupo A** | Alta Probabilidad | Cumple todos los filtros + Filtro VWAP + Filtro Londres | **100% del riesgo base** |
| **Grupo B** | Media Probabilidad | Cumple filtros base + Exclusión de Rango | **70% del riesgo base** |
| **Grupo C** | Baja Probabilidad | Solo filtros base | **40% del riesgo base** (o no operar) |

---

## 5. Arquitectura del EA Unificado

Para que esto sea factible sin romper el motor actual, propongo:

1.  **Clase `CEstrategyController`**: Una nueva clase que contendrá un array de objetos `CRupturaEngine`.
2.  **Mapeo de Magic Numbers**: Cada estrategia tendrá su propio Magic Number para que el historial y el logueo sigan siendo independientes.
3.  **Módulo de Riesgo Global**: Una función que se ejecute en cada `OnTick` antes de que las estrategias decidan entrar, validando los límites de Prop Firm.

---

## 6. Análisis de Factibilidad

### ¿Es factible unificar los setups?
**SÍ**, es muy factible y recomendable. La estructura actual de `RupturaEngine.mqh` ya es modular. Solo necesitamos:
*   Pasar las variables globales del motor (como `hora_inicio_rango`, `puntos_sl`, etc.) a una estructura o clase para que cada instancia de la estrategia tenga sus propios datos.
*   Crear un bucle en el `OnTick` del EA principal que recorra todas las estrategias activas.

---

## 7. Próximos Pasos Sugeridos

1.  **Refactorizar `RupturaEngine.mqh`** para convertirlo en una Clase (`class CRupturaEngine`) en lugar de variables sueltas.
2.  **Implementar la lógica de Scoring** en el módulo de filtros.
3.  **Crear el EA `Unificado_Pro_Firme.mq5`** con los nuevos inputs de gestión de riesgo.

¿Qué te parece este enfoque? Si estás de acuerdo, podemos empezar a detallar la lógica de puntuación (Scoring) de cada estrategia antes de tocar el código.
