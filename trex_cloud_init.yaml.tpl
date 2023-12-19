#cloud-config
output: {all: '| tee -a /var/log/cloud-init-output.log'}

#
# Download and configure Cisco TRex load generator
#
# Template inputs
# trex_bundle_url
# trex_dpdk_setup_conf_b64

# Script to build DPDK driver
write_files:
- path: /home/ec2-user/dpdk_setup.sh
  owner: ec2-user:ec2-user
  permissions: '0755'
  defer: true
  encoding: b64
  content: |
    ${trex_dpdk_setup_conf_b64}

runcmd:
  # Configure kernel
  - "echo \"vm.nr_hugepages=2048\" > /etc/sysctl.d/80-trex-dpdk.conf"
  - [ sysctl, -w, vm.nr_hugepages=2048 ]
  # Create folders
  - [ mkdir, -p, "/opt/trex" ]
  #
  # Download and unpack installation bundle
  - [ wget, -q, --no-cache, --no-check-certificate, -O, "/opt/trex/latest", "${trex_bundle_url}" ]
  - [ cd, /opt/trex ]
  - [ tar, xzf, /opt/trex/latest ]
  #
  # Download and build igb_uio driver for TRex
  - [ /home/ec2-user/dpdk_setup.sh ]

# Update/Upgrade & Reboot if necessary
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
 - wget
