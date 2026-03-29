//+------------------------------------------------------------------+
//|                                              Four MA on OBV.mq5  |
//|                              Copyright © 2026, Danton Junior     |
//|                               https://www.xtraders.com.br        |
//+------------------------------------------------------------------+
#property copyright   "Copyright © 2026, Danton Junior"
#property link        "https://www.xtraders.com.br"
#property version     "1.2"
#property description "Four MA on OBV is a professional OBV smoothing indicator for MetaTrader 5."
#property description "Plots four customizable Moving Average lines over On Balance Volume."
#property description "Designed to reveal momentum, signal shifts and trend structure."
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4

//--- plot 1
#property indicator_label1  "Fast Line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot 2
#property indicator_label2  "Signal Line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkViolet
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot 3
#property indicator_label3  "Trend Line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLawnGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

//--- plot 4
#property indicator_label4  "Baseline"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrTomato
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

//--- input parameters
input group               "Fast Line"
input bool                 Inp_MA_1_enable         = true;        // Display the Fast Line
input int                  Inp_MA_1_ma_period      = 3;           // Period used to smooth short-term OBV movement
input int                  Inp_MA_1_ma_shift       = 0;           // Visual shift applied to the Fast Line
input ENUM_MA_METHOD       Inp_MA_1_ma_method      = MODE_SMA;    // Smoothing method used by the Fast Line

input group               "Signal Line"
input bool                 Inp_MA_2_enable         = true;        // Display the Signal Line
input int                  Inp_MA_2_ma_period      = 6;           // Period used to refine trade timing signals
input int                  Inp_MA_2_ma_shift       = 0;           // Visual shift applied to the Signal Line
input ENUM_MA_METHOD       Inp_MA_2_ma_method      = MODE_SMA;    // Smoothing method used by the Signal Line

input group               "Trend Line"
input bool                 Inp_MA_3_enable         = true;        // Display the Trend Line
input int                  Inp_MA_3_ma_period      = 12;          // Period used to reveal the underlying OBV trend
input int                  Inp_MA_3_ma_shift       = 0;           // Visual shift applied to the Trend Line
input ENUM_MA_METHOD       Inp_MA_3_ma_method      = MODE_SMA;    // Smoothing method used by the Trend Line

input group               "Baseline"
input bool                 Inp_MA_4_enable         = true;        // Display the Baseline
input int                  Inp_MA_4_ma_period      = 24;          // Period used to define broader OBV structure
input int                  Inp_MA_4_ma_shift       = 0;           // Visual shift applied to the Baseline
input ENUM_MA_METHOD       Inp_MA_4_ma_method      = MODE_SMA;    // Smoothing method used by the Baseline

input group               "OBV Source"
input ENUM_APPLIED_VOLUME  Inp_OBV_applied_volume  = VOLUME_TICK; // Volume source used in the OBV calculation

//--- indicator buffers
double Fast_Line_Buffer[];
double Signal_Line_Buffer[];
double Trend_Line_Buffer[];
double Baseline_Buffer[];

//--- indicator handles
int handle_iOBV        = INVALID_HANDLE;
int handle_Fast_Line   = INVALID_HANDLE;
int handle_Signal_Line = INVALID_HANDLE;
int handle_Trend_Line  = INVALID_HANDLE;
int handle_Baseline    = INVALID_HANDLE;

//--- calculated bars cache
int bars_calculated = 0;

