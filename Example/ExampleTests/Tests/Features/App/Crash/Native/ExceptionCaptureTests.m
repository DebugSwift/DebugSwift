//
//  ExceptionCaptureTests.m
//  DebugSwift
//
//  Created by gua on 2026/10/21.
//

// Host-only: real uncaught Objective-C exceptions run in disposable children.
#import <Foundation/Foundation.h>
#import "DebugSwiftExceptionCapture.h"
#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

static int markerOutput;
static int scenario;
static NSUncaughtExceptionHandler *installedHandler;
static pthread_mutex_t unrelatedLock = PTHREAD_MUTEX_INITIALIZER;

static void receiver(void *value) {
    NSException *exception = (__bridge NSException *)value;
    assert([exception.name isEqualToString:@"OriginalException"]);
    assert(NSGetUncaughtExceptionHandler() == NULL);
    (void)write(markerOutput, "S", 1);
    if (scenario == 2) {
        [NSException raise:@"ReceiverException" format:@"secondary failure"];
    }
    if (scenario == 4) {
        installedHandler(exception);
    }
}

static void replacement(void *value) {
    (void)value;
    (void)write(markerOutput, "X", 1);
}

static void previous(NSException *exception) {
    assert([exception.name isEqualToString:@"OriginalException"]);
    assert(NSGetUncaughtExceptionHandler() == NULL);
    (void)write(markerOutput, "P", 1);
    if (scenario == 3) {
        [NSException raise:@"PreviousHandlerException" format:@"secondary failure"];
    }
}

static void runCase(int testScenario, const char *expected, const char *name) {
    int markers[2];
    assert(pipe(markers) == 0);
    pid_t child = fork();
    assert(child >= 0);
    if (child == 0) {
        close(markers[0]);
        markerOutput = markers[1];
        scenario = testScenario;
        struct rlimit limit = { 0, 0 };
        assert(setrlimit(RLIMIT_CORE, &limit) == 0);
        alarm(5);
        @autoreleasepool {
            NSSetUncaughtExceptionHandler(scenario == 0 ? NULL : previous);
            assert(DSExceptionCaptureInstall(NULL) == EINVAL);
            assert(DSExceptionCaptureInstall(receiver) == 0);
            installedHandler = NSGetUncaughtExceptionHandler();
            assert(DSExceptionCaptureInstall(replacement) == 0);
            assert(NSGetUncaughtExceptionHandler() == installedHandler);
            assert(pthread_mutex_lock(&unrelatedLock) == 0);
            [NSException raise:@"OriginalException" format:@"fatal fixture"];
        }
        _exit(99);
    }
    close(markers[1]);
    int status;
    assert(waitpid(child, &status, 0) == child);
    assert(WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL);
    char received[8] = { 0 };
    ssize_t count = read(markers[0], received, sizeof(received) - 1);
    assert(count == (ssize_t)strlen(expected));
    assert(strcmp(received, expected) == 0);
    close(markers[0]);
    printf("PASS: %s\n", name);
}

int main(void) {
    runCase(0, "S", "uncaught NSException terminates without a previous handler");
    runCase(1, "SP", "installation freezes receiver/previous handler while another mutex is held");
    runCase(2, "SP", "throwing receiver still forwards the original NSException");
    runCase(3, "SP", "throwing previous exception handler still terminates");
    runCase(4, "S", "recursive exception handler invocation is one-shot");
    return 0;
}
