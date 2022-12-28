import mkdeb
import os
import sys
import argparse


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--version", type=str, help="version")
    parser.add_argument("-p", "--arch", type=str, help="arch")
    parser.add_argument("-o", "--vendor", type=str, help="vendor")
    parser.add_argument("-e", "--with_ekuiper", type=bool,
                         help="package with ekuiper")
    return parser.parse_args()


args = parse_args()

home = '/home/neuron'
package_dir = home + '/Program' + args.vendor + '/package'
if args.with_ekuiper:
    package_dir = package_dir + '/neuron'
else:
    package_dir = package_dir + '/neuronex'

rules = []

rules.append(mkdeb.FileMap("deb/conffiles", "/DEBIAN/", "r", "conffiles"))
rules.append(mkdeb.FileMap("deb/postinst", "/DEBIAN/", "r", "postinst"))
rules.append(mkdeb.FileMap("deb/preinst", "/DEBIAN/", "r", "preinst"))
rules.append(mkdeb.FileMap("deb/prerm", "/DEBIAN/", "r", "prerm"))

rules.append(mkdeb.FileMap("neuron.service", "/etc/systemd/system/"))

rules.append(mkdeb.FileMap("neuron.sh", "/opt/neuron/", "x"))
rules.append(mkdeb.FileMap("stop.sh", "/opt/neuron/", "x"))

rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/core/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/logs/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/persistence/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/certs/"))

rules.append(mkdeb.FileMap(package_dir + '/neuron', "/opt/neuron/", "x"))
rules.append(mkdeb.FileMap(
    package_dir + '/libneuron-base.so', "/usr/local/lib/"))
rules.append(mkdeb.FileMap(
     package_dir + "/libzlog.so.1.2", "/usr/local/lib/"))

mkdeb.copy_dir(package_dir + '/config', '/opt/neuron/')
mkdeb.copy_dir(package_dir + '/plugins', '/opt/neuron/')
mkdeb.copy_dir(package_dir + '/dist', '/opt/neuron/')

if args.with_ekuiper:
    mkdeb.copy_dir('../build/ekuiper', '/opt/neuron/')
    rules.append(mkdeb.FileMap("ekuiper.sh", "/opt/neuron/ekuiper/", "x"))
    rules.append(mkdeb.FileMap(
        "neuron.ekuiper.service", "/etc/systemd/system/"))

mkdeb.create_deb_file(rules)

if args.with_ekuiper:
    mkdeb.create_control("neuronex", args.version,
                         args.arch, "neuron plus ekuiper", "")
    cmd = 'dpkg-deb -b tmp/ ' + 'neuronex' + '-' + \
        args.version + '-' + 'linux' + '-' + args.arch + ".deb"
else:
    mkdeb.create_control("neuron", args.version, args.arch, "neuron", "")
    cmd = 'dpkg-deb -b tmp/ ' + 'neuron' + '-' + \
        args.version + '-' + 'linux' + '-' + args.arch + ".deb"

os.system(cmd)
