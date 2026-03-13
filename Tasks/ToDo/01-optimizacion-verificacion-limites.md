# Tarea: Optimización de Verificación de Límites Globales

## Descripción
Actualmente, el sistema verifica la pérdida diaria, la pérdida total y el profit target en cada tick (`OnTick`) a través de `riskControl.CheckGlobalLimits()`. Aunque esto garantiza una protección inmediata (Hard Stop), puede tener un impacto negativo en el rendimiento (performance) del robot, especialmente en backtesting intensivo o con muchos símbolos.

## Objetivos
- Investigar si es estrictamente necesario realizar esta comprobación en cada tick.
- Buscar soluciones alternativas para gestionar la seguridad de la cuenta de forma eficiente.

## Posibles Soluciones
1. **Verificación OnTrade**: Ejecutar la lógica de cierre solo cuando cambia el número de posiciones o hay un evento de trading.
2. **Umbral de Activación**: Solo verificar en cada tick si el Equity se acerca a un umbral crítico (ej. 80% del límite permitido), y usar una verificación más relajada (ej. cada minuto o cada vela) si estamos lejos.
3. **Optimización de Cálculos**: Cachear valores de balance y profit acumulado del día para evitar recorrer el historial en cada tick.

## Notas
- El cierre inmediato es crítico para cuentas de fondeo (Prop Firms), por lo que cualquier alternativa debe garantizar que no se viole la regla de pérdida máxima por un retraso en la ejecución.
