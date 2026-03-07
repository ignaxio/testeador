# Trading Robot – Time Handling Specification (MT5)

## 1. Purpose

This document defines the requirements for handling **market time and trading sessions** in a MetaTrader 5 trading robot.

The goal is to ensure the robot operates using **real market session times** (Asia, London, New York) regardless of:

* Broker server timezone
* Daylight saving time (DST)
* Broker changes
* Backtesting environment

The system must provide a **robust and broker-independent time framework**.

---

# 2. Problem Description

Trading platforms such as MT5 provide time values based on the **broker server time**.

This creates several problems:

* Different brokers use different server timezones.
* Broker server times may change during daylight saving time.
* Strategies defined using broker time may execute at incorrect market times.
* Backtests and live trading may behave differently if the broker timezone changes.

Example:

Strategy requirement:

* Execute logic at **10:00 London time**

Possible broker server times:

| Broker   | Server Timezone | London 10:00 appears as |
| -------- | --------------- | ----------------------- |
| Broker A | GMT+2           | 12:00                   |
| Broker B | GMT+3           | 13:00                   |
| Broker C | UTC             | 10:00                   |

Without proper conversion, the strategy may trigger at incorrect times.

---

# 3. Design Goal

The trading robot must operate based on **real financial market time**, not broker time.

All time logic must be based on:

* **UTC (Coordinated Universal Time)** as the internal reference
* Conversion to **market session timezones**

The system must automatically handle:

* Daylight saving time (DST)
* Different broker timezones
* Timezone changes between brokers

---

# 4. Core Concept

The time architecture should follow this hierarchy:

```
Broker Server Time
        ↓
Convert to UTC
        ↓
Convert UTC to Market Timezones
        ↓
Use Market Time for strategy logic
```

The robot should **never directly use broker server time for trading decisions**.

---

# 5. Market Timezones

The system must support the following market timezones:

### London

Timezone reference: Europe/London

Characteristics:

* Winter: UTC+0
* Summer (DST): UTC+1

Important session:

* London Open: 08:00 London time

---

### New York

Timezone reference: America/New_York

Characteristics:

* Winter: UTC−5
* Summer (DST): UTC−4

Important session:

* New York Open: 09:30 New York time

---

### Asia

Common trading reference: Tokyo

Timezone reference: Asia/Tokyo

Characteristics:

* UTC+9
* No daylight saving time

Typical session window used in trading strategies.

---

# 6. Trading Sessions

The system must define standard session ranges.

These values should be configurable.

Example:

| Session  | Start | End   |
| -------- | ----- | ----- |
| Asia     | 00:00 | 08:00 |
| London   | 08:00 | 16:30 |
| New York | 13:30 | 22:00 |

All values must be interpreted in **their respective market timezone**.

---

# 7. Session Variables

The system should expose session variables that can be reused by strategies.

Examples:

```
Session.Asia.Start
Session.Asia.End

Session.London.Start
Session.London.End

Session.NewYork.Start
Session.NewYork.End
```

These variables should always represent **correct session times regardless of DST changes**.

---

# 8. Functional Requirements

The time management system must:

1. Provide current **UTC time**.
2. Provide **London market time**.
3. Provide **New York market time**.
4. Provide **Asia market time**.
5. Detect whether the current time is within a specific session.
6. Provide session start and end timestamps for the current trading day.
7. Work identically across different brokers.
8. Automatically handle daylight saving time.

---

# 9. Session Detection

The system must allow strategies to easily determine:

* If current time is inside a session.
* If a session has just opened.
* If a session has just closed.

Examples of possible checks:

* Is current time inside London session?
* Did London session just start?
* Did New York session just end?

---

# 10. Daylight Saving Time

DST differences between regions must be handled automatically.

Important note:

The United States and Europe **do not change DST on the same date**.

This creates periods (2–3 weeks per year) where the relative time between London and New York changes.

The system must correctly handle these periods.

---

# 11. Strategy Use Cases

Examples of how strategies may use the time system:

### Example 1

Opening Range strategy.

Requirements:

* Detect London open
* Measure price range during the first X minutes
* Execute breakout logic afterwards

---

### Example 2

Session-based volatility filter.

Requirements:

* Trade only during London session
* Disable trading during Asia session

---

### Example 3

Session statistics.

Requirements:

* Calculate high/low of the Asia session
* Use it as reference during London session

---

# 12. Backtesting Requirements

The system must behave identically in:

* Live trading
* Strategy testing
* Different brokers
* Different server timezones

The logic must always rely on **market time**, not broker server time.

---

# 13. Extensibility

The system should be designed to allow future extensions such as:

* Additional market sessions
* Custom trading windows
* Session statistics
* Volatility analysis per session
* Strategy activation depending on session regime

---

# 15. Broker Offset & DST Data Source (NEW)

To ensure consistency between live trading and backtesting, the system uses a dual-source approach for calculating the Broker-to-UTC offset.

### 15.1 Live Trading: Auto-Detection
In a live environment, the system automatically detects the current broker offset by comparing the server time with the GMT time.

*   **Method:** `Broker_Offset = TimeCurrent() - TimeGMT()`
*   **Frequency:** Calculated once at the start of the session and verified daily at 00:00 (Broker Time).
*   **Validation:** If the difference is not a multiple of 3600 seconds (1 hour) or 1800 seconds (30 mins), the system should log a warning.

### 15.2 Backtesting: Historical Rule Table (Last 10 Years)
Since `TimeGMT()` in the MT5 Strategy Tester may not always reflect historical DST changes correctly (depending on the broker's history data), the system will include a built-in table of DST transition rules for the last 10 years (2016–2026).

**Historical DST Logic:**
*   The system identifies the **Broker Type** (typically GMT+2/GMT+3 for most Forex brokers following the "New York Close" standard).
*   It applies the historical transition dates for US/EU DST to determine the exact offset at any point in the past 10 years.
*   **Default Rule:** Most MT5 brokers use "London/US Hybrid" logic:
    *   **Winter:** GMT+2
    *   **Summer:** GMT+3 (Aligned with US DST transitions to maintain 5 candles per week).

### 15.3 Future Data Handling
For future dates (2027 and beyond), the system will:
1.  **Project Rules:** Assume current DST transition rules (e.g., 2nd Sunday of March for US) remain constant.
2.  **Live Sync:** In live trading, the Auto-Detection (15.1) will always take precedence over the table, ensuring that even if DST laws change, the robot adapts instantly.
3.  **Configurable Overrides:** Allow the user to manually set a fixed offset or a specific DST region (US, EU, Australia, None) via input parameters if the broker uses a non-standard timezone.

---

# 16. Summary

This system ensures the trading robot:

* Is **broker independent**
* Correctly handles **daylight saving time**
* Operates using **real financial market session times**
* Provides a reusable **session-based architecture** for future strategies.
