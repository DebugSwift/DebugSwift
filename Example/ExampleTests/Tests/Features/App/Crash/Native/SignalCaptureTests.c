//
//  SignalCaptureTests.c
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

// Run on macOS with the command in Scripts/test_signal_capture.sh.
// Each destructive signal runs in a disposable child, with an alarm to detect hangs.
#include "DebugSwiftSignalCapture.h"
#include "SignalCaptureInternal.h"
#include <assert.h>
#include <errno.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <mach-o/dyld.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/ucontext.h>
#include <sys/wait.h>
#include <unistd.h>

static const uint8_t metadata[] = "{\"appVersion\":\"test\"}";
static int markerOutput;
static volatile int stackSink;
static const char *fixturePath;

typedef struct {
    int code;
    uintptr_t faultAddress;
    uint64_t pc;
} DSForwardedContext;

static uint64_t programCounter(void *context) {
    ucontext_t *state = context;
#if defined(__arm64__)
    return __darwin_arm_thread_state64_get_pc(state->uc_mcontext->__ss);
#else
    return state->uc_mcontext->__ss.__rip;
#endif
}

static void originalContextHandler(int number, siginfo_t *info, void *context) {
    assert(number == SIGSEGV && info != NULL && context != NULL);
    DSForwardedContext forwarded = {
        .code = info->si_code,
        .faultAddress = (uintptr_t)info->si_addr,
        .pc = programCounter(context)
    };
    (void)write(markerOutput, "C", 1);
    (void)write(markerOutput, &forwarded, sizeof(forwarded));
}

static void oneShotHandler(int number, siginfo_t *info, void *context) {
    assert(info != NULL && context != NULL);
    struct sigaction action;
    assert(sigaction(number, NULL, &action) == 0);
    assert(action.sa_handler == SIG_DFL);
    sigset_t mask;
    assert(sigprocmask(SIG_BLOCK, NULL, &mask) == 0);
    assert(sigismember(&mask, number) == 1);
    (void)write(markerOutput, "R", 1);
}

static void noDeferHandler(int number) {
    sigset_t mask;
    assert(sigprocmask(SIG_BLOCK, NULL, &mask) == 0);
    assert(sigismember(&mask, number) == 0);
    assert(sigismember(&mask, SIGUSR1) == 1);
    (void)write(markerOutput, "N", 1);
}

static void install(const char *path) {
    assert(DSSignalCaptureInstall(path, metadata, sizeof(metadata) - 1) == 0);
}

static void previousHandler(int signalNumber) {
    assert(signalNumber == SIGABRT);
    (void)write(markerOutput, "H", 1);
}

static void previousInfoHandler(int signalNumber, siginfo_t *info, void *context) {
    assert(signalNumber == SIGABRT && info != NULL && context != NULL);
    sigset_t mask;
    assert(sigprocmask(SIG_BLOCK, NULL, &mask) == 0);
    // The OS must apply the previous handler's mask, not the reporter's mask.
    assert(sigismember(&mask, SIGUSR1) == 1);
    (void)write(markerOutput, "I", 1);
    raise(SIGSEGV);
}

static void abortWithHeldLock(const char *path) {
    install(path);
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    assert(pthread_mutex_lock(&mutex) == 0);
    raise(SIGABRT);
}

static void repeatInstall(const char *path) {
    install(path);
    struct sigaction before;
    assert(sigaction(SIGABRT, NULL, &before) == 0);
    assert(before.sa_flags & SA_ONSTACK);
    assert(!(before.sa_flags & SA_NODEFER));
    static const uint8_t changed[] = "must not replace the original metadata";
    assert(DSSignalCaptureInstall(path, changed, sizeof(changed) - 1) == 0);
    struct sigaction after;
    assert(sigaction(SIGABRT, NULL, &after) == 0);
    assert(before.sa_sigaction == after.sa_sigaction);
    raise(SIGABRT);
}

static void segmentationFault(const char *path) {
    install(path);
    *(volatile int *)(uintptr_t)1 = 42;
}

static void chainOriginalFaultContext(const char *path) {
    struct sigaction action = { .sa_sigaction = originalContextHandler, .sa_flags = SA_SIGINFO };
    sigemptyset(&action.sa_mask);
    assert(sigaction(SIGSEGV, &action, NULL) == 0);
    segmentationFault(path);
}

static void chainOneShot(const char *path) {
    struct sigaction action = { .sa_sigaction = oneShotHandler, .sa_flags = SA_SIGINFO | SA_RESETHAND };
    sigemptyset(&action.sa_mask);
    assert(sigaction(SIGABRT, &action, NULL) == 0);
    install(path);
    raise(SIGABRT);
}

