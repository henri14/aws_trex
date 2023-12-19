# Need tp build the DPDK Poll Mode Driver to support the AWS for ENA driver
# See https://doc.dpdk.org/guides/linux_gsg/sys_reqs.html#compilation-of-the-dpdk
# and https://doc.dpdk.org/guides/nics/ena.html
dnf groupinstall -y "Development Tools"
dnf -y install pip
pip3 install meson ninja
pip3 install pyelftools
dnf -y install numactl-devel
# Install kernel headers for our version
dnf install -y kernel-devel-$(uname -r)
#
# Follow https://doc.dpdk.org/dts/gsg/usr_guide/igb_uio.html
# Get DPDK:
cd ~ec2-user
git clone git://dpdk.org/dpdk
# Get igb_uio:
git clone git://dpdk.org/dpdk-kmods
# Build and setup igb_uio
cp -r ./dpdk-kmods/linux/igb_uio ./dpdk/kernel/linux/
# enable igb_uio build in meson:

# add igb_uio in dpdk/kernel/linux/meson.build subdirs as below:

# subdirs = ['kni', 'igb_uio']
cat <<EOF >meson.build
# SPDX-License-Identifier: BSD-3-Clause
# Copyright(c) 2017 Intel Corporation

mkfile = custom_target('igb_uio_makefile',
        output: 'Makefile',
        command: ['touch', '@OUTPUT@'])

custom_target('igb_uio',
        input: ['igb_uio.c', 'Kbuild'],
        output: 'igb_uio.ko',
        command: ['make', '-C', kernel_dir + '/build',
                'M=' + meson.current_build_dir(),
                'src=' + meson.current_source_dir(),
                'EXTRA_CFLAGS=-I' + meson.current_source_dir() +
                        '/../../../lib/librte_eal/include',
                'modules'],
        depends: mkfile,
        install: true,
        install_dir: kernel_dir + '/extra/dpdk',
        build_by_default: get_option('enable_kmods'))
EOF
mkdir ./dpdk/kernel/linux/igb_uio
cp meson.build ./dpdk/kernel/linux/igb_uio/
export PATH=$PATH:/usr/local/bin
cd /home/ec2-user/dpdk
# Generate build instructions on build directory
meson setup build
# Build it
cd build
ninja
# Install and load igp_uio
meson install
ldconfig
cd /home/ec2-user/dpdk/kernel/linux
make
# [root@ip-10-14-1-75 linux]# lsmod | grep uio
# igb_uio                20480  0
# uio                    32768  1 igb_uio
# Load module at boot time
mkdir /lib/modules/$(uname -r)/kernel/net/dpdk
cp /home/ec2-user/dpdk/kernel/linux/igb_uio.ko /lib/modules/$(uname -r)/kernel/net/dpdk
cat <<EOF >/etc/modprobe.d/dpdk.conf
# Used by TRex
options igb_uio wc_activate=1
EOF
cat <<EOF >/etc/modules-load.d/dpdk.conf
# Used by TRex
igb_uio
EOF

depmod -a
#sudo modprobe uio
#sudo insmod igb_uio.ko wc_activate=1
systemctl restart systemd-modules-load
