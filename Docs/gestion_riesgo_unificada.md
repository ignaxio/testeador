# Especificación: Gestión de Riesgo Unificada y EA Multi-Estrategia (v1.0)

Este documento detalla el plan para unificar los robots de producción en un solo Expert Advisor (EA) y dotarlo de una gestión de riesgo avanzada y dinámica, optimizada para cuentas de fondeo (Prop Firms).

---

## 1. Objetivos de la Unificación

### 1.1 Beneficios Técnicos
*   **Mantenimiento Centralizado**: Cualquier mejora en el motor o en la lógica de entrada se aplica a todas las estrategias instantáneamente.
*   **Control de Riesgo Global**: El EA conoce el beneficio/pérdida total del día sumando todas las estrategias, permitiendo detener la operativa si se alcanza el `Daily Max Loss`.
*   **Optimización de Margen**: Mejor gestión de la equidad disponible al no tener múltiples EAs compitiendo de forma independiente.

### 1.2 Estrategias a Unificar (Instancias)
1.  **engineLnd**: Rango 10 Continuación (Londres).
2.  **engineNY**: NY Reversion (Nueva York - Lunes a Jueves).
3.  **engineNYFridays**: NY Reversion (Nueva York - Viernes).

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
*   Cuando la **Equidad (Equity)** de la cuenta alcanza el objetivo de beneficio configurado, el EA cierra inmediatamente todas las posiciones abiertas y detiene la operativa.
*   *Lógica*: "Prefiero asegurar el pase de la cuenta en cuanto toquemos el número mágico, sin importar si el trade actual tenía un ratio objetivo mayor".
*   Se elimina la reducción de riesgo previa al target para no alargar innecesariamente la consecución del objetivo.

### 3.2 Proximidad al Max Loss (Modo "Safety")
*   Si el drawdown acumulado se acerca al límite (ej. estamos al 70% del DD permitido), el riesgo se reduce dinámicamente.
*   *Fórmula*: `Riesgo Actual = Riesgo Base * (Distancia al Max Loss / Distancia Inicial)`.
*   Esto proporciona una "frenada de emergencia" suave que permite seguir operando con lotajes mínimos para intentar la recuperación sin quebrar la cuenta.

---

## 4. Clasificación de Estrategias por Grupo (Riesgo Configurable)

El EA permite configurar el porcentaje de riesgo base para cada grupo de estrategia, permitiendo que el usuario decida cuánto capital asignar a cada ventaja estadística:

| Grupo | Descripción | Instancia Asociada | Riesgo Configurable (Input) |
| :--- | :--- | :--- | :--- |
| **Grupo A** | NY Reversión (Viernes) | `engineNYFridays` | `InpRiskGroupA` (ej. 0.5%) |
| **Grupo B** | Londres Continuación (Todos los días) | `engineLnd` | `InpRiskGroupB` (ej. 0.35%) |
| **Grupo C** | NY Reversión (Lunes a Jueves) | `engineNY` | `InpRiskGroupC` (ej. 0.2%) |

---

## 5. Arquitectura del EA Unificado

Para que esto sea factible sin romper el motor actual, propongo:

1.  **Clase `CEstrategyController`**: Una nueva clase que contendrá un array de objetos `CRupturaEngine`.
2.  **Mapeo de Magic Numbers**: Cada estrategia tendrá su propio Magic Number para que el historial y el logueo sigan siendo independientes.
3.  **Módulo de Riesgo Global**: Una función que se ejecute en cada `OnTick` antes de que las estrategias decidan entrar, validando los límites de Prop Firm.

---

## 6. Análisis de Factibilidad

### 6.1 Arquitectura de Ejecución (Optimización)
Para maximizar la eficiencia y seguridad, el EA diferencia entre dos ciclos:

1.  **Ciclo OnTick (Seguridad Directa)**:
    *   `CheckGlobalLimits()`: Verifica la **Equidad** en cada tick. Si se toca el Profit Target o el Max Loss, cierra todo al instante.
    *   **Gestión de SL (Trail/BE)**: Cada motor ajusta los niveles de Stop Loss en tiempo real según el precio actual.
2.  **Ciclo OnBar (Operativa y Filtros)**:
    *   `CanOperate()` y `GetDynamicRiskMultiplier()`: Se evalúan solo al cierre de vela. Esto decide si se permiten nuevas entradas y con qué lotaje.
    *   **Detección de Señales**: Las estrategias buscan rupturas de rango solo al confirmar el cierre de la vela de referencia.

---

## 7. Próximos Pasos Sugeridos

1.  **Refactorizar `RupturaEngine.mqh`** para convertirlo en una Clase (`class CRupturaEngine`) en lugar de variables sueltas.
2.  **Implementar la lógica de Scoring** en el módulo de filtros.
3.  **Crear el EA `Unificado_Pro_Firme.mq5`** con los nuevos inputs de gestión de riesgo.

¿Qué te parece este enfoque? Si estás de acuerdo, podemos empezar a detallar la lógica de puntuación (Scoring) de cada estrategia antes de tocar el código.
