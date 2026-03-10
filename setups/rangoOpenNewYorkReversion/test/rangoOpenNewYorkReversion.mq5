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

// --- INPUTS PARA OPTIMIZACIÓN (Configuración v2.2) ---
input group "=== Filtros de Testeo (v2.2) ==="
input bool   inp_usar_exclusion_rango = true;  // Exclusión Rango (3100-4500)
input bool   inp_usar_filtro_velas    = true;  // Filtro Velas Consecutivas
input int    inp_max_velas_consec     = 3;     // Máximo velas permitidas

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
   
   // --- Filtros de Entrada (v2.2) ---
   usar_filtro_volumen           = false;
   volumen_limite                = 1000;
   usar_filtro_opening_range_size = false;
   opening_range_size            = 2000;
   usar_filtro_distancia_ruptura  = false;
   distancia_ruptura_maxima      = 10.0;
   
   // --- Aplicar Configuración v2.2 ---
   usar_filtro_exclusion_rango   = inp_usar_exclusion_rango;
   usar_filtro_velas_consecutivas = inp_usar_filtro_velas;
   max_velas_consecutivas         = inp_max_velas_consec;
   
   usar_filtro_vwap     = false;
   vwap_multiplicador_atr = 0.0;
   usar_filtro_londres  = false;
   
   // --- Configuración del Sistema ---
   MagicNumber       = 12345;
   nombre_estrategia = "test-newyork-v2.2";

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
