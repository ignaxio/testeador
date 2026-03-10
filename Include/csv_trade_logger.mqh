//+------------------------------------------------------------------+
//|                                           csv_trade_logger.mqh |
//|                                  Copyright 2024, TradingBot |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, TradingBot"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\ArrayObj.mqh>

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
   double   atr_val;
   double   yesterday_range;
   double   dist_breakout;
   long     ticket;
   double   mae_pts;
   double   mfe_pts;
   string   sma_trend;
   double   breakout_volume;
   int      spread;
   double   dist_vwap;
   double   dist_london_h;
   double   dist_london_l;
   double   dist_yesterday_h;
   double   dist_yesterday_l;
   int      consecutive_candles;

   CTradeData()
   {
      time_open = 0;
      direction = "";
      entry_price = 0;
      sl = 0;
      tp = 0;
      range_size = 0;
      atr_val = 0;
      yesterday_range = 0;
      dist_breakout = 0;
      ticket = 0;
      mae_pts = 0;
      mfe_pts = 0;
      sma_trend = "";
      breakout_volume = 0;
      spread = 0;
      dist_vwap = 0;
      dist_london_h = 0;
      dist_london_l = 0;
      dist_yesterday_h = 0;
      dist_yesterday_l = 0;
      consecutive_candles = 0;
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
   int               m_handle_sma200;
   CArrayObj         m_active_trades;

public:
   CCSVTradeLogger()
   {
      m_subfolder = "probadorEstrategiasRupturaRango_tests\\";
      m_handle_sma200 = INVALID_HANDLE;
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
               "Date", "TimeOpen", "TimeClose", "Direction", "EntryPrice", "StopLoss", "TakeProfit", 
               "ResultPoints", "ResultR", "MAE_Points", "MFE_Points", "SMA200_Trend", 
               "Breakout_Volume", "Duration_Minutes", "Spread_Entry",
               "OpeningRangeSize", "ATR", "YesterdayRange", "DistanceBreakout", 
               "Dist_VWAP", "Dist_London_H", "Dist_London_L", "Dist_Yesterday_H", "Dist_Yesterday_L", "Consec_Candles",
               "DayOfWeek", "Month"
            );
            FileClose(handle);
         }
      }
   }

   // Captura los datos iniciales cuando se abre una operación
   void OnTradeOpen(ENUM_ORDER_TYPE tipo, double price, double sl, double tp, double r_top, double r_bottom, ENUM_TIMEFRAMES tf, double breakout_vol, double range_size, double dist_breakout, 
                 double d_vwap, double d_lon_h, double d_lon_l, double d_yes_h, double d_yes_l, int consec)
   {
      CTradeData *new_trade = new CTradeData();
      new_trade.time_open = TimeCurrent();
      new_trade.direction = (tipo == ORDER_TYPE_BUY) ? "LONG" : "SHORT";
      new_trade.entry_price = price;
      new_trade.sl = sl;
      new_trade.tp = tp;
      new_trade.range_size = range_size;
      new_trade.mae_pts = 0;
      new_trade.mfe_pts = 0;
      new_trade.spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      
      // ATR(14)
      int handle_atr = iATR(_Symbol, tf, 14);
      if(handle_atr != INVALID_HANDLE)
      {
         double atr_buffer[];
         ArraySetAsSeries(atr_buffer, true);
         if(CopyBuffer(handle_atr, 0, 0, 1, atr_buffer) > 0)
            new_trade.atr_val = atr_buffer[0];
         IndicatorRelease(handle_atr);
      }

      // Yesterday Range
      new_trade.yesterday_range = iHigh(_Symbol, PERIOD_D1, 1) - iLow(_Symbol, PERIOD_D1, 1);
      new_trade.dist_breakout = dist_breakout;

      // SMA 200 Trend (H1)
      double sma_buffer[];
      ArraySetAsSeries(sma_buffer, true);
      if(CopyBuffer(m_handle_sma200, 0, 0, 1, sma_buffer) > 0)
      {
         double current_price = iClose(_Symbol, PERIOD_H1, 0);
         new_trade.sma_trend = (current_price > sma_buffer[0]) ? "ABOVE" : "BELOW";
      }
      else new_trade.sma_trend = "UNKNOWN";

      // Datos de Volumen
      new_trade.breakout_volume = breakout_vol;
      
      new_trade.dist_vwap = d_vwap;
      new_trade.dist_london_h = d_lon_h;
      new_trade.dist_london_l = d_lon_l;
      new_trade.dist_yesterday_h = d_yes_h;
      new_trade.dist_yesterday_l = d_yes_l;
      new_trade.consecutive_candles = consec;
      
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
            DetectAndLogClose(trade_data, i);
         }
      }
   }

private:
   void DetectAndLogClose(CTradeData *trade_data, int index)
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
                  m_active_trades.Delete(index);
                  return;
               }
            }
         }
      }
      // Si no encontramos el deal de salida pero la posicion ya no existe
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
            trade_data.sma_trend,
            DoubleToString(trade_data.breakout_volume, 0),
            IntegerToString(duration),
            IntegerToString(trade_data.spread),
            DoubleToString(trade_data.range_size, 1),
            DoubleToString(trade_data.atr_val, _Digits),
            DoubleToString(trade_data.yesterday_range, _Digits),
            DoubleToString(trade_data.dist_breakout, _Digits),
            DoubleToString(trade_data.dist_vwap, 1),
            DoubleToString(trade_data.dist_london_h, 1),
            DoubleToString(trade_data.dist_london_l, 1),
            DoubleToString(trade_data.dist_yesterday_h, 1),
            DoubleToString(trade_data.dist_yesterday_l, 1),
            IntegerToString(trade_data.consecutive_candles),
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
