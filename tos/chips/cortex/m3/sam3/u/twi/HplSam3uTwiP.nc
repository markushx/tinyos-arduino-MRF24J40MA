/*
 * Copyright (c) 2009 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 * @author Kevin Klues
 */

configuration HplSam3uTwiP {
  provides interface HplSam3uTwi as HplSam3uTwi0;
  provides interface HplSam3uTwi as HplSam3uTwi1;
  provides interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt0;
  provides interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt1;
}

implementation {

  components HplSam3uTwiImplP as HplTwiP;
  HplSam3uTwi0 = HplTwiP.HplSam3uTwi0;
  HplSam3uTwi1 = HplTwiP.HplSam3uTwi1;
  HplSam3uTwiInterrupt0 = HplTwiP.Interrupt0;
  HplSam3uTwiInterrupt1 = HplTwiP.Interrupt1;

  // make and connect pins/clock/interrupt for this dude
  components HplNVICC, HplSam3uClockC, HplSam3uGeneralIOC, LedsC, NoLedsC;
  HplTwiP.Twi0Interrupt -> HplNVICC.TWI0Interrupt;
  HplTwiP.Twi1Interrupt -> HplNVICC.TWI1Interrupt;
  HplTwiP.Twi0ClockControl -> HplSam3uClockC.TWI0PPCntl;
  HplTwiP.Twi1ClockControl -> HplSam3uClockC.TWI1PPCntl;
  HplTwiP.Twd0Pin -> HplSam3uGeneralIOC.HplPioA9;
  HplTwiP.Twd1Pin -> HplSam3uGeneralIOC.HplPioA24;
  HplTwiP.Twck0Pin -> HplSam3uGeneralIOC.HplPioA10;
  HplTwiP.Twck1Pin -> HplSam3uGeneralIOC.HplPioA25;
  HplTwiP.Leds -> NoLedsC;  

  components McuSleepC;
  HplTwiP.Twi0InterruptWrapper -> McuSleepC;
  HplTwiP.Twi1InterruptWrapper -> McuSleepC;
}
