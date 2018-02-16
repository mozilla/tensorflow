#!/usr/bin/env bash
# Copyright 2017 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================


#wget opencl
AMDGPU_OPENCL_VERSION="17.30-465504"
set +e
mkdir -p /opencl
cd /opencl

if [[ ! -f "amdgpu-pro-$AMDGPU_OPENCL_VERSION.tar.xz" ]]; then
  wget --referer=http://support.amd.com https://www2.ati.com/drivers/linux/ubuntu/amdgpu-pro-$AMDGPU_OPENCL_VERSION.tar.xz -q
fi
tar xf amdgpu-pro-$AMDGPU_OPENCL_VERSION.tar.xz
cd amdgpu-pro-$AMDGPU_OPENCL_VERSION
./amdgpu-pro-install --compute -y
cd ..
rm amdgpu-pro-$AMDGPU_OPENCL_VERSION.tar.xz
rm -rf amdgpu-pro-$AMDGPU_OPENCL_VERSION

wget http://computecpp.codeplay.com/downloads/computecpp-ce/latest/Ubuntu-16.04-64bit.tar.gz -q
tar -xvzf Ubuntu-16.04-64bit.tar.gz
mkdir -p /usr/local/computecpp
cd *Ubuntu-16.04-64bit && cp -R * /usr/local/computecpp
cd ..
rm -rf *Ubuntu-16.04-64bit
rm Ubuntu-16.04-64bit.tar.gz

adduser $(whoami) video

# Enable bazel auto completion.
echo "source /usr/local/lib/bazel/bin/bazel-complete.bash" >> ~/.bashrc
