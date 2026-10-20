//
//  SignalCaptureFixture.c
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

// Host-only fixture compiled by Scripts/test_signal_capture.sh.
#include <stdint.h>

void DSSignalFixtureCrash(void) {
    *(volatile int *)(uintptr_t)1 = 42;
}
