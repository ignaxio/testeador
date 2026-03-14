//+------------------------------------------------------------------+
//|                                                       Filtros.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

//=========================
// FUNCIONES DE VALIDACIÓN
//=========================

bool ValidarRangoSize(bool usar_filtro, double range_points, double limit, bool es_maximo = true)
{
   if(!usar_filtro) return true;
   if((es_maximo && range_points > limit) || (!es_maximo && range_points < limit))
   {
      string comp = es_maximo ? " > " : " < " ;
      Print("Entrada cancelada por filtro de Opening Range Size. Tama�o: ", DoubleToString(range_points, 1), comp, "l�mite: ", DoubleToString(limit, 1));
      return false;
   }
   return true;
}

bool ValidarExclusionRango(bool activar, double range_size)
{
   if(!activar) return true;

   // Si el tamaño está entre 3100 y 4500, NO OPERAR
   if(range_size > 3100.0 && range_size < 4500.0)
   {
      Print("Operación cancelada: Opening Range Size (", range_size, ") está en zona de exclusión (3100-4500)");
      return false;
   }
   return true;
}

bool ValidarATR(bool usar_filtro, double current_atr, double limit, bool es_maximo = true)
{
   if(!usar_filtro) return true;
   if((es_maximo && current_atr > limit) || (!es_maximo && current_atr < limit))
   {
      string comp = es_maximo ? " > " : " < " ;
      Print("Entrada cancelada por filtro de ATR. Valor: ", DoubleToString(current_atr, 1), comp, "límite: ", DoubleToString(limit, 1));
      return false;
   }
   return true;
}
