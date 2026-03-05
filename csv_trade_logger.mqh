//+------------------------------------------------------------------+
//|                                           csv_trade_logger.mqh |
//|                                  Copyright 2024, TradingBot |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, TradingBot"
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| Clase para el logueo de trades en CSV                           |
//+------------------------------------------------------------------+
class CCSVTradeLogger
{
private:
   string            m_filename;
   string            m_subfolder;
   int               m_handle_sma200;

   struct TradeLogData
   {
      datetime time_open;
      string   direction;
      double   entry_price;
      double   sl;
      double   tp;
      double   range_size;
      double   atr_val;
      double   yesterday_range;
      double   dist_breakout;
      long     ticket;
      double   mae_pts;
      double   mfe_pts;
      string   sma_trend;
      double   breakout_volume;
      int      spread;
   } m_last_trade;

public:
   CCSVTradeLogger()
   {
      m_subfolder = "probadorEstrategiasRupturaRango_tests\\";
      m_handle_sma200 = INVALID_HANDLE;
      m_last_trade.ticket = 0;
   }

   ~CCSVTradeLogger()
   {
      if(m_handle_sma200 != INVALID_HANDLE)
         IndicatorRelease(m_handle_sma200);
   }

   void SetStrategyName(string name)
   {
      m_filename = name + ".csv";
   }

   void Init()
   {
      InitFile();
      m_handle_sma200 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
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
               "Date", "Time", "Direction", "EntryPrice", "StopLoss", "TakeProfit", 
               "ResultPoints", "ResultR", "MAE_Points", "MFE_Points", "SMA200_Trend", 
               "Breakout_Volume", "Duration_Minutes", "Spread_Entry",
               "OpeningRangeSize", "ATR", "YesterdayRange", "DistanceBreakout", "DayOfWeek", "Month"
            );
            FileClose(handle);
         }
      }
   }

   // Captura los datos iniciales cuando se abre una operación
   void OnTradeOpen(ENUM_ORDER_TYPE tipo, double price, double sl, double tp, double r_top, double r_bottom, ENUM_TIMEFRAMES tf, double breakout_vol)
   {
      m_last_trade.time_open = TimeCurrent();
      m_last_trade.direction = (tipo == ORDER_TYPE_BUY) ? "LONG" : "SHORT";
      m_last_trade.entry_price = price;
      m_last_trade.sl = sl;
      m_last_trade.tp = tp;
      m_last_trade.range_size = r_top - r_bottom;
      m_last_trade.mae_pts = 0;
      m_last_trade.mfe_pts = 0;
      m_last_trade.spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      
      // ATR(14)
      int handle_atr = iATR(_Symbol, tf, 14);
      if(handle_atr != INVALID_HANDLE)
      {
         double atr_buffer[];
         ArraySetAsSeries(atr_buffer, true);
         if(CopyBuffer(handle_atr, 0, 0, 1, atr_buffer) > 0)
            m_last_trade.atr_val = atr_buffer[0];
         IndicatorRelease(handle_atr);
      }

      // Yesterday Range
      m_last_trade.yesterday_range = iHigh(_Symbol, PERIOD_D1, 1) - iLow(_Symbol, PERIOD_D1, 1);
      
      if(tipo == ORDER_TYPE_BUY)
         m_last_trade.dist_breakout = (price - r_top) / _Point;
      else
         m_last_trade.dist_breakout = (r_bottom - price) / _Point;

      // SMA 200 Trend (H1)
      double sma_buffer[];
      ArraySetAsSeries(sma_buffer, true);
      if(CopyBuffer(m_handle_sma200, 0, 0, 1, sma_buffer) > 0)
      {
         double current_price = iClose(_Symbol, PERIOD_H1, 0);
         m_last_trade.sma_trend = (current_price > sma_buffer[0]) ? "ABOVE" : "BELOW";
      }
      else m_last_trade.sma_trend = "UNKNOWN";

      // Datos de Volumen
      m_last_trade.breakout_volume = breakout_vol;
   }

   void SetActiveTicket(long ticket) { m_last_trade.ticket = ticket; }

   // Obtiene el volumen real de la vela indicada (0=actual, 1=cerrada)
   long GetRealVolume(ENUM_TIMEFRAMES tf, int index)
   {
      long volume_buffer[];
      if(CopyTickVolume(_Symbol, tf, index, 1, volume_buffer) > 0)
         return volume_buffer[0];
      return 0;
   }

   // Actualiza MAE/MFE y detecta el cierre
   void OnTick()
   {
      if(m_last_trade.ticket == 0)
         return;

      if(PositionSelectByTicket(m_last_trade.ticket))
      {
         double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         double current_profit_pts = 0;
         if(pos_type == POSITION_TYPE_BUY)
            current_profit_pts = (current_price - open_price) / _Point;
         else
            current_profit_pts = (open_price - current_price) / _Point;

         if(current_profit_pts > m_last_trade.mfe_pts)
            m_last_trade.mfe_pts = current_profit_pts;
            
         if(current_profit_pts < 0)
         {
            double loss_pts = MathAbs(current_profit_pts);
            if(loss_pts > m_last_trade.mae_pts)
               m_last_trade.mae_pts = loss_pts;
         }
      }
      else
      {
         // La posición se ha cerrado
         DetectAndLogClose();
      }
   }

