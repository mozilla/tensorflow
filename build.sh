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
    GCC_HOST_COMPILER_PATH=/usr/bin/gcc

    export PYTHON_BIN_PATH
    export PYTHONPATH
    export TF_NEED_GCP
    export TF_NEED_HDFS
    export TF_NEED_OPENCL
    export GCC_HOST_COMPILER_PATH

    if [ "${build_gpu}" = "no" ]; then
        echo "" | TF_NEED_CUDA=0 ./configure && bazel build -c opt //tensorflow/tools/pip_package:build_pip_package && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/tensorflow_pkg/
    else
        echo "" | TF_NEED_CUDA=1 TF_CUDA_VERSION=8.0 TF_CUDNN_VERSION=5 CUDA_TOOLKIT_PATH=${HOME_CLEAN}/DeepSpeech/CUDA CUDNN_INSTALL_PATH=${HOME_CLEAN}/DeepSpeech/CUDA TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,3.7,5.2,6.0,6.1" ./configure && bazel build -c opt --config=cuda //tensorflow/tools/pip_package:build_pip_package && ./tensorflow/tools/pip_package/build_pip_package.sh /tmp/tensorflow_pkg/
    fi
popd

ls -halR /tmp/tensorflow_pkg/
