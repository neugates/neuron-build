#!/bin/bash

set -e

home=/home/neuron
library=$home/libs
vendor=?
arch=?

while getopts ":a:v:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        v)
            vendor=$OPTARG
            ;;
    esac
done

neuron_dir=$home/Program/$vendor
tool_dir=$home/buildroot/$vendor/output/host/bin

# $1 repo
# $2 name
# $3 tag
function compile_source_with_tag() {
    cd $neuron_dir
    git clone -b $3 git@github.com:$1
    cd $2
    git submodule update --init
    mkdir build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DDISABLE_UT=ON \
	-DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
	-DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
	-DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake

    make -j4 

    if [ $2 == "neuron" ]; then
    	sudo make install
    fi
}

sudo rm -rf $neuron_dir/*
mkdir -p $neuron_dir
compile_source_with_tag emqx/neuron.git neuron main
compile_source_with_tag emqx/neuron-modules.git neuron-modules main