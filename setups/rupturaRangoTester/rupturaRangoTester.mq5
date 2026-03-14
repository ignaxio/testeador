//+------------------------------------------------------------------+
//|                                         rupturaRangoTester.mq5    |
//|                                  Copyright 2026, Ignasi Farré     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "..\..\Include\RupturaEngine.mqh"

//+------------------------------------------------------------------+
//| INPUTS DEL EXPERT                                                |
//+------------------------------------------------------------------+

// --- Configuración de Horario y Rango ---
input group "Configuración de Rango"
input ENUM_TIMEFRAMES   InpTF                = PERIOD_M2;       // TimeFrame Operativo
input ENUM_MODO_HORARIO InpModoHorario       = MODO_MERCADO;    // Modo Horario (Mercado/Broker)
input ENUM_MARKET_ZONE  InpZonaMercado       = ZONE_NEWYORK;    // Zona Mercado (si MODO_MERCADO)
input string            InpHoraInicioRango   = "09:15";         // Hora Inicio Rango (HH:MM)
input string            InpHoraFinRango      = "09:30";         // Hora Fin Rango (HH:MM)
input int               InpRangoMinPoints    = 100;             // Rango Mínimo (puntos)

// --- Configuración Operativa ---
input group "Configuración Operativa"
input string            InpHoraInicioOp      = "09:31";         // Hora Inicio Operativa
input string            InpHoraFinOp         = "11:00";         // Hora Fin Operativa
input bool              InpCerramosTrades    = false;           // ¿Cerrar al fin de sesión?
input string            InpHoraFinSesion     = "14:30";         // Hora Fin Sesión (Cierre)
input ENUM_DIRECCION    InpDireccion         = Reversion;       // Dirección (Continuacion/Reversion)
input bool              InpPermitirBuy       = true;            // Permitir Compras
input bool              InpPermitirSell      = true;            // Permitir Ventas

// --- Gestión de Riesgo ---
input group "Gestión de Riesgo"
input int               InpPointsSL          = 6000;            // Puntos de Stop Loss
input double            InpRatioTP           = 3.0;             // Ratio Take Profit (R:R)
input bool              InpSLFijo            = false;           // ¿Usar Lote Fijo? (false = % Riesgo)
input double            InpLots              = 0.01;            // Lote Fijo (si InpSLFijo=true)
input double            InpRiskPercent       = 1.0;             // Porcentaje de Riesgo (%)
input bool              InpUseScoring        = false;           // Usar Reducción Riesgo por Scoring

// --- Gestión de SL Dinámico (Breakeven) ---
input group "Gestión SL Dinámico"
input bool              InpUseBE             = false;           // Activar Breakeven
input double            InpRatioBE           = 1.0;             // Ratio para activar BE
input double            InpPercentSLNew      = 100.0;           // % de SL a mover (100% = BE exacto)

// --- Filtros de Entrada ---
input group "Filtro: Tamaño del Rango (Opening Range Size)"
input bool              InpUseRangeSize      = true;            // Activar Filtro Tamaño Rango
input double            InpRangeSizeLimit    = 6000;            // Límite del Rango (puntos)
input bool              InpRangeSizeIsMax    = true;            // ¿Es Límite Máximo? (true=Máx, false=Mín)

input group "Filtro: ATR (Volatilidad)"
input bool              InpUseATR            = true;            // Activar Filtro ATR
input double            InpATRLimit          = 18;              // Límite ATR
input bool              InpATRIsMax          = false;           // ¿Es Límite Máximo? (true=Máx, false=Mín)

input group "Filtro: Volumen"
input bool              InpUseVolume         = false;           // Activar Filtro Volumen
input int               InpVolumeLimit       = 1000;            // Volumen Mínimo requerido

input group "Filtros Técnicos Adicionales"
input bool              InpUseDistBreakout   = false;           // Filtro Distancia Ruptura Máxima
input double            InpDistBreakoutLimit = 10.0;            // Distancia Máxima (puntos)
input bool              InpUseRangeExcl      = true;            // Filtro Exclusión Rango (3100-4500)
input bool              InpUseSMA200         = false;           // Filtro SMA200 (H1)
input bool              InpUseVWAP           = false;           // Filtro VWAP
input double            InpVWAPMult          = 0.5;             // Multiplicador ATR para VWAP
input bool              InpUseConsec         = false;           // Filtro Velas Consecutivas
input int               InpMaxConsec         = 4;               // Máximo de Velas Consecutivas

