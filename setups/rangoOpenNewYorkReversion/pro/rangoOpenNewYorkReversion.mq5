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

CRupturaEngine engine;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Horario ---
   engine.modo_horario      = MODO_MERCADO;
   engine.zona_mercado      = ZONE_NEWYORK;
   
   // --- Configuración de Rango (M2) ---
   engine.time_frame          = PERIOD_M2;
   engine.hora_inicio_rango   = "09:15";
   engine.hora_fin_rango      = "09:30";
   engine.rango_minimo_puntos = 100;
   
   // --- Configuración Operativa ---
   engine.hora_inicio_operativa = "09:31";
   engine.hora_fin_operativa    = "11:00";
   engine.cerramos_trades       = true;
   engine.hora_fin_sesion       = "14:30";
   engine.direccion             = Reversion;
   engine.permitir_buy          = true;
   engine.permitir_sell         = true;
   
   // --- Gestión de Riesgo (Optimizado) ---
   engine.puntos_sl         = 6000;
   engine.ratio             = 3.0;
   engine.sl_fijo           = false;
   engine.Lots              = 0.1;
   engine.porcentaje_riesgo = 0.4;
   
   // --- Gestión de SL Dinámico (Desactivado) ---
   engine.usar_mover_sl_a_be  = false;
   engine.ratio_activacion_be = 2.0;
   engine.porcentaje_sl_nuevo = 50.0;
   
   // --- Filtros de Entrada (v2.2 / v3.0 Final) ---
   engine.usar_filtro_volumen           = false;
   engine.volumen_limite                = 1000;
   engine.usar_filtro_opening_range_size = false;
   engine.opening_range_size            = 6000;
   engine.opening_range_size_max        = true;
   engine.usar_filtro_distancia_ruptura  = false;
   engine.distancia_ruptura_maxima      = 10.0;
   
   // Filtros Especiales
   engine.usar_filtro_exclusion_rango   = true;  // Excluye rangos entre 3100 y 4500 puntos
   engine.usar_filtro_velas_consecutivas = false; // Descartado tras backtest
   engine.usar_filtro_vwap               = false; // Descartado tras backtest
   engine.usar_filtro_londres            = false; // Descartado tras backtest
   
   // --- Filtro de Días ---
   engine.permitir_lunes     = true;
   engine.permitir_martes    = true;
   engine.permitir_miercoles = true;
   engine.permitir_jueves    = true;
   engine.permitir_viernes   = false;
   
   // --- Configuración del Sistema ---
   engine.MagicNumber       = 12347;
   engine.nombre_estrategia = "ny-reversion-pro-v3";
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
