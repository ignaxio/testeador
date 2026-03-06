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

// --- Gestión de SL Dinámico ---
void AplicarGestionSLDinamico(long magic, bool activar, double ratio_act, double porc_nuevo)
{
   if(!activar) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == magic)
      {
         double precio_ent = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl_actual  = PositionGetDouble(POSITION_SL);
         double tp_actual  = PositionGetDouble(POSITION_TP);
         double precio_act = PositionGetDouble(POSITION_PRICE_CURRENT);
         ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         double distancia_r = MathAbs(precio_ent - sl_actual);
         if(distancia_r <= 0) continue;

         double beneficio_puntos = (tipo == POSITION_TYPE_BUY) ? (precio_act - precio_ent) : (precio_ent - precio_act);
         double r_actual = beneficio_puntos / distancia_r;

         if(r_actual >= ratio_act)
         {
            double nuevo_sl;
            if(tipo == POSITION_TYPE_BUY)
               nuevo_sl = precio_ent - (distancia_r * (1.0 - (porc_nuevo / 100.0)));
            else
               nuevo_sl = precio_ent + (distancia_r * (1.0 - (porc_nuevo / 100.0)));

            // Verificar si el movimiento es una mejora para evitar errores de modificación
            if((tipo == POSITION_TYPE_BUY && nuevo_sl > sl_actual + _Point) || (tipo == POSITION_TYPE_SELL && nuevo_sl < sl_actual - _Point))
            {
               CTrade trade_mod;
               trade_mod.PositionModify(ticket, nuevo_sl, tp_actual);
               Print("SL Dinámico: Ticket ", ticket, " movido a ", nuevo_sl, " (R actual: ", NormalizeDouble(r_actual, 2), ")");
            }
         }
      }
   }
}
