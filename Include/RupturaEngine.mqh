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
#include "Constantes.mqh"
#include "Utilidades.mqh"
#include "Filtros.mqh"
#include "GestionRiesgo.mqh"

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
   if(!EsNuevaVela(ultima_vela_time, time_frame))
      return;

   if(EsNuevoDia(ultimo_dia))
      ResetearDia();

   if(!rango_calculado)
      ConstruirRango();

   if(rango_calculado && !trade_ejecutado_hoy)
   {
      if(EstamosEnHorarioOperativo(hora_inicio_operativa, hora_fin_operativa))
         EvaluarEntrada();
   }

   if(cerramos_trades)
      GestionarCierrePorHora();

   logger.OnTick();
}

//=========================
// FUNCIONES LÓGICAS
//=========================

void ResetearDia()
{
   rango_calculado = false;
   trade_ejecutado_hoy = false;

   rango_top = 0;
   rango_bottom = 0;

   Print("Nuevo día detectado. Variables reseteadas.");
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

   // Multiplicador para puntos (3/5 digitos)
   int digits_sym = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double multiplier_sym = (digits_sym == 3 || digits_sym == 5) ? 10.0 : 1.0;

   // Calculos para filtros
   double current_range_size = (rango_top - rango_bottom);
   double range_in_points = NormalizeDouble(current_range_size / (_Point * multiplier_sym), 1);
   long breakout_vol = logger.GetRealVolume(time_frame, 1);
   
   double precio_actual_para_dist = (tipo_orden == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist_breakout = 0;
   if(tipo_orden == ORDER_TYPE_BUY)
      dist_breakout = (precio_actual_para_dist - rango_top) / (_Point * multiplier_sym);
   else
      dist_breakout = (rango_bottom - precio_actual_para_dist) / (_Point * multiplier_sym);
   dist_breakout = NormalizeDouble(dist_breakout, 1);

   // Validacion de Filtros
   if(!ValidarRangoSize(usar_filtro_opening_range_size, range_in_points, opening_range_size)) return;
   if(!ValidarVolumen(usar_filtro_volumen, breakout_vol, volumen_limite)) return;
   if(!ValidarDistanciaRuptura(usar_filtro_distancia_ruptura, dist_breakout, distancia_ruptura_maxima)) return;
   
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
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
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
      lote = CalcularLotePorRiesgo(puntos_sl, porcentaje_riesgo);

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
   datetime ahora = TimeCurrent();
   string fecha_hoy = TimeToString(ahora, TIME_DATE);
   datetime fin_sesion = StringToTime(fecha_hoy + " " + hora_fin_sesion);

   if(ahora >= fin_sesion)
   {
      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               trade.PositionClose(ticket);
               Print("Posición cerrada por fin de sesión. Ticket: ", ticket);
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
