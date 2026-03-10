//+------------------------------------------------------------------+
//|                                   rangoOpenNewYorkReversion.mq5  |
//|                                  Copyright 2026, Ignasi Farré    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "3.0"
#property strict

#include "..\..\..\Include\RupturaEngine.mqh"

// NO HAY INPUTS - Parámetros fijos para uso profesional optimizado (v3.0)

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Horario ---
   modo_horario      = MODO_MERCADO;
   zona_mercado      = ZONE_NEWYORK;
   
   // --- Configuración de Rango (M2) ---
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
   
   // --- Gestión de Riesgo (Optimizado) ---
   puntos_sl         = 6000;
   ratio             = 3.0;
   sl_fijo           = false;
   Lots              = 0.1;
   porcentaje_riesgo = 1.0;
   
   // --- Gestión de SL Dinámico (Desactivado) ---
   usar_mover_sl_a_be  = false;
   ratio_activacion_be = 2.0;
   porcentaje_sl_nuevo = 50.0;
   
   // --- Filtros de Entrada (v2.2 / v3.0 Final) ---
   usar_filtro_volumen           = false;
   volumen_limite                = 1000;
   usar_filtro_opening_range_size = false;
   opening_range_size            = 2000;
   usar_filtro_distancia_ruptura  = false;
   distancia_ruptura_maxima      = 10.0;
   
   // Filtros Especiales
   usar_filtro_exclusion_rango   = true;  // Excluye rangos entre 3100 y 4500 puntos
   usar_filtro_velas_consecutivas = false; // Descartado tras backtest
   usar_filtro_vwap               = false; // Descartado tras backtest
   usar_filtro_londres            = false; // Descartado tras backtest
   
   // --- Filtro de Días ---
   permitir_lunes     = true;
   permitir_martes    = true;
   permitir_miercoles = true;
   permitir_jueves    = true;
   permitir_viernes   = true;
   
   // --- Configuración del Sistema ---
   MagicNumber       = 12347;
   nombre_estrategia = "ny-reversion-pro-v3";
   imprimir_csv      = true;

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
