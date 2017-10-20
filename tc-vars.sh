#!/bin/bash

set -ex

export OS=$(uname)
if [ "${OS}" = "Linux" ]; then
    export DS_ROOT_TASK=$(/usr/bin/realpath "${HOME}")

    BAZEL_URL=https://github.com/bazelbuild/bazel/releases/download/0.5.4/bazel-0.5.4-installer-linux-x86_64.sh
    BAZEL_SHA256=9981da210d2d96e68662127ba9d96844ce2822524b18e98fcec54a70345cff9c

    CUDA_URL=https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run
    CUDA_SHA256=64dc4ab867261a0d690735c46d7cc9fc60d989da0d69dc04d1714e409cacbdf0

    # From https://gitlab.com/nvidia/cuda/blob/centos7/8.0/devel/cudnn7/Dockerfile
    CUDNN_URL=http://developer.download.nvidia.com/compute/redist/cudnn/v7.0.2/cudnn-8.0-linux-x64-v7.tgz
    CUDNN_SHA256=b667807f2b82af7a9ed5451e9ff5ea7a11deeef85aafdc5529e1adfddcc069ca

elif [ "${OS}" = "Darwin" ]; then
    if [ -z "${TASKCLUSTER_TASK_DIR}" -o -z "${TASKCLUSTER_ARTIFACTS}" ]; then
        echo "Inconsistent OSX setup: missing some vars."
        echo "TASKCLUSTER_TASK_DIR=${TASKCLUSTER_TASK_DIR}"
        echo "TASKCLUSTER_ARTIFACTS=${TASKCLUSTER_ARTIFACTS}"
        exit 1
    fi;

    export DS_ROOT_TASK=${TASKCLUSTER_TASK_DIR}

    BAZEL_URL=https://github.com/bazelbuild/bazel/releases/download/0.5.4/bazel-0.5.4-installer-darwin-x86_64.sh
    BAZEL_SHA256=1a83525f2da8816192d22e334d5cfe396cb00c36057922c8c3a39fc9dbbe2b0f
fi;

# /tmp/artifacts for docker-worker on linux,
# and task subdir for generic-worker on osx
export TASKCLUSTER_ARTIFACTS=${TASKCLUSTER_ARTIFACTS:-/tmp/artifacts}

### Define variables that needs to be exported to other processes

PATH=${DS_ROOT_TASK}/bin:$PATH
if [ "${OS}" = "Darwin" ]; then
    PATH=${DS_ROOT_TASK}/homebrew/bin/:${DS_ROOT_TASK}/homebrew/opt/node@6/bin:$PATH
fi;
export PATH

if [ "${OS}" = "Linux" ]; then
    export LD_LIBRARY_PATH=${DS_ROOT_TASK}/DeepSpeech/CUDA/lib64/:$LD_LIBRARY_PATH
    export PYTHON_BIN_PATH=${DS_ROOT_TASK}/DeepSpeech/tf-venv/bin/python
    export PYTHONPATH=${DS_ROOT_TASK}/DeepSpeech/tf-venv/lib/python2.7/site-packages
elif [ "${OS}" = "Darwin" ]; then
    export PYENV_VERSION=2.7.13
    export PYENV_ROOT=${DS_ROOT_TASK}/pyenv/
    export PYTHON_BIN_PATH=${PYENV_ROOT}/versions/${PYENV_VERSION}/envs/tf-venv/bin/python
    export PYTHONPATH=${PYENV_ROOT}/versions/${PYENV_VERSION}/envs/tf-venv/lib/python2.7/site-packages
fi;

export TF_NEED_GCP=0
export TF_NEED_HDFS=0
export TF_NEED_OPENCL=0

if [ "${OS}" = "Linux" ]; then
    TF_NEED_JEMALLOC=1
elif [ "${OS}" = "Darwin" ]; then
    TF_NEED_JEMALLOC=0
fi;
export TF_NEED_JEMALLOC

export TF_ENABLE_XLA=1
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_MPI=0
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc

## Below, define or export some build variables

# Enable some SIMD support. Limit ourselves to what Tensorflow needs.
# Also ensure to not require too recent CPU: AVX2/FMA introduced by:
#  - Intel with Haswell (2013)
#  - AMD with Excavator (2015)
#
# Build for generic amd64 platforms, no device-specific optimization
# See https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html for targetting specific CPUs
CC_OPT_FLAGS="-mtune=generic -march=x86-64 -msse -msse2 -msse3 -msse4.1 -msse4.2 -mavx -mavx2 -mfma"
BAZEL_OPT_FLAGS=""
for flag in ${CC_OPT_FLAGS};
do
    BAZEL_OPT_FLAGS="${BAZEL_OPT_FLAGS} --copt=${flag}"
done;

export CC_OPT_FLAGS

if [ "${OS}" = "Darwin" ]; then
    BAZEL_OUTPUT_CACHE_DIR="${DS_ROOT_TASK}/.bazel_cache/"
    BAZEL_OUTPUT_CACHE_INSTANCE="${BAZEL_OUTPUT_CACHE_DIR}/output/"
    mkdir -p ${BAZEL_OUTPUT_CACHE_INSTANCE} || true

    # We need both to ensure stable path ; default value for output_base is some
    # MD5 value.
    BAZEL_OUTPUT_USER_ROOT="--output_user_root ${BAZEL_OUTPUT_CACHE_DIR} --output_base ${BAZEL_OUTPUT_CACHE_INSTANCE}"
    export BAZEL_OUTPUT_USER_ROOT
fi;

### Define build parameters/env variables that we will re-ues in sourcing scripts.
TF_CUDA_FLAGS="TF_CUDA_CLANG=0 TF_CUDA_VERSION=8.0 TF_CUDNN_VERSION=5 CUDA_TOOLKIT_PATH=${DS_ROOT_TASK}/DeepSpeech/CUDA CUDNN_INSTALL_PATH=${DS_ROOT_TASK}/DeepSpeech/CUDA TF_CUDA_COMPUTE_CAPABILITIES=\"3.0,3.5,3.7,5.2,6.0,6.1\""
BAZEL_ARM_FLAGS="--config=rpi3"
BAZEL_CUDA_FLAGS="--config=cuda"

### Define build targets that we will re-ues in sourcing scripts.
BUILD_TARGET_PIP="//tensorflow/tools/pip_package:build_pip_package"
BUILD_TARGET_LIB_CPP_API="//tensorflow:libtensorflow_cc.so"
BUILD_TARGET_GRAPH_TRANSFORMS="//tensorflow/tools/graph_transforms:transform_graph"
BUILD_TARGET_GRAPH_SUMMARIZE="//tensorflow/tools/graph_transforms:summarize_graph"
BUILD_TARGET_GRAPH_BENCHMARK="//tensorflow/tools/benchmark:benchmark_model"
BUILD_TARGET_AOT_DEPS="//tensorflow/compiler/aot:runtime //tensorflow/compiler/xla/service/cpu:runtime_matmul //tensorflow/compiler/xla:executable_run_options"
