# Fix: Gestión de SL Dinámico se activa múltiples veces

## Descripción del Problema
La función `AplicarGestionSLDinamico` está moviendo el Stop Loss (SL) múltiples veces una vez que se alcanza el ratio de activación (`ratio_act`). Según el comportamiento deseado, esta funcionalidad debería mover el SL una sola vez a la nueva posición y no volver a realizar ninguna modificación adicional para esa posición.

### Logs de Error Observados:
```
CS	0	06:13:49.248	Trade	2026.01.02 19:07:37   position modified [#2 buy 0.01 US100 25081.01 sl: 25051.01 tp: 25261.01]
CS	0	06:13:49.250	rupturaRangoTester (US100,M2)	2026.01.02 19:07:37   SL Dinámico: Ticket 2 movido a 25051.01 (R actual: 1.0)
... (múltiples movimientos rápidos seguidos) ...
CS	0	06:13:49.268	rupturaRangoTester (US100,M2)	2026.01.02 19:07:40   SL Dinámico: Ticket 2 movido a 25080.985 (R actual: 1254.2)
```

## Causa Raíz
La lógica actual en `GestionRiesgo.mqh` calcula un `nuevo_sl` basado en la distancia original al SL (`distancia_r`). Sin embargo, no hay una verificación persistente o una marca que indique que la posición ya ha sido gestionada. Además, al recalcular `distancia_r = MathAbs(precio_ent - sl_actual)`, si el `sl_actual` cambia, la base del cálculo del ratio y del nuevo SL también cambia, lo que provoca un bucle de retroalimentación donde el SL se persigue a sí mismo infinitamente (o hasta que el precio deje de moverse).

## Requerimientos de la Solución
1. Asegurar que el SL se mueva **una sola vez**.
2. Utilizar el riesgo inicial (distancia al SL original) para los cálculos, no el SL modificado.
3. Evitar recálculos que dependan del SL actual si este ya ha sido movido por esta lógica.

## Tareas
- [x] Analizar el método de persistencia para marcar posiciones gestionadas (ej. usando el comentario de la posición o un array persistente).
- [x] Corregir el cálculo de `distancia_r` para que use el riesgo inicial si es posible, o asegurar que la lógica de parada sea robusta.
- [x] Implementar la restricción de "un solo movimiento".
- [x] Verificar el comportamiento en el Probador de Estrategias.

## Conclusión
Se ha corregido la lógica en `Include\GestionRiesgo.mqh` introduciendo una verificación `ya_modificado`. Esta verificación comprueba si el SL actual ya ha alcanzado o superado el nivel objetivo (`nuevo_sl`). Esto previene que la función `AplicarGestionSLDinamico` entre en un bucle infinito de modificaciones rápidas, asegurando que el SL se mueva exactamente una vez a su nueva posición cuando se alcanza el ratio de activación.

---
**Nota**: Para la propuesta de optimización de rendimiento y captura de métricas avanzada (Caché de Posiciones), consultar la nueva tarea: [06-posicion-cache-rendimiento.md](06-posicion-cache-rendimiento.md)