private:
   void DetectAndLogClose()
   {
      if(HistorySelectByPosition(m_last_trade.ticket))
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
                  int duration_min = (int)((time_close - m_last_trade.time_open) / 60);

                  WriteToCSV(exit_price, duration_min);
                  
                  Print("Trade logueado en CSV automáticamente por el logger.");
                  m_last_trade.ticket = 0;
                  break;
               }
            }
         }
      }
      else
      {
         m_last_trade.ticket = 0;
      }
   }

   void WriteToCSV(double exit_price, int duration)
   {
      double res_points = 0;
      if(m_last_trade.direction == "LONG")
         res_points = (exit_price - m_last_trade.entry_price) / _Point;
      else
         res_points = (m_last_trade.entry_price - exit_price) / _Point;

      double stop_dist = MathAbs(m_last_trade.entry_price - m_last_trade.sl);
      double res_r = 0;
      if(stop_dist > 0)
         res_r = (MathAbs(exit_price - m_last_trade.entry_price)) / stop_dist;
      
      if(res_points < 0) res_r = -MathAbs(res_r);
      else res_r = MathAbs(res_r);

      // Normalizar puntos
      res_points = NormalizeDouble(res_points, 1);
      res_r = NormalizeDouble(res_r, 2);

      MqlDateTime dt;
      TimeToStruct(m_last_trade.time_open, dt);
      
      int handle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
      if(handle != INVALID_HANDLE)
      {
         Print("Escribiendo datos del trade en CSV (Carpeta COMMON)...");
         FileSeek(handle, 0, SEEK_END);
         FileWrite(handle, 
            TimeToString(m_last_trade.time_open, TIME_DATE),
            TimeToString(m_last_trade.time_open, TIME_MINUTES),
            m_last_trade.direction,
            DoubleToString(m_last_trade.entry_price, _Digits),
            DoubleToString(m_last_trade.sl, _Digits),
            DoubleToString(m_last_trade.tp, _Digits),
            DoubleToString(res_points, 1),
            DoubleToString(res_r, 2),
            DoubleToString(m_last_trade.mae_pts, 1),
            DoubleToString(m_last_trade.mfe_pts, 1),
            m_last_trade.sma_trend,
            DoubleToString(m_last_trade.breakout_volume, 0),
            IntegerToString(duration),
            IntegerToString(m_last_trade.spread),
            DoubleToString(m_last_trade.range_size, _Digits),
            DoubleToString(m_last_trade.atr_val, _Digits),
            DoubleToString(m_last_trade.yesterday_range, _Digits),
            DoubleToString(m_last_trade.dist_breakout, _Digits),
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
