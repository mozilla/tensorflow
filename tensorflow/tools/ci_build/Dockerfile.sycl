FROM ubuntu:16.04

LABEL maintainer="Luke Iwanski <luke@codeplay.com>"

# Copy and run the install scripts.
COPY install/*.sh /install/
RUN /install/install_bootstrap_deb_packages.sh
RUN add-apt-repository -y ppa:openjdk-r/ppa && \
    add-apt-repository -y ppa:george-edison55/cmake-3.x
RUN /install/install_deb_packages.sh
RUN /install/install_pip_packages.sh

# Install bazel
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
RUN curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -

RUN apt-get update && apt-get install bazel -y

#RUN /install/install_golang.sh

RUN apt-get install ocl-icd-opencl-dev opencl-headers -y
RUN /install/install_sycl.sh

# Set up the master bazelrc configuration file.
COPY install/.bazelrc /etc/bazel.bazelrc

ENV LD_LIBRARY_PATH /usr/local/computecpp/lib:$LD_LIBRARY_PATH

# Configure the build for SYCL configuration.
ENV HOST_CXX_COMPILER /usr/bin/g++
ENV HOST_C_COMPILER /usr/bin/gcc
ENV TF_NEED_OPENCL_SYCL 1
ENV TF_NEED_COMPUTECPP 1
