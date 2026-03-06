//+------------------------------------------------------------------+
//|                                              RupturaEngine.mqh   |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

#include <Trade/Trade.mqh>
#include "csv_trade_logger.mqh"

//=========================
// ENUMS
//=========================

enum ENUM_DIRECCION
{
   Continuacion = 0,
   Reversion = 1
};

//=========================
// VARIABLES DEL MOTOR (Configurables desde el MQ5)
//=========================

ENUM_TIMEFRAMES time_frame;
string          hora_inicio_rango;
string          hora_fin_rango;
int             rango_minimo_puntos;

string          hora_inicio_operativa;
string          hora_fin_operativa;
bool            cerramos_trades;
string          hora_fin_sesion;
ENUM_DIRECCION  direccion;
bool            permitir_buy;
bool            permitir_sell;

int             puntos_sl;
double          ratio;
bool            sl_fijo;
double          Lots;
double          porcentaje_riesgo;

bool            usar_filtro_volumen;
int             volumen_limite;
bool            usar_filtro_opening_range_size;
double          opening_range_size;
bool            usar_filtro_distancia_ruptura;
double          distancia_ruptura_maxima;

int             MagicNumber;
string          nombre_estrategia;

//=========================
// VARIABLES GLOBALES DE ESTADO
//=========================

CTrade trade;
CCSVTradeLogger logger;

datetime ultimo_dia = 0;
datetime ultima_vela_time = 0;

bool rango_calculado = false;
bool trade_ejecutado_hoy = false;

double rango_top = 0;
double rango_bottom = 0;

//+------------------------------------------------------------------+
//| Engine initialization                                            |
//+------------------------------------------------------------------+

int EngineOnInit()
{
   Print("Motor de Rupturas iniciado: ", nombre_estrategia);
   trade.SetExpertMagicNumber(MagicNumber);
   
   logger.SetStrategyName(nombre_estrategia);
   logger.Init();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Engine tick function                                             |
//+------------------------------------------------------------------+

void EngineOnTick()
{
   if(!EsNuevaVela())
      return;

   if(EsNuevoDia())
      ResetearDia();

   if(!rango_calculado)
      ConstruirRango();

   if(rango_calculado && !trade_ejecutado_hoy)
   {
      if(EstamosEnHorarioOperativo())
         EvaluarEntrada();
   }

   if(cerramos_trades)
      GestionarCierrePorHora();

   logger.OnTick();
}

//=========================
// FUNCIONES BASE
//=========================

bool EsNuevaVela()
{
   datetime tiempo_actual = iTime(_Symbol, time_frame, 0);

   if(tiempo_actual != ultima_vela_time)
   {
      ultima_vela_time = tiempo_actual;
      return true;
   }

   return false;
}

bool EsNuevoDia()
{
   datetime tiempo_actual = TimeCurrent();
   MqlDateTime estructura_tiempo_actual, estructura_tiempo_ultimo_dia;
   
   TimeToStruct(tiempo_actual, estructura_tiempo_actual);
   TimeToStruct(ultimo_dia, estructura_tiempo_ultimo_dia);

   if(estructura_tiempo_actual.day != estructura_tiempo_ultimo_dia.day)
   {
      ultimo_dia = tiempo_actual; 
      return true;
   }

   return false;
}

void ResetearDia()
{
   rango_calculado = false;
   trade_ejecutado_hoy = false;

   rango_top = 0;
   rango_bottom = 0;

   Print("Nuevo día detectado. Variables reseteadas.");
}

void DibujarRango(datetime t1, double p1, datetime t2, double p2)
{
   string name = "rango_" + TimeToString(t1, TIME_DATE);
   
   ObjectDelete(0, name);
   
   if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrSkyBlue);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true); 
      ObjectSetInteger(0, name, OBJPROP_FILL, true); 
   }
}

void ConstruirRango()
{
   datetime ahora = TimeCurrent();

   datetime hoy_inicio = StringToTime(TimeToString(ahora, TIME_DATE) + " 00:00");
   datetime dt_inicio_rango = StringToTime(TimeToString(ahora, TIME_DATE) + " " + hora_inicio_rango);
   datetime dt_fin_rango    = StringToTime(TimeToString(ahora, TIME_DATE) + " " + hora_fin_rango);

   if(ahora < dt_fin_rango)
      return;

   int index_inicio = iBarShift(_Symbol, time_frame, dt_inicio_rango, false);
   int index_fin    = iBarShift(_Symbol, time_frame, dt_fin_rango, false);

   if(index_inicio < 0 || index_fin < 0)
   {
      Print("Error obteniendo barras del rango.");
      return;
   }

   rango_top = -DBL_MAX;
   rango_bottom = DBL_MAX;

   for(int i = index_fin; i <= index_inicio; i++)
   {
      double high = iHigh(_Symbol, time_frame, i);
      double low  = iLow(_Symbol, time_frame, i);

      if(high > rango_top)
         rango_top = high;

      if(low < rango_bottom)
         rango_bottom = low;
   }

   double tamaño_rango = (rango_top - rango_bottom) / _Point;

   if(tamaño_rango < rango_minimo_puntos)
   {
      Print("Rango inválido por tamaño mínimo.");
      rango_calculado = true; 
      return;
   }

   rango_calculado = true;

   DibujarRango(dt_inicio_rango, rango_top, dt_fin_rango, rango_bottom);

   Print("Rango calculado y dibujado correctamente.");
   Print("Top: ", rango_top, " Bottom: ", rango_bottom);
}

bool EstamosEnHorarioOperativo()
{
   datetime ahora = TimeCurrent();
   string fecha_hoy = TimeToString(ahora, TIME_DATE);

   datetime inicio = StringToTime(fecha_hoy + " " + hora_inicio_operativa);
   datetime fin    = StringToTime(fecha_hoy + " " + hora_fin_operativa);

   if(ahora >= inicio && ahora <= fin)
      return true;

   return false;
}

