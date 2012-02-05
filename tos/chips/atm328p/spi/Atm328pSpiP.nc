/*
 * Copyright (c) 2012 Johny Mattsson
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Atm328pSpiConfig.h"

module Atm328pSpiP
{
  provides
  {
    interface Init;
    interface SpiByte;
    interface SpiPacket;
    interface FastSpiByte;
    interface Resource[uint8_t id];
  }
  uses
  {
    interface Resource as Arbiter[uint8_t id];
    interface ArbiterInfo;
    interface AsyncStdControl as SpiControl;
    interface HplAtm328pSpi as HplSpi;
    interface HplAtm328pPower as HplPower;

    // Note: SS line(s) are up to the user to pull low before using the SPI
    interface GeneralIO as SS;
    interface GeneralIO as SCK;
    interface GeneralIO as MOSI;
    interface GeneralIO as MISO;
  }
}
implementation
{
  inline void wait_for_spi_byte ()
  {
    while (!call HplSpi.interruptPending ()) {}
  }

  void init_pins (bool is_master)
  {
    if (is_master)
    {
      call SS.makeOutput ();
      call SCK.makeOutput ();
      call MOSI.makeOutput ();
      call MISO.makeInput ();
    }
    else
    {
      call SS.makeInput ();
      call SCK.makeInput ();
      call MOSI.makeInput ();
      call MISO.makeOutput ();
    }
  }

  command error_t Init.init ()
  {
    error_t res;

    call HplPower.powerOnSpi ();
    res = call SpiControl.start ();
    if (res != SUCCESS)
      goto out;

    init_pins (ATM328P_SPI_IS_MASTER);
    call HplSpi.setMasterSlave (ATM328P_SPI_IS_MASTER);
    call HplSpi.setDataOrder (ATM328P_SPI_IS_LITTLE_ENDIAN);
    call HplSpi.setClockPolarity (ATM328P_SPI_CLOCK_POLARITY_IS_HIGH_IDLE);
    call HplSpi.setClockPhase (ATM328P_SPI_CLOCK_PHASE_IS_SAMPLE_ON_TRAILING);
    call HplSpi.setClockRate (ATM328P_SPI_CLOCK_RATE);
    call HplSpi.setDoubleSpeed (ATM328P_SPI_USE_DOUBLE_SPEED);

  out:
    // State is frozen while powered off, so safe to shut down here
    call HplPower.powerOffSpi ();
    return res;
  }


  error_t spi_start ()
  {
    error_t res;

    call HplPower.powerOnSpi ();
    res = call SpiControl.start ();
    if (res != SUCCESS)
      call HplPower.powerOffSpi ();

    return res;
  }

  error_t spi_stop ()
  {
    error_t res = call SpiControl.stop ();
    if (res == SUCCESS)
      call HplPower.powerOffSpi ();

    return res;
  }


  async command uint8_t SpiByte.write (uint8_t byte)
  {
    call HplSpi.disableInterrupt ();
    call HplSpi.write (byte);
    wait_for_spi_byte ();
    return call HplSpi.read (); // this clears the interrupt flag
  }


  async command error_t SpiPacket.send (uint8_t *txBuf, uint8_t *rxBuf, uint16_t len)
  {
    // FIXME: make this a chunked transfer, using the interrupt to kick off
    // the next chunk.
    // For now, we use the dead-simple approach, and signal the async done 
    // straight from in here.
    uint8_t *tx = txBuf, *rx = rxBuf;
    uint16_t i;
    for (i = 0; i < len; ++i)
    {
      uint8_t tmp;
      *(rxBuf ? rx++ : &tmp) = call SpiByte.write (txBuf ? *tx++ : 0);
    }
    signal SpiPacket.sendDone (txBuf, rxBuf, len, SUCCESS);
    return SUCCESS;
  }


  async command void FastSpiByte.splitWrite (uint8_t byte)
  {
    call HplSpi.disableInterrupt ();
    call HplSpi.write (byte);
  }

  async command uint8_t FastSpiByte.splitRead ()
  {
    wait_for_spi_byte ();
    return call HplSpi.read ();
  }

  async command uint8_t FastSpiByte.splitReadWrite (uint8_t byte)
  {
    uint8_t data;
    wait_for_spi_byte ();
    data = call HplSpi.read ();
    call HplSpi.write (byte);
    return data;
  }

  async command uint8_t FastSpiByte.write (uint8_t byte)
  {
    return call SpiByte.write (byte);
  }


  async command error_t Resource.immediateRequest[uint8_t id] ()
  {
    error_t res = call Arbiter.immediateRequest[id] ();
    if (res == SUCCESS)
      spi_start ();
    return res;
  }

  async command error_t Resource.request[uint8_t id] ()
  {
    return call Arbiter.request[id] ();
  }

  async command error_t Resource.release[uint8_t id] ()
  {
    atomic {
      error_t res = call Arbiter.release[id] ();
      if (res == SUCCESS)
        spi_stop ();
      return res;
    }
  }

  async command bool Resource.isOwner[uint8_t id] ()
  {
    return call Arbiter.isOwner[id] ();
  }

  event void Arbiter.granted[uint8_t id] ()
  {
    spi_start ();
    signal Resource.granted[id] ();
  }

  default event void Resource.granted[uint8_t id] () {}


  async event void HplSpi.transferComplete ()
  {
    // FIXME - use this for chunked transfer
  }
}
