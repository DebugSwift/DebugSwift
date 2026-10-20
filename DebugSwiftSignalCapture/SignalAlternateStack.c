//
//  SignalAlternateStack.c
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

#include "DebugSwiftSignalCapture.h"
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

typedef struct {
    void *mapping;
    size_t mappingSize;
    void *stack;
} DSAlternateStack;

static pthread_key_t ds_stackKey;
static pthread_once_t ds_stackKeyOnce = PTHREAD_ONCE_INIT;
static int ds_stackKeyError;

static void ds_releaseStack(void *value) {
    DSAlternateStack *owned = value;
    stack_t current;
    if (sigaltstack(NULL, &current) != 0) {
        return;
    }
    if (current.ss_sp == owned->stack) {
        stack_t disabled = { .ss_flags = SS_DISABLE };
        if (sigaltstack(&disabled, NULL) != 0) {
            return; // Never release memory that the kernel could still use as a signal stack.
        }
    }
    munmap(owned->mapping, owned->mappingSize);
    free(owned);
}

static void ds_createStackKey(void) {
    ds_stackKeyError = pthread_key_create(&ds_stackKey, ds_releaseStack);
}

int DSSignalCapturePrepareCurrentThread(void) {
    int result = pthread_once(&ds_stackKeyOnce, ds_createStackKey);
    if (result != 0 || ds_stackKeyError != 0) {
        return result != 0 ? result : ds_stackKeyError;
    }

    stack_t current;
    if (sigaltstack(NULL, &current) != 0) {
        return errno;
    }
    if (!(current.ss_flags & SS_DISABLE)) {
        return 0;
    }

    DSAlternateStack *owned = pthread_getspecific(ds_stackKey);
    if (owned == NULL) {
        owned = calloc(1, sizeof(*owned));
        if (owned == NULL) {
            return ENOMEM;
        }
        size_t pageSize = (size_t)getpagesize();
        size_t stackSize = 64 * 1024;
        owned->mappingSize = stackSize + 2 * pageSize;
        owned->mapping = mmap(NULL, owned->mappingSize, PROT_NONE, MAP_PRIVATE | MAP_ANON, -1, 0);
        if (owned->mapping == MAP_FAILED) {
            result = errno;
            free(owned);
            return result;
        }
        owned->stack = (char *)owned->mapping + pageSize;
        if (mprotect(owned->stack, stackSize, PROT_READ | PROT_WRITE) != 0) {
            result = errno;
            munmap(owned->mapping, owned->mappingSize);
            free(owned);
            return result;
        }
        result = pthread_setspecific(ds_stackKey, owned);
        if (result != 0) {
            munmap(owned->mapping, owned->mappingSize);
            free(owned);
            return result;
        }
    }

    stack_t stack = {
        .ss_sp = owned->stack,
        .ss_size = owned->mappingSize - 2 * (size_t)getpagesize(),
        .ss_flags = 0
    };
    return sigaltstack(&stack, NULL) == 0 ? 0 : errno;
}
