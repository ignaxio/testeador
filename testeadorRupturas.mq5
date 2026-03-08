//+------------------------------------------------------------------+
//|                                           testeadorRupturas.mq5  |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property version   "1.4"
#property strict

#include "Include/RupturaEngine.mqh"

//=========================
// INPUTS
//=========================

input group "--- Configuración de Rango (UTC) ---"
input ENUM_TIMEFRAMES time_frame_in = PERIOD_M5;        // Temporalidad del gráfico
input string hora_inicio_rango_in      = "09:00";       // Hora inicio cálculo rango (UTC)
input string hora_fin_rango_in         = "09:30";       // Hora fin cálculo rango (UTC)
input int    rango_minimo_puntos_in    = 2;             // Tamaño mínimo del rango (puntos)

input group "--- Configuración Operativa (UTC) ---"
input string hora_inicio_operativa_in  = "09:31";       // Hora inicio para buscar entradas (UTC)
input string hora_fin_operativa_in     = "12:00";       // Hora fin para buscar entradas (UTC)
input bool   cerramos_trades_in        = true;          // ¿Cerrar trades al final de la sesión?
input string hora_fin_sesion_in        = "18:00";       // Hora de cierre forzoso (UTC)
input ENUM_DIRECCION direccion_in      = Continuacion;  // Dirección: Continuación o Reversión
input bool   permitir_buy_in           = true;          // Permitir operaciones de COMPRA
input bool   permitir_sell_in          = true;          // Permitir operaciones de VENTA

input group "--- Gestión de Riesgo ---"
input int    puntos_sl_in              = 100;           // Puntos de Stop Loss
input double ratio_in                  = 3.0;           // Ratio Take Profit (Ej: 3.0 = 1:3)
input bool   sl_fijo_in                = true;          // ¿Usar lote fijo (true) o riesgo % (false)?
input double Lots_in                   = 0.1;           // Volumen de lote fijo
input double porcentaje_riesgo_in      = 1.0;           // Porcentaje de riesgo por operación

input group "--- Gestión de SL Dinámico (Pruebas) ---"
input bool   usar_mover_sl_a_be_in  = false; // Activar movimiento de SL
input double ratio_activacion_be_in = 2.0;   // Ratio para activar (Ej: 2.0 para 2R)
input double porcentaje_sl_nuevo_in = 50.0;  // Nuevo SL % (50% = mitad del riesgo inicial)

input group "--- Filtros de Entrada ---"
input bool   usar_filtro_volumen_in    = false;         // Activar filtro de volumen real
input int    volumen_limite_in         = 1000;          // Volumen mínimo requerido
input bool   usar_filtro_opening_range_size_in = false; // Activar filtro tamaño de rango
input double opening_range_size_in      = 50.0;         // Tamaño mínimo del rango (puntos)
input bool   usar_filtro_distancia_ruptura_in = false;  // Activar filtro distancia ruptura
input double distancia_ruptura_maxima_in = 10.0;        // Distancia máxima permitida (puntos)

input group "--- Configuración del Sistema ---"
input int MagicNumber_in               = 12345;         // Identificador único del EA
input string nombre_estrategia_in      = "ORB_Strategy_v1"; // Nombre para el log de trades

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // Mapeo de inputs a variables del motor
   time_frame = time_frame_in;
   hora_inicio_rango = hora_inicio_rango_in;
   hora_fin_rango = hora_fin_rango_in;
   rango_minimo_puntos = rango_minimo_puntos_in;
   
   hora_inicio_operativa = hora_inicio_operativa_in;
   hora_fin_operativa = hora_fin_operativa_in;
   cerramos_trades = cerramos_trades_in;
   hora_fin_sesion = hora_fin_sesion_in;
   direccion = direccion_in;
   permitir_buy = permitir_buy_in;
   permitir_sell = permitir_sell_in;
   
   puntos_sl = puntos_sl_in;
   ratio = ratio_in;
   sl_fijo = sl_fijo_in;
   Lots = Lots_in;
   porcentaje_riesgo = porcentaje_riesgo_in;
   
   usar_mover_sl_a_be  = usar_mover_sl_a_be_in;
   ratio_activacion_be = ratio_activacion_be_in;
   porcentaje_sl_nuevo = porcentaje_sl_nuevo_in;
   
   usar_filtro_volumen = usar_filtro_volumen_in;
   volumen_limite = volumen_limite_in;
   usar_filtro_opening_range_size = usar_filtro_opening_range_size_in;
   opening_range_size = opening_range_size_in;
   usar_filtro_distancia_ruptura = usar_filtro_distancia_ruptura_in;
   distancia_ruptura_maxima = distancia_ruptura_maxima_in;
   
   MagicNumber = MagicNumber_in;
   nombre_estrategia = nombre_estrategia_in;

   return EngineOnInit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   EngineOnTick();
}
