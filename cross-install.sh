#!/bin/bash

set -e

#x86_64-neuron-linux-musl
home=/home/neuron
branch=main
vendor=?
arch=?
gcc=?
gxx=?
install_dir=?
cross=false
cp=false
docker=false

while getopts ":a:v:c:p:d:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        v)
            vendor=$OPTARG
            ;;
        c)
            cross=$OPTARG
            ;;
        p)
            cp=$OPTARG
            ;;
        d)
            docker=$OPTARG
            ;;
    esac
done

case $cross in
    (true)  
        gcc=$vendor-gcc;
        gxx=$vendor-g++;;
    (false) 
        gcc=/home/neuron/buildroot_datalayers/$vendor/output/host/bin/$vendor-gcc;
        gxx=/home/neuron/buildroot_datalayers/$vendor/output/host/bin/$vendor-g++;;
esac

install_dir=$home/$branch/libs/$vendor/
library=$home/$branch/library/$vendor/

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
            compile_prefix=/home/neuron/buildroot_datalayers/$vendor/output/host/bin/$vendor-;;
    esac
    cd $library
    git clone -b OpenSSL_1_1_1 https://github.com/openssl/openssl.git
    cd openssl
    mkdir -p $install_dir/openssl/ssl
    platform=linux-$arch
    if [[ $arch == "riscv64" ]]; then
      platform=linux-generic64
    fi
    ./Configure $platform no-asm no-async shared \
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
    curl -L -A "Mozilla/5.0" https://www.sqlite.org/2022/sqlite-autoconf-3390000.tar.gz \
      --output sqlite3.tar.gz
    mkdir -p sqlite3
    tar xzf sqlite3.tar.gz --strip-components=1 -C sqlite3
    cd sqlite3

    ./configure --prefix=$install_dir \
                --disable-shared --disable-readline \
                --host=$vendor \
                CC=$gcc  CFLAGS=-fPIC

    make -j4
    make install
}

function build_protobuf() {
    cd $library
    wget --no-check-certificate --content-disposition https://github.com/protocolbuffers/protobuf/releases/download/v3.20.1/protobuf-cpp-3.20.1.tar.gz
    tar -xzf protobuf-cpp-3.20.1.tar.gz
    cd protobuf-3.20.1

    ./configure --prefix=$install_dir CC=$gcc --host=$vendor --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC

    make -j4
    make install

    cp ./LICENSE $install_dir/protobuf-LICENSE 
}

function build_protobuf-c(){
    cd $library
    git clone -b v1.4.0 https://github.com/protobuf-c/protobuf-c.git
    cd protobuf-c
    ./autogen.sh

    ./configure --prefix=$install_dir CC=$gcc --host=$vendor --disable-protoc --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC PKG_CONFIG_PATH=$vendor

    make -j4
    make install

    cp ./LICENSE $install_dir/protobuf-c-LICENSE 
}

function build_libxml2(){
    cd $library
    git clone -b v2.9.14 https://github.com/GNOME/libxml2
    cd libxml2
    ./autogen.sh

    ./configure --prefix=$install_dir CC=$gcc --host=$vendor --enable-shared=no --with-http=no --with-python=no --with-lzma=no --with-zlib=no CFLAGS='-O2 -fno-semantic-interposition -fPIC' PKG_CONFIG_PATH=$vendor

    make -j4
    make install
}

function build_grpc() {
    cd $library
    #git clone -b v1.56.0 --recurse-submodules https://github.com/grpc/grpc.git

    if [ "$cp" = true ]; then
        echo "Copying grpc from /home/neuron/third_party"
        cp -r /home/neuron/third_party/grpc ./
    else
        echo "Cloning grpc repository"
        git clone -b v1.56.0 --recurse-submodules https://github.com/grpc/grpc.git
        cp /library/third_party/GENERATED_AbseilCopts.cmake grpc/third_party/abseil-cpp/absl/copts/GENERATED_AbseilCopts.cmake
    fi

    cd grpc
    mkdir -p cmake/build && cd cmake/build

    local cmake_args="
        -DCMAKE_C_COMPILER=$gcc
        -DCMAKE_CXX_COMPILER=$gxx
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_STAGING_PREFIX=$install_dir
        -DCMAKE_PREFIX_PATH=$install_dir
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
        -DgRPC_INSTALL=ON
        -DgRPC_BUILD_TESTS=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBUILD_SHARED_LIBS=OFF
        -DgRPC_ABSL_PROVIDER=module
        -DgRPC_CARES_PROVIDER=module
        -DgRPC_PROTOBUF_PROVIDER=module
        -DgRPC_RE2_PROVIDER=module
        -DgRPC_SSL_PROVIDER=package
        -DgRPC_ZLIB_PROVIDER=package
        -DABSL_PROPAGATE_CXX_STD=ON
        -DABSL_BUILD_DLL=OFF
        -Dprotobuf_BUILD_PROTOC_BINARIES=off
        -DgRPC_BUILD_CODEGEN=off
        -DProtobuf_PROTOC_EXECUTABLE=/library/third_party/protoc-23.1.0
        -DgRPC_CPP_PLUGIN_EXECUTABLE=/library/third_party/grpc_cpp_plugin
    "

    if [ "$arch" != "x86_64" ]; then
        cmake_args="$cmake_args -DCMAKE_CROSSCOMPILING=TRUE"
    fi

    cmake ../.. $cmake_args
    make -j4
    make install
}

