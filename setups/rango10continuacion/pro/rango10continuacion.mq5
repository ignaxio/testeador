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

CRupturaEngine engine;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Rango ---
   engine.time_frame          = PERIOD_M2;
   engine.modo_horario        = MODO_BROKER; // MODO_MERCADO (Auto DST) o MODO_BROKER (Estático)
   engine.zona_mercado        = ZONE_LONDON;
   engine.hora_inicio_rango   = "09:00";
   engine.hora_fin_rango      = "09:30";
   engine.rango_minimo_puntos = 100;
   
   // --- Configuración Operativa ---
   engine.hora_inicio_operativa = "09:31";
   engine.hora_fin_operativa    = "12:00";
   engine.cerramos_trades       = true;
   engine.hora_fin_sesion       = "20:30";
   engine.direccion             = Continuacion;
   engine.permitir_buy          = true;
   engine.permitir_sell         = true;
   
   // --- Gestión de Riesgo ---
   engine.puntos_sl         = 10000;
   engine.ratio             = 3;
   engine.sl_fijo           = false; // Usar riesgo por porcentaje
   engine.Lots              = 0.1;
   engine.porcentaje_riesgo = 0.6;
   
   // --- Filtros ---
   engine.usar_filtro_opening_range_size = true;
   engine.opening_range_size            = 2000;
   engine.opening_range_size_mayor_que        = false;
   engine.usar_filtro_exclusion_rango   = true;
   
   // --- Sistema ---
   engine.MagicNumber       = 99901;
   engine.nombre_estrategia = "rango10-continuacion-pro-v1";
   engine.imprimir_csv      = true;

   return engine.Init();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   engine.OnTick();
}
