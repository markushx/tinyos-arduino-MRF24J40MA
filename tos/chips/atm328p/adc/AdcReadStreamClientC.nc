#include "Atm328pAdc.h"
generic configuration AdcReadStreamClientC()
{
  provides interface ReadStream<uint16_t>;

  uses interface AdcConfigure<const Atm328pAdcConfig_t *>;
}
implementation
{
  enum { ID = unique(UQ_ATM328P_ADC_CLIENT) };

  components AdcC, AdcInitP, RealMainP;
  AdcInitP.AdcControl -> AdcC;
  AdcInitP.PlatformInit <- RealMainP.PlatformInit;

  ReadStream = AdcC.ReadStream[ID];
  AdcConfigure = AdcC.AdcConfigure[ID];
}