function build_bison() {
    cd $library
    wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
    tar -xzf bison-3.8.2.tar.gz
    cd bison-3.8.2
    ./configure --prefix=$install_dir --disable-shared --enable-static
    make -j$(nproc)
    sudo make install
}

function build_flex() {
    cd $library
    wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
    tar -xzf flex-2.6.4.tar.gz
    cd flex-2.6.4
    ./configure --prefix=$install_dir --disable-shared --enable-static
    make -j$(nproc)
    sudo make install
}

function build_thrift() {
    #sudo apt-get install -y flex bison
    cd $library
    git clone -b 0.21.0 https://github.com/apache/thrift.git
    cd thrift
    mkdir -p build/cmake/build && cd build/cmake/build

    cmake ../../.. \
        -DCMAKE_C_COMPILER=$gcc \
        -DCMAKE_CXX_COMPILER=$gxx \
        -DZLIB_INCLUDE_DIR=/usr/local/include \
        -DCMAKE_INSTALL_PREFIX=$install_dir \
        -DCMAKE_PREFIX_PATH=$install_dir \
        -DCMAKE_STAGING_PREFIX=$install_dir \
        -DCMAKE_FIND_ROOT_PATH=$install_dir \
        -DTHRIFT_COMPILER=/library/third_party/thrift \
        -DCMAKE_FIND_USE_CMAKE_PATH=ON \
        -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_NODEJS=OFF \
        -DBUILD_PYTHON=OFF \
        -DBUILD_JAVA=OFF \
        -DBUILD_JAVASCRIPT=OFF \
        -DBUILD_KOTLIN=OFF \
        -DBUILD_TESTING=OFF

    make -j4
    make install
}

function build_boost() {
    cd $library
    wget https://github.com/boostorg/boost/releases/download/boost-1.81.0/boost-1.81.0.tar.gz
    tar -xzf boost-1.81.0.tar.gz
    cd boost-1.81.0

    mkdir build && cd build

    system_processor=""
    case "$arch" in
        x86_64)
            system_processor="x86_64"
            ;;
        armv7 | armv4)
            system_processor="arm"
            ;;
        aarch64)
            system_processor="aarch64"
            ;;
        riscv64)
            system_processor="riscv64"
            ;;
        mips)
            system_processor="mips"
            ;;
        *)
            echo "Unknown architecture: $arch"
            exit 1
            ;;
    esac

    cmake .. \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=$system_processor \
        -DCMAKE_C_COMPILER=$gcc \
        -DCMAKE_CXX_COMPILER=$gxx \
        -DCMAKE_STAGING_PREFIX=$install_dir \
        -DCMAKE_PREFIX_PATH=$install_dir \
        -DWITH_CONTEXT=OFF

    make -j4
    make install
}

function build_gflags() {
    cd $library
    git clone https://github.com/gflags/gflags.git
    cd gflags
    mkdir -p build && cd build

    cmake .. \
        -DCMAKE_C_COMPILER=$gcc \
        -DCMAKE_CXX_COMPILER=$gxx \
        -DCMAKE_INSTALL_PREFIX=$install_dir \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

    make -j$(nproc)
    make install
}

function build_zlib() {
    cd $library
    wget https://zlib.net/zlib-1.3.1.tar.gz
    tar -xzf zlib-1.3.1.tar.gz
    cd zlib-1.3.1

    CHOST=$vendor

    export CFLAGS="-fPIC"
    export CXXFLAGS="-fPIC"

    CC=$gcc ./configure \
        --prefix=$install_dir \
        --static

    make -j4
    make install
}

