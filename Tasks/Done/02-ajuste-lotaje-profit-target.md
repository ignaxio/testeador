# Tarea: Ajuste de Lotaje por Proximidad al Profit Target

## Descripción
Para optimizar el paso de fases de fondeo, el robot debe evaluar cuánto falta para alcanzar el objetivo de beneficio (Profit Target) antes de abrir una operación. Si el beneficio potencial de la operación (TP) excede el objetivo restante, el lotaje debe ajustarse para que el TP sea exactamente el Profit Target. Se añadirá un **margen de seguridad del 0.02%** sobre el target para asegurar que se sobrepase por completo.

## Objetivos
- Calcular la distancia monetaria restante hasta el Profit Target (incluyendo el +0.02%).
- Antes de ejecutar una orden, calcular si el TP proyectado sobrepasa el objetivo.
- Modificar el lotaje (en lugar de solo el TP) para optimizar el riesgo, asegurando que la operación cierre en el nivel exacto del objetivo.

## Consideraciones de Rendimiento
Para evitar que esta lógica afecte el rendimiento del robot (especialmente en `OnTick`):
1. **Cálculo Bajo Demanda**: La lógica solo debe ejecutarse una vez que se ha detectado una señal de entrada válida, justo antes de llamar a `EjecutarOrden`.
2. **Cacheo de Datos**: Los valores de balance y profit acumulado del día ya deberían estar disponibles o ser calculados de forma eficiente en `riskControl`.
3. **Optimización Matemática**: Realizar el ajuste del lote mediante una fórmula directa basada en el ratio de riesgo, evitando bucles o consultas pesadas al historial en el momento de la entrada.

## Requisitos Lógicos
- Consultar el estado global de riesgo (`riskControl`) antes de calcular el lotaje en el motor (`RupturaEngine`).
- Si faltan, por ejemplo, $100 para el target y el trade estándar ganaría $300, reducir el lote a 1/3 del original.
- **Margen de Seguridad**: Añadir un 0.02% al balance inicial como buffer adicional al target.
- **Redondeo**: El ajuste de lote debe redondearse hacia **arriba** (dentro del `LotStep`) para garantizar que se alcance el objetivo.
- Asegurarse de que el lote resultante respete el `LotStep` y los mínimos permitidos por el broker.

## Notas
- El ajuste debe ocurrir en el momento de la entrada (`EjecutarOrden` en `RupturaEngine.mqh`).
- Hay que considerar el valor del tick y la distancia al TP para la reducción precisa del lotaje.
- Si el profit restante es insignificante (ej. < 1 tick value o coste de comisión), evaluar si vale la pena abrir la operación.
