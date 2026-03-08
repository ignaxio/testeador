//+------------------------------------------------------------------+
//|                                           TestTimeService.mq5    |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "..\Include\TimeService.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== TEST TIMESERVICE INICIADO ===");
   CTimeService::Init();
   
   // Test de visualización
   datetime ahora = TimeCurrent();
   datetime utc   = CTimeService::GetUTCTime(ahora);
   datetime lon   = CTimeService::GetMarketTime(ZONE_LONDON, ahora);
   datetime ny    = CTimeService::GetMarketTime(ZONE_NEWYORK, ahora);
   datetime tok   = CTimeService::GetMarketTime(ZONE_TOKYO, ahora);
   
   Print("Broker Time: ", ahora);
   Print("UTC Time:    ", utc);
   Print("London Time: ", lon);
   Print("NY Time:     ", ny);
   Print("Tokyo Time:  ", tok);
   
   // Test de sesión activa (ejemplo: Rango de Londres 09:00 - 10:00 Market)
   bool activa_market = CTimeService::IsMarketSessionActive(ZONE_LONDON, "09:00", "10:00", ahora);
   Print("¿Rango London 09:00-10:00 activo? ", activa_market ? "SÍ" : "NO");
   
   // Test Fase 2: Formatos inválidos
   Print("Test Validación HH:MM Market (esperado error):");
   bool error_format = CTimeService::IsMarketSessionActive(ZONE_LONDON, "8:0", "10:00", ahora);
   
   // Test Fase 2: Cruce de medianoche
   Print("Test Cruce Medianoche Market (22:00-04:00) a las 23:00 (esperado SÍ):");
   // Simulamos las 23:00 Market
   datetime test_midnight = StringToTime(TimeToString(ahora, TIME_DATE) + " 23:00");
   bool activa_midnight = CTimeService::IsMarketSessionActive(ZONE_LONDON, "22:00", "04:00", test_midnight);
   Print("¿Cruce 22:00-04:00 activo a las 23:00 Market? ", activa_midnight ? "SÍ" : "NO");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Mostrar en comentario para visualización en backtest
   string msg = StringFormat("Broker: %s\nLondon: %s\nNY: %s\nUTC: %s", 
      TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS),
      TimeToString(CTimeService::GetMarketTime(ZONE_LONDON), TIME_MINUTES|TIME_SECONDS),
      TimeToString(CTimeService::GetMarketTime(ZONE_NEWYORK), TIME_MINUTES|TIME_SECONDS),
      TimeToString(CTimeService::GetUTCTime(), TIME_MINUTES|TIME_SECONDS));
      
   Comment(msg);
}
