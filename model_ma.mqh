//+------------------------------------------------------------------+
//|                                                    cmodel_ma.mqh |
//|                            Copyright 2010, Vasily Sokolov (C-4). |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Models\Model.mqh>
#include <mm.mqh>
//+----------------------------------------------------------------------+
//| This model uses one moving average.                                  |
//| Buy when the current price crosses the moving average upward,        |
//| Sell when the current price crosses the moving average downward      |
//| This algoritm uses simple Trailing Stop                              |
//+----------------------------------------------------------------------+  
struct cmodel_ma_param
  {
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   int               ma;
   int               bar_tral_size;
   double            delta;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cmodel_ma : public CModel
  {
private:
   int               m_ma;
   int               m_bar_tral_size;
   double            m_ma_buff_main[];
   MqlRates          m_raters[];
   double            m_current_price;
   double            m_price_ma;
   int               m_handle_ma;
   t_period          m_timing_buy;
   t_period          m_timing_sell;
public:
                     cmodel_ma();
   bool              Init();
   bool              Init(cmodel_ma_param &m_param);
   bool              Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES TimeFrame,double delta,uint ma,uint size_bral_tral);
   bool              Processing();
protected:
   bool              InitIndicators();
   bool              CheckParam(cmodel_ma_param &m_param);
   bool              LongOpened();
   bool              ShortOpened();
   bool              LongClosed();
   bool              ShortClosed();
   bool              TralOrders();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
cmodel_ma::cmodel_ma()
  {
   m_handle_ma=INVALID_HANDLE;
   ArraySetAsSeries(m_ma_buff_main,true);
   ArraySetAsSeries(m_raters,true);
   m_current_price=0.0;
   m_price_ma=0.0;
  }
//this default loader
bool cmodel_ma::Init()
  {
   m_magic         = 142383;
   m_model_name    =  "Moving Average Model";
   m_symbol        = _Symbol;
   m_timeframe     = _Period;
   m_ma            = 12;
   m_bar_tral_size = 3;
   m_delta         = 0;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::Init(cmodel_ma_param &m_param)
  {
   m_magic      = 148394;
   m_model_name = "MACD MODEL";
   m_symbol     = m_param.symbol;
   m_timeframe  = (ENUM_TIMEFRAMES)m_param.timeframe;
   m_ma         = m_param.ma;
   m_bar_tral_size=m_param.bar_tral_size;
   m_delta=m_param.delta;
   if(!CheckParam(m_param))return(false);
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES TimeFrame,double delta,uint ma,uint size_bral_tral)
  {
   if(ma==0)ma=12;
   m_magic=magic;
   m_model_name=name;
   m_symbol=symbol;
   m_timeframe=TimeFrame;
   m_ma=ma;
   m_bar_tral_size=size_bral_tral;
   m_delta=delta;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::CheckParam(cmodel_ma_param &m_param)
  {
   if(!SymbolInfoInteger(m_symbol,SYMBOL_SELECT))
     {
      Print("Symbol ",m_symbol," selection has failed. Check symbol name");
      return(false);
     }
   if(m_ma==0)
     {
      Print("Fast EMA must be > 0. Set MA = 12 (default)");
      m_ma=12;
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::InitIndicators()
  {
   if(m_handle_ma==INVALID_HANDLE)
     {
      Print("Load indicators...");
      if((m_handle_ma=iMA(m_symbol,m_timeframe,m_ma,0,MODE_SMA,PRICE_CLOSE))==INVALID_HANDLE)
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
bool cmodel_ma::Processing()
  {
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
//if(m_account_info.TradeAllowed()==false)return(false);
//if(m_account_info.TradeExpert()==false)return(false);

   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
//Copy last data of moving average
//CopyBuffer(this.m_handle_ma,0,0,1,m_macd_buff_main);
   TralOrders();
   GetNumberOrders(m_orders);
   if(m_orders.buy_orders>0) LongClosed();
   else                        LongOpened();
   if(m_orders.sell_orders!=0) ShortClosed();
   else                        ShortOpened();
   LongOpened();
   ShortOpened();
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::LongOpened(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_SHORTONLY)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);

   bool rezult,time_buy=true;
   double lot=0.01;
   double sl=0.0;
   mm open_mm;
   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(this.m_handle_ma,0,0,1,m_ma_buff_main);
   CopyRates(m_symbol,m_timeframe,0,m_bar_tral_size,m_raters);
   GetNumberOrders(m_orders);
//Print("LongOpened");
   if(timing(m_symbol,m_timeframe,m_timing_buy)==true)time_buy=true;
   if(m_symbol_info.Ask()>m_ma_buff_main[0] && m_raters[0].open<m_ma_buff_main[0] && m_orders.buy_orders==0 && time_buy==true)
     {

      //lot=open_mm.optimal_f(m_symbol,ORDER_TYPE_BUY,m_symbol_info.Ask(),0.01,m_delta);
      //lot=open_mm.jons_fp(m_symbol, ORDER_TYPE_BUY, m_symbol_info.Ask(), 0.01, 10000, m_delta);
      //sl=iLowest(m_symbol,m_timeframe,MODE_LOW,1,m_bar_tral_size);
      double sl=m_symbol_info.Bid()-30*_Point;
      double tp=m_symbol_info.Ask()+100*_Point;
      Print("Open buy position with Stop Loss: ",sl);
      rezult=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_ADD,0,lot,m_symbol_info.Ask(),sl,tp,"MA Buy");
      time_buy=false;
      return(rezult);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::ShortOpened(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_LONGONLY)return(false);
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);

   bool rezult,time_sell=true;
   double lot=0.01;
   double sl=0.0;
   mm open_mm;

   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   GetNumberOrders(m_orders);
   CopyBuffer(this.m_handle_ma,0,0,1,m_ma_buff_main);
   CopyRates(m_symbol,m_timeframe,0,m_bar_tral_size,m_raters);
   if(timing(m_symbol,m_timeframe,m_timing_sell)==true)time_sell=true;
   if(m_symbol_info.Bid()<m_ma_buff_main[0] && m_raters[0].open>m_ma_buff_main[0] && m_orders.sell_orders==0 && time_sell==true)
     {
      //lot=open_mm.optimal_f(m_symbol, ORDER_TYPE_SELL, m_symbol_info.Bid(), 0.0, m_delta);
      //lot=open_mm.jons_fp(m_symbol,ORDER_TYPE_SELL,m_symbol_info.Bid(),0.01,10000,m_delta);
      //sl=iHighest(m_symbol,m_timeframe,MODE_HIGH,1,m_bar_tral_size);
      double sl=m_symbol_info.Bid()+30*_Point;
      double tp=m_symbol_info.Ask()-100*_Point;
      rezult=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_ADD,0,lot,m_symbol_info.Bid(),sl,tp,"MA Sell");
      time_sell=false;
      return(rezult);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::LongClosed(void)
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
      CopyBuffer(this.m_handle_ma,0,1,2,m_ma_buff_main);
      if(m_symbol_info.Bid()<=t.StopLoss() && t.StopLoss()!=0.0)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Bid(),0.0,0.0,"MA: buy closed buy stop-loss");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::ShortClosed(void)
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
      CopyBuffer(this.m_handle_ma,0,1,2,m_ma_buff_main);
      if(m_symbol_info.Ask()>=t.StopLoss() && t.StopLoss()!=0.0)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Ask(),0.0,0.0,"MA: sell closed buy stop-loss");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_ma::TralOrders(void)
  {
   int total_elements;
   int rez=false;
   double sl;
// if new bar is started
   //if(timing(m_symbol,m_timeframe,m_timing))
     {
      CopyRates(m_symbol,m_timeframe,0,m_bar_tral_size,m_raters);
      CTableOrders *t;
      total_elements=GetPointer(ListTableOrders.Total());
      Print("Total Elements: ", total_elements);
      if(total_elements==0)return(false);
      for(int i=total_elements-1;i>=0;i--)
        {
         if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
         t=ListTableOrders.GetNodeAtIndex(i);
         if(CheckPointer(t)==POINTER_INVALID)continue;
         m_symbol_info.Refresh();
         m_symbol_info.RefreshRates();
         if(t.Type()==ORDER_TYPE_BUY)
           {
            sl=iLowest(m_symbol,m_timeframe,MODE_LOW,1,m_bar_tral_size);
            if(sl>t.StopLoss())t.StopLoss(sl);
           }
         if(t.Type()==ORDER_TYPE_SELL)
           {
            sl=iHighest(m_symbol,m_timeframe,MODE_HIGH,1,m_bar_tral_size);
            if(sl<t.StopLoss())t.StopLoss(sl);
           }
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
