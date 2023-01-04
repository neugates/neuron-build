#!/bin/bash

set -e

home=/home/neuron
vendor=?
arch=?
ui_version=2.3.1
version=?
ekuiper_version=1.7.3
ekuiper_arch=?
ekuiper=false

while getopts ":a:v:e:k:o:" OPT; do
    case ${OPT} in
        a)
            arch=$OPTARG
            ;;
        o)
            vendor=$OPTARG
            ;;
	e)
	    ekuiper=$OPTARG
	    ;;
	k)
	    ekuiper_arch=$OPTARG
	    ;;
	v)
	    version=$OPTARG
	    ;;
    esac
done


neuron_dir=$home/Program/$vendor/neuron
neuron_modules_dir=$home/Program/$vendor/neuron-modules
package_dir=$home/Program/$vendor/package/neuron
library=$home/libs/$vendor

function download_ui() {
	cd $package_dir

	case $ekuiper in
		(true)
			wget https://github.com/emqx/neuron-dashboard/releases/download/$ui_version/neuron-dashboard.zip;

			unzip neuron-dashboard.zip;
			rm -rf neuron-dashboard.zip;;
		(false)
			wget https://github.com/emqx/neuron-dashboard/releases/download/$ui_version/neuron-dashboard-lite.zip;

			unzip neuron-dashboard-lite.zip;
			rm -rf neuron-dashboard-lite.zip;;
	esac
}

function download_ekuiper() {
	cd $package_dir

	case $ekuiper in
		(true)
			wget https://github.com/lf-edge/ekuiper/releases/download/$ekuiper_version/kuiper-$ekuiper_version-linux-$ekuiper_arch.tar.gz;

			mkdir ekuiper;
			tar xvf kuiper-$ekuiper_version-linux-$ekuiper_arch.tar.gz --strip-components=1 -C ekuiper/;
			rm -rf kuiper-$ekuiper_version-linux-$ekuiper_arch.tar.gz;;
	esac
}

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

download_ui
download_ekuiper

cp $library/lib/libzlog.so.1.2 $package_dir/

cp $neuron_dir/build/libneuron-base.so $package_dir/
cp $neuron_dir/build/neuron $package_dir/
cp $neuron_dir/build/config/neuron.key \
	$neuron_dir/build/config/neuron.pem \
	$neuron_dir/build/config/zlog.conf \
	$neuron_dir/build/config/dev.conf \
	$neuron_dir/build/config/*.sql \
	$package_dir/config/

cp $neuron_modules_dir/neuron-helper.sh $package_dir/

cp $neuron_modules_dir/default_plugins.json \
	$neuron_modules_dir/build/config/opcua_cert.der \
 	$neuron_modules_dir/build/config/opcua_key.der \
	$package_dir/config/

cp $neuron_dir/build/plugins/libplugin-mqtt.so \
	$neuron_dir/build/plugins/libplugin-ekuiper.so \
	$neuron_dir/build/plugins/libplugin-modbus-tcp.so \
	$neuron_dir/build/plugins/libplugin-file.so \
	$neuron_dir/build/plugins/libplugin-monitor.so \
	$package_dir/plugins/

cp $neuron_dir/build/plugins/schema/*.json \
	$package_dir/plugins/schema/

cp $neuron_modules_dir/build/plugins/libplugin-modbus-plus-tcp.so \
    	$neuron_modules_dir/build/plugins/libplugin-modbus-rtu.so \
	$neuron_modules_dir/build/plugins/libplugin-modbus-qh-tcp.so \
    	$neuron_modules_dir/build/plugins/libplugin-opcua.so \
    	$neuron_modules_dir/build/plugins/libplugin-s7comm.so \
    	$neuron_modules_dir/build/plugins/libplugin-s7comm-for-300.so \
    	$neuron_modules_dir/build/plugins/libplugin-fins.so \
    	$neuron_modules_dir/build/plugins/libplugin-qna3e.so \
    	$neuron_modules_dir/build/plugins/libplugin-iec104.so \
    	$neuron_modules_dir/build/plugins/libplugin-bacnet.so \
    	$neuron_modules_dir/build/plugins/libplugin-dlt645-2007.so\
    	$neuron_modules_dir/build/plugins/libplugin-knx.so\
    	$neuron_modules_dir/build/plugins/libplugin-nona11.so\
    	$neuron_modules_dir/build/plugins/libplugin-ads.so\
    	$neuron_modules_dir/build/plugins/libplugin-license-server.so\
    	$neuron_modules_dir/build/plugins/libplugin-EtherNet-IP.so\
    	$neuron_modules_dir/build/plugins/libplugin-focas.so \
    	$neuron_modules_dir/build/plugins/libplugin-a1e.so\
    	$neuron_modules_dir/build/plugins/libplugin-websocket.so\
	$neuron_modules_dir/build/plugins/libplugin-sparkplugb.so\
    	$package_dir/plugins/

cp $neuron_modules_dir/build/plugins/focas/libfwlib32.so.1 $package_dir/

cp $neuron_modules_dir/build/plugins/schema/*.json \
	$package_dir/plugins/schema/

cd $package_dir/..
rm -rf neuron*.tar.gz

case $ekuiper in
	(true)
		tar czf neuronex-$version-linux-$arch.tar.gz neuron
		echo "neuronex-$version-linux-$arch.tar.gz";;
	(false)
		tar czf neuron-$version-linux-$arch.tar.gz neuron
		echo "neuron-$version-linux-$arch.tar.gz";;
esac