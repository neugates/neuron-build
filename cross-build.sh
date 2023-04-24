#!/bin/bash

set -e

home=/home/neuron
library=$home/libs
vendor=?
arch=?
branch=?
cross=false
user=emqx

while getopts ":a:v:b:c:u:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        v)
            vendor=$OPTARG
            ;;
        b)
            branch=$OPTARG
            ;;
        c)
            cross=$OPTARG
            ;;
        u)
            user=$OPTARG
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

function compile_source_with_tag() {
    local user=$1
    local repo=$2
    local branch=$3

    cd $neuron_dir
    git clone -b $branch git@github.com:${user}/${repo}.git
    cd $repo
    git submodule update --init
    mkdir build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DDISABLE_UT=ON \
	-DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
	-DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
	-DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake

    make -j4 

    if [ $repo == "neuron" ]; then
    	sudo make install
    fi
}

sudo rm -rf $neuron_dir/*
mkdir -p $neuron_dir
compile_source_with_tag $user neuron $branch
compile_source_with_tag $user neuron-modules $branch
