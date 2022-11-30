#!/bin/bash

set -e

install_dir=
arch=x86_64
compile=
library=

while getopts ":d:a:c:b:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        b)
            library=$OPTARG
            ;;
        c)
            compile=$OPTARG
            ;;
        d)
            install_dir=$OPTARG
            ;;
    esac
done

gcc_compile=${compile}-gcc
gxx_compile=${compile}-g++

function compile_source() {
    cd $library
    git clone https://github.com/$1
    cd $2
    mkdir build && cd build
    cmake .. -DCMAKE_C_COMPILER=${gcc_compile} \
        -DCMAKE_CXX_COMPILER=${gxx_compile} \
        -DCMAKE_STAGING_PREFIX=${install_dir} \
        -DCMAKE_PREFIX_PATH=${install_dir} \
        $3
    # github-hosted runners has 2 core
    make -j4 && sudo make install
}

function compile_source_with_tag() {
    cd $library
    git clone -b $3 https://github.com/$1 $2
    cd $2
    mkdir build && cd build
    cmake .. -DCMAKE_C_COMPILER=${gcc_compile} \
        -DCMAKE_CXX_COMPILER=${gxx_compile} \
        -DCMAKE_STAGING_PREFIX=${install_dir} \
        -DCMAKE_PREFIX_PATH=${install_dir} \
        $4
    # github-hosted runners has 2 core
    make -j4 && sudo make install
}

function build_openssl() {
    echo "Installing openssl (1.1.1)"
    cd $library
    git clone -b OpenSSL_1_1_1 https://github.com/openssl/openssl.git
    cd openssl
    mkdir -p ${install_dir}/openssl/ssl
    ./Configure linux-${arch} no-asm shared \
        --prefix=${install_dir} \
        --openssldir=${install_dir}/openssl/ssl \
        --cross-compile-prefix=${compile}- 
    make clean
    make -j4
    make install_sw
    make clean
}

function build_zlog() {
    cd $library
    git clone -b 1.2.15 https://github.com/HardySimpson/zlog.git
    cd zlog
    echo ${gcc_compile}
    make CC=${gcc_compile}
    if [ $arch == "x86_64" ]; then
        sudo make install
        sudo make PREFIX=${install_dir} install
    else
        sudo make PREFIX=${install_dir} install
    fi
}

function build_sqlite3() {
    cd $library
    curl https://www.sqlite.org/2022/sqlite-autoconf-3390000.tar.gz \
      --output sqlite3.tar.gz
    mkdir -p sqlite3
    tar xzf sqlite3.tar.gz --strip-components=1 -C sqlite3
    cd sqlite3
    ./configure --prefix=${install_dir} \
                --disable-shared --disable-readline \
                --host ${arch} CC=${gcc_compile} \
      && make -j4 \
      && sudo make install
}

function install_protobuf-c() {
    cd $library
    echo "Install protobuf-c(1.4)"
    git clone https://github.com/neugates/neuron-build.git
    cd neuron-build
    sudo cp -r ${arch}/protobuf-c/include/* ${install_dir}/include/
    sudo cp -r ${arch}/protobuf-c/lib/* ${install_dir}/lib/
    echo "End install protobuf-c(1.4)"
}

build_zlog
build_openssl 
build_sqlite3
install_protobuf-c

compile_source neugates/jansson.git jansson "-DJANSSON_BUILD_DOCS=OFF -DJANSSON_EXAMPLES=OFF"

compile_source_with_tag benmcollins/libjwt.git libjwt v1.13.1 "-DENABLE_PIC=ON -DBUILD_SHARED_LIBS=OFF"
compile_source_with_tag ARMmbed/mbedtls.git mbedtls v2.16.12 "-DCMAKE_BUILD_TYPE=Release -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DENABLE_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
compile_source_with_tag open62541/open62541.git open62541 v1.0.6 "-DBUILD_SHARED_LIBS=OFF -DUA_ENABLE_AMALGAMATION=ON -DUA_ENABLE_ENCRYPTION=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DUA_LOGLEVEL=100"
compile_source_with_tag neugates/NanoSDK.git NanoSDK neuron "-DBUILD_SHARED_LIBS=OFF -DNNG_TESTS=OFF -DNNG_ENABLE_SQLITE=ON -DNNG_ENABLE_TLS=ON"

if [ $arch == "x86_64" ]; then
    compile_source_with_tag google/googletest.git googletest release-1.11.0
fi