static void chainNoDefer(const char *path) {
    struct sigaction action = { .sa_handler = noDeferHandler, .sa_flags = SA_NODEFER };
    sigemptyset(&action.sa_mask);
    sigaddset(&action.sa_mask, SIGUSR1);
    assert(sigaction(SIGABRT, &action, NULL) == 0);
    install(path);
    raise(SIGABRT);
}

static void dynamicallyLoadedFault(const char *path) {
    install(path);
    void *library = dlopen(fixturePath, RTLD_NOW | RTLD_LOCAL);
    assert(library != NULL);
    void (*trigger)(void) = dlsym(library, "DSSignalFixtureCrash");
    assert(trigger != NULL);
    trigger();
}

__attribute__((noinline)) static void overflowStack(unsigned depth) {
    volatile char space[4096];
    memset((void *)space, (int)depth, sizeof(space));
    // The volatile condition and post-call access prevent tail-call removal.
    if (stackSink == 0) {
        overflowStack(depth + 1);
    }
    stackSink += space[depth % sizeof(space)];
}

static void *overflowWorker(void *unused) {
    (void)unused;
    assert(DSSignalCapturePrepareCurrentThread() == 0);
    stack_t stack;
    assert(sigaltstack(NULL, &stack) == 0);
    assert(!(stack.ss_flags & SS_DISABLE));
    overflowStack(1);
    return NULL;
}

static void stackOverflow(const char *path) {
    install(path);
    pthread_attr_t attributes;
    assert(pthread_attr_init(&attributes) == 0);
    assert(pthread_attr_setstacksize(&attributes, 64 * 1024) == 0);
    pthread_t worker;
    assert(pthread_create(&worker, &attributes, overflowWorker, NULL) == 0);
    assert(pthread_join(worker, NULL) == 0);
}

static void chainHandler(const char *path) {
    struct sigaction action = { .sa_handler = previousHandler };
    sigemptyset(&action.sa_mask);
    assert(sigaction(SIGABRT, &action, NULL) == 0);
    install(path);
    raise(SIGABRT);
}

static void chainInfoHandlerAndFaultAgain(const char *path) {
    struct sigaction action = { .sa_sigaction = previousInfoHandler, .sa_flags = SA_SIGINFO };
    sigemptyset(&action.sa_mask);
    sigaddset(&action.sa_mask, SIGUSR1);
    assert(sigaction(SIGABRT, &action, NULL) == 0);
    install(path);
    raise(SIGABRT);
}

static void chainIgnoredSignal(const char *path) {
    signal(SIGABRT, SIG_IGN);
    install(path);
    raise(SIGABRT);
}

static void invalidPathDoesNotReplaceHandlers(void) {
    struct sigaction original;
    assert(sigaction(SIGABRT, NULL, &original) == 0);
    assert(DSSignalCaptureInstall("/does-not-exist/DebugSwift/report.bin", metadata, sizeof(metadata) - 1) == ENOENT);
    struct sigaction after;
    assert(sigaction(SIGABRT, NULL, &after) == 0);
    assert(original.sa_handler == after.sa_handler);
    assert(original.sa_flags == after.sa_flags);
    puts("PASS: failed installation preserves original handler");
}

static void *prepareAndExit(void *unused) {
    (void)unused;
    assert(DSSignalCapturePrepareCurrentThread() == 0);
    assert(DSSignalCapturePrepareCurrentThread() == 0);
    return NULL;
}

static void alternateStackLifecycle(void) {
    // Exercise thread-local ownership/destruction without modifying the main thread's stack.
    for (int index = 0; index < 16; index++) {
        pthread_t worker;
        assert(pthread_create(&worker, NULL, prepareAndExit, NULL) == 0);
        assert(pthread_join(worker, NULL) == 0);
    }
    puts("PASS: alternate stack thread lifecycle");
}

static void imageUnloadInvalidatesCachedMapping(void) {
    DSPrepareSignalImages();
    void *library = dlopen(fixturePath, RTLD_NOW | RTLD_LOCAL);
    assert(library != NULL);
    uintptr_t address = (uintptr_t)dlsym(library, "DSSignalFixtureCrash");
    assert(address != 0);
    DSSignalImage image = { 0 };
    DSSignalImageForAddress(address, &image);
    assert(image.textSize != 0);
    assert(dlclose(library) == 0);
    DSSignalImage removed = { 0 };
    DSSignalImageForAddress(address, &removed);
    assert(removed.textSize == 0);
    puts("PASS: unloaded images are not matched to stale addresses");
}

