//+------------------------------------------------------------------+
//|                                                            A.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Bryan Cueto Fernández"
#property version   "1.00"
#define EXPERT_MAGIC 123456
#property script_show_inputs

#include <Trade\Trade.mqh>
#include <Object.mqh>
#include <ChartObjects\ChartObject.mqh>
//#include <ChartObjects\ChartObjectsTicks.mqh>

input double Porcentaje = 3.0;
input double DistanciaTakeProfit = 0.0;
double stopLoss = 0.0;

int mouse_x;
int mouse_y;

MqlTradeRequest request = {};
MqlTradeResult result = {};

double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);

enum TIPO_ORDEN
  {
   Comprar = ORDER_TYPE_BUY,
   Vender = ORDER_TYPE_SELL
  };
  
input TIPO_ORDEN orderType = Vender;

int OnInit()
{
   Print("Launched the EA ",MQLInfoString(MQL_PROGRAM_NAME));
   ChartRedraw();
   // Create an MqlTradeRequest with the calculated lot size and specified stop loss distance
   
   return(INIT_SUCCEEDED);
}


// Handle chart events
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
//--- left-clicking on a chart
   if(id==CHARTEVENT_CLICK)
   {
      Print("Mouse click coordinates on a chart: x = ",lparam," y = ",dparam);
      mouse_x = lparam;
      mouse_y = dparam;

      //Calculate the price at the clicked point
      int forget;
      datetime forgettoo;
      ChartXYToTimePrice(ChartID(), mouse_x, mouse_y, forget, forgettoo, stopLoss);
      
      double lot = calcLots(Porcentaje);
      
         if (orderType == ORDER_TYPE_BUY)
   {
      request.type = ORDER_TYPE_BUY;
      if(DistanciaTakeProfit != 0.0)
        {
            double value = MathFloor((SymbolInfoDouble(Symbol(), SYMBOL_ASK) + (DistanciaTakeProfit * tickSize)) / tickSize) * tickSize;
            request.tp = value;
        }

      request.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   }
   else if (orderType == ORDER_TYPE_SELL)
   {
      request.type = ORDER_TYPE_SELL;
      if(DistanciaTakeProfit != 0.0)
        {
            double value = MathFloor((SymbolInfoDouble(Symbol(), SYMBOL_BID) - (DistanciaTakeProfit * tickSize)) / tickSize) * tickSize;
            request.tp = value;
        }

      request.price= SymbolInfoDouble(Symbol(),SYMBOL_BID);
   }
   request.symbol = Symbol();

      request.sl = MathFloor(stopLoss / tickSize) * tickSize;
      if(lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP))
        {
         lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
        }
      request.volume = lot;
      request.deviation = 100;
      request.type_filling = ORDER_FILLING_IOC;
      request.action = TRADE_ACTION_DEAL;
      
      Print(stopLoss);
      
      Print(request.volume);
      
      if(!OrderSend(request,result))
      {
      
         PrintFormat("OrderSend error %d",GetLastError());
         Print(request.volume, " ", request.sl, " ", request.tp, " ");
         PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }
      else
      {
         Print("Operación realizada.");
         ExpertRemove();
      }
   }
}


//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick()
{
   //if(done2)
   //{
   //   ExpertRemove();
   //}
}

double calcLots(double percentOfLoss)
{
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   int DistanciaStopLoss = MathAbs(request.price - stopLoss)/tickSize;
   Print(MathAbs(request.price - stopLoss), " ", request.price - stopLoss, " ", request.price, " ", stopLoss);
   
   double moneyAtRisk = AccountInfoDouble(ACCOUNT_BALANCE) * percentOfLoss / 100;
   double moneyLotStep = DistanciaStopLoss * tickValue * lotStep;
   Print(moneyLotStep, " ", DistanciaStopLoss, " ", tickValue, " ", lotStep);
   double lot = MathFloor(moneyAtRisk / moneyLotStep) * lotStep;
   //Print(moneyAtRisk,"/",moneyLotStep,"*",lotStep, "    ", tickSize);
   while (lotStep < 1)
   {
      lotStep *= 10;
   }
   Print(lotStep);
   return NormalizeDouble(lot, lotStep);
}