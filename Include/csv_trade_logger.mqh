//+------------------------------------------------------------------+
//|                                           csv_trade_logger.mqh |
//|                                  Copyright 2024, TradingBot |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, TradingBot"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\ArrayObj.mqh>

#include "PositionCache.mqh"

//+------------------------------------------------------------------+
//| Clase para almacenar datos de un trade específico                |
//+------------------------------------------------------------------+
class CTradeData : public CObject
{
public:
   datetime time_open;
   string   direction;
   double   entry_price;
   double   sl;
   double   tp;
   double   range_size;
   long     ticket;
   string   strategy_id;
   long     magic;
   double   mae_pts;
   double   mfe_pts;
   double   atr_ent;
   
   // Nuevos campos del Caché
   double   r_maximo;

   CTradeData()
   {
      time_open = 0;
      direction = "";
      entry_price = 0;
      sl = 0;
      tp = 0;
      range_size = 0;
      ticket = 0;
      strategy_id = "";
      magic = 0;
      mae_pts = 0;
      mfe_pts = 0;
      r_maximo = 0;
      atr_ent = 0;
   }
};

//+------------------------------------------------------------------+
//| Clase para el logueo de trades en CSV                           |
//+------------------------------------------------------------------+
class CCSVTradeLogger
{
private:
   string            m_filename;
   string            m_subfolder;
   CArrayObj         m_active_trades;

public:
   CCSVTradeLogger()
   {
      m_subfolder = "probadorEstrategiasRupturaRango_tests\\";
   }

   ~CCSVTradeLogger()
   {
   }

   void SetStrategyName(string name)
   {
      m_filename = name + ".csv";
   }

   void Init()
   {
      InitFile();
   }

