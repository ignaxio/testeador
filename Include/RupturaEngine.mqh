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

//+------------------------------------------------------------------+
//| Clase Motor de Rupturas                                          |
//+------------------------------------------------------------------+
class CRupturaEngine
{
private:
   // --- Objetos ---
   CTrade            m_trade;
   CCSVTradeLogger   m_logger;

   // --- Variables de Estado ---
   datetime          m_ultimo_dia;
   datetime          m_ultima_vela_time;
   bool              m_rango_calculado;
   bool              m_rango_fijado;
   bool              m_trade_ejecutado_hoy;
   double            m_rango_top;
   double            m_rango_bottom;

   // --- Métodos Internos ---
   void              ResetearDia();
   void              ConstruirRango();
   void              EvaluarEntrada();
   void              EjecutarOrden(ENUM_ORDER_TYPE tipo, double range_points, int consec);
   void              GestionarCierrePorHora();
   bool              IsBrokerSessionActive(string start_time, string end_time, datetime broker_time = 0);
   bool              HayPosicionAbierta();
   bool              PositionSelectByMagic(long magic);
   void              GetLondonHighLow(double &h, double &l);
   int               GetConsecutiveCandles();
   double            GetDailyVWAP();
   double            GetDailyATR(int period = 14);
   ENUM_TRADE_SCORE  CalculateTradeScore(double range_points, int consec);

public:
   // --- Configuración (Pública para fácil asignación desde MQ5) ---
   ENUM_TIMEFRAMES   time_frame;
   ENUM_MODO_HORARIO modo_horario; // Cómo interpretar los inputs de horario
   ENUM_MARKET_ZONE  zona_mercado; // Zona horaria de referencia (solo MODO_MERCADO)
   string            hora_inicio_rango;
   string            hora_fin_rango;
   int               rango_minimo_puntos;

   string            hora_inicio_operativa;
   string            hora_fin_operativa;
   bool              cerramos_trades;
   string            hora_fin_sesion;
   ENUM_DIRECCION    direccion;
   bool              permitir_buy;
   bool              permitir_sell;

   int               puntos_sl;
   double            ratio;
   bool              sl_fijo;
   double            Lots;
   double            porcentaje_riesgo;
   bool              usar_mover_sl_a_be;
   double            ratio_activacion_be;
   double            porcentaje_sl_nuevo;

   bool              usar_filtro_volumen;
   int               volumen_limite;
   bool              usar_filtro_opening_range_size;
   double            opening_range_size;
   bool              opening_range_size_max;
   bool              usar_filtro_atr;
   double            atr_limit;
   bool              atr_limit_max;
   bool              usar_filtro_distancia_ruptura;
   double            distancia_ruptura_maxima;
   bool              usar_filtro_exclusion_rango;
   bool              usar_filtro_sma200;
   bool              usar_filtro_vwap;
   double            vwap_multiplicador_atr;
   bool              usar_filtro_velas_consecutivas;
   int               max_velas_consecutivas;
   bool              permitir_lunes;
   bool              permitir_martes;
   bool              permitir_miercoles;
   bool              permitir_jueves;
   bool              permitir_viernes;
   bool              imprimir_csv;
   bool              usar_scoring; // Si es true, aplica reducción de riesgo por puntuación (A/B/C)

   int               MagicNumber;
   string            nombre_estrategia;