static void runCase(const char *name, void (*trigger)(const char *), int expectedSignal, char expectedMarker) {
    char directory[] = "/tmp/debugswift-signal-test.XXXXXX";
    assert(mkdtemp(directory) != NULL);
    char path[256];
    assert(snprintf(path, sizeof(path), "%s/report.bin", directory) > 0);
    int marker[2];
    assert(pipe(marker) == 0);
    fflush(stdout);
    pid_t child = fork();
    assert(child >= 0);
    if (child == 0) {
        close(marker[0]);
        markerOutput = marker[1];
        struct rlimit limit = { 0, 0 };
        setrlimit(RLIMIT_CORE, &limit);
        alarm(5);
        trigger(path);
        _exit(100); // No fatal signal case is allowed to return.
    }
    close(marker[1]);
    int status;
    assert(waitpid(child, &status, 0) == child);
    assert(WIFSIGNALED(status));
    int actualSignal = WTERMSIG(status);
    assert(expectedSignal != 0 ? actualSignal == expectedSignal : (actualSignal == SIGSEGV || actualSignal == SIGBUS));
    int input = open(path, O_RDONLY);
    assert(input >= 0);
    struct stat attributes;
    assert(fstat(input, &attributes) == 0);
    assert(attributes.st_size == sizeof(DSSignalCrashRecord));
    DSSignalCrashRecord record;
    assert(read(input, &record, sizeof(record)) == sizeof(record));
    close(input);
    assert(DSSignalCrashRecordIsValid(&record));
    assert(record.metadataLength == sizeof(metadata) - 1);
    assert(memcmp(record.metadata, metadata, sizeof(metadata) - 1) == 0);
    assert(record.timestamp > 0);
    assert(record.instructionAddress != 0 && record.stackPointer != 0);
    assert(record.instructionImage.loadAddress != 0);
    assert(record.instructionAddress >= record.instructionImage.loadAddress);
    assert(record.instructionAddress - record.instructionImage.loadAddress < record.instructionImage.textSize);
    uint8_t emptyUUID[16] = { 0 };
    assert(memcmp(record.instructionImage.uuid, emptyUUID, sizeof(emptyUUID)) != 0);
    if (trigger == segmentationFault || trigger == chainOriginalFaultContext || trigger == dynamicallyLoadedFault) {
        assert(record.signalNumber == SIGSEGV && record.faultAddress == 1);
    } else if (trigger != stackOverflow) {
        assert(record.signalNumber == SIGABRT);
    }
    char received = 0;
    ssize_t count = read(marker[0], &received, 1);
    assert(expectedMarker == 0 ? count == 0 : (count == 1 && received == expectedMarker));
    if (trigger == chainOriginalFaultContext) {
        DSForwardedContext forwarded;
        assert(read(marker[0], &forwarded, sizeof(forwarded)) == sizeof(forwarded));
        assert(forwarded.code == record.signalCode);
        assert(forwarded.faultAddress == record.faultAddress);
        assert(forwarded.pc == record.instructionAddress);
    }
    if (trigger == dynamicallyLoadedFault) {
        assert(record.instructionImage.loadAddress != (uintptr_t)_dyld_get_image_header(0));
    }
    close(marker[0]);
    assert(unlink(path) == 0);
    assert(rmdir(directory) == 0);
    printf("PASS: %s\n", name);
}

int main(int argc, char **argv) {
    assert(argc == 2);
    fixturePath = argv[1];
    invalidPathDoesNotReplaceHandlers();
    alternateStackLifecycle();
    imageUnloadInvalidatesCachedMapping();
    runCase("SIGABRT while a normal mutex is held", abortWithHeldLock, SIGABRT, 0);
    runCase("repeated installation remains one-shot", repeatInstall, SIGABRT, 0);
    runCase("real SIGSEGV preserves fault registers", segmentationFault, SIGSEGV, 0);
    runCase("worker stack overflow uses alternate stack", stackOverflow, 0, 0);
    runCase("previous one-argument handler is forwarded", chainHandler, SIGABRT, 'H');
    runCase("previous siginfo handler faults without reporter reentry", chainInfoHandlerAndFaultAgain, SIGSEGV, 'I');
    runCase("SIG_IGN is never called as a function", chainIgnoredSignal, SIGABRT, 0);
    runCase("previous handler receives original siginfo and PC", chainOriginalFaultContext, SIGSEGV, 'C');
    runCase("previous SA_RESETHAND is reset before forwarding", chainOneShot, SIGABRT, 'R');
    runCase("previous SA_NODEFER and explicit mask are honored", chainNoDefer, SIGABRT, 'N');
    runCase("images loaded after installation are recorded", dynamicallyLoadedFault, SIGSEGV, 0);
    return 0;
}
