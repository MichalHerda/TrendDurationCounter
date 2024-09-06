//+------------------------------------------------------------------+
//|                                         TrendDurationCounter.mq4 |
//|                                              Copyright 2024, MH. |
//+------------------------------------------------------------------+
#property strict



enum TREND_MODE 
   {
    UPWARD,
    DOWNWARD,
    BOTH,
   };



struct trend 
   {
    datetime timestamp;
    int duration;
    double scope;
    TREND_MODE trendMode;
   };
   


struct instrumentData
   {
    string symbol;
    trend data[];
   };
   

    
input ENUM_TIMEFRAMES trendTf = PERIOD_H1;
input TREND_MODE trendMode = BOTH;                    // trends taken into account
input int trendPeriod = 0;                            // bar index, when trends counting starts
input int maPeriod = 5;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE;
input int trendFilter = 3;                            // minimal trend duration
input bool includeShares = false;



instrumentData instrumentDataArray[];



double pricePosition(string symbol, ENUM_TIMEFRAMES tf, int period, TREND_MODE trend_mode) 
   {
    int maximumPriceIdx = iHighest(symbol, tf, period);
    double maximumPrice = iHigh(symbol, tf, maximumPriceIdx);
    
    int minimumPriceIdx = iLowest(symbol, tf, period);
    double minimumPrice = iLow(symbol, tf, minimumPriceIdx);
    
    double span = maximumPrice - minimumPrice;
    
    double currentPrice = 0;
    if(trend_mode == UPWARD) { currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK); }
    if(trend_mode == DOWNWARD) { currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID); }
    if(trend_mode == BOTH) { Print("Wrong trend_mode. Switch to UPWARD "); 
                             trend_mode = UPWARD;
                             currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);                          
                           }
    double calculatedPrice = currentPrice - minimumPrice;
                            
    if( (span != 0) && (maximumPrice > minimumPrice) )
      {
       return (calculatedPrice / span) * 100;
      }
   else
       return 0; 
   } 
   
bool isShare(string symbol)
   {
    int firstCharCode = StringGetChar(symbol, 0);
    return firstCharCode == '#';
   }


   
int countNonShareInstruments(int availableSymbols)
   {
      int nonShareInstruments = 0;
      
      for(int i = 0; i < availableSymbols; i++) {
         string symbol = SymbolName(i, false);
         if(!isShare(symbol)) nonShareInstruments++;
      }
      
      return nonShareInstruments;
   }



int OnInit()
  {
   //EventSetTimer(60);
   int availableSymbols = SymbolsTotal(false);
   Print("available symbols: ", availableSymbols);
   
   Print("non share instruments: ", countNonShareInstruments(availableSymbols));
   for(int i = 0; i < availableSymbols; i++) {
   
      string symbol = SymbolName(i, false);
      
      if(!includeShares && isShare(symbol)) {
         Print(symbol, " is stocks, the current settings do not support stocks.");
      }
      
      else {
         int barsNo = iBars(symbol, trendTf) - 1;
         int firstCalculatedBarIdx = barsNo - maPeriod;
         datetime firstBarTime = iTime(symbol, trendTf, barsNo);
         Print("name: ", symbol, "first bar time: ", firstBarTime);
         datetime firstCalculatedBarTime = iTime(symbol, trendTf, firstCalculatedBarIdx);
         Print("index: ",i ,". name: ", symbol, ". bars no: ", barsNo, ". first calculated idx: ", firstCalculatedBarIdx, ". starts: ", firstCalculatedBarTime);
      }
      
   }   
   return(INIT_SUCCEEDED);
  }



void OnDeinit(const int reason)
  {
   //EventKillTimer();   
  }



void OnTick()
  {
   
  }



void OnTimer()
  {
   
  }

