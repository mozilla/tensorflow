#!/bin/bash

set -xe

source $(dirname $0)/tc-vars.sh

mkdir -p ${TASKCLUSTER_ARTIFACTS} || true

cp ${DS_ROOT_TASK}/DeepSpeech/tf/bazel-bin/tensorflow/libtensorflow_cc.so ${TASKCLUSTER_ARTIFACTS}
cp ${DS_ROOT_TASK}/DeepSpeech/tf/bazel-bin/tensorflow/tools/graph_transforms/transform_graph ${TASKCLUSTER_ARTIFACTS}

# Let's perform some cleanup
rm -fr ${DS_ROOT_TASK}/dls/

# Keeping homebrew seems to screw later, so let's just remove it and save some space
if [ "${OS}" = "Darwin" ]; then
    rm -fr ${TASKCLUSTER_TASK_DIR}/homebrew/
fi;

# Make a tar of
#  - /home/build-user/ (linux
#  - /Users/build-user/TaskCluster/HeavyTasks/X/ (OSX)
tar -C ${DS_ROOT_TASK} -cf - . | pixz -9 > ${TASKCLUSTER_ARTIFACTS}/home.tar.xz
