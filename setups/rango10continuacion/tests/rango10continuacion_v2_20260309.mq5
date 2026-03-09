//+------------------------------------------------------------------+
//|                               rango10continuacion_v2_20260309.mq5 |
//|                                  Copyright 2026, Ignasi Farré     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property strict

#include "..\..\..\Include\RupturaEngine.mqh"

// NO HAY INPUTS AQUÍ - Parámetros fijos para uso profesional optimizado (V2)

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Rango ---
   time_frame          = PERIOD_M2;
   modo_horario        = MODO_BROKER; // MODO_MERCADO (Auto DST) o MODO_BROKER (Estático)
   zona_mercado        = ZONE_LONDON;
   hora_inicio_rango   = "09:00";
   hora_fin_rango      = "09:30";
   rango_minimo_puntos = 100;
   
   // --- Configuración Operativa (Optimización V2) ---
   hora_inicio_operativa = "09:31";
   hora_fin_operativa    = "11:00"; // Reducido de 12:00 para evitar estancamiento
   cerramos_trades       = true;
   hora_fin_sesion       = "20:30";
   direccion             = Continuacion;
   permitir_buy          = true;
   permitir_sell         = true;
   
   // --- Gestión de Riesgo ---
   puntos_sl         = 10000;
   ratio             = 3;
   sl_fijo           = false; // Usar riesgo por porcentaje
   Lots              = 0.1;
   porcentaje_riesgo = 1;
   
   // --- Filtros (Optimización V2) ---
   usar_filtro_volumen           = false;
   volumen_limite                = 500;
   usar_filtro_opening_range_size = true;
   opening_range_size            = 2500; // Incrementado de 2000 tras análisis
   usar_filtro_distancia_ruptura  = false;
   distancia_ruptura_maxima      = 10.0;
   usar_filtro_exclusion_rango   = true;
   usar_filtro_sma200            = true; // Nuevo filtro de tendencia
   
   // --- Filtro de Días (Optimización V2) ---
   permitir_lunes     = true;
   permitir_martes    = true;
   permitir_miercoles = true;
   permitir_jueves    = true;
   permitir_viernes   = false; // Desactivado por baja esperanza estadística
   
   // --- Sistema ---
   MagicNumber       = 88902; // Rango 88x para tests
   nombre_estrategia = "rango10continuacion_v2_test";

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
