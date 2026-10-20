//
//  DebugSwiftSignalCapture.h
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

#ifndef DEBUG_SWIFT_SIGNAL_CAPTURE_H
#define DEBUG_SWIFT_SIGNAL_CAPTURE_H

#include <stddef.h>
#include <stdint.h>
#include "DebugSwiftExceptionCapture.h"

#define DS_SIGNAL_RECORD_MAGIC 0x44534352u
#define DS_SIGNAL_RECORD_VERSION 2u
#define DS_SIGNAL_METADATA_CAPACITY 2048u

typedef struct {
    uint64_t loadAddress;
    uint64_t preferredAddress;
    uint64_t textSize;
    uint8_t uuid[16];
} DSSignalImage;

// Fixed-width, versioned disk format. Metadata is encoded before handlers are installed.
typedef struct {
    uint32_t magic;
    uint32_t version;
    int32_t signalNumber;
    int32_t signalCode;
    uint64_t faultAddress;
    uint64_t instructionAddress;
    uint64_t stackPointer;
    uint64_t framePointer;
    uint64_t linkRegister;
    int64_t timestamp;
    DSSignalImage instructionImage;
    DSSignalImage linkImage;
    uint32_t metadataLength;
    uint32_t reserved;
    uint8_t metadata[DS_SIGNAL_METADATA_CAPACITY];
} DSSignalCrashRecord;

// Normal execution only. Installs once per process and prepares the calling thread's stack.
// Returns zero on success or an errno value. Owns its output FD for the process lifetime.
int DSSignalCaptureInstall(const char *path, const uint8_t *metadata, size_t metadataLength);

// Alternate signal stacks are per thread. Call on each application-owned worker thread
// that needs stack-overflow coverage, before running its work. Reuses an existing stack.
int DSSignalCapturePrepareCurrentThread(void);

int DSSignalCrashRecordIsValid(const DSSignalCrashRecord *record);

#endif
