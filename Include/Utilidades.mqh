//+------------------------------------------------------------------+
//|                                                   Utilidades.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

//=========================
// FUNCIONES DE TIEMPO Y VELAS
//=========================

bool EsNuevaVela(datetime &last_candle_time, ENUM_TIMEFRAMES tf)
{
   datetime tiempo_actual = iTime(_Symbol, tf, 0);

   if(tiempo_actual != last_candle_time)
   {
      last_candle_time = tiempo_actual;
      return true;
   }

   return false;
}

bool EsNuevoDia(datetime &last_day)
{
   datetime tiempo_actual = TimeCurrent();
   MqlDateTime estructura_tiempo_actual, estructura_tiempo_ultimo_dia;
   
   TimeToStruct(tiempo_actual, estructura_tiempo_actual);
   TimeToStruct(last_day, estructura_tiempo_ultimo_dia);

   if(estructura_tiempo_actual.day != estructura_tiempo_ultimo_dia.day)
   {
      last_day = tiempo_actual; 
      return true;
   }

   return false;
}

bool EstamosEnHorarioOperativo(string hora_inicio, string hora_fin)
{
   datetime ahora = TimeCurrent();
   string fecha_hoy = TimeToString(ahora, TIME_DATE);

   datetime inicio = StringToTime(fecha_hoy + " " + hora_inicio);
   datetime fin    = StringToTime(fecha_hoy + " " + hora_fin);

   if(ahora >= inicio && ahora <= fin)
      return true;

   return false;
}

//=========================
// FUNCIONES DE DIBUJO
//=========================

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
