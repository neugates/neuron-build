#!/bin/bash

set -e

#x86_64-neuron-linux-musl
home=/home/neuron
vendor=?
arch=?
gcc=?
gxx=?
install_dir=?
cross=false

while getopts ":a:v:c" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        v)
            vendor=$OPTARG
            ;;
        c)
            cross=true
            ;;
    esac
done

case $cross in
    (true)  
        gcc=$vendor-gcc;
        gxx=$vendor-g++;;
    (false) 
        gcc=$home/buildroot/$vendor/output/host/bin/$vendor-gcc;
        gxx=$home/buildroot/$vendor/output/host/bin/$vendor-g++;;
esac

install_dir=$home/libs/$vendor/
library=$home/library/$vendor/

echo "arch: "$arch
echo "vendor: "$vendor
echo "gcc: "$gcc
echo "g++: "$gxx
echo "install dir: "$install_dir
echo "library dir: "$library

if [ $vendor == ? ];then
    echo "need input vendor"
    exit 1
fi

if [ $arch == ? ];then
    echo "need input arch"
    exit 1
fi

# $1 repo
# $2 name
# $3 cmake option
function compile_source() {
    cd $library
    git clone https://github.com/$1
    cd $2
    mkdir build && cd build
    cmake .. -DCMAKE_C_COMPILER=$gcc \
        -DCMAKE_CXX_COMPILER=$gxx \
        -DCMAKE_STAGING_PREFIX=$install_dir \
        -DCMAKE_PREFIX_PATH=$install_dir \
        $3
    # github-hosted runners has 2 core
    make -j4 && make install
}

# $1 repo
# $2 name
# $3 tag
# $4 cmake option
function compile_source_with_tag() {
    cd $library
    git clone -b $3 https://github.com/$1 $2
    cd $2
    mkdir build && cd build
    cmake .. -DCMAKE_C_COMPILER=$gcc \
        -DCMAKE_CXX_COMPILER=$gxx \
        -DCMAKE_STAGING_PREFIX=$install_dir \
        -DCMAKE_PREFIX_PATH=$install_dir \
        $4
    # github-hosted runners has 2 core
    make -j4 && make install
}

function build_openssl() {
    echo "Installing openssl (1.1.1)"
    case $cross in
        (true)  
            compile_prefix=$vendor-;;
        (false) 
            compile_prefix=$home/buildroot/$vendor/output/host/bin/$vendor-;;
    esac
    cd $library
    git clone -b OpenSSL_1_1_1 https://github.com/openssl/openssl.git
    cd openssl
    mkdir -p $install_dir/openssl/ssl
    ./Configure linux-$arch no-asm no-async shared \
        --prefix=$install_dir \
        --openssldir=$install_dir/openssl/ssl \
        --cross-compile-prefix=$compile_prefix
    make clean
    make -j4
    make install_sw
    make clean
}

function build_zlog() {
    cd $library
    git clone -b 1.2.15 https://github.com/HardySimpson/zlog.git
    cd zlog
    make CC=$gcc
    make PREFIX=$install_dir install
}

function build_sqlite3() {
    cd $library
    curl https://www.sqlite.org/2022/sqlite-autoconf-3390000.tar.gz \
      --output sqlite3.tar.gz
    mkdir -p sqlite3
    tar xzf sqlite3.tar.gz --strip-components=1 -C sqlite3
    cd sqlite3

    ./configure --prefix=$install_dir \
                --disable-shared --disable-readline \
                --host $arch CC=$gcc  CFLAGS=-fPIC

    make -j4
    make install
}

function build_protobuf() {
    cd $library
    wget --no-check-certificate --content-disposition https://github.com/protocolbuffers/protobuf/releases/download/v3.20.1/protobuf-cpp-3.20.1.tar.gz
    tar -xzvf protobuf-cpp-3.20.1.tar.gz
    cd protobuf-3.20.1

    ./configure --prefix=$install_dir CC=$gcc --host=$vendor --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC

    make -j4
    make install
}

function build_protobuf-c(){
    cd $library
    git clone -b v1.4.0 https://github.com/protobuf-c/protobuf-c.git
    cd protobuf-c
    ./autogen.sh

    ./configure --prefix=$install_dir CC=$gcc --host=$vendor --disable-protoc --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC PKG_CONFIG_PATH=$vendor

    make -j4
    make install
}

sudo rm -rf $library
sudo rm -rf $install_dir
mkdir -p $library
mkdir -p $install_dir/bin
mkdir -p $install_dir/include
mkdir -p $install_dir/lib

build_zlog
build_openssl 
build_sqlite3
build_protobuf
build_protobuf-c

compile_source neugates/jansson.git jansson "-DJANSSON_BUILD_DOCS=OFF -DJANSSON_EXAMPLES=OFF"
compile_source_with_tag google/googletest.git googletest release-1.11.0
compile_source_with_tag benmcollins/libjwt.git libjwt v1.13.1 "-DENABLE_PIC=ON -DBUILD_SHARED_LIBS=OFF"
compile_source_with_tag ARMmbed/mbedtls.git mbedtls v2.16.12 "-DCMAKE_BUILD_TYPE=Release -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DENABLE_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
compile_source_with_tag neugates/open62541.git open62541 neuron "-DBUILD_SHARED_LIBS=OFF -DUA_ENABLE_AMALGAMATION=ON -DUA_ENABLE_ENCRYPTION=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DUA_LOGLEVEL=100"
compile_source_with_tag neugates/NanoSDK.git NanoSDK neuron "-DBUILD_SHARED_LIBS=OFF -DNNG_TESTS=OFF -DNNG_ENABLE_SQLITE=ON -DNNG_ENABLE_TLS=ON"