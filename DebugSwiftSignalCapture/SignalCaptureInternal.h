//
//  SignalCaptureInternal.h
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

#ifndef DEBUG_SWIFT_SIGNAL_CAPTURE_INTERNAL_H
#define DEBUG_SWIFT_SIGNAL_CAPTURE_INTERNAL_H

#include "DebugSwiftSignalCapture.h"

void DSPrepareSignalImages(void);
void DSSignalImageForAddress(uint64_t address, DSSignalImage *image);

#endif
