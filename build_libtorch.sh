#!/usr/bin/env bash

set -xe pipefail

SRC_ROOT="$( cd "$(dirname "$0")" ; pwd -P)"
PYTORCH_ROOT=${PYTORCH_ROOT:-$SRC_ROOT/pytorch}
PYTORCH_BUILD_VERSION="1.6.0"
LIBTORCH_VARIANT="shared-without-deps"

if [[ "$LIBTORCH_VARIANT" == *"cxx11-abi"* ]]; then
  export _GLIBCXX_USE_CXX11_ABI=1
else
  export _GLIBCXX_USE_CXX11_ABI=0
fi

retry () {
  $* || (sleep 1 && $*) || (sleep 2 && $*) || (sleep 4 && $*) || (sleep 8 && $*)
}

install_deps() {
  sudo apt install -y build-essential cmake ninja-build zip
  sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 100
  sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 100
}


install_blas() {
  sudo apt install -y libopenblas-dev
}

install_ccache() {
  sudo apt install -y ccache
  export PATH="/usr/lib/ccache:$PATH"
}

checkout_pytorch() {
  if [[ ! -d "$PYTORCH_ROOT" ]]; then
    git clone https://github.com/pytorch/pytorch $PYTORCH_ROOT
  fi
  cd $PYTORCH_ROOT
  if ! git checkout v${PYTORCH_BUILD_VERSION}; then
    git checkout tags/v${PYTORCH_BUILD_VERSION}
  fi
  git submodule update --init --recursive
}

install_requirements() {
  retry pip install -qr $PYTORCH_ROOT/requirements.txt
}

build_pytorch() {
  cd $PYTORCH_ROOT
  python setup.py clean

  if [[ $LIBTORCH_VARIANT = *"static"* ]]; then
    STATIC_CMAKE_FLAG="-DTORCH_STATIC=1"
  fi
  time CMAKE_ARGS=${CMAKE_ARGS[@]} \
  EXTRA_CAFFE2_CMAKE_FLAGS="${EXTRA_CAFFE2_CMAKE_FLAGS[@]} $STATIC_CMAKE_FLAG" \

  python setup.py install --user
}

pack_libtorch() {
  cd $PYTORCH_ROOT

  rm -rf libtorch
  mkdir -p libtorch/{lib,bin,include,share}

  # Copy over all lib files
  cp -rv build/lib/*                libtorch/lib/
  cp -rv build/lib*/torch/lib/*     libtorch/lib/

  # Copy over all include files
  cp -rv build/include/*            libtorch/include/
  cp -rv build/lib*/torch/include/* libtorch/include/

  # Copy over all of the cmake files
  cp -rv build/lib*/torch/share/*   libtorch/share/

  echo "${PYTORCH_BUILD_VERSION}" > libtorch/build-version
  echo "$(cd $PYTORCH_ROOT && git rev-parse HEAD)" > libtorch/build-hash

  PACKAGE_NAME=libtorch-rpi-$LIBTORCH_VARIANT-$PYTORCH_BUILD_VERSION.zip
  zip -rq $SRC_ROOT/$PACKAGE_NAME libtorch
  cd $SRC_ROOT
  sha256sum $PACKAGE_NAME > $PACKAGE_NAME.sha256
}

build_wheel() {
  cd $PYTORCH_ROOT
  python setup.py bdist_wheel

  cd $PYTORCH_ROOT/dist
  for file in *.whl; do
    cp $file $SRC_ROOT
    sha256sum $file > $SRC_ROOT/$file.sha256
  done
}

install_deps
install_blas
install_ccache
checkout_pytorch
install_requirements

build_pytorch
pack_libtorch

build_wheel
