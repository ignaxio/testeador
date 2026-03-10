//+------------------------------------------------------------------+
//|                                                   UnifiedEA.mq5 |
//|                                  Copyright 2026, Ignasi Farré     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "3.0"
#property strict

#include "..\..\Include\RupturaEngine.mqh"
#include "..\..\Include\GestionRiesgo.mqh"

// --- INPUTS DE GESTIÓN DE RIESGO (FONDEO) ---
input group "=== Configuración Cuenta Fondeo ==="
input double InpBalance          = 100000.0; // Balance Inicial Cuenta
input double InpDailyMaxLoss     = 4.0;      // % Máximo Pérdida Diaria
input double InpTotalMaxLoss     = 10.0;     // % Máximo Pérdida Total
input double InpTargetProfit     = 10.0;     // % Objetivo de Beneficio
input bool   InpHardStop         = true;     // Detener EA si se tocan límites

input group "=== Estrategias Activas ==="
input bool   InpLndEnable        = true;     // Activar Londres Continuación
input bool   InpNYEnable         = true;     // Activar NY Reversión (Lunes-Jueves)
input bool   InpNYFridaysEnable  = true;     // Activar NY Reversión (Viernes)

input group "=== Riesgo por Grupo de Estrategia ==="
input double InpRiskGroupA         = 0.5;      // % Riesgo Grupo A (NY Viernes)
input double InpRiskGroupB         = 0.35;     // % Riesgo Grupo B (Londres)
input double InpRiskGroupC         = 0.2;      // % Riesgo Grupo C (NY Lunes-Jueves)

// --- OBJETOS GLOBALES ---
CRupturaEngine       engineLnd;
CRupturaEngine       engineNY;
CRupturaEngine       engineNYFridays;
CGestionRiesgoUnified riskControl;

