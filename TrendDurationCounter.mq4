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



int OnInit()
  {
   //EventSetTimer(60);
   int availableSymbols = SymbolsTotal(false);
   Print("available symbols: ", availableSymbols);
   
   for(int i = 0; i < availableSymbols; i++) {
   
      string symbol = SymbolName(i, false);
      int barsNo = iBars(symbol, trendTf) - 1;
      int firstCalculatedBarIdx = barsNo - maPeriod;
      datetime firstBarTime = iTime(symbol, trendTf, barsNo);
      Print("name: ", symbol, "first bar time: ", firstBarTime);
      datetime firstCalculatedBarTime = iTime(symbol, trendTf, firstCalculatedBarIdx);
      Print("index: ",i ,". name: ", symbol, ". bars no: ", barsNo, "first calculated idx: ", firstCalculatedBarIdx, "starts: ", firstCalculatedBarTime);
      
      
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

