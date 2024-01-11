import mkdeb
import os
import sys
import argparse


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--version", type=str, help="version")
    parser.add_argument("-a", "--arch", type=str, help="arch")
    parser.add_argument("-o", "--vendor", type=str, help="vendor")
    return parser.parse_args()


args = parse_args()

home = '/home/neuron'
branch = '/v2.7'
package_dir = home + branch + '/Program/' + args.vendor + '/package/neuron'
rules = []

rules.append(mkdeb.FileMap("deb/conffiles", "/DEBIAN/", "r", "conffiles"))
rules.append(mkdeb.FileMap("deb/postinst", "/DEBIAN/", "r", "postinst"))
rules.append(mkdeb.FileMap("deb/preinst", "/DEBIAN/", "r", "preinst"))
rules.append(mkdeb.FileMap("deb/prerm", "/DEBIAN/", "r", "prerm"))

rules.append(mkdeb.FileMap(package_dir + '/LICENSE', '/opt/neuron'))
rules.append(mkdeb.FileMap("neuron.service", "/etc/systemd/system/"))

rules.append(mkdeb.FileMap("neuron.sh", "/opt/neuron/", "x"))
rules.append(mkdeb.FileMap("stop.sh", "/opt/neuron/", "x"))

rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/core/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/logs/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/persistence/"))
rules.append(mkdeb.FileMap(".gitkeep", "/opt/neuron/certs/"))

rules.append(mkdeb.FileMap(package_dir + '/neuron', "/opt/neuron/", "x"))
rules.append(mkdeb.FileMap(
    package_dir + "/libfocas32.so.1", "/opt/neuron/"))
rules.append(mkdeb.FileMap(
    package_dir + '/libneuron-base.so', "/opt/neuron/"))
rules.append(mkdeb.FileMap(
    package_dir + '/liblicense.so', "/opt/neuron/"))
rules.append(mkdeb.FileMap(
    package_dir + "/libzlog.so.1.2", "/opt/neuron/"))

mkdeb.copy_dir(package_dir + '/config', '/opt/neuron/')
mkdeb.copy_dir(package_dir + '/plugins', '/opt/neuron/')
mkdeb.copy_dir(package_dir + '/persistence', '/opt/neuron/')

mkdeb.create_deb_file(rules)

mkdeb.create_control("neuron", args.version,
                     args.arch, "neuron cn package", "")
cmd = 'dpkg-deb -Zxz -b tmp/ ' + 'neuron' + '-' + \
    args.version + '-' + 'linux' + '-' + args.arch + ".deb"

os.system(cmd)
