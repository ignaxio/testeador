//+------------------------------------------------------------------+
//|                                                 GestionRiesgo.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Clase Gestión de Riesgo Unified (Prop Firm Optimized)            |
//+------------------------------------------------------------------+
class CGestionRiesgoUnified
{
private:
   double   m_balance_inicial;
   double   m_target_profit;
   double   m_max_pérdida_diaria;
   double   m_max_pérdida_total;
   bool     m_hard_stop;
   bool     m_limit_reached;

   double   GetRealizedDailyProfit()
   {
      datetime today = iTime(_Symbol, PERIOD_D1, 0);
      if(!HistorySelect(today, TimeCurrent())) return 0;
      
      double profit = 0;
      int total = HistoryDealsTotal();
      for(int i=0; i<total; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
         {
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
               profit += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_SWAP);
         }
      }
      return profit;
   }

public:
   CGestionRiesgoUnified() 
   {
      m_balance_inicial = 0;
      m_target_profit = 0;
      m_max_pérdida_diaria = 0;
      m_max_pérdida_total = 0;
      m_hard_stop = true;
      m_limit_reached = false;
   }

   void Configure(double balance, double target_perc, double daily_loss_perc, double total_loss_perc, bool hard_stop)
   {
      m_balance_inicial = balance;
      m_target_profit = balance * (target_perc / 100.0);
      m_max_pérdida_diaria = balance * (daily_loss_perc / 100.0);
      m_max_pérdida_total = balance * (total_loss_perc / 100.0);
      m_hard_stop = hard_stop;
      m_limit_reached = false;
   }

   // --- Lógica de Riesgo Dinámico ---
   double GetDynamicRiskMultiplier()
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double profit_actual = balance - m_balance_inicial;
      double dd_actual = m_balance_inicial - equity;

      // 1. Modo "Finish" (Cerca del objetivo)
      // Si falta menos del 2% para el objetivo, reducimos riesgo a la mitad
      double dist_to_target = m_target_profit - profit_actual;
      if(dist_to_target > 0 && dist_to_target < (m_balance_inicial * 0.02))
         return 0.5;

      // 2. Modo "Safety" (Cerca del Max Loss Total)
      // Riesgo escala linealmente hacia abajo conforme nos acercamos al límite
      if(dd_actual > (m_max_pérdida_total * 0.7)) // Si hemos consumido el 70% del DD permitido
      {
         double dist_to_limit = m_max_pérdida_total - dd_actual;
         double initial_buffer = m_max_pérdida_total;
         double ratio = dist_to_limit / initial_buffer;
         return MathMax(0.2, ratio); // Mínimo 20% del riesgo base
      }

      return 1.0;
   }

   bool CanOperate()
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      // 1. Pérdida Total (Equity vs Balance Inicial)
      if(m_balance_inicial > 0 && m_balance_inicial - equity >= m_max_pérdida_total)
      {
         if(!m_limit_reached && m_hard_stop) {
            Print("GESTIÓN RIESGO: Límite de pérdida TOTAL alcanzado. (Equity: ", NormalizeDouble(equity, 2), " | Límite: ", NormalizeDouble(m_balance_inicial - m_max_pérdida_total, 2), ")");
            m_limit_reached = true;
         }
         return false;
      }

      // 2. Pérdida Diaria (Realizada + Flotante del día)
      double floating_profit = equity - balance;
      double realized_today = GetRealizedDailyProfit();
      double total_today = realized_today + floating_profit;

      if(total_today <= -m_max_pérdida_diaria)
      {
         if(!m_limit_reached && m_hard_stop) {
            Print("GESTIÓN RIESGO: Límite de pérdida DIARIA alcanzado. (Pérdida hoy: ", NormalizeDouble(total_today, 2), " | Límite diario: ", NormalizeDouble(-m_max_pérdida_diaria, 2), ")");
            m_limit_reached = true;
         }
         return false;
      }

      // 3. Objetivo alcanzado
      if(m_balance_inicial > 0 && balance - m_balance_inicial >= m_target_profit)
      {
         if(!m_limit_reached) {
            Print("GESTIÓN RIESGO: Objetivo de beneficio ALCANZADO (", NormalizeDouble(balance - m_balance_inicial, 2), "). Prueba superada.");
            m_limit_reached = true;
         }
         return false;
      }

      m_limit_reached = false; // Reset if conditions are fine
      return true;
   }
   
   // --- Información de Diagnóstico ---
   void PrintStatus()
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      Print("GESTIÓN RIESGO STATUS: Balance Inicial: ", m_balance_inicial, 
            " | Equity Actual: ", NormalizeDouble(equity, 2), 
            " | Drawdown Actual: ", NormalizeDouble(m_balance_inicial - equity, 2), 
            " / ", NormalizeDouble(m_max_pérdida_total, 2));
   }

   void CheckGlobalLimits(long magic = -1)
   {
      if(!CanOperate() && m_hard_stop)
      {
         CTrade trade_close;
         for(int i=PositionsTotal()-1; i>=0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0)
            {
               if(magic == -1 || PositionGetInteger(POSITION_MAGIC) == magic)
                  trade_close.PositionClose(ticket);
            }
         }
      }
   }
};

//=========================
// FUNCIONES DE GESTIÓN DE RIESGO (Compatibilidad)
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
