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

ENUM_TIMEFRAMES   time_frame;
ENUM_MODO_HORARIO modo_horario; // Cómo interpretar los inputs de horario
ENUM_MARKET_ZONE  zona_mercado; // Zona horaria de referencia (solo MODO_MERCADO)
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
bool            usar_mover_sl_a_be;
double          ratio_activacion_be;
double          porcentaje_sl_nuevo;

bool            usar_filtro_volumen;
int             volumen_limite;
bool            usar_filtro_opening_range_size;
double          opening_range_size;
bool            usar_filtro_distancia_ruptura;
double          distancia_ruptura_maxima;
bool            usar_filtro_exclusion_rango;
bool            usar_filtro_sma200;
bool            permitir_lunes;
bool            permitir_martes;
bool            permitir_miercoles;
bool            permitir_jueves;
bool            permitir_viernes;

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
bool rango_fijado = false; // El rango ya no crece y es válido para entradas
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
   
   // Inicializar el servicio de tiempo
   CTimeService::Init();
   
   // Inicializar permisos de días si no se han configurado (compatibilidad)
   if(!permitir_lunes && !permitir_martes && !permitir_miercoles && !permitir_jueves && !permitir_viernes)
   {
      permitir_lunes = permitir_martes = permitir_miercoles = permitir_jueves = permitir_viernes = true;
   }
   
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

   if(!rango_fijado)
      ConstruirRango();

   if(rango_fijado && !trade_ejecutado_hoy)
   {
      bool horario_activo = false;
      if(modo_horario == MODO_MERCADO)
         horario_activo = CTimeService::IsMarketSessionActive(zona_mercado, hora_inicio_operativa, hora_fin_operativa);
      else
         horario_activo = IsBrokerSessionActive(hora_inicio_operativa, hora_fin_operativa);

      if(horario_activo)
         EvaluarEntrada();
   }

   if(cerramos_trades)
      GestionarCierrePorHora();

   // Nueva gestión de SL
   AplicarGestionSLDinamico(MagicNumber, usar_mover_sl_a_be, ratio_activacion_be, porcentaje_sl_nuevo);

   logger.OnTick();
}

//=========================
// FUNCIONES LÓGICAS
//=========================

void ResetearDia()
{
   rango_calculado = false;
   rango_fijado = false;
   trade_ejecutado_hoy = false;

   rango_top = 0;
   rango_bottom = 0;

   Print("Nuevo día detectado. Variables reseteadas.");
}

