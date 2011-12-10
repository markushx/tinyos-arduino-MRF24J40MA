#include <avr/sleep.h>

module McuSleepC {
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
}
implementation {
  async command void McuSleep.sleep() {
    sei ();
    sleep_mode ();
    asm ("" : : : "memory");
    cli ();
  }

  async command void McuPowerState.update() {
  }
}