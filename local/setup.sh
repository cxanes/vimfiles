#!/usr/bin/env bash

set -o nounset    # error when referencing undefined variable
set -o errexit    # exit when command fails

ROOT="$PWD"

export PATH="$ROOT/bin:$PATH"

# Install latest nodejs
# https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#automation-script
#if [ ! -x "$(command -v node)" ]; then
    curl --fail -LSs https://install-node.now.sh/latest | bash -s -- -P "$ROOT" -f
    # Or use apt-get
    # sudo apt-get install nodejs
#fi

PACKAGES="$ROOT/packages"
LLVM=clang+llvm-8.0.0-x86_64-linux-gnu-ubuntu-18.04
LLVM_RESOURCE=lib/clang/8.0.0

# Install ccls
# https://github.com/MaskRay/ccls/wiki/Build
#if [ ! -x "$(command -v ccls)" ]; then
    if [ ! -d "$PACKAGES/ccls" ]; then
        mkdir -p "$PACKAGES" && pushd "$PACKAGES"
        git clone --depth=1 --recursive https://github.com/MaskRay/ccls
        cd ccls
        echo "Download LLVM binary..."
        wget -cqO- http://releases.llvm.org/8.0.0/$LLVM.tar.xz | tar xJf -
        cmake -H. -BRelease -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$PWD/$LLVM
        cmake --build Release -- -j8 && mkdir -p "$ROOT/bin" && cp Release/ccls "$ROOT/bin"
        # https://github.com/MaskRay/ccls/wiki/Install#clang-resource-directory
        mkdir -p $ROOT/$LLVM_RESOURCE && cp -R $LLVM/$LLVM_RESOURCE/include $ROOT/$LLVM_RESOURCE
        popd
    else
        pushd "$PACKAGES/ccls"
        git pull --recurse-submodule=yes
        cmake --build Release -- -j8 && cp Release/ccls "$ROOT/bin"
        popd
    fi
#fi
