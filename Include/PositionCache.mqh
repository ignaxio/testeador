//+------------------------------------------------------------------+
//|                                                PositionCache.mqh |
//|                                  Copyright 2024, Junie           |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Junie"
#property link      "https://www.mql5.com"
#property strict

#include <Arrays\ArrayObj.mqh>

//+------------------------------------------------------------------+
//| Estructura para almacenar el estado de una posición en caché     |
//+------------------------------------------------------------------+
class CPositionState : public CObject
{
public:
   long     ticket;
   bool     gestionado_sl;
   
   // Datos de Apertura (Snapshots)
   double   precio_ent;
   double   sl_inicial;
   double   tp_inicial;
   
   // Métricas de Recorrido (Live)
   double   r_maximo;
   double   precio_max;
   double   precio_min;
   
   CPositionState()
   {
      ticket = 0;
      gestionado_sl = false;
      precio_ent = 0;
      sl_inicial = 0;
      tp_inicial = 0;
      r_maximo = 0;
      precio_max = 0;
      precio_min = 0;
   }
};

//+------------------------------------------------------------------+
//| Clase para gestionar el caché de posiciones                      |
//+------------------------------------------------------------------+
class CPositionCache
{
private:
   CArrayObj m_cache;

public:
   CPositionCache() {}
   ~CPositionCache() { m_cache.Clear(); }

   // Añadir una nueva posición al caché
   void Add(long ticket_id, double p_ent, double sl_ini, double tp_ini)
   {
      if(Get(ticket_id) != NULL) return; // Ya existe

      CPositionState *state = new CPositionState();
      state.ticket = ticket_id;
      state.precio_ent = p_ent;
      state.sl_inicial = sl_ini;
      state.tp_inicial = tp_ini;
      state.precio_max = p_ent;
      state.precio_min = p_ent;
      
      m_cache.Add(state);
   }

   // Buscar una posición por ticket
   CPositionState* Get(long ticket_id)
   {
      for(int i = 0; i < m_cache.Total(); i++)
      {
         CPositionState *state = (CPositionState*)m_cache.At(i);
         if(state.ticket == ticket_id) return state;
      }
      return NULL;
   }

   // Actualizar métricas live de una posición
   void UpdateMetrics(long ticket_id, double current_price)
   {
      CPositionState *state = Get(ticket_id);
      if(state == NULL) return;

      // Actualizar precios extremos
      if(current_price > state.precio_max) state.precio_max = current_price;
      if(current_price < state.precio_min) state.precio_min = current_price;

      // Calcular R-Máximo
      double riesgo = MathAbs(state.precio_ent - state.sl_inicial);
      if(riesgo > 0)
      {
         bool es_buy = (state.sl_inicial < state.precio_ent);
         double beneficio_max = es_buy ? (state.precio_max - state.precio_ent) : (state.precio_ent - state.precio_min);
         double r_tick = beneficio_max / riesgo;
         if(r_tick > state.r_maximo) state.r_maximo = r_tick;
      }
   }

   // Marcar como gestionado
   void SetManaged(long ticket_id, bool managed = true)
   {
      CPositionState *state = Get(ticket_id);
      if(state != NULL) state.gestionado_sl = managed;
   }

   // Eliminar posición (al cerrar)
   void Remove(long ticket_id)
   {
      for(int i = 0; i < m_cache.Total(); i++)
      {
         CPositionState *state = (CPositionState*)m_cache.At(i);
         if(state.ticket == ticket_id)
         {
            m_cache.Delete(i);
            return;
         }
      }
   }
   
   void Clear() { m_cache.Clear(); }
};
