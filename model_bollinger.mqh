//+------------------------------------------------------------------+
//|                                              model_bollinger.mqh |
//|                            Copyright 2010, Vasily Sokolov (C-4). |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Models\Model.mqh>
#include <mm.mqh>
//+----------------------------------------------------------------------+
//| This model uses bollinger bands. 
//| Buy when price is lower than lower band
//| Sell when price is higher than upper band
//+----------------------------------------------------------------------+  
struct cmodel_bollinger_param
  {
   string            symbol;
   ENUM_TIMEFRAMES   timeframe;
   int               period_bollinger;
   double            deviation;
   int               shift_bands;
   int               period_ATR;
   double            k_ATR;
   double            delta;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cmodel_bollinger : public CModel
  {
private:
   int               m_bollinger_period;
   double            m_deviation;
   int               m_bands_shift;
   int               m_ATR_period;
   double            m_k_ATR;
   //------------Indicators Data:-------------
   int               m_bollinger_handle;
   int               m_ATR_handle;
   double            m_bollinger_buff_main[];
   double            m_ATR_buff_main[];
   //-----------------------------------------
   MqlRates          m_raters[];
   double            m_current_price;
public:
                     cmodel_bollinger();
   bool              Init();
   bool              Init(cmodel_bollinger_param &m_param);
   bool              Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES TimeFrame,double delta,
                          uint bollinger_period,double deviation,int bands_shift,uint ATR_period,double k_ATR);
   bool              Processing();
protected:
   bool              InitIndicators();
   bool              CheckParam(cmodel_bollinger_param &m_param);
   bool              LongOpened();
   bool              ShortOpened();
   bool              LongClosed();
   bool              ShortClosed();
   bool              CloseByStopSignal();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
cmodel_bollinger::cmodel_bollinger()
  {
   m_bollinger_handle   = INVALID_HANDLE;
   m_ATR_handle         = INVALID_HANDLE;
   ArraySetAsSeries(m_bollinger_buff_main,true);
   ArraySetAsSeries(m_ATR_buff_main,true);
   ArraySetAsSeries(m_raters,true);
   m_current_price=0.0;
  }
//this default loader
bool cmodel_bollinger::Init()
  {
   m_magic              = 322311;
   m_model_name         =  "Bollinger Bands Model";
   m_symbol             = _Symbol;
   m_timeframe          = _Period;
   m_bollinger_period   = 20;
   m_deviation          = 2.0;
   m_bands_shift        = 0;
   m_ATR_period         = 20;
   m_k_ATR              = 2.0;
   m_delta              = 0;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::Init(cmodel_bollinger_param &m_param)
  {
   m_magic              = 322311;
   m_model_name         = "Bollinger Model";
   m_symbol             = m_param.symbol;
   m_timeframe          = (ENUM_TIMEFRAMES)m_param.timeframe;
   m_bollinger_period   = m_param.period_bollinger;
   m_deviation          = m_param.deviation;
   m_bands_shift        = m_param.shift_bands;
   m_ATR_period=m_param.period_ATR;
   m_k_ATR              = m_param.k_ATR;
   m_delta              = m_param.delta;
//if(!CheckParam(m_param))return(false);
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::Init(ulong magic,string name,string symbol,ENUM_TIMEFRAMES timeframe,double delta,
                            uint bollinger_period,double deviation,int bands_shift,uint ATR_period,double k_ATR)
  {
   m_magic           = magic;
   m_model_name      = name;
   m_symbol          = symbol;
   m_timeframe       = timeframe;
   m_delta           = delta;
   m_bollinger_period= bollinger_period;
   m_deviation       = deviation;
   m_bands_shift     = bands_shift;
   m_ATR_period      = ATR_period;
   m_k_ATR           = k_ATR;
   if(!InitIndicators())return(false);
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*bool cmodel_bollinger::CheckParam(cmodel_bollinger_param &m_param)
{
   if(!SymbolInfoInteger(m_symbol, SYMBOL_SELECT)){
      Print("Symbol ", m_symbol, " select failed. Check valid name symbol");
      return(false);
   }
   if(m_ma == 0){
      Print("Fast EMA must be bigest 0. Set MA = 12 (default)");
      m_ma=12;
   }
   return(true);
}*/

bool cmodel_bollinger::InitIndicators()
  {
   m_bollinger_handle=iBands(m_symbol,m_timeframe,m_bollinger_period,m_bands_shift,m_deviation,PRICE_CLOSE);
   if(m_bollinger_handle==INVALID_HANDLE)
     {
      Print("Error in creation of Bollinger indicator. Restart the Expert Advisor.");
      return(false);
     }
   m_ATR_handle=iATR(m_symbol,m_timeframe,m_ATR_period);
   if(m_ATR_handle==INVALID_HANDLE)
     {
      Print("Error in creation of ATR indicator. Restart the Expert Advisor.");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::Processing()
  {
//if(timing(m_symbol,m_timeframe, m_timing)==false)return(false);

//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
//if(m_account_info.TradeAllowed()==false)return(false);
//if(m_account_info.TradeExpert()==false)return(false);

 m_symbol_info.Name(m_symbol);
 m_symbol_info.RefreshRates();
//Copy last data of moving average

 /*  GetNumberOrders(m_orders);

   if(m_orders.buy_orders>0) LongClosed();
   else                        LongOpened();
   if(m_orders.sell_orders!=0) ShortClosed();
   else                        ShortOpened();
   if(m_orders.all_orders!=0)CloseByStopSignal();
   */
   LongOpened();
   ShortOpened();
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::LongOpened(void)
  {
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_SHORTONLY)return(false);
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);
//Print("Model Bollinger: ", m_orders.buy_orders);
   bool rezult,time_buy=true;
   double lot=0.01;
   double sl=m_symbol_info.Bid()-30*_Point;
   double tp=m_symbol_info.Ask()+100*_Point;
   mm open_mm;
   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
//lot=open_mm.optimal_f(m_symbol,OP_BUY,m_symbol_info.Ask(),sl,delta);
   CopyBuffer(m_bollinger_handle,2,0,3,m_bollinger_buff_main);
   CopyBuffer(m_ATR_handle,0,0,3,m_ATR_buff_main);
   CopyRates(m_symbol,m_timeframe,0,3,m_raters);
   if(m_raters[1].close>m_bollinger_buff_main[1] && m_raters[1].open<m_bollinger_buff_main[1])
     {
      sl=NormalizeDouble(m_symbol_info.Ask()-m_ATR_buff_main[0]*m_k_ATR,_Digits);
      lot=open_mm.optimal_f(m_symbol,ORDER_TYPE_BUY,m_symbol_info.Ask(),sl,m_delta);
      SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_ADD,0,lot,m_symbol_info.Ask(),sl,tp,"BollBand buy");
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::ShortOpened(void)
  {
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_LONGONLY)return(false);
//if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_CLOSEONLY)return(false);

   bool rezult,time_sell=true;
   double lot=0.01;
   double sl=m_symbol_info.Bid()+30*_Point;
   double tp=m_symbol_info.Ask()-100*_Point;
   mm open_mm;

   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(m_bollinger_handle,1,0,3,m_bollinger_buff_main);
   CopyBuffer(m_ATR_handle,0,0,3,m_ATR_buff_main);
   CopyRates(m_symbol,m_timeframe,0,3,m_raters);
   if(m_raters[1].close<m_bollinger_buff_main[1] && m_raters[1].open>m_bollinger_buff_main[1])
     {
      sl=NormalizeDouble(m_symbol_info.Bid()+m_ATR_buff_main[0]*m_k_ATR,_Digits);
      lot=open_mm.optimal_f(m_symbol,ORDER_TYPE_SELL,m_symbol_info.Ask(),sl,m_delta);
      SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_ADD,0,lot,m_symbol_info.Ask(),sl,tp,"BollBand Sell");
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*bool cmodel_bollinger::LongClosed(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   int rez=false;
   total_elements=ListTableOrders.Total();
   if(total_elements==0)return(false);
   m_symbol_info.Name(m_symbol);
   m_symbol_info.RefreshRates();
   CopyBuffer(m_bollinger_handle,1,0,3,m_bollinger_buff_main);
   CopyBuffer(m_ATR_handle,0,0,3,m_ATR_buff_main);
   CopyRates(m_symbol,m_timeframe,0,3,m_raters);
   if(m_raters[1].close<m_bollinger_buff_main[1] && m_raters[1].open>m_bollinger_buff_main[1])
     {
      for(int i=total_elements-1;i>=0;i--)
        {
         if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
         t=ListTableOrders.GetNodeAtIndex(i);
         if(CheckPointer(t)==POINTER_INVALID)continue;
         if(t.Type()!=ORDER_TYPE_BUY)continue;
         m_symbol_info.Refresh();
         m_symbol_info.RefreshRates();
         rez=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Bid(),0.0,0.0,"BUY: closed by signal");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::ShortClosed(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   int rez=false;
   total_elements=ListTableOrders.Total();
   if(total_elements==0)return(false);
   CopyBuffer(m_bollinger_handle,2,0,3,m_bollinger_buff_main);
   CopyBuffer(m_ATR_handle,0,0,3,m_ATR_buff_main);
   CopyRates(m_symbol,m_timeframe,0,3,m_raters);
   if(m_raters[1].close>m_bollinger_buff_main[1] && m_raters[1].open<m_bollinger_buff_main[1])
     {
      for(int i=total_elements-1;i>=0;i--)
        {
         if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
         t=ListTableOrders.GetNodeAtIndex(i);
         if(CheckPointer(t)==POINTER_INVALID)continue;
         if(t.Type()!=ORDER_TYPE_SELL)continue;
         m_symbol_info.Refresh();
         m_symbol_info.RefreshRates();
         rez=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Ask(),0.0,0.0,"SELL: closed by signal");
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cmodel_bollinger::CloseByStopSignal(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   bool rez=false;
   total_elements=ListTableOrders.Total();
   if(total_elements==0)return(false);
   for(int i=total_elements-1;i>=0;i--)
     {
      if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
      t=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(t)==POINTER_INVALID)continue;
      if(t.Type()!=ORDER_TYPE_SELL && t.Type()!=ORDER_TYPE_BUY)continue;
      m_symbol_info.Refresh();
      m_symbol_info.RefreshRates();
      CopyRates(m_symbol,m_timeframe,0,3,m_raters);
      if(m_symbol_info.Bid()<=t.StopLoss() && t.Type()==ORDER_TYPE_BUY)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_SELL,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Bid(),0.0,0.0,"BUY: closed by stop");
         continue;
        }
      if(m_symbol_info.Ask()>=t.StopLoss() && t.Type()==ORDER_TYPE_SELL)
        {
         rez=SendOrder(m_symbol,ORDER_TYPE_BUY,ORDER_DELETE,t.Ticket(),t.VolumeInitial(),m_symbol_info.Ask(),0.0,0.0,"SELL: closed by stop");
         continue;
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
*/