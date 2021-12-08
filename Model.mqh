//+------------------------------------------------------------------+
//|                                                   model_macd.mqh |
//|                            Copyright 2010, Vasily Sokolov (C-4). |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Vasily Sokolov (C-4)."
#property link      "http://www.mql5.com"

#include <Arrays\List.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <TableOrders.mqh>
#include <Time.mqh>
#include <mm.mqh>
#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_ORDER_MODE
  {
   ORDER_ADD,
   ORDER_DELETE
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_TYPE_DELETED_ORDER
  {
   DELETE_ALL_LONG,
   DELETE_ALL_SHORT,
   DELETE_ALL_BUY,
   DELETE_ALL_BUY_STOP,
   DELETE_ALL_BUY_LIMIT,
   DELETE_ALL_BUY_STOP_LIMIT,
   DELETE_ALL_SELL,
   DELETE_ALL_SELL_STOP,
   DELETE_ALL_SELL_LIMIT,
   DELETE_ALL_SELL_STOP_LIMIT
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct n_orders
  {
   int               all_orders;
   int               long_orders;
   int               short_orders;
   int               buy_sell_orders;
   int               delayed_orders;
   int               buy_orders;
   int               sell_orders;
   int               buy_stop_orders;
   int               sell_stop_orders;
   int               buy_limit_orders;
   int               sell_limit_orders;
   int               buy_stop_limit_orders;
   int               sell_stop_limit_orders;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CModel : public CObject
  {
protected:
   long              m_magic;
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   string            m_model_name;
   double            m_delta;
   CTableOrders     *table;
   CList            *ListTableOrders;
   CList            *DeletedTableOrders;
   CAccountInfo      m_account_info;
   CTrade            m_trade;
   CSymbolInfo       m_symbol_info;
   COrderInfo        m_order_info;
   CHistoryOrderInfo m_history_order_info;
   CPositionInfo     m_position_info;
   CDealInfo         m_deal_info;
   t_period          m_timing;
   n_orders          m_orders;
public:
                     CModel()  { Init();   }
                    ~CModel() { Deinit(); }
   string            Name(){return(m_model_name);}
   void              Name(string name){m_model_name=name;}
   ENUM_TIMEFRAMES   Period(void){return(m_timeframe);}
   string            Symbol(void){return(m_symbol);}
   void              Symbol(string set_symbol){m_symbol=set_symbol;}
   bool virtual      Init();
   void virtual      Deinit(){delete ListTableOrders;}
   bool virtual      Processing(){return(true);}
   double            GetMyPosition();
   //bool              Delete(ENUM_TYPE_DELETED_ORDER);
   bool              Delete(ulong Ticket);
   bool              Delete(ENUM_TYPE_DELETED_ORDER type);
   void              CloseAllOrders();
protected:
   bool              Add(ulong Tiket,double stop_loss,double take_profit);
   void              GetNumberOrders(n_orders &orders);
   bool              SendOrder(string symbol,ENUM_ORDER_TYPE op_type,ENUM_ORDER_MODE op_mode,ulong ticket,double lot,double price,double stop_loss,double take_profit,string comment);
   bool              ReplaceDelayedOrders(void);
   //double            CheckLot(string symbol, double lot, ENUM_ORDER_TYPE op_type);
   //double            CheckMargin(string symbol, ENUM_ORDER_TYPE op_type, double lot, double open_price);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::Init()
  {
   m_magic      = 0;
   m_symbol     = _Symbol;
   m_timeframe  = _Period;
   m_delta      = 0.0;
   m_model_name = "default model";
   ListTableOrders=new CList();
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::Delete(ENUM_TYPE_DELETED_ORDER type)
  {
   int orders_total;
   CTableOrders *t;
   bool rezult=false;
   orders_total=ListTableOrders.Total();
   for(int i=0;i<ListTableOrders.Total();i++)
     {
      t=ListTableOrders.GetNodeAtIndex(i);
      if(type==DELETE_ALL_BUY)
        {
         switch(t.Type())
           {
            case ORDER_TYPE_BUY:
            case ORDER_TYPE_BUY_STOP:
            case ORDER_TYPE_BUY_LIMIT:
            case ORDER_TYPE_BUY_STOP_LIMIT:
               rezult=ListTableOrders.DeleteCurrent();
               //zero pointer
               //Print("The Table of orders: orders ");
               continue;
           }
        }
      if(type==DELETE_ALL_SELL)
        {
         switch(t.Type())
           {
            case ORDER_TYPE_SELL:
            case ORDER_TYPE_SELL_STOP:
            case ORDER_TYPE_SELL_LIMIT:
            case ORDER_TYPE_SELL_STOP_LIMIT:
               rezult=ListTableOrders.DeleteCurrent();
               //Print("DELETE ALL SELL");
               //zero pointer
               continue;
           }
        }
     }
   return(rezult);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::Delete(ulong ticket)
  {
   CTableOrders *t;
   bool rezult=false;
   int orders_total=ListTableOrders.Total();
   if(orders_total<=0)return(false);
   for(int i=orders_total-1;i>=0;i--)
     {
      t=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(t)==POINTER_INVALID)continue;
      if(t.Ticket()==ticket)
        {
         rezult=ListTableOrders.DeleteCurrent();
         if(rezult==true)Print("Order with ticket ",ticket," has been removed successfully");
         else Print("Error deleting order");
        }
     }
   return(rezult);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CModel::GetNumberOrders(n_orders &orders)
  {
   int orders_total;
   CTableOrders *t;
   ENUM_ORDER_TYPE order_type;
   orders_total=ListTableOrders.Total();
   orders.all_orders=0;
   orders.buy_limit_orders=0;
   orders.buy_orders=0;
   orders.buy_sell_orders=0;
   orders.buy_sell_orders=0;
   orders.buy_stop_limit_orders=0;
   orders.buy_stop_orders=0;
   orders.delayed_orders=0;
   orders.long_orders=0;
   orders.sell_limit_orders=0;
   orders.sell_orders=0;
   orders.sell_stop_limit_orders=0;
   orders.sell_stop_orders=0;
   orders.short_orders=0;
   if(CheckPointer(ListTableOrders)==POINTER_INVALID)return;
   for(int i=0;i<orders_total;i++)
     {
      t=ListTableOrders.GetNodeAtIndex(i);
      if(!CheckPointer(t))continue;
      order_type=(ENUM_ORDER_TYPE)t.Type();
      switch(order_type)
        {
         case ORDER_TYPE_BUY:
            orders.all_orders++;
            orders.long_orders++;
            orders.buy_orders++;
            continue;
         case ORDER_TYPE_SELL:
            orders.all_orders++;
            orders.short_orders++;
            orders.sell_orders++;
            continue;
         case ORDER_TYPE_BUY_STOP:
            orders.all_orders++;
            orders.long_orders++;
            orders.delayed_orders++;
            orders.buy_stop_orders++;
            continue;
         case ORDER_TYPE_SELL_STOP:
            orders.all_orders++;
            orders.short_orders++;
            orders.delayed_orders++;
            orders.sell_stop_orders++;
            continue;
         case ORDER_TYPE_BUY_LIMIT:
            orders.all_orders++;
            orders.long_orders++;
            orders.delayed_orders++;
            orders.buy_limit_orders++;
            continue;
         case ORDER_TYPE_SELL_LIMIT:
            orders.all_orders++;
            orders.short_orders++;
            orders.delayed_orders++;
            orders.sell_limit_orders++;
            continue;
         case ORDER_TYPE_BUY_STOP_LIMIT:
            orders.all_orders++;
            orders.long_orders++;
            orders.delayed_orders++;
            orders.buy_stop_limit_orders++;
            continue;
         case ORDER_TYPE_SELL_STOP_LIMIT:
            orders.all_orders++;
            orders.short_orders++;
            orders.delayed_orders++;
            orders.sell_stop_limit_orders++;
            continue;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::Add(ulong Ticket,double stop_loss,double take_profit)
  {
   CTableOrders *t=new CTableOrders;
   if(!t.Add(Ticket,stop_loss,take_profit))
     {
      Print("The order addition has failed. Check order parameters.");
      return(false);
     }
   if(!ListTableOrders.Add(GetPointer(t)))
     {
      Print("Can't add order to the orders table. Error!");
      return(false);
     }
   Print("Order ",Ticket," has been added successfully");
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CModel::GetMyPosition()
  {
   int elements=0.0;
   double volume_position=0.0;
   double volume_current=0.0;
   CTableOrders *order_now;
   elements=ListTableOrders.Total();
   for(int i=0;i<elements;i++)
     {
      order_now=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(order_now)==POINTER_INVALID)continue;
      if(order_now.Type()==ORDER_TYPE_SELL)
         volume_position+=(order_now.VolumeInitial()*(-1));
      if(order_now.Type()==ORDER_TYPE_BUY)
         volume_position+=order_now.VolumeInitial();
     }
   return(volume_position);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::SendOrder(string symbol,ENUM_ORDER_TYPE op_type,ENUM_ORDER_MODE op_mode,ulong ticket,double lot,double price,double stop_loss,double take_profit,string comment)
  {
   ulong code_return=0;
   CSymbolInfo symbol_info;
   CTrade      trade;
   symbol_info.Name(symbol);
   symbol_info.RefreshRates();
   mm send_order_mm;
   double lot_send=lot;
   double lot_max=m_symbol_info.LotsMax();
//double lot_max=5.0;
   bool rez=false;
   int floor_lot=(int)MathFloor(lot/lot_max);

/*lot_check=CheckLot(symbol, lot, op_type);
   //All or nothing
   if(lot_check!=lot&&op_mode==ORDER_DELETE)return(false);
   if(lot_check==EMPTY_VALUE)return(false);
   lot_margin=CheckMargin(symbol, op_type, lot_check, price);
   //All or nothing
   if(lot_margin!=lot_check&&op_mode==ORDER_DELETE)return(false);
   if(lot_margin==EMPTY_VALUE)return(false);
   lot=lot_margin;
   lot_send=lot_margin;*/

   if(MathMod(lot,lot_max)==0)floor_lot=floor_lot-1;
   int itteration=(int)MathCeil(lot/lot_max);
   if(itteration>1)
      Print("The order volume exceeds the maximum allowed volume. It will be divided into ",itteration," parts");
   for(int i=1;i<=itteration;i++)
     {
      if(i==itteration)lot_send=lot-(floor_lot*lot_max);
      else lot_send=lot_max;
      for(int ii=0;ii<3;ii++)
        {
         //Print("Send Order: TRADE_RETCODE_DONE");
         symbol_info.RefreshRates();
         if(op_type==ORDER_TYPE_BUY)price=symbol_info.Ask();
         if(op_type==ORDER_TYPE_SELL)price=symbol_info.Bid();
         m_trade.SetDeviationInPoints(ulong(0.0003/(double)symbol_info.Point()));
         m_trade.SetExpertMagicNumber(m_magic);
         switch(op_type)
           {
            case ORDER_TYPE_BUY:
               rez=m_trade.PositionOpen(m_symbol,op_type,lot_send,price,0.0,0.0,comment);
            case ORDER_TYPE_SELL:
               rez=m_trade.PositionOpen(m_symbol,op_type,lot_send,price,0.0,0.0,comment);
               break;
            case ORDER_TYPE_BUY_LIMIT:
               rez=m_trade.BuyLimit(lot_send,price,m_symbol,0.0,0.0,0,0,comment);
               break;
            case ORDER_TYPE_BUY_STOP:
               rez=m_trade.BuyStop(lot_send,price,m_symbol,0.0,0.0,0,0,comment);
               break;
            case ORDER_TYPE_SELL_LIMIT:
               rez=m_trade.SellLimit(lot_send,price,m_symbol,0.0,0.0,0,0,comment);
               break;
            case ORDER_TYPE_SELL_STOP:
               rez=m_trade.SellStop(lot_send,price,m_symbol,0.0,0.0,0,0,comment);
               break;
           }
/*if(op_type == ORDER_TYPE_BUY||op_type == ORDER_TYPE_SELL)
            rez=m_trade.PositionOpen(m_symbol, op_type, lot_send, price, 0.0, 0.0, comment);
         if(op_type == ORDER_TYPE_BUY_STOP ||op_type == ORDER_TYPE_SELL_STOP||
            op_type == ORDER_TYPE_BUY_LIMIT||op_type == ORDER_TYPE_SELL_LIMIT){
            rez=m_trade.PositionOpen(m_symbol, op_type, lot_send, price, 0.0, 0.0, comment);
         }*/
         
         // Don't remove Sleep! It's needed to place order into m_history_order_info!!!
         Sleep(3000);
         if(m_trade.ResultRetcode()==TRADE_RETCODE_PLACED||
            m_trade.ResultRetcode()==TRADE_RETCODE_DONE_PARTIAL||
            m_trade.ResultRetcode()==TRADE_RETCODE_DONE)
           {
            //Print(m_trade.ResultComment());
            //rez=m_history_order_info.Ticket(m_trade.ResultOrder());
            if(op_mode==ORDER_ADD)
              {
               rez=Add(m_trade.ResultOrder(),stop_loss,take_profit);
              }
            if(op_mode==ORDER_DELETE)
              {
               rez=Delete(ticket);
              }
            code_return=m_trade.ResultRetcode();
            break;
           }
         else
           {
            Print(m_trade.ResultComment());
           }
         if(m_trade.ResultRetcode()==TRADE_RETCODE_TRADE_DISABLED||
            m_trade.ResultRetcode()==TRADE_RETCODE_MARKET_CLOSED||
            m_trade.ResultRetcode()==TRADE_RETCODE_NO_MONEY||
            m_trade.ResultRetcode()==TRADE_RETCODE_TOO_MANY_REQUESTS||
            m_trade.ResultRetcode()==TRADE_RETCODE_SERVER_DISABLES_AT||
            m_trade.ResultRetcode()==TRADE_RETCODE_CLIENT_DISABLES_AT||
            m_trade.ResultRetcode()==TRADE_RETCODE_LIMIT_ORDERS||
            m_trade.ResultRetcode()==TRADE_RETCODE_LIMIT_VOLUME)
           {
            break;
           }
        }
     }
   return(rez);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CModel::ReplaceDelayedOrders(void)
  {
   if(m_symbol_info.TradeMode()==SYMBOL_TRADE_MODE_DISABLED)return(false);
   CTableOrders *t;
   int total_elements;
   int history_orders=HistoryOrdersTotal();
   ulong ticket;
   bool rez=false;
   long request;
   total_elements=ListTableOrders.Total();
   int try=0;
   if(total_elements==0)return(false);
// Proceed each order in table
   for(int i=total_elements-1;i>=0;i--)
     {
      if(CheckPointer(ListTableOrders)==POINTER_INVALID)continue;
      t=ListTableOrders.GetNodeAtIndex(i);
      if(CheckPointer(t)==POINTER_INVALID)continue;
      switch(t.Type())
        {
         //case ORDER_TYPE
         case ORDER_TYPE_BUY:
         case ORDER_TYPE_SELL:
            for(int b=0;b<history_orders;b++)
              {
               ticket=HistoryOrderGetTicket(b);
               // if order ticket from history is equal to one of the "simulated-Stop-Loss" or "simulated-Take-Profit" tickets
               // it means that order should be deleted from the table of orders
               if(ticket==t.TicketSL() || ticket==t.TicketTP())
                 {
                  ListTableOrders.DeleteCurrent();
                 }
              }
            // if we haven't found the Stop Loss and Take Profit orders in the history,
            // it seems that we haven't placed them. Hence we need to place them
            // using the methods for pending orders, presented below
            // the loop will continue, there isn't a "break" statement
         case ORDER_TYPE_BUY_LIMIT:
         case ORDER_TYPE_BUY_STOP:
         case ORDER_TYPE_BUY_STOP_LIMIT:
         case ORDER_TYPE_SELL_LIMIT:
         case ORDER_TYPE_SELL_STOP:
         case ORDER_TYPE_SELL_STOP_LIMIT:
            for(int b=0;b<history_orders;b++)
              {
               ticket=HistoryOrderGetTicket(b);
               // if the historical order ticket is equal to the pending order ticket,
               // it means that pending order has been executed and we need to place
               // the pending "simulated-Stop-Loss" and "simulated-Take-Profit" orders
               // Also we need to change the status (ORDER_TYPE_BUY or ORDER_TYPE_SELL)
               //  of pending order in the orders table              
               m_order_info.InfoInteger(ORDER_STATE,request);
               if(t.Ticket()==ticket && 
                  (request==ORDER_STATE_PARTIAL || request==ORDER_STATE_FILLED))
                 {
                  // Change order status in the orders table:
                  m_order_info.InfoInteger(ORDER_TYPE,request);
                  if(t.Type()!=request)t.Type((int)request);
                  //------------------------------------------------------------------
                  // Let's place "simulated-Stop-Loss" and "simulated-Take-Profit" pending orders
                  // the price levels should be defined
                  // also we need to check the absence of "simulated-Stop-Loss" and "simulated-Take-Profit"
                  // related with current order:
                  if(t.StopLoss()!=0.0 && t.TicketSL()==0)
                    {
                     // Try to place pending order
                     switch(t.Type())
                       {
                        case ORDER_TYPE_BUY:
                           // Try it 3 times
                           for(try=0;try<3;try++)
                             {
                              m_trade.SellStop(t.VolumeInitial(),t.StopLoss(),m_symbol,0.0,0.0,0,0,"take-profit for buy");
                              if(m_trade.ResultRetcode()==TRADE_RETCODE_PLACED || m_trade.ResultRetcode()==TRADE_RETCODE_DONE)
                                {
                                 t.TicketTP(m_trade.ResultDeal());
                                 break;
                                }
                             }
                        case ORDER_TYPE_SELL:
                           // Try it 3 times
                           for(try=0;try<3;try++)
                             {
                              m_trade.BuyStop(t.VolumeInitial(),t.StopLoss(),m_symbol,0.0,0.0,0,0,"take-profit for buy");
                              if(m_trade.ResultRetcode()==TRADE_RETCODE_PLACED || m_trade.ResultRetcode()==TRADE_RETCODE_DONE)
                                {
                                 t.TicketTP(m_trade.ResultDeal());
                                 break;
                                }
                             }
                       }
                    }
                  if(t.TakeProfit()!=0.0 && t.TicketTP()==0)
                    {
                     // Trying to place "simulated-Take-Profit" pending order
                     switch(t.Type())
                       {
                        case ORDER_TYPE_BUY:
                           // Try it 3 times
                           for(try=0;try<3;try++)
                             {
                              m_trade.SellLimit(t.VolumeInitial(),t.StopLoss(),m_symbol,0.0,0.0,0,0,"take-profit for buy");
                              if(m_trade.ResultRetcode()==TRADE_RETCODE_PLACED || m_trade.ResultRetcode()==TRADE_RETCODE_DONE)
                                {
                                 t.TicketTP(m_trade.ResultDeal());
                                 break;
                                }
                             }
                           break;
                        case ORDER_TYPE_SELL:
                           // Try it 3 times
                           for(try=0;try<3;try++)
                             {
                              m_trade.BuyLimit(t.VolumeInitial(),t.StopLoss(),m_symbol,0.0,0.0,0,0,"take-profit for buy");
                              if(m_trade.ResultRetcode()==TRADE_RETCODE_PLACED || m_trade.ResultRetcode()==TRADE_RETCODE_DONE)
                                {
                                 t.TicketTP(m_trade.ResultDeal());
                                 break;
                                }
                             }
                       }
                    }
                 }
              }
            break;

        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
