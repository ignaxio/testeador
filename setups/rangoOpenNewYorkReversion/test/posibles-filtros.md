# New York Reversion Strategy – Filter Testing Plan

This document lists potential **filters to test** for improving a New York session mean‑reversion strategy. The goal is to test each filter independently and in combination to determine which ones improve:

* Expectancy
* Profit factor
* Drawdown
* Equity curve stability

The process should be **systematic**: test one filter at a time, then combinations of the best ones.

---

# Baseline Strategy (test-newyork.csv)

The baseline version of the strategy is defined as:

* **Entry**: New York Session Reversion (Ruptura 09:15-09:30, Operativa 09:31-11:00)
* **Stop Loss**: 1R (Fixed 6000 points)
* **Take Profit**: 3R (Ratio 3.0)
* **Symbols/Period**: M2 TF

### Baseline Results:

| Configuration | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusion |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Reference |

---

# 1. VWAP Distance Filter

Purpose: Ensure the market is **sufficiently extended** before attempting a reversion.

Example conditions to test:

```
DistanceFromVWAP > 0.5 ATR
DistanceFromVWAP > 0.75 ATR
DistanceFromVWAP > 1 ATR
```

Logic:

* Sell when price is above VWAP by a large deviation
* Buy when price is below VWAP by a large deviation

Metrics to record:

* Trade count
* Expectancy
* Winrate

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **VWAP > 0.5 ATR** | 77 | 23.38% | 0.90 | -0.08 | - | Empeora todo |
| **VWAP > 0.75 ATR** | 27 | 33.33% | 1.50 | 0.33 | - | Mejora PF y Exp |
| **VWAP > 1.0 ATR** | 10 | 30.00% | 1.29 | 0.20 | - | Muy restrictivo |
| **VWAP Overextended (RSQ > 0)** | 146 | 36.30% | 1.62 | 0.41 | - | **GANADOR**: Elimina trades "contra-VWAP" |

> **Nota de Análisis**: El filtro RSQ > 0 (entrar corto solo si precio > VWAP, largo si precio < VWAP) mejora drásticamente la esperanza matemática (de 0.25 a 0.41) manteniendo una buena cantidad de trades.

---

# 2. London Range Break Filter

Purpose: Capture **failed breakouts of the London session**.

Example conditions:

```
NY breaks London High
NY breaks London Low
```

Variations:

```
Break > 0.1 ATR
Break > 0.25 ATR
Break > 0.5 ATR
```

Hypothesis:

Large portion of NY reversions occur after **false London breakouts**.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Dentro de Rango Londres** | 287 | 32.40% | 1.38 | 0.26 | - | Estable |
| **Fuera de Rango Londres** | 6 | 0.00% | 0.00 | -1.00 | - | **EVITAR**: Ruptura de Londres implica tendencia |

---

# 3. Yesterday High/Low Extension

Purpose: Detect **exhaustion moves relative to the previous day**.

Example conditions:

```
Price > YesterdayHigh + 0.25 ATR
Price > YesterdayHigh + 0.5 ATR
Price < YesterdayLow - 0.25 ATR
Price < YesterdayLow - 0.5 ATR
```

Hypothesis:

Markets often reverse after **extended moves beyond previous day's range**.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Dentro de Rango Ayer** | 197 | 31.98% | 1.33 | 0.24 | - | Sin impacto claro |
| **Fuera de Rango Ayer** | 96 | 32.29% | 1.37 | 0.27 | - | Sin impacto claro |

---

# 4. Volume Spike Filter

Purpose: Capture **climactic moves**.

Example conditions:

```
Volume > 1.5 × AverageVolume
Volume > 2 × AverageVolume
```

Interpretation:

Volume spikes often indicate:

* Stop runs
* Liquidity sweeps
* Institutional exits

These conditions frequently precede reversals.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Volume > 1.5x Avg** | | | | | | |
| **Volume > 2.0x Avg** | | | | | | |

---

# 5. Daily Range vs ATR

Purpose: Avoid entering reversions **too early in the day**.

Example conditions:

```
DayRange > 0.8 ATR
DayRange > 1.0 ATR
DayRange > 1.2 ATR
```

Logic:

If the market has already moved significantly, the probability of reversion increases.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **DayRange > 0.8 ATR** | | | | | | |
| **DayRange > 1.0 ATR** | | | | | | |
| **DayRange > 1.2 ATR** | | | | | | |

---

# 6. Distance From NY Open

Purpose: Confirm the market has **moved far enough from the opening price**.

Example conditions:

```
DistanceFromNYOpen > 0.5 ATR
DistanceFromNYOpen > 0.75 ATR
DistanceFromNYOpen > 1 ATR
```

This filter helps avoid:

* Early noise
* Small oscillations near the open

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **DistOpen > 0.5 ATR** | | | | | | |
| **DistOpen > 0.75 ATR** | | | | | | |
| **DistOpen > 1.0 ATR** | | | | | | |

---

# 7. Trend Context Filter

Purpose: Align reversions with **higher timeframe trend context**.

Example conditions:

```
Price BELOW SMA200 → prefer SHORT
Price ABOVE SMA200 → prefer LONG
```

Alternative trend filters to test:

```
SMA100
SMA50
EMA200
```

Hypothesis:

Reversion trades perform better **against short‑term moves but within larger trend context**.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Trend SMA200** | | | | | | |
| **Trend EMA200** | | | | | | |

---

# 8. Consecutive Candles Filter

Purpose: Detect **momentum exhaustion**.

Example conditions:

```
4 consecutive bullish candles → look for SHORT
5 consecutive bullish candles → look for SHORT
4 consecutive bearish candles → look for LONG
```

This filter attempts to capture:

* Momentum exhaustion
* Overextended impulse moves

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **1-2 Velas Seguidas** | 146 | 36.30% | 1.62 | 0.41 | - | **MEJOR**: Reversión inmediata |
| **4+ Velas Seguidas** | 82 | 24.39% | 0.85 | -0.15 | - | **EVITAR**: Momentum fuerte |

---

# 9. Day of Week Filter

Purpose: Remove statistically weak days.

Possible tests:

```
Remove Monday
Remove Wednesday
Trade only Tue–Fri
Trade only Tue + Fri
```

Track performance differences in:

* Expectancy
* Drawdown
* Profit factor

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Solo Tue–Fri** | | | | | | |
| **Solo Tue + Fri** | | | | | | |

---

# 10. Extreme Reversion Setup (Advanced)

Create a **secondary setup** for extreme conditions.

Example rule:

```
DistanceFromVWAP > 1.2 ATR
AND
DayRange > 1 ATR
AND
VolumeSpike
```

Exit idea:

```
TP = 3R or 4R
```

This setup should have **lower frequency but higher expectancy**.

#### Resultados de la Prueba:
| Configuración | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Conclusión |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| **Extreme Setup** | | | | | | |

---

# Testing Methodology

Recommended process:

1. Test each filter individually.
2. Record results.
3. Identify top 3 filters.
4. Test combinations of the best filters.

Example sequence:

```
Baseline
Baseline + VWAP filter
Baseline + London filter
Baseline + Yesterday filter
```

Then combine:

```
VWAP + London
VWAP + ATR
London + ATR
```

---

# Metrics to Track

For each test record:

* Number of trades
* Winrate
* Expectancy (R per trade)
* Profit factor
* Max drawdown

Example table structure:

| Filter | Trades | Winrate | Expectancy | PF | DD |
| ------ | ------ | ------- | ---------- | -- | -- |

---

# Resumen Final de Resultados

| Filtro / Combinación | Trades | Winrate | Profit Factor | Expectancy (R) | Max DD | Estado |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline (test-newyork.csv)** | 293 | 32.08% | 1.35 | 0.25 | - | Referencia |
| | | | | | | |

---

# Final Goal

Identify **2–3 robust filters** that:

* Improve expectancy
* Reduce drawdown
* Do not over‑reduce trade count

Ideal outcome:

```
Expectancy > 0.30R
Profit Factor > 1.8
Stable equity curve
```

These filters can then be integrated into the **final NY reversion trading robot**.