function build_arrow() {
    cd $library
    wget https://github.com/apache/arrow/releases/download/apache-arrow-19.0.1/apache-arrow-19.0.1.tar.gz
    tar -xzf apache-arrow-19.0.1.tar.gz
    cd apache-arrow-19.0.1/cpp

    cp /library/third_party/gRPCConfig.cmake $install_dir/lib/cmake/grpc/

    mkdir -p build && cd build

    cmake_args=(
        -DCMAKE_C_COMPILER="$gcc"
        -DCMAKE_CXX_COMPILER="$gxx"
        -DCMAKE_STAGING_PREFIX="$install_dir"
        -DCMAKE_PREFIX_PATH="$install_dir"
        -DCMAKE_BUILD_TYPE=Release
        -DARROW_BUILD_SHARED=OFF
        -DARROW_BUILD_STATIC=ON
        -DARROW_COMPUTE=ON
        -DARROW_CSV=ON
        -DARROW_JSON=OFF
        -DARROW_PARQUET=ON
        -DARROW_DATASET=ON
        -DARROW_FLIGHT=ON
        -DARROW_FLIGHT_SQL=ON
        -DARROW_WITH_GRPC=ON
        -DARROW_WITH_UTF8PROC=OFF
        -DARROW_PROTOBUF_USE_SHARED=OFF
        -DARROW_gRPC_USE_SHARED=OFF
        -DCMAKE_INSTALL_PREFIX="$install_dir"
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
        -DCMAKE_C_FLAGS="-fPIC"
        -DCMAKE_CXX_FLAGS="-fPIC"
        -DARROW_SIMD_LEVEL=NONE
        -DARROW_RUNTIME_SIMD_LEVEL=NONE
        -DProtobuf_ROOT="$install_dir"
        -DgRPC_ROOT="$install_dir"
        -DgRPC_DIR="$install_dir/lib/cmake/grpc"
        -DARROW_GRPC_CPP_PLUGIN="/library/third_party/grpc_cpp_plugin"
        -DPROTOBUF_PROTOC_EXECUTABLE="/home/neuron/test/libs/x86_64-buildroot-linux-gnu/bin/protoc"
        -DPROTOBUF_INCLUDE_DIR="$install_dir/include"
        -DPROTOBUF_LIBRARY="$install_dir/lib/libprotobuf.a"
        -GNinja
    )

    if [ "$arch" != "x86_64" ]; then
        cmake_args+=(
            -DCMAKE_SYSTEM_PROCESSOR="$arch"
            -DCMAKE_CROSSCOMPILING=TRUE
        )
    fi

    cmake .. "${cmake_args[@]}"

    ninja
    ninja install
}

function build_arrow_docker() {
    cd $library
    wget https://github.com/apache/arrow/releases/download/apache-arrow-19.0.1/apache-arrow-19.0.1.tar.gz
    tar -xzf apache-arrow-19.0.1.tar.gz
    cd apache-arrow-19.0.1/cpp

    mkdir -p build && cd build

    cmake .. \
        -DCMAKE_C_COMPILER="$gcc" \
        -DCMAKE_CXX_COMPILER="$gxx" \
        -DCMAKE_STAGING_PREFIX="$install_dir" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_PREFIX_PATH="$install_dir;/usr" \
        -DCMAKE_BUILD_TYPE=Release \
        -DARROW_BUILD_SHARED=OFF \
        -DARROW_BUILD_STATIC=ON \
        -DARROW_COMPUTE=ON \
        -DARROW_CSV=ON \
        -DARROW_JSON=OFF \
        -DARROW_PARQUET=ON \
        -DARROW_DATASET=ON \
        -DARROW_FLIGHT=ON \
        -DARROW_FLIGHT_SQL=ON \
        -DARROW_WITH_GRPC=ON \
        -DARROW_WITH_UTF8PROC=OFF \
        -DARROW_PROTOBUF_USE_SHARED=OFF \
        -DARROW_gRPC_USE_SHARED=OFF \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DCMAKE_C_FLAGS="-fPIC" \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DARROW_SIMD_LEVEL=NONE \
        -DARROW_RUNTIME_SIMD_LEVEL=NONE \
        -DProtobuf_ROOT="/usr" \
        -DgRPC_ROOT="/usr" \
        -GNinja

    ninja
    ninja install
}

sudo rm -rf $library
sudo rm -rf $install_dir
mkdir -p $library
mkdir -p $install_dir/bin
mkdir -p $install_dir/include
mkdir -p $install_dir/lib

build_openssl 
build_protobuf
build_protobuf-c
build_zlib

if [ "$docker" == "true" ]; then
    build_arrow_docker
else
    build_grpc
    build_bison
    build_flex
    build_boost
    build_thrift
    build_gflags
    build_arrow
fi

build_zlog
build_sqlite3
build_libxml2

compile_source neugates/jansson.git jansson "-DJANSSON_BUILD_DOCS=OFF -DJANSSON_EXAMPLES=OFF"
compile_source_with_tag google/googletest.git googletest release-1.11.0
compile_source_with_tag benmcollins/libjwt.git libjwt v1.13.1 "-DENABLE_PIC=ON -DBUILD_SHARED_LIBS=OFF"
compile_source_with_tag ARMmbed/mbedtls.git mbedtls v2.16.12 "-DCMAKE_BUILD_TYPE=Release -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DENABLE_TESTING=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON"
compile_source_with_tag neugates/open62541.git open62541 neuron-1.2.9 "-DBUILD_SHARED_LIBS=OFF -DUA_ENABLE_ENCRYPTION=ON -DUA_ENABLE_ENCRYPTION_OPENSSL=ON -DUA_ENABLE_AMALGAMATION=ON -DUA_BUILD_EXAMPLES=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DUA_LOGLEVEL=500 -DCMAKE_BUILD_TYPE=Release"
compile_source_with_tag neugates/NanoSDK.git NanoSDK neuron "-DBUILD_SHARED_LIBS=OFF -DNNG_TESTS=OFF -DNNG_ENABLE_SQLITE=ON -DNNG_ENABLE_TLS=ON"
compile_source_with_tag warmcat/libwebsockets.git libwebsockets v4.3.5 "-DLWS_WITH_SHARED=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DLWS_WITHOUT_TESTAPPS=ON"
