#include "Atm328pAdc.h"
module HplAtm328pAdcP
{
  provides interface HplAtm328pAdc as Adc;
  provides interface StdControl;
}
implementation
{
  enum {
    ADMUX_REFS_MASK  = 0x03 << REFS0,
    ADMUX_MUX_MASK   = 0x0f << MUX0,
    ADCSRB_ADTS_MASK = 0x07 << ADTS0,
    ADCSRA_ADPS_MASK = 0x07 << ADPS0,
  };

  /* Note: read-modify-write access to ADCSRA can clobber an interrupt.
   *   This applies even if doing the r-m-w via sbi/cbi, so can't easily
   *   avoid that danger other than via "don't mess with things while
   *   converting".
   */

  command error_t StdControl.start ()
  {
    // TODO: power management, also should auto-disable during sleep (p258).

    ADCSRA |= _BV(ADEN);

    return SUCCESS;
  }

  command error_t StdControl.stop ()
  {
    if (call Adc.isConverting ())
      return FAIL;

    ADCSRA &= ~_BV(ADEN);

    return SUCCESS;
  }


  async command void Adc.setReference (Atm328pAdcRef_t ref)
  {
    ADMUX = (ADMUX & ~ADMUX_REFS_MASK) | (ref << REFS0);
  }

  async command Atm328pAdcRef_t Adc.getReference ()
  {
    return ((ADMUX & ADMUX_REFS_MASK) >> REFS0);
  }


  async command void Adc.setChannel (Atm328pAdcChannel_t channel)
  {
    ADMUX = (ADMUX & ~ADMUX_MUX_MASK) | (channel << MUX0);
  }

  async command Atm328pAdcChannel_t Adc.getChannel ()
  {
    return ((ADMUX & ADMUX_MUX_MASK) >> MUX0);
  }


  async command void Adc.startConversion ()
  {
    ADCSRA |= _BV(ADSC);
  }

  async command bool Adc.isConverting ()
  {
    return ADCSRA & _BV(ADSC);
  }


  async command void Adc.enableAutoTrigger ()
  {
    ADCSRA |= _BV(ADATE);
  }

  async command void Adc.disableAutoTrigger ()
  {
    ADCSRA &= ~_BV(ADATE);
  }

  async command bool Adc.isAutoTriggered ()
  {
    return ADCSRA & _BV(ADATE);
  }

  async command void Adc.setAutoTriggerSource (Atm328pAdcTriggerSource_t source)
  {
    ADCSRB = (ADCSRB & ~ADCSRB_ADTS_MASK) | (source << ADTS0);
  }

  async command Atm328pAdcTriggerSource_t Adc.getAutoTriggerSource ()
  {
    return ((ADCSRB & ADCSRB_ADTS_MASK) >> ADTS0);
  }


  async command void Adc.enableInterrupt ()
  {
    ADCSRA |= _BV(ADIE);
  }

  async command void Adc.disableInterrupt ()
  {
    ADCSRA &= ~_BV(ADIE);
  }

  async command bool Adc.interruptEnabled ()
  {
    return ADCSRA & _BV(ADIE);
  }


  async command void Adc.setPrescaler (Atm328pAdcPrescale_t prescale)
  {
    ADCSRA = (ADCSRA & ~ADCSRA_ADPS_MASK) | (prescale << ADPS0);
  }

  async command Atm328pAdcPrescale_t Adc.getPrescaler ()
  {
    return ((ADCSRA & ADCSRA_ADPS_MASK) >> ADPS0);
  }


  async command void Adc.enableDigitalInput (Atm328pAdcChannel_t channel)
  {
    switch (channel)
    {
      case ATM328P_ADC_CHANNEL_0:
      case ATM328P_ADC_CHANNEL_1:
      case ATM328P_ADC_CHANNEL_2:
      case ATM328P_ADC_CHANNEL_3:
      case ATM328P_ADC_CHANNEL_4:
      case ATM328P_ADC_CHANNEL_5: DIDR0 &= ~_BV(channel); break;
      default: break;
    }
  }

  async command void Adc.disableDigitalInput (Atm328pAdcChannel_t channel)
  {
    switch (channel)
    {
      case ATM328P_ADC_CHANNEL_0:
      case ATM328P_ADC_CHANNEL_1:
      case ATM328P_ADC_CHANNEL_2:
      case ATM328P_ADC_CHANNEL_3:
      case ATM328P_ADC_CHANNEL_4:
      case ATM328P_ADC_CHANNEL_5: DIDR0 |= _BV(channel); break;
      default: break;
    }
  }

  async command bool Adc.digitalInputEnabled (Atm328pAdcChannel_t channel)
  {
    switch (channel)
    {
      case ATM328P_ADC_CHANNEL_0:
      case ATM328P_ADC_CHANNEL_1:
      case ATM328P_ADC_CHANNEL_2:
      case ATM328P_ADC_CHANNEL_3:
      case ATM328P_ADC_CHANNEL_4:
      case ATM328P_ADC_CHANNEL_5: return DIDR0 & _BV(channel);
      default: return FALSE;
    }
  }

  async command uint16_t Adc.get ()
  {
    return ADC;
  }

  AVR_ATOMIC_HANDLER(ADC_vect)
  {
    signal Adc.done ();
  }
}
