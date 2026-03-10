# Análisis de Portafolio: Continuación Rango 10 vs. Reversión NY

Este documento presenta un análisis detallado de la combinación de dos estrategias de trading ganadoras: **Rango 10 Continuación (Sesión Londres)** y **NY Reversion (Sesión Nueva York)**.

## 1. Resumen Ejecutivo del Portafolio

Al combinar ambas estrategias, obtenemos un sistema robusto que opera en dos de las ventanas de mayor volatilidad del mercado (Apertura de Londres y Apertura de Nueva York), logrando una diversificación temporal natural.

| Métrica | Rango 10 Continuación | NY Reversion (v3.0) | **Portafolio Combinado** |
| :--- | :---: | :---: | :---: |
| **Total Trades (2025+)** | 174 | 236 | **410** |
| **Winrate (%)** | 42.53 % | 33.47 % | **37.32 %** |
| **Profit Factor** | 1.71 | 1.44 | **1.54** |
| **Esperanza (R)** | 0.388 R | 0.301 R | **0.338 R** |
| **Max Drawdown (R)** | 8.00 R | 14.45 R | **15.49 R** |
| **Recovery Factor** | 8.43 | 4.92 | **8.95** |
| **Beneficio Total (R)** | 67.48 R | 71.11 R | **138.59 R** |

---

## 2. Ventajas de la Unificación

### 2.1. Diversificación Temporal
- **Sesión Londres (09:00 - 12:00 UTC)**: El robot de Continuación captura el impulso inicial de la mañana europea.
- **Sesión NY (09:30 - 11:00 NY Time)**: El robot de Reversión captura el agotamiento de los movimientos extremos tras la apertura americana.
- **Resultado**: El capital no está expuesto simultáneamente en ambas estrategias, lo que optimiza el uso del margen.

### 2.2. Suavizado de la Curva de Equidad
El **Factor de Recuperación (Recovery Factor)** del portafolio (**8.95**) es superior al de cualquiera de las estrategias por separado (8.43 y 4.92). Esto indica que el sistema conjunto sale de sus rachas negativas de forma mucho más eficiente.

### 2.3. Eficiencia en Cuentas de Fondeo (Prop Firms)
Para una cuenta de fondeo con un límite de DD del 10%:
- Si arriesgas un **0.25%** por operación, tu DD máximo histórico del portafolio sería de **3.87%**.
- Esto te deja un margen de seguridad enorme del **6.13%** antes de fallar la prueba, mientras que el beneficio proyectado en un año (basado en 2025) sería de aproximadamente **34.6%** (138R * 0.25%).

---

## 3. Análisis de Rendimiento Mensual (Portafolio)

| Mes | Profit (R) | Trades | Winrate |
| :--- | :---: | :---: | :---: |
| Enero | +43.82 | 70 | 48.57 % |
| Febrero | +22.05 | 67 | 41.79 % |
| Marzo | +30.40 | 54 | 44.44 % |
| Abril | -0.22 | 50 | 26.00 % |
| Mayo | +7.14 | 30 | 33.33 % |
| Junio | +22.13 | 38 | 52.63 % |
| Julio | +10.21 | 42 | 35.71 % |
| Agosto | +11.76 | 39 | 41.03 % |
| Septiembre | +8.23 | 32 | 46.88 % |
| Octubre | +3.64 | 50 | 36.00 % |
| Noviembre | +16.97 | 44 | 40.91 % |
| Diciembre | -1.58 | 42 | 28.57 % |

---

## 4. Correlación y Gestión de Riesgo

El análisis de correlación muestra que las estrategias coinciden en estado de Drawdown el **48.75%** del tiempo. Aunque no es una descorrelación total (ya que operan el mismo activo o activos similares), el hecho de que sus picos de pérdida máxima no ocurran exactamente al mismo tiempo permite que el Max DD conjunto (**15.49R**) sea significativamente menor que la suma de sus DDs individuales (**22.45R**).

### Recomendación para Producción:
1. **Riesgo por Operación**: Se recomienda un riesgo moderado (0.25% - 0.5%) por estrategia.
2. **Capital**: Idealmente operar ambas estrategias en la misma cuenta para aprovechar la compensación de beneficios.
3. **Control de Racha**: Dado que el portafolio puede tener rachas de pérdidas de hasta 15 operaciones (debido a la naturaleza de reversión de NY), es vital mantener la disciplina y no reducir el riesgo durante el drawdown.

## 5. Conclusión Final

La combinación de **Rango 10 Continuación** y **NY Reversion** crea un portafolio de trading institucionalmente sólido. Mientras que el robot de Londres aporta estabilidad y un alto factor de beneficio, el robot de NY aporta un gran volumen de operaciones y captación de beneficios en momentos de alta liquidez.

**Veredicto**: La unión de ambos sistemas es **altamente eficiente** y está lista para ser operada de forma conjunta tanto en cuentas reales como en procesos de fondeo.