// --- VARIABLES DE ESTADO ---
double   g_dynamic_mult = 1.0;
bool     g_can_operate = true;
datetime g_last_bar_risk = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // 0. Auto-detección de Balance (Soporte para Backtest y Prop Firm)
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double initial_b = InpBalance;

   if(initial_b <= 0) 
   {
      initial_b = currentBalance;
      Print("GESTIÓN RIESGO: Balance Inicial AUTO-DETECTADO en ", initial_b);
   }
   else if(MQLInfoInteger(MQL_TESTER) && initial_b != currentBalance)
   {
      Print("GESTIÓN RIESGO (Tester): Balance configurado (", initial_b, ") no coincide con el balance del probador (", currentBalance, "). Ajustando...");
      initial_b = currentBalance;
   }

   // 1. Configurar Módulo de Riesgo
   riskControl.Configure(initial_b, InpTargetProfit, InpDailyMaxLoss, InpTotalMaxLoss, InpHardStop);
   riskControl.PrintStatus();

   // 2. Configurar Estrategia LONDRES (Continuación) - GRUPO B
   if(InpLndEnable)
   {
      engineLnd.nombre_estrategia = "Lnd_Continuacion";
      engineLnd.MagicNumber       = 88101;
      engineLnd.time_frame        = PERIOD_M2;
      engineLnd.modo_horario      = MODO_BROKER;
      engineLnd.hora_inicio_rango = "09:00";
      engineLnd.hora_fin_rango    = "09:30";
      engineLnd.hora_inicio_operativa = "09:31";
      engineLnd.hora_fin_operativa    = "11:00";
      engineLnd.cerramos_trades       = true;
      engineLnd.hora_fin_sesion       = "20:30";
      engineLnd.direccion         = Continuacion;
      engineLnd.puntos_sl         = 10000;
      engineLnd.ratio             = 3.0;
      engineLnd.porcentaje_riesgo = InpRiskGroupB;
      engineLnd.usar_filtro_opening_range_size = false;
      engineLnd.opening_range_size = 2000;
      engineLnd.usar_filtro_exclusion_rango = true;
      engineLnd.usar_filtro_sma200 = false;
      engineLnd.usar_scoring      = false; // Riesgo asignado directamente por Grupo B
      
      if(engineLnd.Init() != INIT_SUCCEEDED) return INIT_FAILED;
   }

   // 3. Configurar Estrategia NUEVA YORK SEMANA (Reversión) - GRUPO C
   if(InpNYEnable)
   {
      engineNY.nombre_estrategia  = "NY_Semana";
      engineNY.MagicNumber        = 88201;
      engineNY.time_frame         = PERIOD_M2;
      engineNY.modo_horario       = MODO_MERCADO;
      engineNY.zona_mercado       = ZONE_NEWYORK;
      engineNY.hora_inicio_rango  = "09:15";
      engineNY.hora_fin_rango     = "09:30";
      engineNY.hora_inicio_operativa = "09:31";
      engineNY.hora_fin_operativa    = "11:00";
      engineNY.cerramos_trades       = true;
      engineNY.hora_fin_sesion       = "14:30";
      engineNY.direccion          = Reversion;
      engineNY.puntos_sl          = 6000;
      engineNY.ratio              = 3.0;
      engineNY.porcentaje_riesgo  = InpRiskGroupC;
      engineNY.usar_filtro_vwap   = false;
      engineNY.usar_filtro_exclusion_rango = true;
      engineNY.permitir_viernes   = false; // Solo de Lunes a Jueves
      engineNY.usar_scoring       = false; // Riesgo asignado directamente por Grupo C
      
      if(engineNY.Init() != INIT_SUCCEEDED) return INIT_FAILED;
   }

   // 4. Configurar Estrategia NUEVA YORK VIERNES (Reversión) - GRUPO A
   if(InpNYFridaysEnable)
   {
      engineNYFridays.nombre_estrategia  = "NY_Viernes";
      engineNYFridays.MagicNumber        = 88202;
      engineNYFridays.time_frame         = PERIOD_M2;
      engineNYFridays.modo_horario       = MODO_MERCADO;
      engineNYFridays.zona_mercado       = ZONE_NEWYORK;
      engineNYFridays.hora_inicio_rango  = "09:15";
      engineNYFridays.hora_fin_rango     = "09:30";
      engineNYFridays.hora_inicio_operativa = "09:31";
      engineNYFridays.hora_fin_operativa    = "11:00";
      engineNYFridays.cerramos_trades       = true;
      engineNYFridays.hora_fin_sesion       = "14:30";
      engineNYFridays.direccion          = Reversion;
      engineNYFridays.puntos_sl          = 6000;
      engineNYFridays.ratio              = 3.0;
      engineNYFridays.porcentaje_riesgo  = InpRiskGroupA;
      engineNYFridays.usar_filtro_vwap   = false;
      engineNYFridays.usar_filtro_exclusion_rango = true;
      engineNYFridays.permitir_lunes     = false;
      engineNYFridays.permitir_martes    = false;
      engineNYFridays.permitir_miercoles = false;
      engineNYFridays.permitir_jueves    = false;
      engineNYFridays.permitir_viernes   = true; // Solo Viernes
      engineNYFridays.usar_scoring       = false; // Riesgo asignado directamente por Grupo A
      
      if(engineNYFridays.Init() != INIT_SUCCEEDED) return INIT_FAILED;
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. SEGURIDAD (OnTick): Esto DEBE ejecutarse en cada tick por protección de la cuenta (Equity).
   // Cerramos todas las posiciones inmediatamente si se alcanza el Profit Target o el Max Loss.
   riskControl.CheckGlobalLimits();

   // 2. OPERATIVA DE ENTRADAS (Optimizado OnBar): Validamos límites de fondeo y riesgo dinámico
   // solo al cierre de vela para evitar cálculos innecesarios en cada tick.
   datetime current_bar = iTime(_Symbol, PERIOD_M2, 0);
   if(current_bar != g_last_bar_risk)
   {
      g_last_bar_risk = current_bar;
      g_can_operate = riskControl.CanOperate();
      if(g_can_operate)
         g_dynamic_mult = riskControl.GetDynamicRiskMultiplier();
   }

   // 3. GESTIÓN DE MOTORES
   // El OnTick de cada motor ahora es inteligente: gestiona SL/Cierres en cada tick 
   // pero busca nuevas entradas solo al cierre de vela.
   if(InpLndEnable)
   {
      if(g_can_operate) engineLnd.porcentaje_riesgo = InpRiskGroupB * g_dynamic_mult;
      else engineLnd.porcentaje_riesgo = 0; // Bloqueo de entradas
      
      engineLnd.OnTick();
   }
   
   if(InpNYEnable)
   {
      if(g_can_operate) engineNY.porcentaje_riesgo = InpRiskGroupC * g_dynamic_mult;
      else engineNY.porcentaje_riesgo = 0; // Bloqueo de entradas
      
      engineNY.OnTick();
   }

   if(InpNYFridaysEnable)
   {
      if(g_can_operate) engineNYFridays.porcentaje_riesgo = InpRiskGroupA * g_dynamic_mult;
      else engineNYFridays.porcentaje_riesgo = 0; // Bloqueo de entradas
      
      engineNYFridays.OnTick();
   }
}
