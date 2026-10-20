//
//  SignalImages.c
//  DebugSwift
//
//  Created by gua on 2026/10/20.
//

#include "SignalCaptureInternal.h"
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <string.h>

// Slots are never reused or modified after publication. Signal readers need no lock,
// allocation, dyld API, or retry if a fault interrupts an image callback on this thread.
#define DS_IMAGE_CAPACITY 4096
typedef struct {
    atomic_bool active;
    const struct mach_header *header;
    DSSignalImage image;
} DSImageEntry;

_Static_assert(ATOMIC_INT_LOCK_FREE == 2 && ATOMIC_BOOL_LOCK_FREE == 2, "Image publication must be lock-free");

static DSImageEntry ds_images[DS_IMAGE_CAPACITY];
static atomic_uint ds_imageCount = ATOMIC_VAR_INIT(0);
static pthread_mutex_t ds_imageLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_once_t ds_imageOnce = PTHREAD_ONCE_INIT;

static void ds_addImage(const struct mach_header *header, intptr_t slide) {
    if (header->magic != MH_MAGIC_64) {
        return;
    }
    const struct mach_header_64 *header64 = (const struct mach_header_64 *)header;
    const uint8_t *cursor = (const uint8_t *)(header64 + 1);
    const uint8_t *end = cursor + header64->sizeofcmds;
    DSSignalImage image = { 0 };
    for (uint32_t index = 0; index < header64->ncmds; index++) {
        if ((size_t)(end - cursor) < sizeof(struct load_command)) {
            return;
        }
        const struct load_command *command = (const struct load_command *)cursor;
        if (command->cmdsize < sizeof(*command) || command->cmdsize > (size_t)(end - cursor)) {
            return;
        }
        if (command->cmd == LC_SEGMENT_64 && command->cmdsize >= sizeof(struct segment_command_64)) {
            const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
            if (strncmp(segment->segname, SEG_TEXT, sizeof(segment->segname)) == 0) {
                image.preferredAddress = segment->vmaddr;
                image.loadAddress = segment->vmaddr + (uint64_t)slide;
                image.textSize = segment->vmsize;
            }
        } else if (command->cmd == LC_UUID && command->cmdsize >= sizeof(struct uuid_command)) {
            memcpy(image.uuid, ((const struct uuid_command *)command)->uuid, sizeof(image.uuid));
        }
        cursor += command->cmdsize;
    }
    if (image.textSize == 0) {
        return;
    }

    pthread_mutex_lock(&ds_imageLock);
    unsigned count = atomic_load_explicit(&ds_imageCount, memory_order_relaxed);
    for (unsigned index = 0; index < count; index++) {
        if (ds_images[index].header == header && atomic_load_explicit(&ds_images[index].active, memory_order_relaxed)) {
            pthread_mutex_unlock(&ds_imageLock);
            return;
        }
    }
    if (count < DS_IMAGE_CAPACITY) {
        ds_images[count].header = header;
        ds_images[count].image = image;
        atomic_store_explicit(&ds_images[count].active, true, memory_order_release);
        atomic_store_explicit(&ds_imageCount, count + 1, memory_order_release);
    }
    // At capacity, new images remain unmapped and their frames stay raw rather than guessing.
    pthread_mutex_unlock(&ds_imageLock);
}

static void ds_removeImage(const struct mach_header *header, intptr_t slide) {
    (void)slide;
    pthread_mutex_lock(&ds_imageLock);
    unsigned count = atomic_load_explicit(&ds_imageCount, memory_order_relaxed);
    for (unsigned index = 0; index < count; index++) {
        if (ds_images[index].header == header) {
            atomic_store_explicit(&ds_images[index].active, false, memory_order_release);
        }
    }
    pthread_mutex_unlock(&ds_imageLock);
}

static void ds_registerImageCallbacks(void) {
    // Register removal first so an unload between the registrations cannot leave a stale image.
    _dyld_register_func_for_remove_image(ds_removeImage);
    _dyld_register_func_for_add_image(ds_addImage);
}

void DSPrepareSignalImages(void) {
    pthread_once(&ds_imageOnce, ds_registerImageCallbacks);
}

void DSSignalImageForAddress(uint64_t address, DSSignalImage *image) {
    unsigned count = atomic_load_explicit(&ds_imageCount, memory_order_acquire);
    for (unsigned index = 0; index < count; index++) {
        const DSImageEntry *entry = &ds_images[index];
        if (atomic_load_explicit(&entry->active, memory_order_acquire) && address >= entry->image.loadAddress &&
            address - entry->image.loadAddress < entry->image.textSize) {
            DSSignalImage candidate = entry->image;
            if (atomic_load_explicit(&entry->active, memory_order_acquire)) {
                *image = candidate;
                return;
            }
        }
    }
}
