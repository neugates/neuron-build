## Deps list

| Name       | Version |      |
| ---------- | ------- | ---- |
| protobuf   | v3.20.1 |      |
| protobuf-c | v1.4.0  |      |

## Build

### protobuf

```sh
cd ${workbench}
wget --no-check-certificate --content-disposition https://github.com/protocolbuffers/protobuf/releases/download/v3.20.1/protobuf-cpp-3.20.1.tar.gz
tar -xzvf protobuf-cpp-3.20.1.tar.gz
cd protobuf-3.20.1
```

#### x86_64

```sh
./configure --prefix=${workbench}/neuron2-libs/x86_64/protobuf/ --host=x86_64-linux-gnu --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC
make -j4 && make intall && make clean
```

#### aarch64

```sh
./configure --prefix=${workbench}/neuron2-libs/aarch64/protobuf/ --host=aarch64-linux-gnu --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC
make -j4 && make intall && make clean
```

#### armv4

```sh
./configure --prefix=${workbench}/neuron2-libs/armv4/protobuf/ --host=arm-linux-gnueabihf --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC
make -j4 && make intall && make clean
```

### protobuf-c

```sh
git clone -b v1.4.0 git@github.com:protobuf-c/protobuf-c.git
cd protobuf-c
./autogen.sh
```

#### x86_64

```sh
./configure --prefix=${workbench}/neuron2-libs/x86_64/protobuf-c/ --host=x86_64-linux-gnu --disable-protoc --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC PKG_CONFIG_PATH=${workbench}/neuron2-libs/x86_64/protobuf/lib/pkgconfig
make -j4 && make intall && make clean
```

#### aarch64

```sh
./configure --prefix=${workbench}/neuron2-libs/aarch64/protobuf-c/ --host=aarch64-linux-gnu --disable-protoc --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC PKG_CONFIG_PATH=${workbench}/neuron2-libs/aarch64/protobuf/lib/pkgconfig
make -j4 && make intall && make clean
```

#### armv4

```sh
./configure --prefix=${workbench}/neuron2-libs/armv4/protobuf-c/ --host=arm-linux-gnueabihf --disable-protoc --enable-shared=no CFLAGS=-fPIC CXXFLAGS=-fPIC PKG_CONFIG_PATH=${workbench}/neuron2-libs/armv4/protobuf/lib/pkgconfig
make -j4 && make intall && make clean
```

