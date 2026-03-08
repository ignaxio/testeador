//+------------------------------------------------------------------+
//|                                                  TimeService.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

#include "DSTData.mqh"

enum ENUM_MARKET_ZONE
{
   ZONE_UTC,
   ZONE_LONDON,
   ZONE_NEWYORK,
   ZONE_TOKYO
};

//+------------------------------------------------------------------+
//| Clase para el manejo de tiempos y conversiones horarias          |
//+------------------------------------------------------------------+
class CTimeService
{
private:
   static int        m_broker_offset;    // Diferencia Broker - UTC en segundos
   static bool       m_is_initialized;   // Flag de inicialización
   static datetime   m_last_update_day;  // Último día de actualización del offset

   static int CalculateHistoricalOffset(datetime time);

public:
   static void       Init();
   static void       UpdateOffset();
   static datetime   GetUTCTime(datetime broker_time = 0);
   static bool       IsInitialized() { return m_is_initialized; }
   
   // Fase 2: Conversión a Mercados
   static datetime   GetMarketTime(ENUM_MARKET_ZONE zone, datetime broker_time = 0);
   static bool       IsMarketSessionActive(ENUM_MARKET_ZONE zone, string start_time, string end_time, datetime broker_time = 0);
   
   static bool       ValidateHHMM(string time_str);
};

// Inicialización de miembros estáticos
int      CTimeService::m_broker_offset = 0;
bool     CTimeService::m_is_initialized = false;
datetime CTimeService::m_last_update_day = 0;

//+------------------------------------------------------------------+
//| Inicializa el servicio de tiempo                                 |
//+------------------------------------------------------------------+
void CTimeService::Init()
{
   UpdateOffset();
   m_is_initialized = true;
   Print("TimeService: Inicializado. Offset detectado: ", m_broker_offset / 3600, "h");
}

//+------------------------------------------------------------------+
//| Actualiza el desfase entre el Broker y UTC                       |
//+------------------------------------------------------------------+
void CTimeService::UpdateOffset()
{
   datetime now = TimeCurrent();
   
   // Evitar recálculos innecesarios el mismo día (caching)
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime today_start = StructToTime(dt);
   
   if(m_last_update_day == today_start && m_is_initialized)
      return;

   // 1. Auto-detección en Live
   if(!MQLInfoInteger(MQL_TESTER))
   {
      datetime gmt = TimeGMT();
      m_broker_offset = (int)(now - gmt);
      
      // Validación de offset (múltiplos de 30 min)
      if(m_broker_offset % 1800 != 0)
      {
         Print("TimeService WARNING: Offset detectado no estándar: ", m_broker_offset, " segundos. Verifique configuración.");
      }
      
      if(MathAbs(m_broker_offset) > 50400) // 14 horas
      {
         Print("TimeService WARNING: Offset extremadamente alto detectado: ", m_broker_offset / 3600, "h.");
      }
   }
   else
   {
      // 2. Backtesting: Usar tabla histórica/reglas
      m_broker_offset = CalculateHistoricalOffset(now);
   }

   m_last_update_day = today_start;
}

//+------------------------------------------------------------------+
//| Obtiene la hora UTC actual o de un timestamp específico          |
//+------------------------------------------------------------------+
datetime CTimeService::GetUTCTime(datetime broker_time = 0)
{
   if(!m_is_initialized) Init();
   
   datetime t = (broker_time == 0) ? TimeCurrent() : broker_time;
   return t - m_broker_offset;
}

//+------------------------------------------------------------------+
//| Calcula el offset histórico para la mayoría de brokers FX        |
//| (GMT+2 Invierno / GMT+3 Verano - Basado en US DST)               |
//+------------------------------------------------------------------+
int CTimeService::CalculateHistoricalOffset(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   
   // Buscar el año en la tabla DST
   int total = ArraySize(dst_table);
   for(int i = 0; i < total; i++)
   {
      if(dst_table[i].year == dt.year)
      {
         // Si estamos entre el inicio y fin de DST US -> GMT+3 (10800s)
         if(time >= dst_table[i].us_start && time < dst_table[i].us_end)
            return 10800;
         
         break;
      }
   }
   
   // Por defecto o Horario de Invierno -> GMT+2 (7200s)
   if(dt.year < dst_table[0].year || dt.year > dst_table[total-1].year)
   {
      Print("TimeService WARNING: Año ", dt.year, " fuera de rango DSTData. Usando invierno (GMT+2) por defecto.");
   }
   return 7200;
}

