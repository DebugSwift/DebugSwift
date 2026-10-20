//
//  DebugSwiftExceptionCapture.h
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

#ifndef DEBUG_SWIFT_EXCEPTION_CAPTURE_H
#define DEBUG_SWIFT_EXCEPTION_CAPTURE_H

// Borrowed NSException pointer, valid only for the duration of the receiver.
// Keep the public C module importable without Objective-C language extensions.
typedef void (*DSExceptionReceiver)(void *exception);

// Normal execution only. Publishes one immutable receiver/previous-handler snapshot.
// The terminal path never acquires the installation mutex. A receiver or previous
// handler that throws another Objective-C exception cannot reenter this reporter.
// Returns zero on success or an errno value; subsequent installs are no-ops.
int DSExceptionCaptureInstall(DSExceptionReceiver receiver);

#endif
