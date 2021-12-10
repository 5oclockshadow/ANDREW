//+------------------------------------------------------------------+
//|                                                   MACD model.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Models\model_macd.mqh>
#include <Models\model_ma.mqh>
#include <Models\model_bollinger.mqh>

CList *list_model;
CTrade trade;
MqlTick new_tick,
old_tick;
// --- Model Bollinger Param ----
input string   str_bollinger="";       // Parameters of Model Bollinger
input   int    period_bollinger = 20;  // Period Bollinger 
input   double dev_bollinger    = 2.0; // Deviation Bollinger
input   double k_ATR            = 2.0; // Rate ATR
input   double delta_risk       = 100; // Rate Delta (risk)
                                       // --- Model MACD Param -----
input string str_macd="";              // Parameters of Model MACD
input uint Fast_MA        = 12;        // Fast Moving Average
input uint Slow_MA        = 26;        // Slow Moving Average
input double percent_risk = 5.0;       // Rate Risk in %
uint Signal_MA = 9;              // Signal Moving Average
                                 //bool is_testing=false;

bool macd_default=false;
bool macd_best=true;
bool bollinger_default=false;
bool bollinger_best=true;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   InitModels();
   EventSetTimer(30);
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   CModel *model;                         // create pointer to base model
   for(int i=0;i<list_model.Total();i++)
     { // proceed all models in the list
      model=list_model.GetNodeAtIndex(i); // set pointer to the current model
      model.Processing();                 // call processing of the current model
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete list_model;                     // release memory (list of models)
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitModels()
  {
   list_model = new CList;             // create a list with models
   cmodel_macd *model_macd;            // declare pointer to MACD model
   cmodel_bollinger *model_bollinger;  // declare pointer to Bollinger model
   cmodel_ma* model_ma;                // declare pointer to MA model
   

//----------------------------------------MACD DEFAULT----------------------------------------
  /* if(macd_default==true && macd_best==false)
     {
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
                                  // Model initialization has successful
      if(model_macd.Init(129475,"Model macd M15",_Symbol,_Period,0.0,Fast_MA,Slow_MA,Signal_MA))
        {

         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {
         // initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," create has failed");
        }
     }*/
//-------------------------------------------------------------------------------------------
//----------------------------------------MACD BEST------------------------------------------
   if(macd_best==true && macd_default==false)
     {
     // Movin Average Section
     model_ma=new cmodel_ma; // Initialize pointer to MA Model Instance
     if(model_ma.Init(129475,"MA model M1","XAUUSD",PERIOD_M1,delta_risk,12,10))
       {
        Print("Print(Model ",model_ma.Name()," with period = ",model_ma.Period(),
              " on symbol ",model_ma.Symbol()," successfully created");
        list_model.Add(model_ma);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
     
     // 1.1 EURUSD M1; FMA=8; SMA=21; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd M1","EURUSD",PERIOD_M1,delta_risk,8,21,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
     
     // 1.1 XAUUSD M1; FMA=8; SMA=21; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd M1","XAUUSD",PERIOD_M1,delta_risk,8,21,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
     
     // 1.1 XAGUSD H30; FMA=8; SMA=21; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd H30","XAGUSD",PERIOD_M30,delta_risk,8,21,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
     
      // 1.1 EURUSD H30; FMA=20; SMA=24; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd H30","EURUSD",PERIOD_M30,delta_risk,20,24,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
      // 1.2 EURUSD H3; FMA=8; SMA=12; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd M1","AUDCAD",PERIOD_M1,delta_risk,8,12,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
      // 1.3 AUDUSD H1; FMA=10; SMA=18; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd M15","GBPUSD",PERIOD_M1,delta_risk,10,18,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
      // 1.4 AUDUSD H4; FMA=14; SMA=15; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd H4","AUDUSD",PERIOD_H4,delta_risk,14,15,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
      // 1.5 GBPUSD H6; FMA=20; SMA=33; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd M5","USDCAD",PERIOD_M5,delta_risk,20,33,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
      // 1.6 GBPUSD H12; FMA=12; SMA=30; 
      model_macd=new cmodel_macd; // Initialize pointer with MACD model instance
      if(model_macd.Init(129475,"Model macd H6","GBPUSD",PERIOD_H12,delta_risk,12,30,9))
        {
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," successfully created");
         list_model.Add(model_macd);// add model to the list of models
        }
      else
        {// initialization of model has failed
         Print("Print(Model ",model_macd.Name()," with period = ",model_macd.Period(),
               " on symbol ",model_macd.Symbol()," creation has failed");
        }
     }
   }  
