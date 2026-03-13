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

## Optimización de Rendimiento
Se han analizado dos opciones para evitar cálculos excesivos en `OnTick`:
1. **OnBar**: Calcular una vez por vela.
2. **Cálculo Lazy (Bajo Demanda)**: El motor solicita el dato solo al momento de la entrada.

**Decisión**: Se implementará el **Cálculo Lazy**. Es la opción más eficiente porque elimina por completo el cálculo en `OnTick`. El valor de `remaining_target` solo se consultará en el milisegundo anterior a la apertura de la orden, garantizando precisión absoluta con el mínimo coste computacional.

## Requisitos Lógicos
- El motor (`RupturaEngine`) debe tener una referencia al controlador de riesgo o solicitar el dato de forma externa.
- Eliminar el paso de `remaining_target` a través de la cadena de funciones `OnTick -> EvaluarEntrada -> EjecutarOrden`.
- Si el profit restante es insignificante (ej. < 1 tick value o coste de comisión), evaluar si vale la pena abrir la operación.
