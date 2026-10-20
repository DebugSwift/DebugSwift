//
//  ExceptionCapture.m
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

#import "DebugSwiftExceptionCapture.h"
#import <Foundation/NSException.h>
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <unistd.h>

_Static_assert(ATOMIC_BOOL_LOCK_FREE == 2, "Exception publication must be lock-free");

static pthread_mutex_t ds_exceptionInstallLock = PTHREAD_MUTEX_INITIALIZER;
static atomic_bool ds_exceptionPublished = ATOMIC_VAR_INIT(false);
static atomic_flag ds_exceptionHandling = ATOMIC_FLAG_INIT;
static DSExceptionReceiver ds_exceptionReceiver;
static NSUncaughtExceptionHandler *ds_previousExceptionHandler;

static _Noreturn void ds_terminateException(void) {
    kill(getpid(), SIGKILL);
    _exit(128 + SIGKILL);
}

static void ds_handleException(NSException *exception) {
    if (!atomic_load_explicit(&ds_exceptionPublished, memory_order_acquire) ||
        atomic_flag_test_and_set_explicit(&ds_exceptionHandling, memory_order_relaxed)) {
        ds_terminateException();
    }
    NSSetUncaughtExceptionHandler(NULL);
    // Foundation and application callbacks remain best-effort. An Objective-C
    // exception here must not prevent forwarding the ORIGINAL exception and exit.
    @try {
        ds_exceptionReceiver((__bridge void *)exception);
    } @catch (NSException *ignored) {
        (void)ignored;
    }
    @try {
        if (ds_previousExceptionHandler != NULL) {
            ds_previousExceptionHandler(exception);
        }
    } @catch (NSException *ignored) {
        (void)ignored;
    }
    ds_terminateException();
}

int DSExceptionCaptureInstall(DSExceptionReceiver receiver) {
    if (receiver == NULL) {
        return EINVAL;
    }
    int result = pthread_mutex_lock(&ds_exceptionInstallLock);
    if (result != 0) {
        return result;
    }
    if (!atomic_load_explicit(&ds_exceptionPublished, memory_order_acquire)) {
        ds_exceptionReceiver = receiver;
        ds_previousExceptionHandler = NSGetUncaughtExceptionHandler();
        // Release publishes both pointers before any thread can enter our handler.
        atomic_store_explicit(&ds_exceptionPublished, true, memory_order_release);
        NSSetUncaughtExceptionHandler(ds_handleException);
    }
    pthread_mutex_unlock(&ds_exceptionInstallLock);
    return 0;
}
