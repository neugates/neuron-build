#!/bin/bash

set -e

home=/home/neuron
branch=v2.8
vendor=?
arch=?
version=?
cnc=false
custom=default
build_type=Release

while getopts ":a:v:o:c:n:d:" OPT; do
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
        c)
            custom=$OPTARG
            ;;
        n)
            cnc=$OPTARG
            ;;
        d)
            build_type=$OPTARG
            ;;
    esac
done


case $build_type in
    (Release)
        neuron_dir=$home/$branch/Program/$vendor/neuron;
        neuron_modules_dir=$home/$branch/Program/$vendor/neuron-modules;
        package_dir=$home/$branch/Program/$vendor/package/neuron;;
    (Debug)
        neuron_dir=$home/$branch/Program_Debug/$vendor/neuron; 
        neuron_modules_dir=$home/$branch/Program_Debug/$vendor/neuron-modules;
        package_dir=$home/$branch/Program_Debug/$vendor/package/neuron;;
esac


library=$home/$branch/libs/$vendor
script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P  )"


rm -rf $package_dir

mkdir -p $package_dir
mkdir -p $package_dir/config
mkdir -p $package_dir/plugins/schema
mkdir -p $package_dir/logs
mkdir -p $package_dir/persistence
mkdir -p $package_dir/certs
mkdir -p $package_dir/simulator


cp .gitkeep $package_dir/logs/
cp .gitkeep $package_dir/persistence/
cp .gitkeep $package_dir/certs/

cp $neuron_dir/LICENSE $package_dir/config
cp $neuron_modules_dir/config/protobuf-LICENSE $package_dir/config/
cp $neuron_modules_dir/config/protobuf-c-LICENSE $package_dir/config/

cp $library/lib/libzlog.so.1.2 $package_dir/

cp $neuron_dir/LICENSE $package_dir/
cp $neuron_dir/build/libneuron-base.so $package_dir/
cp $neuron_modules_dir/build/liblicense.so $package_dir/