//+------------------------------------------------------------------+
//| Obtiene la hora de un mercado específico                         |
//+------------------------------------------------------------------+
datetime CTimeService::GetMarketTime(ENUM_MARKET_ZONE zone, datetime broker_time = 0)
{
   datetime utc = GetUTCTime(broker_time);
   MqlDateTime dt;
   TimeToStruct(utc, dt);

   switch(zone)
   {
      case ZONE_UTC: 
         return utc;

      case ZONE_LONDON:
      {
         // London: UTC+0 Invierno / UTC+1 Verano
         int total = ArraySize(dst_table);
         for(int i = 0; i < total; i++)
         {
            if(dst_table[i].year == dt.year)
            {
               if(utc >= dst_table[i].eu_start && utc < dst_table[i].eu_end)
                  return utc + 3600;
               break;
            }
         }
         return utc;
      }

      case ZONE_NEWYORK:
      {
         // NY: UTC-5 Invierno / UTC-4 Verano
         int total = ArraySize(dst_table);
         for(int i = 0; i < total; i++)
         {
            if(dst_table[i].year == dt.year)
            {
               if(utc >= dst_table[i].us_start && utc < dst_table[i].us_end)
                  return utc - 14400; // -4h
               break;
            }
         }
         return utc - 18000;    // -5h
      }

      case ZONE_TOKYO:
         return utc + 32400; // Tokyo siempre es UTC+9

      default:
         return utc;
   }
}

//+------------------------------------------------------------------+
//| Comprueba si el mercado está dentro de un rango horario          |
//+------------------------------------------------------------------+
bool CTimeService::IsMarketSessionActive(ENUM_MARKET_ZONE zone, string start_time, string end_time, datetime broker_time = 0)
{
   if(!ValidateHHMM(start_time) || !ValidateHHMM(end_time))
   {
      Print("TimeService ERROR: Formato de hora inválido (esperado HH:MM): '", start_time, "' o '", end_time, "'.");
      return false;
   }

   datetime market_now = GetMarketTime(zone, broker_time);
   
   // Extraer solo la hora/minuto actual del mercado para comparar
   MqlDateTime dt_now;
   TimeToStruct(market_now, dt_now);
   int current_minutes = dt_now.hour * 60 + dt_now.min;

   // Parsear horas de inicio y fin a minutos desde medianoche
   int start_h = (int)StringToInteger(StringSubstr(start_time, 0, 2));
   int start_m = (int)StringToInteger(StringSubstr(start_time, 3, 2));
   int end_h   = (int)StringToInteger(StringSubstr(end_time, 0, 2));
   int end_m   = (int)StringToInteger(StringSubstr(end_time, 3, 2));

   int start_minutes = start_h * 60 + start_m;
   int end_minutes   = end_h * 60 + end_m;

   // Manejo de sesiones que cruzan la medianoche (ej: 22:00 a 04:00)
   if(end_minutes < start_minutes)
   {
      return (current_minutes >= start_minutes || current_minutes < end_minutes);
   }

   // Sesión normal (ej: 08:00 a 16:00)
   // Nota: La comparación < end_minutes suele ser preferible para rangos continuos,
   // pero si el usuario pone 10:00 como fin, usualmente espera que a las 10:00:00 ya no esté activo.
   return (current_minutes >= start_minutes && current_minutes < end_minutes);
}

//+------------------------------------------------------------------+
//| Valida el formato HH:MM                                          |
//+------------------------------------------------------------------+
bool CTimeService::ValidateHHMM(string time_str)
{
   if(StringLen(time_str) != 5) return false;
   if(StringSubstr(time_str, 2, 1) != ":") return false;

   int hh = (int)StringToInteger(StringSubstr(time_str, 0, 2));
   int mm = (int)StringToInteger(StringSubstr(time_str, 3, 2));

   return (hh >= 0 && hh <= 23 && mm >= 0 && mm <= 59);
}
