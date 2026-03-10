//+------------------------------------------------------------------+
//|                                       rango10continuacion.mq5     |
//|                                  Copyright 2026, Ignasi Farré     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "1.0"
#property strict
#property description "Robot de trading basado en la estrategia de ruptura y continuación del rango de apertura de Londres (09:00 - 09:30). Opera en M2 buscando un ratio 3:1 con gestión de riesgo del 1% por operación."

#include "..\..\..\Include\RupturaEngine.mqh"

// NO HAY INPUTS AQUÍ - Parámetros fijos para uso profesional

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
   
   // --- Configuración Operativa ---
   hora_inicio_operativa = "09:31";
   hora_fin_operativa    = "12:00";
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
   
   // --- Filtros ---
   usar_filtro_volumen           = false;
   volumen_limite                = 500;
   usar_filtro_opening_range_size = true;
   opening_range_size            = 2000;
   usar_filtro_distancia_ruptura  = false;
   distancia_ruptura_maxima      = 10.0;
   usar_filtro_exclusion_rango   = true;
   
   // --- Sistema ---
   MagicNumber       = 99901;
   nombre_estrategia = "rango10-continuacion-pro-v1";
   imprimir_csv      = false;

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
