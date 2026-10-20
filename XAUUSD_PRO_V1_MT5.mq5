//+------------------------------------------------------------------+
//| XAUUSD PRO V1 - MT5 Expert Advisor (Demo starter)                |
//| Strategy: EMA 20/50/200 + RSI(14) confirmation on closed M5 bar   |
//| Risk controls: ATR-based SL, RR-based TP, one position per symbol|
//| IMPORTANT: Test on DEMO. This is not a profit guarantee.         |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "XAUUSD PRO V1 demo starter EA"

#include <Trade/Trade.mqh>
CTrade trade;

input string          InpSymbol             = "";       // Empty = chart symbol
input ENUM_TIMEFRAMES InpTimeframe          = PERIOD_M5;
input double          InpRiskPercent         = 0.5;      // Risk % of equity per trade
input int             InpFastEMA             = 20;
input int             InpMidEMA              = 50;
input int             InpSlowEMA             = 200;
input int             InpRSIPeriod            = 14;
input double          InpBuyRSIMin            = 52.0;
input double          InpSellRSIMax           = 48.0;
input int             InpATRPeriod            = 14;
input double          InpSL_ATR_Multiplier    = 2.0;
input double          InpRewardRisk           = 1.5;
input int             InpMaxSpreadPoints      = 80;       // Broker points; tune for your broker
input ulong           InpMagic                = 20261020;
input bool            InpAllowBuy             = true;
input bool            InpAllowSell            = true;

int hFast = INVALID_HANDLE, hMid = INVALID_HANDLE, hSlow = INVALID_HANDLE;
int hRSI = INVALID_HANDLE, hATR = INVALID_HANDLE;
datetime lastBarTime = 0;

string TradeSymbol()
{
   if(StringLen(InpSymbol) > 0) return InpSymbol;
   return _Symbol;
}

bool ReadOne(int handle, int buffer, int shift, double &value)
{
   double data[];
   ArraySetAsSeries(data, true);
   if(CopyBuffer(handle, buffer, shift, 1, data) != 1) return false;
   value = data[0];
   return (value != EMPTY_VALUE);
}

bool NewBar()
{
   datetime t[1];
   if(CopyTime(TradeSymbol(), InpTimeframe, 0, 1, t) != 1) return false;
   if(t[0] == lastBarTime) return false;
   lastBarTime = t[0];
   return true;
}

double NormalizeVolume(double volume)
{
   string sym = TradeSymbol();
   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(step <= 0) return 0.0;
   volume = MathFloor(volume / step) * step;
   volume = MathMax(vmin, MathMin(vmax, volume));
   int digits = 0;
   double s = step;
   while(digits < 8 && MathAbs(s - MathRound(s)) > 1e-8) { s *= 10.0; digits++; }
   return NormalizeDouble(volume, digits);
}

double CalculateLots(double entry, double sl)
{
   string sym = TradeSymbol();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPercent / 100.0;
   double tickSize = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE_LOSS);
   double distance = MathAbs(entry - sl);
   if(tickSize <= 0 || tickValue <= 0 || distance <= 0 || riskMoney <= 0) return 0.0;

   double lossPerLot = (distance / tickSize) * tickValue;
   if(lossPerLot <= 0) return 0.0;
   double rawLots = riskMoney / lossPerLot;

   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   if(rawLots < vmin) return 0.0; // Do not force minimum lot if it exceeds chosen risk
   return NormalizeVolume(rawLots);
}

bool HasPosition()
{
   string sym = TradeSymbol();
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetString(POSITION_SYMBOL) == sym)
         return true;
   }
   return false;
}

int OnInit()
{
   string sym = TradeSymbol();
   if(!SymbolSelect(sym, true))
   {
      Print("Cannot select symbol: ", sym);
      return INIT_FAILED;
   }

   hFast = iMA(sym, InpTimeframe, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hMid  = iMA(sym, InpTimeframe, InpMidEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(sym, InpTimeframe, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI  = iRSI(sym, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   hATR  = iATR(sym, InpTimeframe, InpATRPeriod);

   if(hFast == INVALID_HANDLE || hMid == INVALID_HANDLE ||
      hSlow == INVALID_HANDLE || hRSI == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("Failed to create indicator handles.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(sym);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hMid  != INVALID_HANDLE) IndicatorRelease(hMid);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hRSI  != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR  != INVALID_HANDLE) IndicatorRelease(hATR);
}

void OnTick()
{
   string sym = TradeSymbol();
   if(!NewBar()) return;

   // Need enough bars for EMA 200.
   if(Bars(sym, InpTimeframe) < InpSlowEMA + 10) return;
   if(HasPosition()) return;

   MqlTick tick;
   if(!SymbolInfoTick(sym, tick)) return;

   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(point <= 0) return;
   double spreadPoints = (tick.ask - tick.bid) / point;
   if(spreadPoints > InpMaxSpreadPoints)
   {
      Print("WAIT: spread too high: ", spreadPoints, " points");
      return;
   }

   double emaFast, emaMid, emaSlow, rsi, atr;
   // Shift 1 = most recently closed candle; avoid forming-candle signals.
   if(!ReadOne(hFast, 0, 1, emaFast) ||
      !ReadOne(hMid, 0, 1, emaMid) ||
      !ReadOne(hSlow, 0, 1, emaSlow) ||
      !ReadOne(hRSI, 0, 1, rsi) ||
      !ReadOne(hATR, 0, 1, atr)) return;

   double close1 = iClose(sym, InpTimeframe, 1);
   if(close1 <= 0 || atr <= 0) return;

   bool buySignal  = InpAllowBuy  && close1 > emaSlow && emaFast > emaMid &&
                     emaMid > emaSlow && rsi >= InpBuyRSIMin;
   bool sellSignal = InpAllowSell && close1 < emaSlow && emaFast < emaMid &&
                     emaMid < emaSlow && rsi <= InpSellRSIMax;

   if(!buySignal && !sellSignal)
   {
      Print("WAIT: no clear setup. Close=", close1, " RSI=", rsi);
      return;
   }

   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double slDistance = atr * InpSL_ATR_Multiplier;
   bool sent = false;

   if(buySignal)
   {
      double entry = tick.ask;
      double sl = NormalizeDouble(entry - slDistance, digits);
      double tp = NormalizeDouble(entry + slDistance * InpRewardRisk, digits);
      double lots = CalculateLots(entry, sl);
      if(lots <= 0) { Print("BUY skipped: calculated lot is below broker minimum or symbol data unavailable."); return; }
      sent = trade.Buy(lots, sym, 0.0, sl, tp, "XAUUSD PRO V1 BUY");
   }
   else if(sellSignal)
   {
      double entry = tick.bid;
      double sl = NormalizeDouble(entry + slDistance, digits);
      double tp = NormalizeDouble(entry - slDistance * InpRewardRisk, digits);
      double lots = CalculateLots(entry, sl);
      if(lots <= 0) { Print("SELL skipped: calculated lot is below broker minimum or symbol data unavailable."); return; }
      sent = trade.Sell(lots, sym, 0.0, sl, tp, "XAUUSD PRO V1 SELL");
   }

   if(!sent)
      Print("Order failed. Retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
   else
      Print("Order sent. Ticket=", trade.ResultOrder(), " Volume=", trade.ResultVolume());
}
//+------------------------------------------------------------------+
