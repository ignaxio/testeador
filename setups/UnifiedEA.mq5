//+------------------------------------------------------------------+
//|                                                   UnifiedEA.mq5 |
//|                                  Copyright 2026, Ignasi Farré     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Ignasi Farré"
#property link      "https://www.mql5.com"
#property version   "3.0"
#property strict

#include "..\Include\RupturaEngine.mqh"
#include "..\Include\GestionRiesgo.mqh"

// --- INPUTS DE GESTIÓN DE RIESGO (FONDEO) ---
input group "=== Configuración Cuenta Fondeo ==="
input double InpBalance          = 100000.0; // Balance Inicial Cuenta
input double InpDailyMaxLoss     = 4.0;      // % Máximo Pérdida Diaria
input double InpTotalMaxLoss     = 10.0;     // % Máximo Pérdida Total
input double InpTargetProfit     = 10.0;     // % Objetivo de Beneficio
input bool   InpHardStop         = true;     // Detener EA si se tocan límites

input group "=== Estrategias Activas ==="
input bool   InpLndEnable        = true;     // Activar Londres Continuación
input bool   InpNYEnable         = true;     // Activar NY Reversión
input double InpRiskBase         = 0.5;      // % Riesgo Base por Trade

// --- OBJETOS GLOBALES ---
CRupturaEngine       engineLnd;
CRupturaEngine       engineNY;
CGestionRiesgoUnified riskControl;

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

   // 2. Configurar Estrategia LONDRES (Continuación)
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
      engineLnd.porcentaje_riesgo = InpRiskBase;
      engineLnd.usar_filtro_opening_range_size = true;
      engineLnd.opening_range_size = 2500;
      engineLnd.usar_filtro_exclusion_rango = true;
      engineLnd.usar_filtro_sma200 = true;
      engineLnd.permitir_viernes   = false;
      
      if(engineLnd.Init() != INIT_SUCCEEDED) return INIT_FAILED;
   }

   // 3. Configurar Estrategia NUEVA YORK (Reversión)
   if(InpNYEnable)
   {
      engineNY.nombre_estrategia  = "NY_Reversion";
      engineNY.MagicNumber        = 88201;
      engineNY.time_frame         = PERIOD_M2;
      engineNY.modo_horario       = MODO_MERCADO;
      engineNY.zona_mercado       = ZONE_NEWYORK;
      engineNY.hora_inicio_rango  = "09:15";
      engineNY.hora_fin_rango     = "09:30";
      engineNY.hora_inicio_operativa = "09:31";
      engineNY.hora_fin_operativa    = "11:00";
      engineNY.cerramos_trades       = false;
      engineNY.hora_fin_sesion       = "14:30";
      engineNY.direccion          = Reversion;
      engineNY.puntos_sl          = 6000;
      engineNY.ratio              = 3.0;
      engineNY.porcentaje_riesgo  = InpRiskBase;
      engineNY.usar_filtro_vwap   = false;
      engineNY.usar_filtro_exclusion_rango = true;
      
      if(engineNY.Init() != INIT_SUCCEEDED) return INIT_FAILED;
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Validar si la cuenta está en condiciones de operar
   if(!riskControl.CanOperate()) 
      return;

   // 2. Obtener multiplicador de riesgo dinámico (Safety / Finish)
   double dynamicMult = riskControl.GetDynamicRiskMultiplier();

   // 3. Ejecutar motores
   if(InpLndEnable)
   {
      engineLnd.porcentaje_riesgo = InpRiskBase * dynamicMult;
      engineLnd.OnTick();
   }
   
   if(InpNYEnable)
   {
      engineNY.porcentaje_riesgo = InpRiskBase * dynamicMult;
      engineNY.OnTick();
   }
}