cp $neuron_dir/build/neuron $package_dir/
cp $neuron_dir/build/config/neuron.key \
    $neuron_dir/build/config/neuron.pem \
    $neuron_dir/build/config/neuron.json \
    $neuron_dir/build/config/zlog.conf \
    $neuron_dir/build/config/dev.conf \
    $neuron_dir/build/config/*.sql \
    $package_dir/config/

cp $neuron_modules_dir/build/config/neuron-default.lic \
    $package_dir/persistence/

cp $neuron_modules_dir/default_plugins.json \
    $neuron_modules_dir/build/config/opcua_cert.der \
     $neuron_modules_dir/build/config/opcua_key.der \
    $package_dir/config/

cp $neuron_dir/build/plugins/libplugin-mqtt.so \
    $neuron_dir/build/plugins/libplugin-ekuiper.so \
    $package_dir/plugins/

cp $neuron_dir/build/plugins/schema/*.json \
    $package_dir/plugins/schema/

cp $neuron_modules_dir/build/plugins/libplugin-websocket.so \
        $neuron_modules_dir/build/plugins/libplugin-gewu.so \
        $neuron_modules_dir/build/plugins/libplugin-sparkplugb.so \
        $neuron_modules_dir/build/plugins/libplugin-opcua.so \
        $neuron_modules_dir/build/plugins/libplugin-EtherNet-IP.so \
        $neuron_modules_dir/build/plugins/libplugin-Profinet.so \
        $neuron_modules_dir/build/plugins/libplugin-qna3e.so \
        $neuron_modules_dir/build/plugins/libplugin-a1e.so \
        $neuron_modules_dir/build/plugins/libplugin-fx.so \
        $neuron_modules_dir/build/plugins/libplugin-s7comm.so \
        $neuron_modules_dir/build/plugins/libplugin-s7comm-for-300.so \
        $neuron_modules_dir/build/plugins/libplugin-s5fetch-write.so \
        $neuron_modules_dir/build/plugins/libplugin-mpi.so \
        $neuron_modules_dir/build/plugins/libplugin-fins-tcp.so \
        $neuron_modules_dir/build/plugins/libplugin-fins-udp.so \
        $neuron_modules_dir/build/plugins/libplugin-hostlink-cmode.so \
        $neuron_modules_dir/build/plugins/libplugin-ads.so \
        $neuron_modules_dir/build/plugins/libplugin-df1.so \
        $neuron_modules_dir/build/plugins/libplugin-comli.so \
        $neuron_modules_dir/build/plugins/libplugin-mewtocol.so \
        $neuron_modules_dir/build/plugins/libplugin-iec104.so \
        $neuron_modules_dir/build/plugins/libplugin-iec61850.so \
        $neuron_modules_dir/build/plugins/libplugin-dlt645-2007.so \
        $neuron_modules_dir/build/plugins/libplugin-dlt645-1997.so \
        $neuron_modules_dir/build/plugins/libplugin-bacnet.so \
        $neuron_modules_dir/build/plugins/libplugin-knx.so \
        $neuron_modules_dir/build/plugins/libplugin-HJ212.so \
        $neuron_modules_dir/build/plugins/libplugin-nona11.so \
        $neuron_modules_dir/build/plugins/libplugin-modbus-tcp.so \
        $neuron_modules_dir/build/plugins/libplugin-modbus-rtu.so \
        $neuron_modules_dir/build/plugins/libplugin-modbus-qh-tcp.so \
        $neuron_modules_dir/build/plugins/libplugin-inovance-modbus-tcp.so \
        $neuron_modules_dir/build/plugins/libplugin-hsms.so \
        $neuron_modules_dir/build/plugins/libplugin-kuka.so \
        $neuron_modules_dir/build/plugins/libplugin-license-server.so \
        $neuron_modules_dir/build/plugins/libplugin-EtherNet-IP-1400.so \
        $neuron_modules_dir/build/plugins/libplugin-EtherNet-IP-5500.so \
        $neuron_modules_dir/build/plugins/libplugin-srtp.so \
        $neuron_modules_dir/build/plugins/libplugin-mtconnect.so \
        $package_dir/plugins/

cp $neuron_modules_dir/build/plugins/schema/*.json \
    $package_dir/plugins/schema/

cp $neuron_modules_dir/build/simulator/opcua_simulator \
	$package_dir/simulator/

case $cnc in 
    (true)
        cp	$neuron_modules_dir/build/plugins/libplugin-focas.so \
            $neuron_modules_dir/build/plugins/libplugin-mitsubishi_cnc.so \
            $neuron_modules_dir/build/plugins/libplugin-heidenhain_cnc.so \
            $package_dir/plugins/;

        cp $neuron_modules_dir/build/plugins/focas/libfocas32.so.1 $package_dir/;;
    (false)
        echo "no cnc";;
esac 

case $custom in
    (cun)
        cp 	$neuron_modules_dir/build/plugins/libplugin-gewu2.so \
            $neuron_modules_dir/build/plugins/libplugin-s7comm-for-un.so \
            $package_dir/plugins/;;
    (default)
        echo "no custom";;
esac

case $build_type in
    (Debug)
        if [ $vendor == "x86_64-neuron-linux-gnu" ]; then
    	    cp /home/neuron/buildroot/$vendor/output/host/usr/$vendor/lib64/libasan.so.2.0.0 $package_dir/
            cd $package_dir
            ln -s ./libasan.so.2.0.0 libasan.so.2
        fi;; 
    (Release)
        echo "release";;
esac


cd $package_dir/..
rm -rf neuron*.tar.gz


case $build_type in
    (Release)
        tar czf neuron-$version-linux-$arch.tar.gz neuron;
        echo "neuron-$version-linux-$arch.tar.gz";;
    (Debug)
        tar czf neuron-$version-debug-linux-$arch.tar.gz neuron;
        echo "neuron-$version-debug-linux-$arch.tar.gz";;
esac