   // --- Constructor e Interfaz ---
   CRupturaEngine();
   int               Init();
   void              OnTick();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRupturaEngine::CRupturaEngine()
{
   m_ultimo_dia = 0;
   m_ultima_vela_time = 0;
   m_rango_calculado = false;
   m_rango_fijado = false;
   m_trade_ejecutado_hoy = false;
   usar_scoring = false; // Por defecto desactivado para no afectar EAs individuales
   m_rango_top = 0;
   m_rango_bottom = 0;
   
   // Valores por defecto
   imprimir_csv = true;
   permitir_buy = true;
   permitir_sell = true;
   permitir_lunes = permitir_martes = permitir_miercoles = permitir_jueves = permitir_viernes = true;
   
   puntos_sl = 0;
   ratio = 0;
   sl_fijo = false;
   Lots = 0.01;
   porcentaje_riesgo = 0.5;
   usar_mover_sl_a_be = false;
   
   usar_filtro_volumen = false;
   usar_filtro_opening_range_size = false;
   opening_range_size            = 2000;
   opening_range_size_max        = true;
   usar_filtro_atr               = false;
   atr_limit                     = 0;
   atr_limit_max                 = true;
   usar_filtro_distancia_ruptura  = false;
   usar_filtro_exclusion_rango = false;
   usar_filtro_sma200 = false;
   usar_filtro_vwap = false;
   usar_filtro_velas_consecutivas = false;
}

//+------------------------------------------------------------------+
//| Engine initialization                                            |
//+------------------------------------------------------------------+
int CRupturaEngine::Init()
{
   Print("Motor de Rupturas iniciado: ", nombre_estrategia);
   m_trade.SetExpertMagicNumber(MagicNumber);
   
   if(imprimir_csv)
   {
      m_logger.SetStrategyName(nombre_estrategia);
      m_logger.Init();
   }
   
   // Inicializar el servicio de tiempo
   CTimeService::Init();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Engine tick function                                             |
//+------------------------------------------------------------------+
void CRupturaEngine::OnTick()
{
   // 1. GESTIÓN DE TRADES ABIERTOS Y LOGS (Siempre en cada tick para precisión)
   if(cerramos_trades)
      GestionarCierrePorHora();

   // Gestión de SL (Trailing / BE) - Debe ser OnTick para reaccionar al precio al instante
   AplicarGestionSLDinamico(MagicNumber, usar_mover_sl_a_be, ratio_activacion_be, porcentaje_sl_nuevo);

   // Logger OnTick para capturar MAE/MFE reales
   if(imprimir_csv)
      m_logger.OnTick();

   // 2. OPERATIVA DE ENTRADAS (Solo al cierre de vela)
   bool is_new_bar = EsNuevaVela(m_ultima_vela_time, time_frame);
   
   // Mostrar comentario solo en nueva vela o modo visual para no sobrecargar
   if(MQLInfoInteger(MQL_VISUAL_MODE) && is_new_bar)
   {
      string msg = StringFormat("Estrategia: %s\nBroker: %s\nLondon: %s\nNY: %s\nUTC: %s", 
         nombre_estrategia,
         TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS),
         TimeToString(CTimeService::GetMarketTime(ZONE_LONDON), TIME_MINUTES|TIME_SECONDS),
         TimeToString(CTimeService::GetMarketTime(ZONE_NEWYORK), TIME_MINUTES|TIME_SECONDS),
         TimeToString(CTimeService::GetUTCTime(), TIME_MINUTES|TIME_SECONDS));
      Comment(msg);
   }

   if(!is_new_bar)
      return;

   // Lógica de entradas (Búsqueda de rango y señales)
   if(EsNuevoDia(m_ultimo_dia))
      ResetearDia();

   if(!m_rango_fijado)
      ConstruirRango();

   if(m_rango_fijado && !m_trade_ejecutado_hoy)
   {
      bool horario_activo = false;
      if(modo_horario == MODO_MERCADO)
         horario_activo = CTimeService::IsMarketSessionActive(zona_mercado, hora_inicio_operativa, hora_fin_operativa);
      else
         horario_activo = IsBrokerSessionActive(hora_inicio_operativa, hora_fin_operativa);

      if(horario_activo)
         EvaluarEntrada();
   }
}

//+------------------------------------------------------------------+
//| Resetear variables al inicio del día                             |
//+------------------------------------------------------------------+
void CRupturaEngine::ResetearDia()
{
   m_rango_calculado = false;
   m_rango_fijado = false;
   m_trade_ejecutado_hoy = false;

   m_rango_top = 0;
   m_rango_bottom = 0;

   MqlDateTime dt_broker_now;
   TimeCurrent(dt_broker_now);
   PrintFormat("[%s] Nuevo día detectado (%02d:%02d:%02d). Variables reseteadas.", nombre_estrategia, dt_broker_now.hour, dt_broker_now.min, dt_broker_now.sec);
}

//+------------------------------------------------------------------+
//| Lógica para construir el rango de referencia                     |
//+------------------------------------------------------------------+
void CRupturaEngine::ConstruirRango()
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

