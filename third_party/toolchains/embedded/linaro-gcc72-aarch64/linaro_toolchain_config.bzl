# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""A Starlark cc_toolchain configuration rule"""

load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "make_variable",
    "tool",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
)

load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
]

preprocessor_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.clif_match,
]

codegen_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.lto_backend,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

def _impl(ctx):

    abi_version = "aarch64"
    abi_libc_version = "glibc_2.24"
    builtin_sysroot = None
    compiler = "gcc"
    host_system_name = "aarch64"
    needs_pic = True
    supports_gold_linker = False
    supports_incremental_linker = False
    supports_fission = False
    supports_interface_shared_objects = False
    supports_normalizing_ar = False
    supports_start_end_lib = False
    supports_thin_archives = False
    target_libc = "glibc_2.24"
    target_cpu = "armv8"
    target_system_name = "armv8"
    toolchain_identifier = "gcc72_linaro_aarch64"
    cc_target_os = None

    action_configs = []

    supports_pic_feature = feature(name = "supports_pic", enabled = True)
    supports_dynamic_linker_feature = feature(name = "supports_dynamic_linker", enabled = True)

    user_compile_flags_feature = feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

    user_link_flags_feature = feature(
        name = "user_link_flags",
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = ["%{user_link_flags}"],
                        iterate_over = "user_link_flags",
                        expand_if_available = "user_link_flags",
                    ),
                ],
            ),
        ],
    )

    shared_flag_feature = feature(
        name = "shared_flag",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.lto_index_for_dynamic_library,
                    ACTION_NAMES.lto_index_for_nodeps_dynamic_library,
                ],
                flag_groups = [flag_group(flags = ["-shared"])],
            ),
        ],
    )

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

    objcopy_embed_flags_feature = feature(
        name = "objcopy_embed_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ["objcopy_embed_data"],
                flag_groups = [flag_group(flags = ["-I", "binary"])],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name = "unfiltered_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
			    # Make C++ compilation deterministic. Use linkstamping instead of these
			    # compiler symbols.
                            "-Wno-builtin-macro-redefined",
                            "-D__DATE__=\"redacted\"",
                            "-D__TIMESTAMP__=\"redacted\"",
                            "-D__TIME__=\"redacted\"",
                            # This makes GCC and Clang do what we want when called through symlinks.
                            "-no-canonical-prefixes",
                        ],
                    ),
                ],
            ),
        ],
    )

    default_compile_flags_feature = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-U_FORTIFY_SOURCE",
                            "-D_FORTIFY_SOURCE=1",
                            "-fstack-protector",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [flag_group(flags = ["-g"])],
                with_features = [with_feature_set(features = ["dbg"])],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-g0",
                            "-O2",
                            "-DNDEBUG",
                            "-ffunction-sections",
                            "-fdata-sections",
                        ],
                    ),
                ],
                with_features = [with_feature_set(features = ["opt"])],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
			    "-std=c++11",
			    "--sysroot=external/LinaroAarch64Gcc72/aarch64-linux-gnu/libc",
			    "-pthread",
			    "-nostdinc",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/aarch64-linux-gnu/include/c++/7.2.1/aarch64-linux-gnu",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/aarch64-linux-gnu/include/c++/7.2.1",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/lib/gcc/aarch64-linux-gnu/7.2.1/include",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/aarch64-linux-gnu/libc/usr/include",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/lib/gcc/aarch64-linux-gnu/7.2.1/include-fixed",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/aarch64-linux-gnu/libc/usr/include",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/aarch64-linux-gnu/libc/usr/include/aarch64-linux-gnu",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/lib/gcc/aarch64-linux-gnu/7.2.1/include",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/include/c++/7.2.1/aarch64-linux-gnu",
			    "-isystem",
			    "external/LinaroAarch64Gcc72/include/c++/7.2.1",
			    # Security hardening on by default.
			    "-fstack-protector",
			    "-fPIE",
			    # All warnings are enabled. Maybe enable -Werror as well?
			    "-Wall",
			    # Enable a few more warnings that aren't part of -Wall.
			    "-Wunused-but-set-parameter",
			    # But disable some that are problematic.
			    "-Wno-free-nonheap-object", # has false positives
			    # Keep stack frames for debugging, even in opt mode.
			    "-fno-omit-frame-pointer",
			    # Enable coloring even if there's no attached terminal. Bazel removes the
			    # escape sequences if --nocolor is specified.
			    "-fdiagnostics-color=always",
                        ],
                    ),
                ],
            ),
        ],
    )

    default_link_flags_feature = feature(
        name = "default_link_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [
                    flag_group(
                        flags = [
    			    # "-target",
    			    # "aarch64-linux-gnu",
    			    "--sysroot=external/LinaroAarch64Gcc72/aarch64-linux-gnu/libc",
    			    "-pass-exit-codes",
    			    "-pie",
    			    "-lstdc++",
    			    "-lm",
    			    "-lpthread",
    			    "-Wl,--dynamic-linker=/lib/ld-linux-aarch64.so.1",
    			    "-Wl,-no-as-needed",
    			    "-Wl,-z,relro,-z,now",
    			    "-no-canonical-prefixes",
    			    # Stamp the binary with a unique identifier.
    			    "-Wl,--build-id=md5",
    			    "-Wl,--hash-style=gnu",
    			    "-Lexternal/LinaroAarch64Gcc72/aarch64-linux-gnu/lib",
    			    "-Lexternal/LinaroAarch64Gcc72/aarch64-linux-gnu/libc/lib",
    			    "-Lexternal/LinaroAarch64Gcc72/aarch64-linux-gnu/libc/usr/lib",
    			    "-Bexternal/LinaroAarch64Gcc72/aarch64-linux-gnu/bin",
                        ],
                    ),
                ],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = ["-Wl,--gc-sections"])],
                with_features = [with_feature_set(features = ["opt"])],
            ),
        ],
    )

    opt_feature = feature(name = "opt")

    dbg_feature = feature(name = "dbg")

    features = [
	default_compile_flags_feature,
	default_link_flags_feature,
	supports_dynamic_linker_feature,
	supports_pic_feature,
	objcopy_embed_flags_feature,
	opt_feature,
	dbg_feature,
	user_compile_flags_feature,
	user_link_flags_feature,
	shared_flag_feature,
	sysroot_feature,
	unfiltered_compile_flags_feature,
    ]

    cxx_builtin_include_directories = [
        "%package(@LinaroAarch64Gcc72//include)%",
        "%package(@LinaroAarch64Gcc72//aarch64-linux-gnu/libc/usr/include)%",
        "%package(@LinaroAarch64Gcc72//aarch64-linux-gnu/libc/lib/gcc/aarch64-linux-gnu/7.2.1/include-fixed)%",
        "%package(@LinaroAarch64Gcc72//include)%/c++/7.2.1",
        "%package(@LinaroAarch64Gcc72//aarch64-linux-gnu/libc/lib/gcc/aarch64-linux-gnu/7.2.1/include)%",
        "%package(@LinaroAarch64Gcc72//aarch64-linux-gnu/libc/lib/gcc/aarch64-linux-gnu/7.2.1/include-fixed)%",
        "%package(@LinaroAarch64Gcc72//lib/gcc/aarch64-linux-gnu/7.2.1/include)%",
        "%package(@LinaroAarch64Gcc72//lib/gcc/aarch64-linux-gnu/7.2.1/include-fixed)%",
        "%package(@LinaroAarch64Gcc72//aarch64-linux-gnu/include)%/c++/7.2.1",
    ]

    artifact_name_patterns = []
    make_variables = []

    tool_paths = [
        tool_path(name = "ar", path = "gcc/aarch64-linux-gnu-ar"),
        tool_path(name = "compat-ld", path = "gcc/aarch64-linux-gnu-ld"),
        tool_path(name = "cpp", path = "gcc/aarch64-linux-gnu-cpp"),
        tool_path(name = "dwp", path = "gcc/aarch64-linux-gnu-dwp"),
        tool_path(name = "gcc", path = "gcc/aarch64-linux-gnu-gcc"),
        tool_path(name = "gcov", path = "arm-frc-linux-gnueabi/arm-frc-linux-gnueabi-gcov-4.9"),
        # C(++), compiles invoke the compiler (as that is the one knowing where
        # to find libraries),, but we provide LD so other rules can invoke the linker.
        tool_path(name = "ld", path = "gcc/aarch64-linux-gnu-ld"),
        tool_path(name = "nm", path = "gcc/aarch64-linux-gnu-nm"),
        tool_path(name = "objcopy", path = "gcc/aarch64-linux-gnu-objcopy"),
        tool_path(name = "objdump", path = "gcc/aarch64-linux-gnu-objdump"),
        tool_path(name = "strip", path = "gcc/aarch64-linux-gnu-strip"),
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        action_configs = action_configs,
        artifact_name_patterns = artifact_name_patterns,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        toolchain_identifier = toolchain_identifier,
        host_system_name = host_system_name,
        target_system_name = target_system_name,
        target_cpu = target_cpu,
target_libc = target_libc,
compiler = compiler,
        abi_version = abi_version,
        abi_libc_version = abi_libc_version,
        tool_paths = tool_paths,
        make_variables = make_variables,
        builtin_sysroot = builtin_sysroot,
        cc_target_os = cc_target_os,
    )

linaro_toolchain_config = rule(
    implementation = _impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
