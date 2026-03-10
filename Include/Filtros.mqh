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

   // Si el tamaño está entre 3100 y 4500, NO OPERAR
   if(range_size > 3100.0 && range_size < 4500.0)
   {
      Print("Operación cancelada: Opening Range Size (", range_size, ") está en zona de exclusión (3100-4500)");
      return false;
   }
   return true;
}

bool ValidarVelasConsecutivas(bool activar, int current_consec, int max_consec)
{
   if(!activar) return true;
   if(current_consec > max_consec)
   {
      Print("Entrada cancelada por velas consecutivas. Actual: ", current_consec, " > Máximo: ", max_consec);
      return false;
   }
   return true;
}

bool ValidarTendenciaSMA200(bool activar, ENUM_ORDER_TYPE tipo_orden)
{
   if(!activar) return true;

   int handle = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_SMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE) return true;

   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(handle, 0, 0, 1, buffer) <= 0)
   {
      IndicatorRelease(handle);
      return true;
   }
   
   double sma = buffer[0];
   
   if(sma <= 0) 
   {
      IndicatorRelease(handle);
      return true; // Error en el indicador, no filtrar
   }

   double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   IndicatorRelease(handle);

   if(tipo_orden == ORDER_TYPE_BUY)
   {
      if(precio < sma)
      {
         Print("Entrada BUY cancelada por filtro SMA200 H1. Precio: ", precio, " < SMA: ", sma);
         return false;
      }
   }
   else if(tipo_orden == ORDER_TYPE_SELL)
   {
      if(precio > sma)
      {
         Print("Entrada SELL cancelada por filtro SMA200 H1. Precio: ", precio, " > SMA: ", sma);
         return false;
      }
   }

   return true;
}

bool ValidarFiltroVWAP(bool activar, ENUM_ORDER_TYPE tipo_orden, double vwap, double atr, double multiplicador)
{
   if(!activar) return true;
   
   if(vwap <= 0 || atr <= 0) return true; // Si hay error en los datos, no filtramos por seguridad
   
   double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double distancia = 0;
   
   if(tipo_orden == ORDER_TYPE_BUY)
   {
      // Para un BUY (reversión de una ruptura bajista), el precio debe estar POR DEBAJO del VWAP
      distancia = vwap - precio;
      if(distancia < atr * multiplicador)
      {
         Print("Entrada BUY cancelada por filtro VWAP. Distancia: ", DoubleToString(distancia, 1), " < Requerido: ", DoubleToString(atr * multiplicador, 1));
         return false;
      }
   }
   else if(tipo_orden == ORDER_TYPE_SELL)
   {
      // Para un SELL (reversión de una ruptura alcista), el precio debe estar POR ENCIMA del VWAP
      distancia = precio - vwap;
      if(distancia < atr * multiplicador)
      {
         Print("Entrada SELL cancelada por filtro VWAP. Distancia: ", DoubleToString(distancia, 1), " < Requerido: ", DoubleToString(atr * multiplicador, 1));
         return false;
      }
   }
   
   return true;
}

bool ValidarFiltroLondres(bool activar, ENUM_ORDER_TYPE tipo_orden, double lonH, double lonL)
{
   if(!activar) return true;
   if(lonH <= 0 || lonL <= 0) return true; // Si no hay datos, no filtramos

   double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(tipo_orden == ORDER_TYPE_BUY)
   {
      // Para un BUY (reversión de una ruptura bajista), el precio debe estar POR ENCIMA del mínimo de Londres
      if(precio < lonL)
      {
         Print("Entrada BUY cancelada por filtro Londres. Precio: ", precio, " < Mínimo Londres: ", lonL);
         return false;
      }
   }
   else if(tipo_orden == ORDER_TYPE_SELL)
   {
      // Para un SELL (reversión de una ruptura alcista), el precio debe estar POR DEBAJO del máximo de Londres
      if(precio > lonH)
      {
         Print("Entrada SELL cancelada por filtro Londres. Precio: ", precio, " > Máximo Londres: ", lonH);
         return false;
      }
   }

   return true;
}
