//+------------------------------------------------------------------+
//|                                                      torders.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Arrays\List.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTableOrders : public CObject
  {
private:
   string            m_symbol;         // order symbol
   ulong             m_magic;          // magic number of the EA
   ulong             m_ticket;         // base order ticket
   ulong             m_ticket_sl;      // stop loss price of base order
   ulong             m_ticket_tp;      // take profit price of base order
   ENUM_ORDER_TYPE   m_type;           // order type
   datetime          m_time_setup;     // order setup time
   double            m_price;          // order price
   double            m_sl;             // stop loss price
   double            m_tp;             // take profit price
   double            m_volume_initial; // order volume
public:
                     CTableOrders();
   bool              Add(COrderInfo &order_info,double stop_loss,double take_profit);
   bool              Add(CHistoryOrderInfo &history_order_info,double stop_loss,double take_profit);
   bool              Add(ulong Ticket,double stop_loss,double take_profit);
   double            StopLoss(void){return(m_sl);}
   void              StopLoss(double new_sl){m_sl=new_sl;}
   double            TakeProfit(void){return(m_tp);}
   void              TakeProfit(double new_tp){m_tp=new_tp;}
   ulong             Magic(){return(m_magic);}
   ulong             Ticket(){return(m_ticket);}
   ulong             TicketSL(){return(m_ticket_sl);}
   ulong             TicketTP(){return(m_ticket_tp);}
   void              Ticket(ulong ticket){m_ticket=ticket;}
   void              TicketSL(ulong ticket){m_ticket_sl=ticket;}
   void              TicketTP(ulong ticket){m_ticket_tp=ticket;}
   int               Type(void){return((ENUM_ORDER_TYPE)m_type);}
   void              Type(int type){m_type=type;}
   datetime          TimeSetup(void){return(m_time_setup);}
   double            Price(){return(m_price);}
   double            VolumeInitial(){return(m_volume_initial);}
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTableOrders::CTableOrders(void)
  {
   m_magic=0;
   m_ticket=0;
   m_type=0;
   m_time_setup=0;
   m_price=0.0;
   m_volume_initial=0.0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTableOrders::Add(CHistoryOrderInfo &history_order_info,double stop_loss,double take_profit)
  {
   HistoryOrderSelect(history_order_info.Ticket());
   m_magic=history_order_info.Magic();
   m_ticket=history_order_info.Ticket();
   m_type=history_order_info.OrderType();
   m_time_setup=history_order_info.TimeSetup();
   m_volume_initial=history_order_info.VolumeInitial();
   m_price=history_order_info.PriceOpen();
   m_sl=stop_loss;
   m_tp=take_profit;
   m_symbol=history_order_info.Symbol();
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTableOrders::Add(ulong Ticket,double stop_loss,double take_profit)
  {
   CHistoryOrderInfo history_order_info;
   COrderInfo        order_info;
   if(HistoryOrderSelect(Ticket))
     {
      history_order_info.Ticket(Ticket);
      m_magic=history_order_info.Magic();
      m_ticket=history_order_info.Ticket();
      m_type=history_order_info.Type();
      m_time_setup=history_order_info.TimeSetup();
      m_volume_initial=history_order_info.VolumeInitial();
      m_price=history_order_info.PriceOpen();
      m_sl=stop_loss;
      m_tp=take_profit;
      m_symbol=history_order_info.Symbol();
      return(true);
     }
   if(OrderSelect(Ticket))
     {
      m_magic=order_info.Magic();
      m_ticket=order_info.Ticket();
      m_type=order_info.Type();
      m_time_setup=order_info.TimeSetup();
      m_volume_initial=order_info.VolumeInitial();
      m_price=order_info.PriceOpen();
      m_sl=stop_loss;
      m_tp=take_profit;
      m_symbol=order_info.Symbol();
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTableOrders::Add(COrderInfo &order_info,double stop_loss,double take_profit)
  {
   OrderSelect(order_info.Ticket());
   m_magic=order_info.Magic();
   m_ticket=order_info.Ticket();
   m_type=order_info.OrderType();
   m_time_setup=order_info.TimeSetup();
   m_volume_initial=order_info.VolumeInitial();
   m_price=order_info.PriceOpen();
   m_sl=stop_loss;
   m_tp=take_profit;
   m_symbol=order_info.Symbol();
   return(true);
  }
//+------------------------------------------------------------------+
