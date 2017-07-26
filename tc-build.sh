#!/bin/bash

set -ex

source $(dirname $0)/tc-vars.sh

build_gpu=no
build_arm=no

if [ "$1" = "--gpu" ]; then
    build_gpu=yes
fi

if [ "$1" = "--arm" ]; then
    build_gpu=no
    build_arm=yes
fi

pushd ~/DeepSpeech/tf/
    # Pure amd64 CPU-only build
    if [ "${build_gpu}" = "no" -a "${build_arm}" = "no" ]; then
        echo "" | TF_NEED_CUDA=0 ./configure && bazel build -c opt ${BAZEL_OPT_FLAGS} ${BUILD_TARGET_PIP} ${BUILD_TARGET_LIB} ${BUILD_TARGET_GRAPH_TRANSFORMS} && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/artifacts/
    fi

    # Cross RPi3 CPU-only build
    if [ "${build_gpu}" = "no" -a "${build_arm}" = "yes" ]; then
        echo "" | TF_NEED_CUDA=0 ./configure && bazel build -c opt ${BAZEL_ARM_FLAGS} ${BUILD_TARGET_LIB} ${BUILD_TARGET_GRAPH_TRANSFORMS}
    fi

    # Pure amd64 GPU-enabled build
    if [ "${build_gpu}" = "yes" -a "${build_arm}" = "no" ]; then
        eval "export ${TF_CUDA_FLAGS}" && (echo "" | TF_NEED_CUDA=1 ./configure) && bazel build -c opt ${BAZEL_CUDA_FLAGS} ${BAZEL_OPT_FLAGS} ${BUILD_TARGET_PIP} ${BUILD_TARGET_LIB} ${BUILD_TARGET_GRAPH_TRANSFORMS} && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/artifacts/ --gpu
    fi

    if [ $? -ne 0 ]; then
        # There was a failure, just account for it.
        echo "Build failure, please check the output above. Exit code was: $?"
        return 1
    fi
popd
