//
//  SignalCapture.c
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

#include "SignalCaptureInternal.h"
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/ucontext.h>
#include <time.h>
#include <unistd.h>

_Static_assert(ATOMIC_BOOL_LOCK_FREE == 2, "Signal reentry guard must always be lock-free");
_Static_assert(sizeof(DSSignalCrashRecord) == 2200, "Changing the disk layout requires a new record version");

static const int ds_signals[] = { SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGPIPE, SIGSEGV, SIGSYS, SIGTRAP };
#define DS_SIGNAL_COUNT (sizeof(ds_signals) / sizeof(ds_signals[0]))

static pthread_mutex_t ds_installLock = PTHREAD_MUTEX_INITIALIZER;
static bool ds_installed;
static atomic_bool ds_handling = ATOMIC_VAR_INIT(false);
static int ds_output = -1;
static struct sigaction ds_previous[DS_SIGNAL_COUNT];
static struct sigaction ds_default;
static DSSignalCrashRecord ds_record;

static _Noreturn void ds_terminate(int signalNumber) {
    // Also handles a previous SIG_IGN or a previous handler that returns.
    sigaction(signalNumber, &ds_default, NULL);
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, signalNumber);
    sigprocmask(SIG_UNBLOCK, &mask, NULL);
    raise(signalNumber);
    _exit(128 + signalNumber);
}

static void ds_captureRegisters(void *context) {
    if (context == NULL) {
        return;
    }
    ucontext_t *state = context;
    if (state->uc_mcontext == NULL) {
        return;
    }
    // Only copy registers from the supplied context. Do not unwind/dereference the damaged stack.
#if defined(__arm64__)
    ds_record.instructionAddress = __darwin_arm_thread_state64_get_pc(state->uc_mcontext->__ss);
    ds_record.stackPointer = __darwin_arm_thread_state64_get_sp(state->uc_mcontext->__ss);
    ds_record.framePointer = __darwin_arm_thread_state64_get_fp(state->uc_mcontext->__ss);
    ds_record.linkRegister = __darwin_arm_thread_state64_get_lr(state->uc_mcontext->__ss);
#elif defined(__x86_64__)
    ds_record.instructionAddress = state->uc_mcontext->__ss.__rip;
    ds_record.stackPointer = state->uc_mcontext->__ss.__rsp;
    ds_record.framePointer = state->uc_mcontext->__ss.__rbp;
#endif
    DSSignalImageForAddress(ds_record.instructionAddress, &ds_record.instructionImage);
    DSSignalImageForAddress(ds_record.linkRegister, &ds_record.linkImage);
}

static void ds_forwardSignal(int signalNumber, siginfo_t *info, void *context) {
    const struct sigaction *previous = NULL;
    for (size_t index = 0; index < DS_SIGNAL_COUNT; index++) {
        sigaction(ds_signals[index], &ds_previous[index], NULL);
        if (ds_signals[index] == signalNumber) {
            previous = &ds_previous[index];
        }
    }
    if (previous == NULL || previous->sa_handler == SIG_DFL || previous->sa_handler == SIG_IGN) {
        ds_terminate(signalNumber);
    }

    // Fatal forwarding is always one-shot, including when the old reporter faults again.
    // Invoke its correctly typed function with the ORIGINAL siginfo/ucontext, never raise
    // a replacement signal to deliver it. Only final default termination uses raise().
    sigaction(signalNumber, &ds_default, NULL);
    sigset_t mask;
    if (context != NULL) {
        mask = ((ucontext_t *)context)->uc_sigmask;
    } else {
        sigemptyset(&mask);
    }
    for (int candidate = 1; candidate < NSIG; candidate++) {
        if (sigismember(&previous->sa_mask, candidate) == 1) {
            sigaddset(&mask, candidate);
        }
    }
    if (!(previous->sa_flags & SA_NODEFER)) {
        sigaddset(&mask, signalNumber);
    }
    sigprocmask(SIG_SETMASK, &mask, NULL);
    if (previous->sa_flags & SA_SIGINFO) {
        previous->sa_sigaction(signalNumber, info, context);
    } else {
        previous->sa_handler(signalNumber);
    }
    ds_terminate(signalNumber);
}

