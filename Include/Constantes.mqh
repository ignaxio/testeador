//+------------------------------------------------------------------+
//|                                                   Constantes.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

//=========================
// ENUMS
//=========================

enum ENUM_MODO_HORARIO
{
   MODO_MERCADO, // Usa la zona horaria (ej. Londres) y ajusta DST automáticamente
   MODO_BROKER   // Usa la hora que veas en el terminal, sin ajustes
};

enum ENUM_DIRECCION
{
   Continuacion = 0,
   Reversion = 1
};

enum ENUM_TRADE_SCORE
{
   SCORE_A = 100, // 100% de riesgo base
   SCORE_B = 70,  // 70% de riesgo base
   SCORE_C = 40   // 40% de riesgo base
};
