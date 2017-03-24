#!/bin/bash

set -ex

HOME_CLEAN=$(/usr/bin/realpath "${HOME}")

PATH=${HOME_CLEAN}/bin/:$PATH
export PATH

LD_LIBRARY_PATH=${HOME_CLEAN}/DeepSpeech/CUDA/lib64/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

build_gpu=no
if [ "$1" = "--gpu" ]; then
    build_gpu=yes
fi

pushd ~/DeepSpeech/tf/
    PYTHON_BIN_PATH=${HOME_CLEAN}/DeepSpeech/tf-venv/bin/python
    PYTHONPATH=${HOME_CLEAN}/DeepSpeech/tf-venv/lib/python2.7/site-packages
    TF_NEED_GCP=0
    TF_NEED_HDFS=0
    TF_NEED_OPENCL=0
    TF_NEED_JEMALLOC=1
    TF_ENABLE_XLA=1
    GCC_HOST_COMPILER_PATH=/usr/bin/gcc

    # Enable some SIMD support. Limit ourselves to what Tensorflow needs.
    # Also ensure to not require too recent CPU: AVX2/FMA introduced by:
    #  - Intel with Haswell (2013)
    #  - AMD with Excavator (2015)
    #
    # Build for generic amd64 platforms, no device-specific optimization
    # See https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html for targetting specific CPUs
    #CC_OPT_FLAGS="-mtune=generic -march=x86-64 -msse -msse2 -msse3 -msse4.1 -msse4.2 -mavx -mavx2 -mfma"
    #BAZEL_OPT_FLAGS="--copt=-mtune=generic --cxxopt=-mtune=generic --copt=-march=x86-64 --cxxopt=-march=x86-64 --copt=-msse --cxxopt=-msse --copt=-msse2 --cxxopt=-msse2 --copt=-msse3 --cxxopt=-msse3 --copt=-msse4.1 --cxxopt=-msse4.1 --copt=-msse4.2 --cxxopt=-msse4.2 --copt=-mavx --cxxopt=-mavx --copt=-mavx2 --cxxopt=-mavx2 --copt=-mfma --cxxopt=-mfma"
    CC_OPT_FLAGS="-march=corei7"
    BAZEL_OPT_FLAGS="--copt=-march=corei7 --cxxopt=-march=corei7"

    export PYTHON_BIN_PATH
    export PYTHONPATH
    export TF_NEED_GCP
    export TF_NEED_HDFS
    export TF_NEED_OPENCL
    export TF_NEED_JEMALLOC
    export TF_ENABLE_XLA
    export GCC_HOST_COMPILER_PATH
    export CC_OPT_FLAGS

    if [ "${build_gpu}" = "no" ]; then
        echo "" | TF_NEED_CUDA=0 ./configure && bazel build --verbose_failures -c opt ${BAZEL_OPT_FLAGS} //tensorflow/tools/pip_package:build_pip_package && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/tensorflow_pkg/
    else
        echo "" | TF_NEED_CUDA=1 TF_CUDA_VERSION=8.0 TF_CUDNN_VERSION=5 CUDA_TOOLKIT_PATH=${HOME_CLEAN}/DeepSpeech/CUDA CUDNN_INSTALL_PATH=${HOME_CLEAN}/DeepSpeech/CUDA TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,3.7,5.2,6.0,6.1" ./configure && bazel build --verbose_failures -c opt --config=cuda ${BAZEL_OPT_FLAGS} //tensorflow/tools/pip_package:build_pip_package && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/tensorflow_pkg/ --gpu
    fi
popd

ls -halR /tmp/tensorflow_pkg/