static void ds_handleSignal(int signalNumber, siginfo_t *info, void *context) {
    if (atomic_exchange_explicit(&ds_handling, true, memory_order_relaxed)) {
        ds_terminate(signalNumber);
    }

    // One-shot before doing any capture: subsequent faults must never reenter this reporter.
    for (size_t index = 0; index < DS_SIGNAL_COUNT; index++) {
        sigaction(ds_signals[index], &ds_default, NULL);
    }

    ds_record.signalNumber = signalNumber;
    ds_record.signalCode = info != NULL ? info->si_code : 0;
    ds_record.faultAddress = info != NULL ? (uintptr_t)info->si_addr : 0;
    struct timespec timestamp;
    if (clock_gettime(CLOCK_REALTIME, &timestamp) == 0) {
        ds_record.timestamp = timestamp.tv_sec;
    }
    ds_captureRegisters(context);

    const uint8_t *bytes = (const uint8_t *)&ds_record;
    size_t remaining = sizeof(ds_record);
    while (remaining > 0) {
        ssize_t written = write(ds_output, bytes, remaining);
        if (written > 0) {
            bytes += written;
            remaining -= (size_t)written;
        } else if (written < 0 && errno == EINTR) {
            continue;
        } else {
            break;
        }
    }

    ds_forwardSignal(signalNumber, info, context);
}

int DSSignalCaptureInstall(const char *path, const uint8_t *metadata, size_t metadataLength) {
    if (path == NULL || metadata == NULL || metadataLength == 0 || metadataLength > DS_SIGNAL_METADATA_CAPACITY) {
        return EINVAL;
    }
    int result = DSSignalCapturePrepareCurrentThread();
    if (result != 0) {
        return result;
    }
    result = pthread_mutex_lock(&ds_installLock);
    if (result != 0) {
        return result;
    }
    if (ds_installed) {
        pthread_mutex_unlock(&ds_installLock);
        return 0;
    }

    ds_output = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, S_IRUSR | S_IWUSR);
    if (ds_output < 0) {
        result = errno;
        pthread_mutex_unlock(&ds_installLock);
        return result;
    }
    ds_default.sa_handler = SIG_DFL;
    sigemptyset(&ds_default.sa_mask);
    ds_record.magic = DS_SIGNAL_RECORD_MAGIC;
    ds_record.version = DS_SIGNAL_RECORD_VERSION;
    ds_record.metadataLength = (uint32_t)metadataLength;
    memcpy(ds_record.metadata, metadata, metadataLength);
    DSPrepareSignalImages();

    struct sigaction action = { .sa_sigaction = ds_handleSignal, .sa_flags = SA_SIGINFO | SA_ONSTACK };
    sigemptyset(&action.sa_mask);
    for (size_t index = 0; index < DS_SIGNAL_COUNT; index++) {
        sigaddset(&action.sa_mask, ds_signals[index]);
        if (sigaction(ds_signals[index], NULL, &ds_previous[index]) != 0) {
            result = errno;
            close(ds_output);
            ds_output = -1;
            pthread_mutex_unlock(&ds_installLock);
            return result;
        }
    }
    size_t installedCount = 0;
    for (; installedCount < DS_SIGNAL_COUNT; installedCount++) {
        if (sigaction(ds_signals[installedCount], &action, NULL) != 0) {
            result = errno;
            break;
        }
    }
    if (installedCount == DS_SIGNAL_COUNT) {
        ds_installed = true;
    } else {
        for (size_t index = 0; index < installedCount; index++) {
            sigaction(ds_signals[index], &ds_previous[index], NULL);
        }
        close(ds_output);
        ds_output = -1;
    }
    pthread_mutex_unlock(&ds_installLock);
    return result;
}

int DSSignalCrashRecordIsValid(const DSSignalCrashRecord *record) {
    if (record == NULL || record->magic != DS_SIGNAL_RECORD_MAGIC || record->version != DS_SIGNAL_RECORD_VERSION ||
        record->metadataLength == 0 || record->metadataLength > DS_SIGNAL_METADATA_CAPACITY) {
        return 0;
    }
    for (size_t index = 0; index < DS_SIGNAL_COUNT; index++) {
        if (record->signalNumber == ds_signals[index]) {
            return 1;
        }
    }
    return 0;
}
