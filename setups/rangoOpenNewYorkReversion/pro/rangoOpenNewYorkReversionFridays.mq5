//+------------------------------------------------------------------+
//|                                 rangoOpenNewYorkReversionv2.mq5  |
//|                                  Copyright 2026, Ignasi Farré    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "2.0"
#property strict

#include "..\..\..\Include\RupturaEngine.mqh"

// NO HAY INPUTS AQUÍ - Parámetros fijos para uso profesional optimizado (V2: Ratio dinámico por día)

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
   puntos_sl         = 5000;
   ratio             = 3.0; // Ratio base (se ajustará dinámicamente en OnTick)
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
   
   // --- Configuración del Sistema ---
   MagicNumber       = 12346; // Cambiado para diferenciar de la v1
   nombre_estrategia = "newyork-reversion-v2";
   imprimir_csv      = false;

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   MqlDateTime dt;
   TimeCurrent(dt);

    permitir_lunes = false;
    permitir_martes = false;
    permitir_miercoles = false;
    permitir_jueves = false;


   EngineOnTick();
}