void EvaluarEntrada()
{
   double cierre = iClose(_Symbol, time_frame, 1); 

   bool ruptura_arriba = (cierre > rango_top);
   bool ruptura_abajo  = (cierre < rango_bottom);

   if(!ruptura_arriba && !ruptura_abajo)
      return;

   ENUM_ORDER_TYPE tipo_orden;

   if(direccion == Continuacion)
   {
      if(ruptura_arriba)
         tipo_orden = ORDER_TYPE_BUY;
      else
         tipo_orden = ORDER_TYPE_SELL;
   }
   else 
   {
      if(ruptura_arriba)
         tipo_orden = ORDER_TYPE_SELL;
      else
         tipo_orden = ORDER_TYPE_BUY;
   }

   if(tipo_orden == ORDER_TYPE_BUY && !permitir_buy)
      return;

   if(tipo_orden == ORDER_TYPE_SELL && !permitir_sell)
      return;

   double current_range_size = (rango_top - rango_bottom);
   int digits_sym = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double multiplier_sym = (digits_sym == 3 || digits_sym == 5) ? 10.0 : 1.0;
   double range_in_points = current_range_size / (_Point * multiplier_sym);
   range_in_points = NormalizeDouble(range_in_points, 1);

   if(usar_filtro_opening_range_size)
   {
      if(range_in_points <= opening_range_size)
      {
         Print("Entrada cancelada por filtro de Opening Range Size. Tamaño (puntos): ", DoubleToString(range_in_points, 1), " es menor o igual al límite: ", DoubleToString(opening_range_size, 1));
         return;
      }
   }

   long breakout_vol = logger.GetRealVolume(time_frame, 1);
   
   if(usar_filtro_volumen)
   {
      if(breakout_vol <= volumen_limite)
      {
         Print("Entrada cancelada por filtro de volumen. Vol: ", breakout_vol, " no es mayor al límite: ", volumen_limite);
         return;
      }
   }

   double precio_actual_para_dist = (tipo_orden == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                   : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double dist_breakout = 0;
   if(tipo_orden == ORDER_TYPE_BUY)
      dist_breakout = (precio_actual_para_dist - rango_top) / (_Point * multiplier_sym);
   else
      dist_breakout = (rango_bottom - precio_actual_para_dist) / (_Point * multiplier_sym);

   dist_breakout = NormalizeDouble(dist_breakout, 1);

   if(usar_filtro_distancia_ruptura)
   {
      if(dist_breakout > distancia_ruptura_maxima)
      {
         Print("Entrada cancelada por filtro de Distancia de Ruptura. Distancia (puntos): ", DoubleToString(dist_breakout, 1), " es mayor que el máximo: ", DoubleToString(distancia_ruptura_maxima, 1));
         return;
      }
   }
   
   double precio_ejec = precio_actual_para_dist;
   double sl_ejec, tp_ejec;
   if(tipo_orden == ORDER_TYPE_BUY)
   {
      sl_ejec = precio_ejec - puntos_sl * _Point;
      tp_ejec = precio_ejec + (puntos_sl * ratio) * _Point;
   }
   else
   {
      sl_ejec = precio_ejec + puntos_sl * _Point;
      tp_ejec = precio_ejec - (puntos_sl * ratio) * _Point;
   }

   logger.OnTradeOpen(tipo_orden, precio_ejec, sl_ejec, tp_ejec, rango_top, rango_bottom, time_frame, (double)breakout_vol, range_in_points, dist_breakout);

   EjecutarOrden(tipo_orden);
}

void EjecutarOrden(ENUM_ORDER_TYPE tipo)
{
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                   : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl, tp;

   if(tipo == ORDER_TYPE_BUY)
   {
      sl = precio - puntos_sl * _Point;
      tp = precio + (puntos_sl * ratio) * _Point;
   }
   else
   {
      sl = precio + puntos_sl * _Point;
      tp = precio - (puntos_sl * ratio) * _Point;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   
   double lote;
   if(sl_fijo)
      lote = Lots;
   else
      lote = CalcularLotePorRiesgo();

   bool resultado;

   if(tipo == ORDER_TYPE_BUY)
      resultado = trade.Buy(lote, _Symbol, precio, sl, tp);
   else
      resultado = trade.Sell(lote, _Symbol, precio, sl, tp);

   if(resultado)
   {
      Print("Trade ejecutado correctamente.");
      trade_ejecutado_hoy = true;
      
      if(PositionSelectByMagic(MagicNumber))
         logger.SetActiveTicket(PositionGetInteger(POSITION_TICKET));
   }
   else
   {
      Print("Error al ejecutar trade. Código: ", GetLastError());
   }
}

void GestionarCierrePorHora()
{
   if(!HayPosicionAbierta())
      return;

   datetime ahora = TimeCurrent();
   string fecha_hoy = TimeToString(ahora, TIME_DATE);
   datetime fin_sesion = StringToTime(fecha_hoy + " " + hora_fin_sesion);

   if(ahora >= fin_sesion)
   {
      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               trade.PositionClose(PositionGetTicket(i));
               Print("Posición cerrada por fin de sesión.");
            }
         }
      }
   }
}

bool HayPosicionAbierta()
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            return true;
      }
   }
   return false;
}

double CalcularLotePorRiesgo()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   double riesgo_dinero = balance * porcentaje_riesgo / 100.0;

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double valor_punto_por_lote = tick_value / tick_size;

   double riesgo_por_lote = puntos_sl * _Point * valor_punto_por_lote;

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

bool PositionSelectByMagic(long magic)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == magic)
         return true;
   }
   return false;
}