   // Bloqueo de seguridad: No puede ser post_rango si ni siquiera hemos llegado a la hora de inicio hoy
   if(time_now < t_inicio_rango)
   {
      post_rango = false;
      en_rango = false;
      m_rango_fijado = false;
      m_rango_calculado = false;
   }

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

   // VALIDACIÓN DE FECHA ESTRICTA: 
   MqlDateTime dt_vela, dt_broker_now;
   TimeCurrent(dt_broker_now);
   TimeToStruct(iTime(_Symbol, time_frame, index_inicio), dt_vela);
   
   if(dt_vela.day != dt_broker_now.day || dt_vela.mon != dt_broker_now.mon)
      return; 

   m_rango_top = -DBL_MAX;
   m_rango_bottom = DBL_MAX;

   for(int i = index_fin; i <= index_inicio; i++)
   {
      double high = iHigh(_Symbol, time_frame, i);
      double low  = iLow(_Symbol, time_frame, i);

      if(high > m_rango_top) m_rango_top = high;
      if(low < m_rango_bottom) m_rango_bottom = low;
   }

   // 4. Dibujar el rango dinámicamente
   DibujarRango(dt_inicio_rango_broker, m_rango_top, dt_fin_rango_broker, m_rango_bottom, MagicNumber);

   // 5. Si ya terminó el periodo del rango, fijarlo y validar
   if(post_rango && !m_rango_fijado)
   {
      double tamaño_rango = (m_rango_top - m_rango_bottom) / _Point;
      
      if(tamaño_rango < rango_minimo_puntos)
      {
         if(!m_rango_calculado)
            PrintFormat("[%s] Rango finalizado pero INVÁLIDO por tamaño insuficiente (%.1f pts < %d pts).", nombre_estrategia, tamaño_rango, rango_minimo_puntos);
         m_rango_calculado = true;
         m_rango_fijado = false; 
         return;
      }

      m_rango_calculado = true;
      m_rango_fijado = true;
      
      MqlDateTime dt_b;
      TimeCurrent(dt_b);
      PrintFormat("[%s] %02d:%02d:%02d Rango finalizado y FIJADO. Top: %.5f Bottom: %.5f", 
                  nombre_estrategia, dt_b.hour, dt_b.min, dt_b.sec, m_rango_top, m_rango_bottom);
   }
   else if(en_rango)
   {
      m_rango_fijado = false;
      m_rango_calculado = false;
   }
}

