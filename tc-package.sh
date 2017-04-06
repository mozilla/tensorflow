#!/bin/bash

set -xe

mkdir -p /tmp/artifacts/
cp ${HOME}/DeepSpeech/tf/bazel-bin/tensorflow/libtensorflow.so /tmp/artifacts/
tar -C ${HOME} -cf - . | pixz -9 > /tmp/artifacts/home.tar.xz
