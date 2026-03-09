# Rango 10 Continuación (PRO) - London 09:00

Este robot de trading automatizado opera la ruptura y continuación del rango de apertura de Londres (09:00 - 09:30). Está diseñado para operar en la temporalidad de 2 minutos (M2) con un enfoque en la gestión de riesgo institucional y alta probabilidad estadística.

### Información del Proyecto
- **Autor:** Ignasi Farré
- **Copyright:** 2026
- **Estrategia:** Ruptura de Rango de Apertura (Opening Range Breakout)
- **Activo:** US100.

### Configuración del Rango (M2)
- **Temporalidad:** 2 Minutos (M2).
- **Hora Inicio Rango:** 09:00 (Hora del Broker).
- **Hora Fin Rango:** 09:30 (Hora del Broker).
- **Tamaño Mínimo:** 100 puntos.

### Parámetros Operativos
- **Horario de Entrada:** De 09:31 a 12:00.
- **Dirección:** Continuación (compra si rompe por arriba, venta si rompe por abajo).
- **Cierre de Sesión:** Cierre forzoso de posiciones a las **20:30**.
- **Identificación de Logs:** `rango10-continuacion-pro-v1`

### Gestión de Riesgo
- **Riesgo por Operación:** 1% fijo del balance de la cuenta.
- **Ratio Objetivo (TP):** 1:3 (3.0).
- **Stop Loss:** Calculado según el bajo/alto del rango para mantener el ratio 3:1.
- **Lote:** Autocalculado para arriesgar exactamente el 1% del capital.

### Filtros y Optimización
Para asegurar la calidad de las entradas, se aplican los siguientes filtros en la versión PRO:
1. **Filtro de Tamaño de Rango:** Mínimo de 2000 puntos para evitar baja volatilidad.
2. **Filtro de Exclusión:** Se evitan rangos de volatilidad errática (identificados en el análisis histórico).

### Análisis de Datos
Los resultados históricos y de validación se encuentran registrados en el archivo:
- `rango10continuacion_pro.csv`

Este archivo contiene el historial de trades generados por el motor `RupturaEngine.mqh` para este setup específico.
