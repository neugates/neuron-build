#!/bin/bash

set -e

home=/home/neuron
bdb=v2.10
library=$home/$bdb/libs
vendor=?
arch=?
branch=?
cross=false
user=emqx
smart=false
clib=glibc
build_type=Release

while getopts ":a:v:b:c:u:s:l:d:" OPT; do
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
        s)
            smart=$OPTARG
            ;;
        l)
            clib=$OPTARG
            ;;
        d)
            build_type=$OPTARG
            ;;
    esac
done

case $build_type in
    (Release)
        neuron_dir=$home/$bdb/Program/$vendor;;
    (Debug)
        neuron_dir=$home/$bdb/Program_Debug/$vendor;; 
esac

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
    cmake .. -DCMAKE_BUILD_TYPE=$build_type -DDISABLE_UT=ON \
	-DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
	-DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
	-DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake

    case $smart in
        (true)
            cmake .. -DSMART_LINK=1 -DCMAKE_BUILD_TYPE=$build_type -DDISABLE_UT=ON \
            -DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
            -DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
            -DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake;;
        (false)
            cmake .. -DCMAKE_BUILD_TYPE=$build_type -DDISABLE_UT=ON \
            -DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
            -DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
            -DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake;;
    esac

    case $clib in
        (glibc)
            ;;
        (*)
            cmake .. -DCMAKE_BUILD_TYPE=$build_type -DDISABLE_UT=ON \
            -DTOOL_DIR=$tool_dir -DCOMPILER_PREFIX=$vendor \
            -DCMAKE_SYSTEM_PROCESSOR=$arch -DLIBRARY_DIR=$library \
            -DCLIB=\'\"$clib\"\' \
            -DCMAKE_TOOLCHAIN_FILE=../cmake/cross.cmake;; 
    esac

    make -j4 

    if [ $repo == "neuron" ]; then
    	sudo make install
    fi
}

sudo rm -rf $neuron_dir/*
mkdir -p $neuron_dir
compile_source_with_tag $user neuron $branch
compile_source_with_tag $user neuron-modules $branch
