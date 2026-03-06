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

bool ValidarRangoSize(bool usar_filtro, double range_points, double limit)
{
   if(!usar_filtro) return true;
   if(range_points <= limit)
   {
      Print("Entrada cancelada por filtro de Opening Range Size. Tamaño: ", DoubleToString(range_points, 1), " <= límite: ", DoubleToString(limit, 1));
      return false;
   }
   return true;
}

bool ValidarVolumen(bool usar_filtro, long current_vol, int limit)
{
   if(!usar_filtro) return true;
   if(current_vol <= limit)
   {
      Print("Entrada cancelada por filtro de volumen. Vol: ", current_vol, " <= límite: ", limit);
      return false;
   }
   return true;
}

bool ValidarDistanciaRuptura(bool usar_filtro, double dist_points, double limit)
{
   if(!usar_filtro) return true;
   if(dist_points > limit)
   {
      Print("Entrada cancelada por filtro de Distancia de Ruptura. Distancia: ", DoubleToString(dist_points, 1), " > máximo: ", DoubleToString(limit, 1));
      return false;
   }
   return true;
}

bool ValidarExclusionRango(bool activar, double range_size)
{
   if(!activar) return true;

   // Si el tamaño está entre 3300 y 4700, NO OPERAR
   if(range_size > 3300.0 && range_size < 4700.0)
   {
      Print("Operación cancelada: Opening Range Size (", range_size, ") está en zona de exclusión (3300-4700)");
      return false;
   }
   return true;
}
