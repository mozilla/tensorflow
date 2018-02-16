#ifndef TENSORFLOW_USE_SYCL
#error This file should only be included when compiling with SYCL support
#endif

#ifndef TENSORFLOW_KERNELS_CONV_OPS_SYCL_KERNEL_HELPERS_H_
#define TENSORFLOW_KERNELS_CONV_OPS_SYCL_KERNEL_HELPERS_H_

#include "tensorflow/core/kernels/conv_ops_sycl_fast_div.h"

namespace tensorflow {
namespace helpers {
/**
 * A 2D tensor index. The most packed index is s1, with s0 the least packed.
 */
struct TensorIndex2D {
  int s0;
  int s1;
};
/**
 * Compute a 2D tensor index from a flattened index. The most packed dimension
 * in memory is assumed to be the last one (i.e. the dimension with size_1
 * elements), while the size of the least packed dimension is not needed for the
 * calculation.
 */
template <typename Index, bool use_fast_div>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex2D unflatten2d(
    Index index, typename fast_div::index_div<Index, use_fast_div>::type div_size_1,
    Index size_1) {
  const Index s01_idx = index;

  const Index s0 = s01_idx / div_size_1;
  const Index s1 = s01_idx - s0 * size_1;

  TensorIndex2D result{s0, s1};
  return result;
}
template <>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex2D unflatten2d<int, false>(
    int index, typename fast_div::index_div<int, false>::type /*div_size_1*/, int size_1) {
  const int s01_idx = index;

  const int s0 = s01_idx / size_1;
  const int s1 = s01_idx % size_1;

  TensorIndex2D result{s0, s1};
  return result;
}
/**
 * A 3D tensor index. The most packed index is s2, with s0 the least packed.
 */
struct TensorIndex3D {
  int s0;
  int s1;
  int s2;
  int s3;
};
/**
 * Compute a 3D tensor index from a flattened index. The most packed dimension
 * in memory is assumed to be the last one (i.e. the dimension with size_2
 * elements), while the size of the least packed dimension is not needed for the
 * calculation.
 */
template <typename Index, bool use_fast_div>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex3D unflatten3d(
    Index index, typename fast_div::index_div<Index, use_fast_div>::type div_size_1,
    Index size_1, typename fast_div::index_div<Index, use_fast_div>::type div_size_2,
    Index size_2) {
  const Index s012_idx = index;

  const Index s01_idx = s012_idx / div_size_2;
  const Index s2 = s012_idx - s012_idx * size_2;
  const Index s0 = s01_idx / div_size_1;
  const Index s1 = s01_idx - s0 * size_1;

  TensorIndex3D result{s0, s1, s2};
  return result;
}
template <>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex3D unflatten3d<int, false>(
    int index, typename fast_div::index_div<int, false>::type /*div_size_1*/, int size_1,
    typename fast_div::index_div<int, false>::type /*div_size_2*/, int size_2) {
  const int s012_idx = index;

  const int s01_idx = s012_idx / size_2;
  const int s2 = s012_idx % size_2;
  const int s0 = s01_idx / size_1;
  const int s1 = s01_idx % size_1;

  TensorIndex3D result{s0, s1, s2};
  return result;
}
/**
 * A 4D tensor index. The most packed index is s3, with s0 the least packed.
 */
struct TensorIndex4D {
  int s0;
  int s1;
  int s2;
  int s3;
};
/**
 * Compute a 4D tensor index from a flattened index. The most packed dimension
 * in memory is assumed to be the last one (i.e. the dimension with size_3
 * elements), while the size of the least packed dimension is not needed for the
 * calculation.
 */
template <typename Index, bool use_fast_div>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex4D unflatten4d(
    Index index, typename fast_div::index_div<Index, use_fast_div>::type div_size_1,
    Index size_1, typename fast_div::index_div<Index, use_fast_div>::type div_size_2,
    Index size_2, typename fast_div::index_div<Index, use_fast_div>::type div_size_3,
    Index size_3) {
  const Index s0123_idx = index;

  const Index s012_idx = s0123_idx / div_size_3;
  const Index s3 = s0123_idx - s012_idx * size_3;
  const Index s01_idx = s012_idx / div_size_2;
  const Index s2 = s012_idx - s012_idx * size_2;
  const Index s0 = s01_idx / div_size_1;
  const Index s1 = s01_idx - s0 * size_1;

  TensorIndex4D result{s0, s1, s2, s3};
  return result;
}
template <>
inline TF_ATTRIBUTE_ALWAYS_INLINE TensorIndex4D unflatten4d<int, false>(
    int index, typename fast_div::index_div<int, false>::type /*div_size_1*/, int size_1,
    typename fast_div::index_div<int, false>::type /*div_size_2*/, int size_2,
    typename fast_div::index_div<int, false>::type /*div_size_3*/, int size_3) {
  const int s0123_idx = index;

  const int s012_idx = s0123_idx / size_3;
  const int s3 = s0123_idx % size_3;
  const int s01_idx = s012_idx / size_2;
  const int s2 = s012_idx % size_2;
  const int s0 = s01_idx / size_1;
  const int s1 = s01_idx % size_1;

  TensorIndex4D result{s0, s1, s2, s3};
  return result;
}
}  // namespace helpers
}  // namespace tensorflow
#endif  // TENSORFLOW_KERNELS_CONV_OPS_SYCL_KERNEL_HELPERS_H_
