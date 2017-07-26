#!/bin/bash

set -ex

HOME_CLEAN=$(/usr/bin/realpath "${HOME}")

PATH=${HOME_CLEAN}/bin/:$PATH
export PATH

LD_LIBRARY_PATH=${HOME_CLEAN}/DeepSpeech/CUDA/lib64/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

BAZEL_URL=https://github.com/bazelbuild/bazel/releases/download/0.4.2/bazel-0.4.2-installer-linux-x86_64.sh
BAZEL_SHA256=b76b62a8c0eead1fc2215699382f1608c7bb98529fc48c5e9ef3dfa1b8b7585e

CUDA_URL=https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run
CUDA_SHA256=64dc4ab867261a0d690735c46d7cc9fc60d989da0d69dc04d1714e409cacbdf0

CUDNN_URL=http://developer.download.nvidia.com/compute/redist/cudnn/v5.1/cudnn-8.0-linux-x64-v5.1.tgz
CUDNN_SHA256=c10719b36f2dd6e9ddc63e3189affaa1a94d7d027e63b71c3f64d449ab0645ce

PYTHON_BIN_PATH=${HOME_CLEAN}/DeepSpeech/tf-venv/bin/python
export PYTHON_BIN_PATH

PYTHONPATH=${HOME_CLEAN}/DeepSpeech/tf-venv/lib/python2.7/site-packages
export PYTHONPATH

TF_NEED_GCP=0
export TF_NEED_GCP

TF_NEED_HDFS=0
export TF_NEED_HDFS

TF_NEED_OPENCL=0
export TF_NEED_OPENCL

TF_NEED_JEMALLOC=1
export TF_NEED_JEMALLOC

TF_ENABLE_XLA=1
export TF_ENABLE_XLA

GCC_HOST_COMPILER_PATH=/usr/bin/gcc
export GCC_HOST_COMPILER_PATH

# Enable some SIMD support. Limit ourselves to what Tensorflow needs.
# Also ensure to not require too recent CPU: AVX2/FMA introduced by:
#  - Intel with Haswell (2013)
#  - AMD with Excavator (2015)
#
# Build for generic amd64 platforms, no device-specific optimization
# See https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html for targetting specific CPUs
CC_OPT_FLAGS="-mtune=generic -march=x86-64 -msse -msse2 -msse3 -msse4.1 -msse4.2 -mavx -mavx2 -mfma"
BAZEL_OPT_FLAGS="--copt=-mtune=generic --cxxopt=-mtune=generic --copt=-march=x86-64 --cxxopt=-march=x86-64 --copt=-msse --cxxopt=-msse --copt=-msse2 --cxxopt=-msse2 --copt=-msse3 --cxxopt=-msse3 --copt=-msse4.1 --cxxopt=-msse4.1 --copt=-msse4.2 --cxxopt=-msse4.2 --copt=-mavx --cxxopt=-mavx --copt=-mavx2 --cxxopt=-mavx2 --copt=-mfma --cxxopt=-mfma"
export CC_OPT_FLAGS

TF_CUDA_FLAGS="TF_CUDA_VERSION=8.0 TF_CUDNN_VERSION=5 CUDA_TOOLKIT_PATH=${HOME_CLEAN}/DeepSpeech/CUDA CUDNN_INSTALL_PATH=${HOME_CLEAN}/DeepSpeech/CUDA TF_CUDA_COMPUTE_CAPABILITIES=\"3.0,3.5,3.7,5.2,6.0,6.1\""
BAZEL_ARM_FLAGS="--host_crosstool_top=@bazel_tools//tools/cpp:toolchain --crosstool_top=//tools/arm_compiler:toolchain --cpu=rpi-armeabi"
BAZEL_CUDA_FLAGS="--config=cuda"

BUILD_TARGET_PIP="//tensorflow/tools/pip_package:build_pip_package"
BUILD_TARGET_LIB="//tensorflow:libtensorflow.so"
