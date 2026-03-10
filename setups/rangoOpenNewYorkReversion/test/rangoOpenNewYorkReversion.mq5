//+------------------------------------------------------------------+
//|                                   rangoOpenNewYorkReversion.mq5  |
//|                                  Copyright 2026, Ignasi Farré    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "1.0"
#property strict

#include "..\..\..\Include\RupturaEngine.mqh"

// --- INPUTS PARA OPTIMIZACIÓN (Temporales para pruebas) ---
input group "=== Filtros de Testeo ==="
input bool   inp_usar_vwap      = false; // Test: Filtro VWAP
input double inp_vwap_atr_mult  = 0.5;   // Mult. ATR para VWAP

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Horario ---
   modo_horario      = MODO_MERCADO;
   zona_mercado      = ZONE_NEWYORK;
   
   // --- Configuración de Rango ---
   time_frame          = PERIOD_M2;
   hora_inicio_rango   = "09:15";
   hora_fin_rango      = "09:30";
   rango_minimo_puntos = 100;
   
   // --- Configuración Operativa ---
   hora_inicio_operativa = "09:31";
   hora_fin_operativa    = "11:00";
   cerramos_trades       = false;
   hora_fin_sesion       = "14:30";
   direccion             = Reversion;
   permitir_buy          = true;
   permitir_sell         = true;
   
   // --- Gestión de Riesgo ---
   puntos_sl         = 6000;
   ratio             = 3.0;
   sl_fijo           = true;
   Lots              = 0.1;
   porcentaje_riesgo = 1.0;
   
   // --- Gestión de SL Dinámico (Pruebas) ---
   usar_mover_sl_a_be  = false;
   ratio_activacion_be = 2.0;
   porcentaje_sl_nuevo = 50.0;
   
   // --- Filtros de Entrada ---
   usar_filtro_volumen           = false;
   volumen_limite                = 1000;
   usar_filtro_opening_range_size = false;
   opening_range_size            = 2000;
   usar_filtro_distancia_ruptura  = false;
   distancia_ruptura_maxima      = 10.0;
   
   // --- Filtros de Testeo (VWAP) ---
   usar_filtro_vwap     = inp_usar_vwap;
   vwap_multiplicador_atr = inp_vwap_atr_mult;
   
   // --- Configuración del Sistema ---
   MagicNumber       = 12345;
   nombre_estrategia = "test-newyork";

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