//+------------------------------------------------------------------+
//| Evaluar condiciones de entrada                                   |
//+------------------------------------------------------------------+
void CRupturaEngine::EvaluarEntrada()
{
   double cierre = iClose(_Symbol, time_frame, 1); 

   bool ruptura_arriba = (cierre > m_rango_top);
   bool ruptura_abajo  = (cierre < m_rango_bottom);

   if(MQLInfoInteger(MQL_DEBUG) || MQLInfoInteger(MQL_TESTER))
   {
      // Opcional: Log de cada evaluación de vela si es necesario para depurar
      // PrintFormat("[%s] Eval: Cierre=%.5f | Top=%.5f | Bottom=%.5f", nombre_estrategia, cierre, m_rango_top, m_rango_bottom);
   }

   if(!ruptura_arriba && !ruptura_abajo)
      return;

   PrintFormat("[%s] *** RUPTURA DETECTADA *** Cierre: %.5f | Rango: %.5f - %.5f", nombre_estrategia, cierre, m_rango_bottom, m_rango_top);

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
   {
      PrintFormat("[%s] Entrada BUY ignorada (permitir_buy = false)", nombre_estrategia);
      return;
   }
   if(tipo_orden == ORDER_TYPE_SELL && !permitir_sell)
   {
      PrintFormat("[%s] Entrada SELL ignorada (permitir_sell = false)", nombre_estrategia);
      return;
   }

   int digits_sym = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double multiplier_sym = (digits_sym == 3 || digits_sym == 5) ? 10.0 : 1.0;

   double current_range_size = (m_rango_top - m_rango_bottom);
   double range_in_points = NormalizeDouble(current_range_size / (_Point * multiplier_sym), 1);
   long breakout_vol = m_logger.GetRealVolume(time_frame, 1);
   
   double precio_actual_para_dist = (tipo_orden == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist_breakout = 0;
   if(tipo_orden == ORDER_TYPE_BUY)
      dist_breakout = (precio_actual_para_dist - m_rango_top) / (_Point * multiplier_sym);
   else
      dist_breakout = (m_rango_bottom - precio_actual_para_dist) / (_Point * multiplier_sym);
   dist_breakout = NormalizeDouble(dist_breakout, 1);

   // Validacion de Filtros
   if(!ValidarRangoSize(usar_filtro_opening_range_size, range_in_points, opening_range_size, opening_range_size_max)) return;
   if(!ValidarATR(usar_filtro_atr, GetDailyATR(), atr_limit, atr_limit_max)) return;
   if(!ValidarVolumen(usar_filtro_volumen, breakout_vol, volumen_limite)) return;
   if(!ValidarDistanciaRuptura(usar_filtro_distancia_ruptura, dist_breakout, distancia_ruptura_maxima)) return;
   if(!ValidarExclusionRango(usar_filtro_exclusion_rango, range_in_points)) return;
   if(!ValidarTendenciaSMA200(usar_filtro_sma200, tipo_orden)) return;
   
   
   if(!ValidarFiltroVWAP(usar_filtro_vwap, tipo_orden, GetDailyVWAP(), GetDailyATR(), vwap_multiplicador_atr)) return;

   int current_consec = GetConsecutiveCandles();
   if(!ValidarVelasConsecutivas(usar_filtro_velas_consecutivas, current_consec, max_velas_consecutivas)) return;

   // Validación de días de la semana
   MqlDateTime dt_hoy;
   TimeCurrent(dt_hoy);
   if(dt_hoy.day_of_week == 1 && !permitir_lunes) return;
   if(dt_hoy.day_of_week == 2 && !permitir_martes) return;
   if(dt_hoy.day_of_week == 3 && !permitir_miercoles) return;
   if(dt_hoy.day_of_week == 4 && !permitir_jueves) return;
   if(dt_hoy.day_of_week == 5 && !permitir_viernes) return;
   
   EjecutarOrden(tipo_orden, range_in_points, current_consec);
}

//+------------------------------------------------------------------+
//| Ejecutar la orden al mercado                                     |
//+------------------------------------------------------------------+
void CRupturaEngine::EjecutarOrden(ENUM_ORDER_TYPE tipo, double range_points, int consec)
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

   m_trade.SetExpertMagicNumber(MagicNumber);
   
   double lote;
   ENUM_TRADE_SCORE score = CalculateTradeScore(range_points, consec);
   
   if(sl_fijo)
      lote = Lots;
   else
      lote = CalcularLotePorRiesgo(puntos_sl, porcentaje_riesgo * (double)score / 100.0);

   // Log previo a ejecución
   if(imprimir_csv)
   {
      double lonH, lonL;
      GetLondonHighLow(lonH, lonL);
      double yesH = iHigh(_Symbol, PERIOD_D1, 1);
      double yesL = iLow(_Symbol, PERIOD_D1, 1);
      double curVWAP = GetDailyVWAP();
      
      int digits_sym = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double multiplier_sym = (digits_sym == 3 || digits_sym == 5) ? 10.0 : 1.0;

      double dist_breakout = 0;
      if(tipo == ORDER_TYPE_BUY)
         dist_breakout = (precio - m_rango_top) / (_Point * multiplier_sym);
      else
         dist_breakout = (m_rango_bottom - precio) / (_Point * multiplier_sym);
      dist_breakout = NormalizeDouble(dist_breakout, 1);

      m_logger.OnTradeOpen(nombre_estrategia, MagicNumber, tipo, precio, sl, tp, m_rango_top, m_rango_bottom, time_frame, (double)m_logger.GetRealVolume(time_frame, 1), range_points, dist_breakout,
                         (precio - curVWAP)/_Point, (precio - lonH)/_Point, (precio - lonL)/_Point, 
                         (precio - yesH)/_Point, (precio - yesL)/_Point, consec);
   }

   bool resultado;
   if(tipo == ORDER_TYPE_BUY)
      resultado = m_trade.Buy(lote, _Symbol, precio, sl, tp);
   else
      resultado = m_trade.Sell(lote, _Symbol, precio, sl, tp);

   if(resultado)
   {
      PrintFormat("[%s] Trade ejecutado correctamente.", nombre_estrategia);
      m_trade_ejecutado_hoy = true;
      
      if(imprimir_csv && PositionSelectByMagic(MagicNumber))
         m_logger.SetActiveTicket(PositionGetInteger(POSITION_TICKET));
   }
   else
   {
      PrintFormat("[%s] Error al ejecutar trade. Código: %d", nombre_estrategia, GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Cierre automático por horario de fin de sesión                   |
//+------------------------------------------------------------------+
void CRupturaEngine::GestionarCierrePorHora()
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
         if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            m_trade.PositionClose(ticket);
            string ref_str = (modo_horario == MODO_MERCADO) ? "Mercado: " : "Broker: ";
            PrintFormat("[%s] Posición cerrada por fin de sesión (%s%s). Ticket: %d", nombre_estrategia, ref_str, hora_fin_sesion, ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Utilidades internas                                              |
//+------------------------------------------------------------------+
bool CRupturaEngine::IsBrokerSessionActive(string start_time, string end_time, datetime broker_time = 0)
{
   if(!CTimeService::ValidateHHMM(start_time) || !CTimeService::ValidateHHMM(end_time))
      return false;

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

bool CRupturaEngine::HayPosicionAbierta()
{
   return PositionSelectByMagic(MagicNumber);
}

bool CRupturaEngine::PositionSelectByMagic(long magic)
{
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == magic)
         return true;
   }
   return false;
}

void CRupturaEngine::GetLondonHighLow(double &h, double &l)
{
   h = 0; l = 0;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, 0, 300, rates); 
   bool first = true;
   for(int i=0; i<copied; i++) {
      if(CTimeService::IsMarketSessionActive(ZONE_LONDON, "08:00", "15:00", rates[i].time)) {
         if(first) { h = rates[i].high; l = rates[i].low; first = false; }
         else { if(rates[i].high > h) h = rates[i].high; if(rates[i].low < l) l = rates[i].low; }
      }
   }
}

int CRupturaEngine::GetConsecutiveCandles()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, time_frame, 1, 12, rates) < 1) return 0;
   int count = 1;
   bool bullish = (rates[0].close > rates[0].open);
   for(int i=1; i<ArraySize(rates); i++) {
      if((rates[i].close > rates[i].open) == bullish && rates[i].close != rates[i].open) count++;
      else break;
   }
   return count;
}

