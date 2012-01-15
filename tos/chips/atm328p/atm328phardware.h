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
#ifndef _H_atm328phardware_h
#define _H_atm328phardware_h

#include <avr/io.h>
#include <avr/interrupt.h>

typedef uint8_t __nesc_atomic_t;

inline void __nesc_enable_interrupt() {
    sei ();
}

inline void __nesc_disable_interrupt() {
    cli ();
}


inline __nesc_atomic_t __nesc_atomic_start ()
{
    __nesc_atomic_t result = SREG;
    __nesc_disable_interrupt ();
    asm volatile ("" : : : "memory");
    return result;
}

inline void __nesc_atomic_end (__nesc_atomic_t old_SREG)
{
    SREG = old_SREG;
    asm volatile ("" : : : "memory");
}

#define AVR_ATOMIC_HANDLER(signame) \
    void signame () __attribute__((signal)) @atomic_hwevent() @C()

/* Hmm, the atm328p doesn't have support for interrupt priorities, so allowing
 * nested interrupts would open up the potential for very easy stack overflows.
 * For now, it seems best not to support the notion of nested interrupts.
 *
#define AVR_NONATOMIC_HANDLER(signame) \
    void signame () __attribute__((interrupt)) @hwevent() @C()
 */

#define SFR_BIT_SET(reg, bit) \
    asm ("sbi %0, %1" : : "I" (reg - __SFR_OFFSET), "I" (bit) )

#define SFR_BIT_CLR(reg, bit) \
    asm ("cbi %0, %1" : : "I" (reg - __SFR_OFFSET), "I" (bit) )

#define SFR_BIT_READ(reg, bit) \
    ((*((uint8_t *)(reg - __SFR_OFFSET)) & _BV(bit)) != 0)

#define UQ_TIMER_0_ALARM "atm328p.timer0.alarm"
#define UQ_TIMER_1_ALARM "atm328p.timer1.alarm"

#endif