   void InitFile()
   {
      if(!FileIsExist(m_filename, FILE_COMMON))
      {
         int handle = FileOpen(m_filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
         if(handle != INVALID_HANDLE)
         {
            Print("Creando nuevo archivo CSV en carpeta COMMON: ", m_filename);
            FileWrite(handle, 
               "Strategy", "Magic", "Date", "TimeOpen", "TimeClose", "Direction", "EntryPrice", "StopLoss", "TakeProfit", 
               "ResultPoints", "ResultR", "MAE_Points", "MFE_Points", "R_Maximo", "ATR_Entry",
               "Duration_Minutes", "OpeningRangeSize", 
               "DayOfWeek", "Month"
            );
            FileClose(handle);
         }
      }
   }

   // Captura los datos iniciales cuando se abre una operación
   void OnTradeOpen(string strategy_name, long magic_num, ENUM_ORDER_TYPE tipo, double price, double sl, double tp, ENUM_TIMEFRAMES tf, double range_size, double atr_val)
   {
      CTradeData *new_trade = new CTradeData();
      new_trade.strategy_id = strategy_name;
      new_trade.magic = magic_num;
      new_trade.time_open = TimeCurrent();
      new_trade.direction = (tipo == ORDER_TYPE_BUY) ? "LONG" : "SHORT";
      new_trade.entry_price = price;
      new_trade.sl = sl;
      new_trade.tp = tp;
      new_trade.range_size = range_size;
      new_trade.mae_pts = 0;
      new_trade.mfe_pts = 0;
      new_trade.atr_ent = atr_val;
      
      m_active_trades.Add(new_trade);
   }

   void SetActiveTicket(long ticket) 
   { 
      if(m_active_trades.Total() > 0)
      {
         CTradeData *last = (CTradeData*)m_active_trades.At(m_active_trades.Total() - 1);
         if(last != NULL)
            last.ticket = ticket;
      }
   }

   // Actualiza MAE/MFE y detecta el cierre
   void OnTick(CPositionCache *cache = NULL)
   {
      for(int i = m_active_trades.Total() - 1; i >= 0; i--)
      {
         CTradeData *trade_data = (CTradeData*)m_active_trades.At(i);
         if(trade_data == NULL || trade_data.ticket == 0)
            continue;

         if(PositionSelectByTicket(trade_data.ticket))
         {
            double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            double current_profit_pts = 0;
            if(pos_type == POSITION_TYPE_BUY)
               current_profit_pts = (current_price - open_price) / _Point;
            else
               current_profit_pts = (open_price - current_price) / _Point;

            if(current_profit_pts > trade_data.mfe_pts)
               trade_data.mfe_pts = current_profit_pts;
               
            if(current_profit_pts < 0)
            {
               double loss_pts = MathAbs(current_profit_pts);
               if(loss_pts > trade_data.mae_pts)
                  trade_data.mae_pts = loss_pts;
            }
         }
         else
         {
            // La posición se ha cerrado
            // Si hay caché, capturamos los datos finales antes de borrar
            if(cache != NULL)
            {
               CPositionState *state = cache.Get(trade_data.ticket);
               if(state != NULL)
               {
                  trade_data.r_maximo = state.r_maximo;
                  trade_data.atr_ent = state.atr_ent;
                  
                  // Sobrescribir MAE/MFE de precisión si el caché tiene datos mejores
                  double open_price = state.precio_ent;
                  double riesgo_pts = MathAbs(state.precio_ent - state.sl_inicial) / _Point;
                  
                  if(riesgo_pts > 0)
                  {
                     bool es_buy = (state.sl_inicial < state.precio_ent);
                     double mfe_final_pts = es_buy ? (state.precio_max - open_price) : (open_price - state.precio_min);
                     double mae_final_pts = es_buy ? (open_price - state.precio_min) : (state.precio_max - open_price);
                     
                     if(mfe_final_pts / _Point > trade_data.mfe_pts) trade_data.mfe_pts = mfe_final_pts / _Point;
                     if(mae_final_pts / _Point > trade_data.mae_pts) trade_data.mae_pts = mae_final_pts / _Point;
                  }
               }
            }
            
            DetectAndLogClose(trade_data, i, cache);
         }
      }
   }

private:
   void DetectAndLogClose(CTradeData *trade_data, int index, CPositionCache *cache = NULL)
   {
      if(HistorySelectByPosition(trade_data.ticket))
      {
         int total = HistoryDealsTotal();
         for(int i = total - 1; i >= 0; i--)
         {
            ulong deal_ticket = HistoryDealGetTicket(i);
            if(deal_ticket > 0)
            {
               long entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
               if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
               {
                  double exit_price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
                  datetime time_close = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
                  int duration_min = (int)((time_close - trade_data.time_open) / 60);

                  WriteToCSV(trade_data, exit_price, time_close, duration_min);
                  
                  Print("Trade logueado en CSV automáticamente por el logger. Ticket: ", trade_data.ticket);
                  
                  // Limpiar caché ahora que ya hemos logueado
                  if(cache != NULL)
                     cache.Remove(trade_data.ticket);
                     
                  m_active_trades.Delete(index);
                  return;
               }
            }
         }
      }
      // Si no encontramos el deal de salida pero la posicion ya no existe
      if(cache != NULL)
         cache.Remove(trade_data.ticket);
      m_active_trades.Delete(index);
   }

   void WriteToCSV(CTradeData *trade_data, double exit_price, datetime time_close, int duration)
   {
      double res_points = 0;
      if(trade_data.direction == "LONG")
         res_points = (exit_price - trade_data.entry_price) / _Point;
      else
         res_points = (trade_data.entry_price - exit_price) / _Point;

      double stop_dist = MathAbs(trade_data.entry_price - trade_data.sl);
      double res_r = 0;
      if(stop_dist > 0)
         res_r = (MathAbs(exit_price - trade_data.entry_price)) / stop_dist;
      
      if(res_points < 0) res_r = -MathAbs(res_r);
      else res_r = MathAbs(res_r);

      // Normalizar puntos
      res_points = NormalizeDouble(res_points, 1);
      res_r = NormalizeDouble(res_r, 2);

      MqlDateTime dt;
      TimeToStruct(trade_data.time_open, dt);
      
      int handle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
      if(handle != INVALID_HANDLE)
      {
         Print("Escribiendo datos del trade en CSV (Carpeta COMMON)...");
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, 
            trade_data.strategy_id,
            IntegerToString(trade_data.magic),
            TimeToString(trade_data.time_open, TIME_DATE),
            TimeToString(trade_data.time_open, TIME_MINUTES),
            TimeToString(time_close, TIME_MINUTES),
            trade_data.direction,
            DoubleToString(trade_data.entry_price, _Digits),
            DoubleToString(trade_data.sl, _Digits),
            DoubleToString(trade_data.tp, _Digits),
            DoubleToString(res_points, 1),
            DoubleToString(res_r, 2),
            DoubleToString(trade_data.mae_pts, 1),
            DoubleToString(trade_data.mfe_pts, 1),
            DoubleToString(trade_data.r_maximo, 2),
            DoubleToString(trade_data.atr_ent, _Digits),
            IntegerToString(duration),
            DoubleToString(trade_data.range_size, 1),
            GetDayName(dt.day_of_week),
            GetMonthName(dt.mon)
         );
         FileClose(handle);
         Print("Datos escritos correctamente en carpeta COMMON: ", m_filename);
      }
      else
      {
         Print("Error al abrir el archivo CSV para escribir: ", m_filename, " Error: ", GetLastError());
      }
   }

private:
   string GetDayName(int day)
   {
      switch(day)
      {
         case 1: return "Monday";
         case 2: return "Tuesday";
         case 3: return "Wednesday";
         case 4: return "Thursday";
         case 5: return "Friday";
         case 6: return "Saturday";
         case 0: return "Sunday";
      }
      return "";
   }

   string GetMonthName(int month)
   {
      string months[] = {"", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
      if(month >= 1 && month <= 12)
         return months[month];
      return "";
   }
};
