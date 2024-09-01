//+------------------------------------------------------------------+
//|                                         TrendDurationCounter.mq4 |
//|                                              Copyright 2024, MH. |
//+------------------------------------------------------------------+
#property strict



struct trend 
   {
    datetime timestamp;
    int duration;
    double scope;
   };
   


struct instrumentData
   {
    string symbol;
    trend data[];
   };
   

   
enum TREND_MODE 
   {
    UPWARD,
    DOWNWARD,
    BOTH,
   };


   
input ENUM_TIMEFRAMES trendTf = PERIOD_H1;
input TREND_MODE trendMode = BOTH;
input int trendPeriod = 1000;
input int maPeriod = 5;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE;
input int trendFilter = 3;



instrumentData instrumentDataArray[];



int OnInit()
  {
   EventSetTimer(60);
   return(INIT_SUCCEEDED);
  }



void OnDeinit(const int reason)
  {
   EventKillTimer();   
  }



void OnTick()
  {
   
  }



void OnTimer()
  {
   
  }