void ConstruirRango()
{
   if(modo_horario == MODO_MERCADO && !CTimeService::IsInitialized()) return;

   // 1. Comprobar si estamos dentro o después del horario del rango
   bool en_rango = false;
   bool post_rango = false;
   
   datetime time_now;
   datetime t_inicio_rango, t_fin_rango;

   if(modo_horario == MODO_MERCADO)
   {
      time_now = CTimeService::GetMarketTime(zona_mercado);
      en_rango = CTimeService::IsMarketSessionActive(zona_mercado, hora_inicio_rango, hora_fin_rango);
      
      MqlDateTime dt_m;
      TimeToStruct(time_now, dt_m);
      
      dt_m.hour = (int)StringToInteger(StringSubstr(hora_inicio_rango, 0, 2));
      dt_m.min = (int)StringToInteger(StringSubstr(hora_inicio_rango, 3, 2));
      dt_m.sec = 0;
      t_inicio_rango = StructToTime(dt_m);
      
      dt_m.hour = (int)StringToInteger(StringSubstr(hora_fin_rango, 0, 2));
      dt_m.min = (int)StringToInteger(StringSubstr(hora_fin_rango, 3, 2));
      t_fin_rango = StructToTime(dt_m);
   }
   else
   {
      time_now = TimeCurrent();
      en_rango = IsBrokerSessionActive(hora_inicio_rango, hora_fin_rango);
      
      MqlDateTime dt_b;
      TimeToStruct(time_now, dt_b);
      
      dt_b.hour = (int)StringToInteger(StringSubstr(hora_inicio_rango, 0, 2));
      dt_b.min = (int)StringToInteger(StringSubstr(hora_inicio_rango, 3, 2));
      dt_b.sec = 0;
      t_inicio_rango = StructToTime(dt_b);
      
      dt_b.hour = (int)StringToInteger(StringSubstr(hora_fin_rango, 0, 2));
      dt_b.min = (int)StringToInteger(StringSubstr(hora_fin_rango, 3, 2));
      t_fin_rango = StructToTime(dt_b);
   }

   post_rango = (time_now >= t_fin_rango);

   if(!en_rango && !post_rango)
      return; // Aún no ha empezado el rango

   // 2. Obtener los timestamps de inicio y fin para el broker (necesarios para iBarShift)
   datetime dt_inicio_rango_broker, dt_fin_rango_broker;

   if(modo_horario == MODO_MERCADO)
   {
      datetime temp_broker = TimeCurrent();
      datetime market_ref = CTimeService::GetMarketTime(zona_mercado, temp_broker);
      int offset_market_to_broker = (int)(temp_broker - market_ref);

      dt_inicio_rango_broker = t_inicio_rango + offset_market_to_broker;
      dt_fin_rango_broker = t_fin_rango + offset_market_to_broker;
   }
   else
   {
      dt_inicio_rango_broker = t_inicio_rango;
      dt_fin_rango_broker = t_fin_rango;
   }

   // 3. Calcular el rango actual (basado en lo que llevamos de tiempo)
   datetime dt_limite_actual = post_rango ? dt_fin_rango_broker : TimeCurrent();
   
   int index_inicio = iBarShift(_Symbol, time_frame, dt_inicio_rango_broker, false);
   int index_fin    = iBarShift(_Symbol, time_frame, dt_limite_actual, false);

   if(index_inicio < 0 || index_fin < 0) return;

   rango_top = -DBL_MAX;
   rango_bottom = DBL_MAX;

   for(int i = index_fin; i <= index_inicio; i++)
   {
      double high = iHigh(_Symbol, time_frame, i);
      double low  = iLow(_Symbol, time_frame, i);

      if(high > rango_top) rango_top = high;
      if(low < rango_bottom) rango_bottom = low;
   }

   // 4. Dibujar el rango dinámicamente
   DibujarRango(dt_inicio_rango_broker, rango_top, dt_fin_rango_broker, rango_bottom);

   // 5. Si ya terminó el periodo del rango, fijarlo y validar
   if(post_rango)
   {
      double tamaño_rango = (rango_top - rango_bottom) / _Point;
      if(tamaño_rango < rango_minimo_puntos)
      {
         Print("Rango inválido por tamaño mínimo.");
         rango_calculado = true;
         rango_fijado = false; 
         return;
      }

      rango_calculado = true;
      rango_fijado = true;
      Print("Rango finalizado y fijado. Top: ", rango_top, " Bottom: ", rango_bottom);
   }
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
   if(!ValidarExclusionRango(usar_filtro_exclusion_rango, range_in_points)) return;
   if(!ValidarTendenciaSMA200(usar_filtro_sma200, tipo_orden)) return;

   // Validación de días de la semana
   MqlDateTime dt_hoy;
   TimeCurrent(dt_hoy);
   if(dt_hoy.day_of_week == 1 && !permitir_lunes) { Print("Operación cancelada: Lunes no permitido."); return; }
   if(dt_hoy.day_of_week == 2 && !permitir_martes) { Print("Operación cancelada: Martes no permitido."); return; }
   if(dt_hoy.day_of_week == 3 && !permitir_miercoles) { Print("Operación cancelada: Miércoles no permitido."); return; }
   if(dt_hoy.day_of_week == 4 && !permitir_jueves) { Print("Operación cancelada: Jueves no permitido."); return; }
   if(dt_hoy.day_of_week == 5 && !permitir_viernes) { Print("Operación cancelada: Viernes no permitido."); return; }
   
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
   bool fin_sesion = false;
   if(modo_horario == MODO_MERCADO)
      fin_sesion = CTimeService::IsMarketSessionActive(zona_mercado, hora_fin_sesion, "23:59");
   else
      fin_sesion = IsBrokerSessionActive(hora_fin_sesion, "23:59");

   if(fin_sesion)
   {
      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               trade.PositionClose(ticket);
               string ref_str = (modo_horario == MODO_MERCADO) ? "Mercado: " : "Broker: ";
               Print("Posición cerrada por fin de sesión (", ref_str, hora_fin_sesion, "). Ticket: ", ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Comprueba si el broker está dentro de un rango horario (estático) |
//+------------------------------------------------------------------+
bool IsBrokerSessionActive(string start_time, string end_time, datetime broker_time = 0)
{
   if(!CTimeService::ValidateHHMM(start_time) || !CTimeService::ValidateHHMM(end_time))
   {
      Print("RupturaEngine ERROR: Formato de hora broker inválido: '", start_time, "' o '", end_time, "'.");
      return false;
   }

   datetime now = (broker_time == 0) ? TimeCurrent() : broker_time;
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int current_minutes = dt.hour * 60 + dt.min;

   int start_h = (int)StringToInteger(StringSubstr(start_time, 0, 2));
   int start_m = (int)StringToInteger(StringSubstr(start_time, 3, 2));
   int end_h   = (int)StringToInteger(StringSubstr(end_time, 0, 2));
   int end_m   = (int)StringToInteger(StringSubstr(end_time, 3, 2));

   int start_minutes = start_h * 60 + start_m;
   int end_minutes   = end_h * 60 + end_m;

   if(end_minutes < start_minutes)
      return (current_minutes >= start_minutes || current_minutes < end_minutes);

   return (current_minutes >= start_minutes && current_minutes < end_minutes);
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
