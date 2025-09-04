#!/bin/bash

set -e

home=/home/neuron
branch=main
vendor=?
arch=?
version=?
simulator=true

while getopts ":a:v:o:d:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        o)
            vendor=$OPTARG
            ;;
        v)
            version=$OPTARG
            ;;
        d)
            build_type=$OPTARG
            ;;
    esac
done


neuron_dir=$home/$branch/Program/$vendor/neuron
package_dir=$home/$branch/Program/$vendor/package/neuron

library=$home/$branch/libs/$vendor
script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P  )"


rm -rf $package_dir

mkdir -p $package_dir
mkdir -p $package_dir/config
mkdir -p $package_dir/plugins/schema
mkdir -p $package_dir/logs
mkdir -p $package_dir/persistence
mkdir -p $package_dir/certs


cp .gitkeep $package_dir/logs/
cp .gitkeep $package_dir/persistence/
cp .gitkeep $package_dir/certs/

cp $neuron_dir/LICENSE $package_dir/config

cp $library/lib/libzlog.so.1.2 $package_dir/
cp $library/lib/libssl.so.1.1 $package_dir/
cp $library/lib/libcrypto.so.1.1 $package_dir/

cp $neuron_dir/LICENSE $package_dir/
cp $neuron_dir/build/libneuron-base.so $package_dir/

cp $neuron_dir/build/neuron $package_dir/
cp  $neuron_dir/build/config/neuron.json \
    $neuron_dir/build/config/zlog.conf \
    $neuron_dir/build/config/dev.conf \
    $neuron_dir/build/config/*.sql \
    $package_dir/config/

cp $neuron_dir/default_plugins.json \
    $package_dir/config/

cp $neuron_dir/build/plugins/libplugin-mqtt.so \
    $neuron_dir/build/plugins/libplugin-ekuiper.so \
    $neuron_dir/build/plugins/libplugin-modbus-tcp.so  \
    $neuron_dir/build/plugins/libplugin-modbus-rtu.so  \
    $package_dir/plugins/

if [ -f "$neuron_dir/build/plugins/libplugin-datalayers.so" ]; then
    cp "$neuron_dir/build/plugins/libplugin-datalayers.so" "$package_dir/plugins/"
fi

cp $neuron_dir/build/plugins/schema/*.json \
    $package_dir/plugins/schema/

cp	$neuron_dir/build/simulator/modbus_simulator \
    $package_dir/

cp $home/dashboard/neuron-dashboard.zip $package_dir/
cd $package_dir
unzip neuron-dashboard.zip
rm neuron-dashboard.zip

cd $package_dir/..
rm -rf neuron*.tar.gz

tar czf neuron-$version-linux-$arch.tar.gz neuron
echo "neuron-$version-linux-$arch.tar.gz"
