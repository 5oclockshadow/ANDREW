//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2010, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Models\Model.mqh>
#include <mm.mqh>
//+----------------------------------------------------------------------+
//| This model uses MACD indicator.                                      |
//| Buy when the indicator crosses zero line upward                      |
//| Sell when the indicator crosses zero line downward                   |
//+----------------------------------------------------------------------+  
struct cmodel_macd_param
  {
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   int               fast_ema;
   int               slow_ema;
   int               signal_ema;
   double            delta;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cmodel_macd : public CModel
  {
private:
   int               m_slow_ema;
   int               m_fast_ema;
   int               m_signal_ema;
   int               m_handle_macd;
   double            m_macd_buff_main[];
   double            m_macd_current;
   double            m_macd_previous;
public:
                     cmodel_macd();
   bool              Init();
   bool              Init(cmodel_macd_param &m_param);
   bool              Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES TimeFrame,double delta,uint FastEMA,uint SlowEMA,uint SignalEMA);
   bool              Init(string symbol,ENUM_TIMEFRAMES timeframes,int slow_ma,int fast_ma,int smothed_ma);
   bool              Processing();
protected:
   bool              InitIndicators();
   bool              CheckParam(cmodel_macd_param &m_param);
   bool              LongOpened();
   bool              ShortOpened();
   bool              LongClosed();
   bool              ShortClosed();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
cmodel_macd::cmodel_macd()
  {
   m_handle_macd=INVALID_HANDLE;
   ArraySetAsSeries(m_macd_buff_main,true);
   m_macd_current=0.0;
   m_macd_previous=0.0;
  }
//this default loader
bool cmodel_macd::Init()
  {
   m_magic      = 148394;
   m_model_name =  "MACD MODEL";
   m_symbol     = _Symbol;
   m_timeframe  = _Period;
   m_slow_ema   = 8;
   m_fast_ema   = 32;
   m_signal_ema = 3;
   m_delta      = 0;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::Init(cmodel_macd_param &m_param)
  {
   m_magic      = 148394;
   m_model_name = "MACD MODEL";
   m_symbol     = m_param.symbol;
   m_timeframe  = (ENUM_TIMEFRAMES)m_param.timeframe;
   m_fast_ema   = m_param.fast_ema;
   m_slow_ema   = m_param.slow_ema;
   m_signal_ema = m_param.signal_ema;
   m_delta      = m_param.delta;
   if(!CheckParam(m_param))return(false);
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES TimeFrame,double delta,uint FastEMA,uint SlowEMA,uint SignalEMA)
  {
   if(FastEMA==0)FastEMA=8;
   if(SlowEMA==0)SlowEMA=32;
   if(SignalEMA==0)SignalEMA=3;
   m_magic=magic;
   m_model_name=name;
   m_symbol=symbol;
   m_timeframe=TimeFrame;
   m_fast_ema=FastEMA;
   m_slow_ema=SlowEMA;
   m_signal_ema=SignalEMA;
   m_delta=delta;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::CheckParam(cmodel_macd_param &m_param)
  {
   if(!SymbolInfoInteger(m_symbol,SYMBOL_SELECT))
     {
      Print("Symbol ",m_symbol," select failed. Check valid name symbol");
      return(false);
     }
   if(m_fast_ema==0)
     {
      Print("Fast EMA must be > 0");
      return(false);
     }
   if(m_slow_ema==0)
     {
      Print("Slow EMA must be > 0");
      return(false);
     }
   if(m_signal_ema==0)
     {
      Print("Signal EMA must be > 0");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::InitIndicators()
  {
   if(m_handle_macd==INVALID_HANDLE)
     {
      Print("Load indicators...");
      if((m_handle_macd=iMACD(m_symbol,m_timeframe,m_fast_ema,m_slow_ema,m_signal_ema,PRICE_CLOSE))==INVALID_HANDLE)
        {
         printf("Error creating MACD indicator");
         return(false);
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::Processing()
  {
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
//if(m_account_info.TradeAllowed()==false)return(false);
//if(m_account_info.TradeExpert()==false)return(false);

   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(this.m_handle_macd,0,1,2,m_macd_buff_main);
   m_macd_current=m_macd_buff_main[0];
   m_macd_previous=m_macd_buff_main[1];
   GetNumberOrders(m_orders);
   /*if(m_orders.buy_orders>0)  */ LongClosed();
   /*else*/                        LongOpened();
   /*if(m_orders.sell_orders!=0)*/ ShortClosed();
   /*else*/                        ShortOpened();
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::LongOpened(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_SHORTONLY)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);

   bool rezult;
   double lot=0.01;
   
   mm open_mm;
   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(this.m_handle_macd,0,1,2,m_macd_buff_main);

   m_macd_current=m_macd_buff_main[0];
   m_macd_previous=m_macd_buff_main[1];
   GetNumberOrders(m_orders);

//Print("LongOpened");
   if(m_macd_current>0 && m_macd_previous<=0 &&(m_orders.buy_orders!=10))
     {
      //lot=open_mm.jons_fp(m_symbol,ORDER_TYPE_BUY,m_symbol_info.Ask(),0.01,10000,m_delta);
      double sl=m_symbol_info.Bid()-30*_Point;
      double tp=m_symbol_info.Ask()+65*_Point;
      rezult=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_ADD,0,lot,m_symbol_info.Ask(),sl,tp,"MACD Buy");
      return(rezult);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::ShortOpened(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_LONGONLY)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);

   bool rezult;
   double lot=0.01;
   mm open_mm;

   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(this.m_handle_macd,0,1,2,m_macd_buff_main);

   m_macd_current=m_macd_buff_main[0];
   m_macd_previous=m_macd_buff_main[1];
   GetNumberOrders(m_orders);

   if(m_macd_current<=0 && m_macd_previous>=0 && (m_orders.sell_orders!=10))
     {
      //lot=open_mm.jons_fp(m_symbol,ORDER_TYPE_SELL,m_symbol_info.Bid(),0.01,10000,m_delta);
      rezult=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_ADD,0,lot,m_symbol_info.Bid(),m_symbol_info.Ask()+30*_Point,m_symbol_info.Bid()-65*_Point,"MACD Sell");
      return(rezult);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::LongClosed(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   int rez=false;
   total_elements=ListTableOrders.Total();
   if(total_elements==0)return(false);
   for(int i=total_elements-1;i>=0;i--)
     {
      if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
      t=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(t)==POINTER_INVALID)continue;
      if(t.Type()!=ORDER_TYPE_BUY)continue;
      m_symbol_info.Refresh();
      m_symbol_info.RefreshRates();
      CopyBuffer(this.m_handle_macd,0,1,2,m_macd_buff_main);
      if(m_symbol_info.Bid()<=t.StopLoss() && t.StopLoss()!=0.0)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Bid(),0.0,0.0,"MACD: buy closed buy stop-loss");
        }
      if(m_macd_current<0 && m_macd_previous>=0)
        {
         //Print("Long Closed by Order Send");
         rez=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Bid(),0.0,0.0,"MACD: buy closed by signal");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_macd::ShortClosed(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   int rez=false;
   total_elements=ListTableOrders.Total();
   if(total_elements==0)return(false);
   for(int i=total_elements-1;i>=0;i--)
     {
      if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
      t=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(t)==POINTER_INVALID)continue;
      if(t.Type()!=ORDER_TYPE_SELL)continue;
      m_symbol_info.Refresh();
      m_symbol_info.RefreshRates();
      CopyBuffer(this.m_handle_macd,0,1,2,m_macd_buff_main);
      if(m_symbol_info.Ask()>=t.StopLoss() && t.StopLoss()!=0.0)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Ask(),0.0,0.0,"MACD: sell closed buy stop-loss");
        }
      if(m_macd_current>0 && m_macd_previous<=0)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Ask(),0.0,0.0,"MACD: sell closed by signal");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