//+------------------------------------------------------------------+
//| Validate inputs                                                  |
//+------------------------------------------------------------------+
bool ValidateInputs()
  {
   if(Inp_MA_1_enable && Inp_MA_1_ma_period <= 0)
     {
      Print("Error: Fast Line period must be greater than zero.");
      return(false);
     }

   if(Inp_MA_2_enable && Inp_MA_2_ma_period <= 0)
     {
      Print("Error: Signal Line period must be greater than zero.");
      return(false);
     }

   if(Inp_MA_3_enable && Inp_MA_3_ma_period <= 0)
     {
      Print("Error: Trend Line period must be greater than zero.");
      return(false);
     }

   if(Inp_MA_4_enable && Inp_MA_4_ma_period <= 0)
     {
      Print("Error: Baseline period must be greater than zero.");
      return(false);
     }

   if(!Inp_MA_1_enable && !Inp_MA_2_enable && !Inp_MA_3_enable && !Inp_MA_4_enable)
     {
      Print("Error: At least one line must be enabled.");
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Release handles                                                  |
//+------------------------------------------------------------------+
void ReleaseHandles()
  {
   if(handle_Baseline != INVALID_HANDLE)
     {
      IndicatorRelease(handle_Baseline);
      handle_Baseline = INVALID_HANDLE;
     }

   if(handle_Trend_Line != INVALID_HANDLE)
     {
      IndicatorRelease(handle_Trend_Line);
      handle_Trend_Line = INVALID_HANDLE;
     }

   if(handle_Signal_Line != INVALID_HANDLE)
     {
      IndicatorRelease(handle_Signal_Line);
      handle_Signal_Line = INVALID_HANDLE;
     }

   if(handle_Fast_Line != INVALID_HANDLE)
     {
      IndicatorRelease(handle_Fast_Line);
      handle_Fast_Line = INVALID_HANDLE;
     }

   if(handle_iOBV != INVALID_HANDLE)
     {
      IndicatorRelease(handle_iOBV);
      handle_iOBV = INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| Create indicator handles                                         |
//+------------------------------------------------------------------+
bool CreateHandles()
  {
   handle_iOBV = iOBV(_Symbol, PERIOD_CURRENT, Inp_OBV_applied_volume);
   if(handle_iOBV == INVALID_HANDLE)
     {
      PrintFormat("Failed to create iOBV handle for %s/%s. Error %d",
                  _Symbol, EnumToString((ENUM_TIMEFRAMES)_Period), GetLastError());
      return(false);
     }

   if(Inp_MA_1_enable)
     {
      handle_Fast_Line = iMA(_Symbol, PERIOD_CURRENT,
                             Inp_MA_1_ma_period,
                             0,
                             Inp_MA_1_ma_method,
                             handle_iOBV);
      if(handle_Fast_Line == INVALID_HANDLE)
        {
         PrintFormat("Failed to create Fast Line handle. Error %d", GetLastError());
         return(false);
        }
     }

   if(Inp_MA_2_enable)
     {
      handle_Signal_Line = iMA(_Symbol, PERIOD_CURRENT,
                               Inp_MA_2_ma_period,
                               0,
                               Inp_MA_2_ma_method,
                               handle_iOBV);
      if(handle_Signal_Line == INVALID_HANDLE)
        {
         PrintFormat("Failed to create Signal Line handle. Error %d", GetLastError());
         return(false);
        }
     }

   if(Inp_MA_3_enable)
     {
      handle_Trend_Line = iMA(_Symbol, PERIOD_CURRENT,
                              Inp_MA_3_ma_period,
                              0,
                              Inp_MA_3_ma_method,
                              handle_iOBV);
      if(handle_Trend_Line == INVALID_HANDLE)
        {
         PrintFormat("Failed to create Trend Line handle. Error %d", GetLastError());
         return(false);
        }
     }

   if(Inp_MA_4_enable)
     {
      handle_Baseline = iMA(_Symbol, PERIOD_CURRENT,
                            Inp_MA_4_ma_period,
                            0,
                            Inp_MA_4_ma_method,
                            handle_iOBV);
      if(handle_Baseline == INVALID_HANDLE)
        {
         PrintFormat("Failed to create Baseline handle. Error %d", GetLastError());
         return(false);
        }
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Get minimum bars required                                        |
//+------------------------------------------------------------------+
int GetMinBarsRequired()
  {
   int max_period = 0;

   if(Inp_MA_1_enable)
      max_period = MathMax(max_period, Inp_MA_1_ma_period);
   if(Inp_MA_2_enable)
      max_period = MathMax(max_period, Inp_MA_2_ma_period);
   if(Inp_MA_3_enable)
      max_period = MathMax(max_period, Inp_MA_3_ma_period);
   if(Inp_MA_4_enable)
      max_period = MathMax(max_period, Inp_MA_4_ma_period);

   return(max_period + 2);
  }

//+------------------------------------------------------------------+
//| Copy data from indicator buffer                                  |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &target_buffer[],
                         int handle,
                         int amount)
  {
   ResetLastError();

   if(CopyBuffer(handle, 0, 0, amount, target_buffer) < 0)
     {
      PrintFormat("Failed to copy data from indicator handle %d. Error %d",
                  handle, GetLastError());
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Configure plot                                                   |
//+------------------------------------------------------------------+
void ConfigurePlot(const int plot_index,
                   const bool is_enabled,
                   const int ma_period,
                   const int ma_shift,
                   const string label_text)
  {
   PlotIndexSetString(plot_index, PLOT_LABEL, label_text);
   PlotIndexSetInteger(plot_index, PLOT_SHIFT, ma_shift);
   PlotIndexSetDouble(plot_index, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   if(is_enabled)
     {
      PlotIndexSetInteger(plot_index, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetInteger(plot_index, PLOT_DRAW_BEGIN, ma_period - 1);
     }
   else
     {
      PlotIndexSetInteger(plot_index, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(plot_index, PLOT_DRAW_BEGIN, 0);
     }
  }

//+------------------------------------------------------------------+
//| Initialize buffer values                                         |
//+------------------------------------------------------------------+
void InitializeBuffers()
  {
   ArrayInitialize(Fast_Line_Buffer,   EMPTY_VALUE);
   ArrayInitialize(Signal_Line_Buffer, EMPTY_VALUE);
   ArrayInitialize(Trend_Line_Buffer,  EMPTY_VALUE);
   ArrayInitialize(Baseline_Buffer,    EMPTY_VALUE);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ValidateInputs())
      return(INIT_FAILED);

   SetIndexBuffer(0, Fast_Line_Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, Signal_Line_Buffer, INDICATOR_DATA);
   SetIndexBuffer(2, Trend_Line_Buffer, INDICATOR_DATA);
   SetIndexBuffer(3, Baseline_Buffer, INDICATOR_DATA);

   ArraySetAsSeries(Fast_Line_Buffer, true);
   ArraySetAsSeries(Signal_Line_Buffer, true);
   ArraySetAsSeries(Trend_Line_Buffer, true);
   ArraySetAsSeries(Baseline_Buffer, true);

   InitializeBuffers();

   ConfigurePlot(0, Inp_MA_1_enable, Inp_MA_1_ma_period, Inp_MA_1_ma_shift,
                 "Fast Line (" + IntegerToString(Inp_MA_1_ma_period) + ")");
   ConfigurePlot(1, Inp_MA_2_enable, Inp_MA_2_ma_period, Inp_MA_2_ma_shift,
                 "Signal Line (" + IntegerToString(Inp_MA_2_ma_period) + ")");
   ConfigurePlot(2, Inp_MA_3_enable, Inp_MA_3_ma_period, Inp_MA_3_ma_shift,
                 "Trend Line (" + IntegerToString(Inp_MA_3_ma_period) + ")");
   ConfigurePlot(3, Inp_MA_4_enable, Inp_MA_4_ma_period, Inp_MA_4_ma_shift,
                 "Baseline (" + IntegerToString(Inp_MA_4_ma_period) + ")");

   if(!CreateHandles())
     {
      ReleaseHandles();
      return(INIT_FAILED);
     }

   IndicatorSetString(INDICATOR_SHORTNAME, "Four MA on OBV");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int min_bars_required = GetMinBarsRequired();
   if(rates_total < min_bars_required)
      return(0);

   int calculated = rates_total;

   if(Inp_MA_1_enable)
     {
      int calc1 = BarsCalculated(handle_Fast_Line);
      if(calc1 <= 0)
        {
         PrintFormat("BarsCalculated(handle_Fast_Line) returned %d. Error %d",
                     calc1, GetLastError());
         return(0);
        }
      calculated = MathMin(calculated, calc1);
     }

   if(Inp_MA_2_enable)
     {
      int calc2 = BarsCalculated(handle_Signal_Line);
      if(calc2 <= 0)
        {
         PrintFormat("BarsCalculated(handle_Signal_Line) returned %d. Error %d",
                     calc2, GetLastError());
         return(0);
        }
      calculated = MathMin(calculated, calc2);
     }

   if(Inp_MA_3_enable)
     {
      int calc3 = BarsCalculated(handle_Trend_Line);
      if(calc3 <= 0)
        {
         PrintFormat("BarsCalculated(handle_Trend_Line) returned %d. Error %d",
                     calc3, GetLastError());
         return(0);
        }
      calculated = MathMin(calculated, calc3);
     }

   if(Inp_MA_4_enable)
     {
      int calc4 = BarsCalculated(handle_Baseline);
      if(calc4 <= 0)
        {
         PrintFormat("BarsCalculated(handle_Baseline) returned %d. Error %d",
                     calc4, GetLastError());
         return(0);
        }
      calculated = MathMin(calculated, calc4);
     }

   int values_to_copy;

   if(prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated + 1)
      values_to_copy = MathMin(calculated, rates_total);
   else
      values_to_copy = (rates_total - prev_calculated) + 1;

   if(values_to_copy <= 0)
      return(prev_calculated);

   if(Inp_MA_1_enable)
     {
      if(!FillArrayFromBuffer(Fast_Line_Buffer, handle_Fast_Line, values_to_copy))
         return(0);
     }

   if(!Inp_MA_1_enable)
      ArrayInitialize(Fast_Line_Buffer, EMPTY_VALUE);

   if(Inp_MA_2_enable)
     {
      if(!FillArrayFromBuffer(Signal_Line_Buffer, handle_Signal_Line, values_to_copy))
         return(0);
     }

   if(!Inp_MA_2_enable)
      ArrayInitialize(Signal_Line_Buffer, EMPTY_VALUE);

   if(Inp_MA_3_enable)
     {
      if(!FillArrayFromBuffer(Trend_Line_Buffer, handle_Trend_Line, values_to_copy))
         return(0);
     }

   if(!Inp_MA_3_enable)
      ArrayInitialize(Trend_Line_Buffer, EMPTY_VALUE);

   if(Inp_MA_4_enable)
     {
      if(!FillArrayFromBuffer(Baseline_Buffer, handle_Baseline, values_to_copy))
         return(0);
     }

   if(!Inp_MA_4_enable)
      ArrayInitialize(Baseline_Buffer, EMPTY_VALUE);

   bars_calculated = calculated;
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ReleaseHandles();
  }
//+------------------------------------------------------------------+
