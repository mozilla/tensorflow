/* Copyright 2015 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#include "tensorflow/core/kernels/cwise_ops_common.h"

namespace tensorflow {
REGISTER5(UnaryOp, CPU, "Cos", functor::cos, float, Eigen::half, double,
          complex64, complex128);

#if TENSORFLOW_USE_SYCL
#define REGISTER_SYCL_KERNEL(TYPE)                                    \
  REGISTER_KERNEL_BUILDER(                                            \
                          Name("Cos")                                 \
                          .Device(DEVICE_SYCL)                        \
                          .TypeConstraint<TYPE>("T"),                 \
                          UnaryOp<SYCLDevice, functor::cos<TYPE>>);
REGISTER_SYCL_KERNEL(float);
#undef REGISTER_SYCL_KERNEL
#endif // TENSORFLOW_USE_SYCL

#if GOOGLE_CUDA
REGISTER3(UnaryOp, GPU, "Cos", functor::cos, float, Eigen::half, double);
#endif
}  // namespace tensorflow
