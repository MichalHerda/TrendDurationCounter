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



enum SCOPE_MODE
   {
    OPEN_CLOSE,            //from 1 bar open price to last bar close price
    FULL_RANGE,            //from lowest trend price to highest trend price
   };



struct trendData
   {
    datetime timestamp;
    int duration;
    double scope;
    TREND_MODE trendMode;
   };
   


struct instrumentData
   {
    string symbol;
    trendData trendDataArray[];
   };
   

    
input ENUM_TIMEFRAMES trendTf = PERIOD_H1;
input TREND_MODE inputTrendMode = BOTH;               // trends taken into account
input SCOPE_MODE inputScopeMode = OPEN_CLOSE;
input int trendPeriod = 0;                            // bar index, when trends counting starts
input int maPeriod = 5;
input ENUM_MA_METHOD maMethod = MODE_SMA;
input ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE;
input int trendFilter = 3;                            // minimal trend duration
input bool includeShares = false;



instrumentData instrumentDataArray[];
trendData trendDataArray[];


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



double scopeCalculation(double lowestTrendPrice, double highestTrendPrice)
   {
      return highestTrendPrice - lowestTrendPrice;
   }


void fillTrendDataArray(string symbol)
   {
      ArrayResize(trendDataArray, 0);
      
      string fileName = symbol + "_" + EnumToString(trendTf);
      int fileHandle = FileOpen(fileName, FILE_WRITE);
      
      if(fileHandle != INVALID_HANDLE) {
      
         int barsNo = iBars(symbol, trendTf) - 1;
         int firstCalculatedBarIdx = barsNo - maPeriod;
         datetime firstBarTime = iTime(symbol, trendTf, barsNo);
         Print("name: ", symbol, "first bar time: ", firstBarTime);
         datetime firstCalculatedBarTime = iTime(symbol, trendTf, firstCalculatedBarIdx);
         Print("name: ", symbol, ". bars no: ", barsNo, ". first calculated idx: ", 
               firstCalculatedBarIdx, ". starts at: ", firstCalculatedBarTime);
               
         double previousMaValue = iMA(symbol, trendTf, maPeriod, 0, maMethod, appliedPrice, firstCalculatedBarIdx);
         double currentMaValue = 0;
         int trendDuration = 0;
         TREND_MODE iterationTrend = BOTH;
         datetime timestamp = firstCalculatedBarTime;
         
         double lowestTrendPrice = 0;
         double highestTrendPrice = 0;
         double trendScope = 0;
         
         for(int i = firstCalculatedBarIdx - 1; i > 0; i--) {
          
            currentMaValue = iMA(symbol, trendTf, maPeriod, 0, maMethod, appliedPrice, i);
            Print("idx: ", i, ". current iMA: ", currentMaValue);
            //Print(symbol, ". ", trendTf, ". ", maPeriod, ". ", i, ". ", maMethod, ". ", appliedPrice, 0, ". ");
            int currentArraySize = ArraySize(trendDataArray);
            int currentArrayIdx = currentArraySize -1;
            
            if     (currentMaValue > previousMaValue) {
               if(iterationTrend != UPWARD) { 
                  
                  timestamp = iTime(symbol, trendTf, i);
                  if(trendDuration >= trendFilter) {
                     Print("Writing to file: Index = ", currentArrayIdx,  
                           "Timestamp = ", trendDataArray[currentArrayIdx].timestamp,  
                           "Duration = ", trendDataArray[currentArrayIdx].duration);

                     FileWrite(fileHandle, currentArraySize, trendDataArray[currentArrayIdx].timestamp,
                               EnumToString(trendDataArray[currentArrayIdx].trendMode),
                               trendDataArray[currentArrayIdx].scope,
                               trendDataArray[currentArrayIdx].duration);
                  }
                  
                  if(inputScopeMode == OPEN_CLOSE) { 
                     lowestTrendPrice = iOpen(symbol, trendTf, i);
                     highestTrendPrice = iClose(symbol, trendTf, i);
                  }   
                  if(inputScopeMode == FULL_RANGE) {
                     lowestTrendPrice = iLow(symbol, trendTf, i);
                     highestTrendPrice = iHigh(symbol, trendTf, i);
                  }   
                  
                  iterationTrend = UPWARD;         
                  trendDuration = 0;
               }  
               if(iterationTrend == UPWARD) {
                  trendDuration++;
                  
                  if(inputScopeMode == OPEN_CLOSE) { 
                     highestTrendPrice = MathMax(highestTrendPrice, iClose(symbol, trendTf, i));
                  }   
                  if(inputScopeMode == FULL_RANGE) {
                     lowestTrendPrice = MathMin(lowestTrendPrice, iLow(symbol, trendTf, i));
                     highestTrendPrice = MathMax(highestTrendPrice, iHigh(symbol, trendTf, i));
                  }   
                  Print("trend duration", trendDuration);
                  if(inputTrendMode != DOWNWARD) {
                     
                     if(trendDuration == trendFilter) {
                        ArrayResize(trendDataArray, currentArraySize + 1);
                        currentArraySize = ArraySize(trendDataArray);
                        currentArrayIdx = currentArraySize - 1;
                        trendDataArray[currentArrayIdx].timestamp = timestamp;
                        trendDataArray[currentArrayIdx].trendMode = iterationTrend;
                        trendDataArray[currentArrayIdx].duration = trendDuration;
                     }
                     if(trendDuration > trendFilter) {
                        trendDataArray[currentArrayIdx].duration = trendDuration;
                        trendDataArray[currentArrayIdx].scope = scopeCalculation(lowestTrendPrice, highestTrendPrice);
                     }
                  }   
                  Print("trend duration: ", trendDuration);
               } 
            }
            
            else if(currentMaValue < previousMaValue) {
               if(iterationTrend != DOWNWARD) {
                  timestamp = iTime(symbol, trendTf, i);
                   
                  if(trendDuration >= trendFilter) {
                     Print("Writing to file: Index = ", currentArraySize,  
                            ". Timestamp = ", trendDataArray[currentArrayIdx].timestamp, 
                            ". Duration = ", trendDataArray[currentArrayIdx].duration,
                            ". Scope = ", trendDataArray[currentArrayIdx].scope,
                            ". Duration = ", trendDataArray[currentArrayIdx].duration);

                     FileWrite(fileHandle, currentArraySize, trendDataArray[currentArrayIdx].timestamp,
                               EnumToString(trendDataArray[currentArrayIdx].trendMode),
                               trendDataArray[currentArrayIdx].duration,
                               trendDataArray[currentArrayIdx].scope);
                  }
                  
                  if(inputScopeMode == OPEN_CLOSE) { 
                     highestTrendPrice = iOpen(symbol, trendTf, i);
                     lowestTrendPrice = iClose(symbol, trendTf, i);
                  }   
                  if(inputScopeMode == FULL_RANGE) {
                     highestTrendPrice = iHigh(symbol, trendTf, i);
                     lowestTrendPrice = iLow(symbol, trendTf, i);
                  }  
                  
                  iterationTrend = DOWNWARD; 
                  trendDuration = 0;
               }   
               if(iterationTrend == DOWNWARD) {
                  trendDuration++;
                  
                  if(inputScopeMode == OPEN_CLOSE) { 
                     lowestTrendPrice = MathMin(lowestTrendPrice, iClose(symbol, trendTf, i));
                  }   
                  if(inputScopeMode == FULL_RANGE) {
                     highestTrendPrice = MathMax(highestTrendPrice, iHigh(symbol, trendTf, i));
                     lowestTrendPrice = MathMin(lowestTrendPrice, iLow(symbol, trendTf, i));                    
                  }   
                  
                  if(inputTrendMode != UPWARD) {
                     //int currentArraySize = ArraySize(trendDataArray);
                     if(trendDuration == trendFilter) {
                        ArrayResize(trendDataArray, currentArraySize + 1);
                        currentArraySize = ArraySize(trendDataArray);
                        currentArrayIdx = currentArraySize - 1;
                        trendDataArray[currentArrayIdx].timestamp = timestamp;
                        trendDataArray[currentArrayIdx].trendMode = iterationTrend;
                        trendDataArray[currentArrayIdx].duration = trendDuration;
                     }
                     if(trendDuration > trendFilter) {
                        trendDataArray[currentArrayIdx].duration = trendDuration;
                        trendDataArray[currentArrayIdx].scope = scopeCalculation(lowestTrendPrice, highestTrendPrice);
                     }
                  }   
               }
            }
            
            else if(currentMaValue == previousMaValue) {
            
            }
            
            previousMaValue = currentMaValue;
          }  
          FileClose(fileHandle);
       }
       else {
         Print("invalid file handle");
       }
   }


int OnInit()
  {
   //EventSetTimer(60);
   
   ArrayResize(instrumentDataArray, 0);
   
   int availableSymbols = SymbolsTotal(false);
   Print("available symbols: ", availableSymbols);
   
   Print("non share instruments: ", countNonShareInstruments(availableSymbols));
   
   for(int i = 0; i < availableSymbols; i++) {
   
      string symbol = SymbolName(i, false);
      
      if(!includeShares && isShare(symbol)) {
         Print(symbol, " is stocks, the current settings do not support stocks.");
      }
      
      else {
         
         fillTrendDataArray(symbol);
         
         ArrayResize(instrumentDataArray, ArraySize(instrumentDataArray) + 1);
         Print("instrumentDataArray after resizing: ", ArraySize(instrumentDataArray));
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

