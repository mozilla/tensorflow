#ifndef TENSORFLOW_USE_SYCL
#error This file should only be included when compiling with SYCL support
#endif

#ifndef TENSORFLOW_KERNELS_CONV_OPS_DIRECT_TILED_SYCL_KERNELS_H_
#define TENSORFLOW_KERNELS_CONV_OPS_DIRECT_TILED_SYCL_KERNELS_H_

#include "third_party/eigen3/unsupported/Eigen/CXX11/Tensor"

#include "tensorflow/core/kernels/conv_ops_sycl_common.h"
#include "tensorflow/core/kernels/conv_ops_sycl_fast_div.h"
#include "tensorflow/core/kernels/conv_ops_sycl_kernel_helpers.h"
#include "tensorflow/core/kernels/conv_ops_sycl_param_macros.h"

namespace tensorflow {
typedef Eigen::SyclDevice SYCLDevice;
namespace direct_tiled {
struct check_bounds_tag {};
template <typename T, int width>
struct InputRow {
  using Index = int;
  template <typename _T>
  inline TF_ATTRIBUTE_ALWAYS_INLINE InputRow(
      _T const* input, Index const row, Index const n_rows, Index const col,
      Index const n_cols, Index const channel, Index const n_channels) {
    for (int i = 0; i < width; ++i) {
      Index const idx = (row * n_cols + col + i) * n_channels + channel;
      data[i] = input[idx];
    }
  }
  template <typename _T>
  inline TF_ATTRIBUTE_ALWAYS_INLINE InputRow(
      _T const* input, Index const row, Index const n_rows, Index const col,
      Index const n_cols, Index const channel, Index const n_channels,
      check_bounds_tag) {
    for (int i = 0; i < width; ++i) {
      Index const idx = (row * n_cols + col + i) * n_channels + channel;
      data[i] =
          (col + i < 0 || col + i >= n_cols) ? static_cast<_T>(0) : input[idx];
    }
  }
  T data[width];
};
template <typename T, int window_rows, int window_cols>
struct FilterTile {
  using Index = int;
  template <typename _T>
  inline TF_ATTRIBUTE_ALWAYS_INLINE FilterTile(_T const* const input,
                                               Index const channel,
                                               Index const n_channels,
                                               Index const feature,
                                               Index const n_features) {
    for (int i = 0; i < window_rows; ++i) {
      for (int j = 0; j < window_cols; ++j) {
        Index const idx =
            ((i * window_cols + j) * n_channels + channel) * n_features +
            feature;
        data[i][j] = input[idx];
      }
    }
  }
  T data[window_rows][window_cols];
};
template <typename T, int n_out_rows, int n_out_cols>
struct OutputTile {
  using Index = int;
  template <typename _T>
  inline TF_ATTRIBUTE_ALWAYS_INLINE void write_out(
      _T* output, Index const batch, Index const out_row, Index const n_rows,
      Index const out_col, Index const n_cols, Index const feature,
      Index const n_features) {
    Index const offset =
        ((batch * n_rows + out_row) * n_cols + out_col) * n_features + feature;
    output += offset;
    Index const max_row = cl::sycl::min(n_out_rows, n_rows - out_row);
    Index const max_col = cl::sycl::min(n_out_cols, n_cols - out_col);
    for (Index tile_row = 0; tile_row < max_row; ++tile_row) {
      for (Index tile_col = 0; tile_col < max_col; ++tile_col) {
        Index const idx = (tile_row * n_cols + tile_col) * n_features;
        output[idx] = data[tile_row][tile_col];
      }
    }
  }
  T data[n_out_rows][n_out_cols];
};
template <typename T, int n_window_rows, int n_window_cols, int n_out_rows,
          int n_out_cols>
inline TF_ATTRIBUTE_ALWAYS_INLINE void convolve_1xw_one_row(
    InputRow<T, n_out_cols + n_window_rows - 1> const& input,
    FilterTile<T, n_window_rows, n_window_cols> const& filter,
    OutputTile<T, n_out_rows, n_out_cols>& output, int const out_row,
    int const filter_row) {
  for (int out_col = 0; out_col < n_out_cols; ++out_col) {
    int const in_offset = out_col;
    for (int filter_col = 0; filter_col < n_window_cols; ++filter_col) {
      output.data[out_row][out_col] = cl::sycl::mad(
          input.data[in_offset + filter_col],
          filter.data[filter_row][filter_col], output.data[out_row][out_col]);
    }
  }
}
template <typename T, int n_window_rows, int n_window_cols, int n_out_rows,
          int n_out_cols>
inline TF_ATTRIBUTE_ALWAYS_INLINE void convolve_1xw_whole_tile(
    InputRow<T, n_out_cols + n_window_rows - 1> const& input,
    FilterTile<T, n_window_rows, n_window_cols> const& filter,
    OutputTile<T, n_out_rows, n_out_cols>& output, int const row_idx) {
  for (int out_row = 0; out_row < n_out_rows; ++out_row) {
    int filter_row = row_idx - out_row;
    if (filter_row >= 0 && filter_row < n_window_rows) {
      convolve_1xw_one_row(input, filter, output, out_row, filter_row);
    }
  }
}
/**
 * SYCL kernel for naive convolution computation.
 */
template <typename T, ConvType CType, int tile_rows, int tile_cols,
          bool use_fast_div, int window_rows, int window_cols,
          int static_stride = 0>
struct Conv2DTiledSYCL {
  using Index = int;
  using buffer_data = uint8_t;
  using index_div_type =
      typename fast_div::index_div<Index, use_fast_div>::type;
  static constexpr auto input_tile_width = tile_cols + window_cols - 1;
  static constexpr auto read_mode = cl::sycl::access::mode::read;
  static constexpr auto write_mode = cl::sycl::access::mode::discard_write;
  static constexpr auto global_access = cl::sycl::access::target::global_buffer;
  using write_accessor =
      cl::sycl::accessor<buffer_data, 1, write_mode, global_access>;
  using read_accessor =
      cl::sycl::accessor<buffer_data, 1, read_mode, global_access>;
  Conv2DTiledSYCL(Index n_elems, const SYCLConv2DParams& params,
                  const read_accessor input, const read_accessor kernel,
                  write_accessor output) {}
  inline TF_ATTRIBUTE_ALWAYS_INLINE void operator()(cl::sycl::item<1> item) {}
};
template <typename T, int tile_rows, int tile_cols, bool use_fast_div,
          int window_rows, int window_cols, int static_stride>
struct Conv2DTiledSYCL<T, ConvType::Forward, tile_rows, tile_cols, use_fast_div,
                       window_rows, window_cols, static_stride> {
  using Index = int;
  using buffer_data = uint8_t;
  using index_div_type =
      typename fast_div::index_div<Index, use_fast_div>::type;
  static constexpr auto input_tile_width = tile_cols + window_cols - 1;
  static constexpr auto read_mode = cl::sycl::access::mode::read;
  static constexpr auto write_mode = cl::sycl::access::mode::discard_write;
  static constexpr auto global_access = cl::sycl::access::target::global_buffer;
  using write_accessor =
      cl::sycl::accessor<buffer_data, 1, write_mode, global_access>;
  using read_accessor =
      cl::sycl::accessor<buffer_data, 1, read_mode, global_access>;

  inline TF_ATTRIBUTE_ALWAYS_INLINE Conv2DTiledSYCL(
      Index n_elems, const SYCLConv2DParams& params, const read_accessor input,
      const read_accessor kernel, write_accessor output)
      : n_elems_{n_elems},
        div_features_{params.features_},
        n_tile_cols_{RoundRatioUpAboveZero(params.out_cols_, tile_cols)},
        n_tile_rows_{RoundRatioUpAboveZero(params.out_rows_, tile_rows)},
        div_n_tile_cols_{RoundRatioUpAboveZero(params.out_cols_, tile_cols)},
        div_n_tile_rows_{RoundRatioUpAboveZero(params.out_rows_, tile_rows)},
        SNN_CONSTRUCT_CONV_PARAMS(params),
        input_accessor_{input},
        kernel_accessor_{kernel},
        output_accessor_{output} {}

  inline TF_ATTRIBUTE_ALWAYS_INLINE void operator()(cl::sycl::item<1> item) {
    const Index index = item.get_id(0);

    if (index < n_elems_) {
      const T* input_data = ConvertToActualTypeSycl(T, input_accessor_);
      const T* kernel_data = ConvertToActualTypeSycl(T, kernel_accessor_);
      T* output_data = ConvertToActualTypeSycl(T, output_accessor_);

      const helpers::TensorIndex4D tensor_idx =
          helpers::unflatten4d<Index, use_fast_div>(
              index, div_n_tile_rows_, n_tile_rows_, div_n_tile_cols_,
              n_tile_cols_, div_features_, SNN_PARAM(features_));
      const Index feature = tensor_idx.s3;
      const Index col_idx = tensor_idx.s2;
      const Index row_idx = tensor_idx.s1;
      const Index batch = tensor_idx.s0;

      const Index cstart =
          col_idx * tile_cols * SNN_STATIC_PARAM(stride, cols_) -
          SNN_PARAM(pad_cols_);
      const Index rstart =
          row_idx * tile_rows * SNN_STATIC_PARAM(stride, rows_) -
          SNN_PARAM(pad_rows_);

      OutputTile<T, tile_rows, tile_cols> out_tile{};
      const T* input_data_n = input_data +
                              batch * SNN_PARAM(in_cols_) *
                                  SNN_PARAM(in_rows_) * SNN_PARAM(channels_);
      for (Index channel = 0; channel < SNN_PARAM(channels_); ++channel) {
        FilterTile<T, window_rows, window_cols> filter_tile{
            kernel_data, channel, SNN_PARAM(channels_), feature,
            SNN_PARAM(features_)};
        for (Index r = rstart, i = 0;
             i < window_rows + tile_rows - 1 && r < SNN_PARAM(in_rows_);
             ++r, ++i) {
          if (r >= 0) {
            InputRow<T, input_tile_width> input_tile{
                input_data_n,         r,
                SNN_PARAM(in_rows_),  cstart,
                SNN_PARAM(in_cols_),  channel,
                SNN_PARAM(channels_), check_bounds_tag{}};
            convolve_1xw_whole_tile(input_tile, filter_tile, out_tile, i);
          }
        }
      }
      out_tile.write_out(output_data, batch, row_idx * tile_rows,
                         SNN_PARAM(out_rows_), col_idx * tile_cols,
                         SNN_PARAM(out_cols_), feature, SNN_PARAM(features_));
    }
  }

 private:
  const Index n_elems_;
  const index_div_type div_features_;
  const Index n_tile_cols_;
  const Index n_tile_rows_;
  const index_div_type div_n_tile_cols_;
  const index_div_type div_n_tile_rows_;
  SNN_INJECT_CONV_PARAMS;
  const read_accessor input_accessor_;
  const read_accessor kernel_accessor_;
  write_accessor output_accessor_;
};
#if 0
template <typename T, bool use_fast_div, int static_window, int static_stride>
struct Conv2DSYCL<T, ConvType::InputBackprop, use_fast_div, static_window,
                  static_stride> {
  using Index = int;
  using buffer_data = uint8_t;
  using index_div_type =
      typename fast_div::index_div<Index, use_fast_div>::type;
  static constexpr auto read_mode = cl::sycl::access::mode::read;
  static constexpr auto write_mode = cl::sycl::access::mode::discard_write;
  static constexpr auto global_access = cl::sycl::access::target::global_buffer;
  using write_accessor =
      cl::sycl::accessor<buffer_data, 1, write_mode, global_access>;
  using read_accessor =
      cl::sycl::accessor<buffer_data, 1, read_mode, global_access>;

  inline TF_ATTRIBUTE_ALWAYS_INLINE Conv2DSYCL(Index n_elems,
                                               const SYCLConv2DParams& params,
                                               const read_accessor input,
                                               const read_accessor kernel,
                                               write_accessor output)
      : n_elems_{n_elems},
        div_features_{params.features_},
        div_in_rows_{params.in_rows_},
        div_in_cols_{params.in_cols_},
        SNN_CONSTRUCT_CONV_PARAMS(params),
        input_accessor_{input},
        kernel_accessor_{kernel},
        output_accessor_{output} {}

  inline TF_ATTRIBUTE_ALWAYS_INLINE void operator()(cl::sycl::item<1> item) {
    const Index index = item.get_id(0);
    if (index < n_elems_) {
      const T* input_data = ConvertToActualTypeSycl(T, input_accessor_);
      const T* kernel_data = ConvertToActualTypeSycl(T, kernel_accessor_);
      T* output_data = ConvertToActualTypeSycl(T, output_accessor_);

      const Index tile_idx = index / div_features_;
      const Index feature = index - tile_idx * SNN_PARAM(features_);

      const Index brc_idx = tile_idx;
      const Index br_idx = brc_idx / div_in_cols_;
      const Index col_idx = brc_idx - br_idx * SNN_PARAM(in_cols_);
      // c is the index in the padded output tensor (ie with lots of extra
      // zeros), but without the first padding. first_padded_c adds this extra
      // padding.
      const Index c = col_idx + SNN_PARAM(pad_cols_);
      const Index first_padded_c = c - SNN_STATIC_PARAM(window, cols_) + 1;
      // The first and last output indices affected by this input.
      const Index last_used_c = c / SNN_STATIC_PARAM(stride, cols_);
      const Index first_used_c = RoundRatioUpAboveZero(
          first_padded_c, SNN_STATIC_PARAM(stride, cols_));

      const Index firstc =
          first_used_c * SNN_STATIC_PARAM(stride, cols_) - first_padded_c;
      const Index cstart = cl::sycl::max(first_used_c, static_cast<Index>(0));
      const Index cend = cl::sycl::min(last_used_c + 1, SNN_PARAM(out_cols_));

      const Index batch = br_idx / div_in_rows_;
      const Index row_idx = br_idx - batch * SNN_PARAM(in_rows_);
      const Index r = row_idx + SNN_PARAM(pad_rows_);
      const Index last_used_r = r / SNN_STATIC_PARAM(stride, rows_);
      const Index first_padded_r = r - SNN_STATIC_PARAM(window, rows_) + 1;
      const Index first_used_r = RoundRatioUpAboveZero(
          first_padded_r, SNN_STATIC_PARAM(stride, rows_));

      const Index firstr =
          first_used_r * SNN_STATIC_PARAM(stride, rows_) - first_padded_r;
      const Index rstart = cl::sycl::max(first_used_r, static_cast<Index>(0));
      const Index rend = cl::sycl::min(last_used_r + 1, SNN_PARAM(out_rows_));

      T out_val = static_cast<T>(0);
      const T* input_data_n = input_data +
                              batch * SNN_PARAM(out_cols_) *
                                  SNN_PARAM(out_rows_) * SNN_PARAM(channels_);
      for (Index r = rstart, i = firstr; r < rend;
           ++r, i += SNN_STATIC_PARAM(stride, rows_)) {
        for (Index c = cstart, j = firstc; c < cend;
             ++c, j += SNN_STATIC_PARAM(stride, cols_)) {
          for (Index channel = 0; channel < SNN_PARAM(channels_); ++channel) {
            const Index idx =
                (r * SNN_PARAM(out_cols_) + c) * SNN_PARAM(channels_) + channel;
            const Index mirrored_row = SNN_STATIC_PARAM(window, rows_) - i - 1;
            const Index mirrored_col = SNN_STATIC_PARAM(window, cols_) - j - 1;
            const Index k_idx =
                ((mirrored_row * SNN_STATIC_PARAM(window, cols_) +
                  mirrored_col) *
                     SNN_PARAM(features_) +
                 feature) *
                    SNN_PARAM(channels_) +
                channel;
            out_val += input_data_n[idx] * kernel_data[k_idx];
          }
        }
      }
      output_data[index] = out_val;
    }
  }

 private:
  const Index n_elems_;
  const index_div_type div_features_;
  const index_div_type div_in_rows_;
  const index_div_type div_in_cols_;
  SNN_INJECT_CONV_PARAMS;
  const read_accessor input_accessor_;
  const read_accessor kernel_accessor_;
  write_accessor output_accessor_;
};
/*
 * The main difference between the two backprop kernels is the way strides are
 * handled. In the filter backprop the input is strided and the kernel is not
 * whereas in the input backprop this is the other way around.
 *
 * For the filter backprop we are convolving the input with the output as the
 * filter. This means that the static window sizes are actually the
 * params.out_rows_ and params.out_cols_ rather than the params.window_*.
 */
template <typename T, bool use_fast_div, int static_out, int static_stride>
struct Conv2DSYCL<T, ConvType::FilterBackprop, use_fast_div, static_out,
                  static_stride> {
  using Index = int;
  using buffer_data = uint8_t;
  using index_div_type =
      typename fast_div::index_div<Index, use_fast_div>::type;
  static constexpr auto read_mode = cl::sycl::access::mode::read;
  static constexpr auto write_mode = cl::sycl::access::mode::discard_write;
  static constexpr auto global_access = cl::sycl::access::target::global_buffer;
  using write_accessor =
      cl::sycl::accessor<buffer_data, 1, write_mode, global_access>;
  using read_accessor =
      cl::sycl::accessor<buffer_data, 1, read_mode, global_access>;

  inline TF_ATTRIBUTE_ALWAYS_INLINE Conv2DSYCL(Index n_elems,
                                               const SYCLConv2DParams& params,
                                               const read_accessor input,
                                               const read_accessor kernel,
                                               write_accessor output)
      : n_elems_{n_elems},
        div_features_{params.features_},
        div_channels_{params.channels_},
        div_out_cols_{params.out_cols_},
        SNN_CONSTRUCT_CONV_PARAMS(params),
        input_accessor_{input},
        kernel_accessor_{kernel},
        output_accessor_{output} {}

  inline TF_ATTRIBUTE_ALWAYS_INLINE void operator()(cl::sycl::item<1> item) {
    const Index index = item.get_id(0);
    if (index < n_elems_) {
      const T* input_data = ConvertToActualTypeSycl(T, input_accessor_);
      const T* kernel_data = ConvertToActualTypeSycl(T, kernel_accessor_);
      T* output_data = ConvertToActualTypeSycl(T, output_accessor_);

      const Index hwcf_idx = index;
      const Index hwc_idx = hwcf_idx / div_features_;
      const Index feature = hwcf_idx - hwc_idx * SNN_PARAM(features_);
      const Index hw_idx = hwc_idx / div_channels_;
      const Index channel = hwc_idx - hw_idx * SNN_PARAM(channels_);

      const Index row_idx = hw_idx / div_out_cols_;
      const Index col_idx = hw_idx - row_idx * SNN_STATIC_PARAM(out, cols_);
      const Index cstart = col_idx - SNN_PARAM(pad_cols_);
      const Index cend =
          cl::sycl::min(cstart + SNN_PARAM(window_cols_), SNN_PARAM(in_cols_));

      const Index rstart = row_idx - SNN_PARAM(pad_rows_);
      const Index rend =
          cl::sycl::min(rstart + SNN_PARAM(window_rows_), SNN_PARAM(in_rows_));

      const Index filter_rows = RoundRatioUpAboveZero(
          SNN_PARAM(window_rows_), SNN_STATIC_PARAM(stride, rows_));
      const Index filter_cols = RoundRatioUpAboveZero(
          SNN_PARAM(window_cols_), SNN_STATIC_PARAM(stride, cols_));

      T out_val = static_cast<T>(0);
      const T* input_data_n = input_data;
      for (Index b = 0; b < SNN_PARAM(batch_); b++) {
        for (Index r = rstart, i = 0; r < rend;
             ++i, r += SNN_STATIC_PARAM(stride, rows_)) {
          if (r >= 0) {
            for (Index c = cstart, j = 0; c < cend;
                 ++j, c += SNN_STATIC_PARAM(stride, cols_)) {
              if (c >= 0) {
                const Index idx =
                    (r * SNN_PARAM(in_cols_) + c) * SNN_PARAM(channels_) +
                    channel;
                const Index k_idx = ((b * filter_rows + i) * filter_cols + j) *
                                        SNN_PARAM(features_) +
                                    feature;
                out_val += input_data_n[idx] * kernel_data[k_idx];
              }
            }
          }
        }
        input_data_n +=
            SNN_PARAM(in_cols_) * SNN_PARAM(in_rows_) * SNN_PARAM(channels_);
      }
      output_data[index] = out_val;
    }
  }

 private:
  const Index n_elems_;
  const index_div_type div_features_;
  const index_div_type div_channels_;
  const index_div_type div_out_cols_;
  SNN_INJECT_CONV_PARAMS;
  const read_accessor input_accessor_;
  const read_accessor kernel_accessor_;
  write_accessor output_accessor_;
};
#endif
}  // namespace direct
}  // namespace tensorflow
#endif  // TENSORFLOW_KERNELS_CONV_OPS_DIRECT_SYCL_KERNELS_H_
