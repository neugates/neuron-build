#!/bin/bash

set -e

home=/home/neuron
library=$home/libs
neuron_repo=emqx/neuron.git
module_repo=emqx/neuron-module.git
vendor=?
arch=?
branch=?
cross=false

while getopts ":a:v:m:n:b:c:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        v)
            vendor=$OPTARG
            ;;
        m)
            module_repo=$OPTARG
            ;;
        n)
            neuron_repo=$OPTARG
            ;;
        b)
            branch=$OPTARG
            ;;
        c)
            cross=$OPTARG
            ;;
    esac
done

neuron_dir=$home/Program/$vendor

case $cross in
    (true)
        tool_dir=/usr/bin;;
    (false)
        tool_dir=$home/buildroot/$vendor/output/host/bin;;
esac

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
compile_source_with_tag $neuron_repo neuron $branch
compile_source_with_tag $module_repo neuron-modules $branch