input group "Filtro: Días de la Semana"
input bool              InpPermitirLunes     = true;
input bool              InpPermitirMartes    = true;
input bool              InpPermitirMiercoles = true;
input bool              InpPermitirJueves    = true;
input bool              InpPermitirViernes   = false;

// --- Configuración del Sistema ---
input group "Sistema"
input int               InpMagic             = 12347;           // Magic Number
input string            InpStrategyName      = "ruptura-rango-tester"; // Nombre Estrategia
input bool              InpPrintCSV          = true;            // ¿Imprimir CSV?

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                               |
//+------------------------------------------------------------------+
CRupturaEngine engine;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Transferencia de Inputs al Motor ---
   
   // Horario y Rango
   engine.time_frame          = InpTF;
   engine.modo_horario        = InpModoHorario;
   engine.zona_mercado        = InpZonaMercado;
   engine.hora_inicio_rango   = InpHoraInicioRango;
   engine.hora_fin_rango      = InpHoraFinRango;
   engine.rango_minimo_puntos = InpRangoMinPoints;
   
   // Operativa
   engine.hora_inicio_operativa = InpHoraInicioOp;
   engine.hora_fin_operativa    = InpHoraFinOp;
   engine.cerramos_trades       = InpCerramosTrades;
   engine.hora_fin_sesion       = InpHoraFinSesion;
   engine.direccion             = InpDireccion;
   engine.permitir_buy          = InpPermitirBuy;
   engine.permitir_sell         = InpPermitirSell;
   
   // Riesgo
   engine.puntos_sl         = InpPointsSL;
   engine.ratio             = InpRatioTP;
   engine.sl_fijo           = InpSLFijo;
   engine.Lots              = InpLots;
   engine.porcentaje_riesgo = InpRiskPercent;
   engine.usar_scoring      = InpUseScoring;
   
   // Gestión Dinámica SL
   engine.usar_mover_sl_a_be = InpUseBE;
   engine.ratio_activacion_be = InpRatioBE;
   engine.porcentaje_sl_nuevo = InpPercentSLNew;
   
   // Filtros
   engine.usar_filtro_opening_range_size = InpUseRangeSize;
   engine.opening_range_size            = InpRangeSizeLimit;
   engine.opening_range_size_mayor_que        = InpRangeSizeIsMax;
   
   engine.usar_filtro_atr               = InpUseATR;
   engine.atr_limit                     = InpATRLimit;
   engine.atr_limit_mayor_que                 = InpATRIsMax;
   
   engine.usar_filtro_volumen           = InpUseVolume;
   engine.volumen_limite                = InpVolumeLimit;
   
   engine.usar_filtro_distancia_ruptura = InpUseDistBreakout;
   engine.distancia_ruptura_maxima      = InpDistBreakoutLimit;
   engine.usar_filtro_exclusion_rango   = InpUseRangeExcl;
   engine.usar_filtro_sma200            = InpUseSMA200;
   engine.usar_filtro_vwap              = InpUseVWAP;
   engine.vwap_multiplicador_atr        = InpVWAPMult;
   engine.usar_filtro_velas_consecutivas = InpUseConsec;
   engine.max_velas_consecutivas        = InpMaxConsec;
   
   // Días
   engine.permitir_lunes     = InpPermitirLunes;
   engine.permitir_martes    = InpPermitirMartes;
   engine.permitir_miercoles = InpPermitirMiercoles;
   engine.permitir_jueves    = InpPermitirJueves;
   engine.permitir_viernes   = InpPermitirViernes;
   
   // Sistema
   engine.MagicNumber       = InpMagic;
   engine.nombre_estrategia = InpStrategyName;
   engine.imprimir_csv      = InpPrintCSV;

   return engine.Init();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   engine.OnTick();
}
//+------------------------------------------------------------------+