double CRupturaEngine::GetDailyVWAP()
{
   MqlDateTime dt;
   datetime now = TimeCurrent();
   TimeToStruct(now, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime start_of_day = StructToTime(dt);
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, start_of_day, now, rates);
   
   if(copied <= 0) return 0;
   
   double sum_pv = 0;
   double sum_v = 0;
   
   for(int i=0; i<copied; i++)
   {
      double typical = (rates[i].high + rates[i].low + rates[i].close) / 3.0;
      sum_pv += (typical * (double)rates[i].tick_volume);
      sum_v += (double)rates[i].tick_volume;
   }
   
   return (sum_v > 0) ? (sum_pv / sum_v) : 0;
}

double CRupturaEngine::GetDailyATR(int period = 14)
{
   int handle = iATR(_Symbol, PERIOD_D1, period);
   if(handle == INVALID_HANDLE) return 0;
   
   double buffer[];
   ArraySetAsSeries(buffer, true);
   int copied = CopyBuffer(handle, 0, 0, 1, buffer);
   IndicatorRelease(handle);
   
   if(copied <= 0) return 0;
   return buffer[0];
}

//+------------------------------------------------------------------+
//| Calcular puntuación de probabilidad para el trade                |
//+------------------------------------------------------------------+
ENUM_TRADE_SCORE CRupturaEngine::CalculateTradeScore(double range_points, int consec)
{
   if(!usar_scoring) return SCORE_A; // Si no usamos scoring, riesgo completo siempre (100%)

   MqlDateTime dt;
   TimeCurrent(dt);
   
   // Estrategia NY (Reversión)
   if(direccion == Reversion)
   {
      if(dt.day_of_week == 5) return SCORE_A; // NY Viernes -> Grupo A
      return SCORE_C;                         // Resto de NY -> Grupo C
   }
   
   // Estrategia Londres (Continuación)
   if(direccion == Continuacion)
   {
      return SCORE_B; // LND -> Grupo B
   }
   
   return SCORE_B; // Por defecto
}
