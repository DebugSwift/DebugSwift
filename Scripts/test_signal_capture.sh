#!/bin/bash
set -euo pipefail

# Disposable child processes exercise real fatal signals without crashing the test runner.
task_build_dir=$(mktemp -d /tmp/debugswift-signal-tests.XXXXXX)
task_test_dir="Example/ExampleTests/Tests/Features/App/Crash/Native"
xcrun clang -dynamiclib -Wall -Wextra -Werror "$task_test_dir/SignalCaptureFixture.c" \
    -o "$task_build_dir/SignalCaptureFixture.dylib"
for task_optimization in -O0 -O2; do
    echo "Native crash tests ($task_optimization)"
    xcrun clang -std=c11 "$task_optimization" -g -Wall -Wextra -Werror \
        -IDebugSwiftSignalCapture/include \
        -IDebugSwiftSignalCapture \
        DebugSwiftSignalCapture/SignalCapture.c \
        DebugSwiftSignalCapture/SignalAlternateStack.c \
        DebugSwiftSignalCapture/SignalImages.c \
        "$task_test_dir/SignalCaptureTests.c" \
        -o "$task_build_dir/SignalCaptureTests$task_optimization"
    "$task_build_dir/SignalCaptureTests$task_optimization" "$task_build_dir/SignalCaptureFixture.dylib"
    xcrun clang -std=c11 "$task_optimization" -g -Wall -Wextra -Werror \
        -fobjc-arc -fobjc-exceptions -framework Foundation \
        -IDebugSwiftSignalCapture/include \
        DebugSwiftSignalCapture/ExceptionCapture.m "$task_test_dir/ExceptionCaptureTests.m" \
        -o "$task_build_dir/ExceptionCaptureTests$task_optimization"
    "$task_build_dir/ExceptionCaptureTests$task_optimization"
done
