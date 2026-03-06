//+------------------------------------------------------------------+
//|                                                 GestionRiesgo.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

//=========================
// FUNCIONES DE GESTIÓN DE RIESGO
//=========================

double CalcularLotePorRiesgo(int sl_points, double risk_percent)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double riesgo_dinero = balance * risk_percent / 100.0;

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double valor_punto_por_lote = tick_value / tick_size;

   double riesgo_por_lote = sl_points * _Point * valor_punto_por_lote;

   double volumen_min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volumen_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(riesgo_por_lote <= 0)
      return volumen_min;

   double lote = riesgo_dinero / riesgo_por_lote;

   if(lote < volumen_min)
      lote = volumen_min;

   double volumen_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(lote > volumen_max)
      lote = volumen_max;

   lote = MathFloor(lote / volumen_step) * volumen_step;

   int digitos_lote = 0;
   if(volumen_step == 0.1) digitos_lote = 1;
   if(volumen_step == 0.01) digitos_lote = 2;

   return NormalizeDouble(lote, digitos_lote);
}
