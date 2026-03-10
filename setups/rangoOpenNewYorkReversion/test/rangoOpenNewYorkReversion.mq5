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

CRupturaEngine engine;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // --- Configuración de Horario ---
   engine.modo_horario      = MODO_MERCADO;
   engine.zona_mercado      = ZONE_NEWYORK;
   
   // --- Configuración de Rango ---
   engine.time_frame          = PERIOD_M2;
   engine.hora_inicio_rango   = "09:15";
   engine.hora_fin_rango      = "09:30";
   engine.rango_minimo_puntos = 100;
   
   // --- Configuración Operativa ---
   engine.hora_inicio_operativa = "09:31";
   engine.hora_fin_operativa    = "11:00";
   engine.cerramos_trades       = false;
   engine.hora_fin_sesion       = "14:30";
   engine.direccion             = Reversion;
   engine.permitir_buy          = true;
   engine.permitir_sell         = true;
   
   // --- Gestión de Riesgo ---
   engine.puntos_sl         = 6000;
   engine.ratio             = 3.0;
   engine.sl_fijo           = true;
   engine.Lots              = 0.1;
   engine.porcentaje_riesgo = 1.0;
   
   // --- Gestión de SL Dinámico (Pruebas) ---
   engine.usar_mover_sl_a_be  = false;
   engine.ratio_activacion_be = 2.0;
   engine.porcentaje_sl_nuevo = 50.0;
   
   // --- Filtros de Entrada (v2.2) ---
   engine.usar_filtro_volumen           = false;
   engine.volumen_limite                = 1000;
   engine.usar_filtro_opening_range_size = false;
   engine.opening_range_size            = 2000;
   engine.usar_filtro_distancia_ruptura  = false;
   engine.distancia_ruptura_maxima      = 10.0;
   
   // --- Aplicar Configuración v2.2 ---
   engine.usar_filtro_exclusion_rango   = inp_usar_exclusion_rango;
   engine.usar_filtro_velas_consecutivas = inp_usar_filtro_velas;
   engine.max_velas_consecutivas         = inp_max_velas_consec;
   
   engine.usar_filtro_vwap     = false;
   engine.vwap_multiplicador_atr = 0.0;
   engine.usar_filtro_londres  = false;
   
   // --- Configuración del Sistema ---
   engine.MagicNumber       = 12345;
   engine.nombre_estrategia = "test-newyork-v2.2";

   return engine.Init();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   engine.OnTick();
}
