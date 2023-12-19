#cloud-config
output: {all: '| tee -a /var/log/cloud-init-output.log'}

#
# Download and configure Cisco TRex load generator
#
# Template inputs
# samplicator_bundle_url
# samplicator_bundle_dir
# samplicator_conf_b64
# samplicator_service_b64

runcmd:
  # Devel packages
  - [ dnf, groupinstall, -y, "Development Tools" ]
  # Create folders
  - [ mkdir, -p, "/opt/samplicator/etc" ]
  #
  # Copy installation bundle
  - [ wget, -q, --no-cache, -O, "/opt/samplicator/samplicator.tar.gz", "${samplicator_bundle_url}" ]
  - [ cd, /opt/samplicator ]
  - [ tar, xf, samplicator.tar.gz ]
  - [ cd, "${samplicator_bundle_dir}" ]
  - [ ./configure ]
  - [ make ]
  - [ make, install ]
  - [ systemctl, daemon-reload ]
  - [ systemctl, start, samplicator ]

# Update/Upgrade & Reboot if necessary
package_update: true
package_upgrade: true
package_reboot_if_required: true

packages:
 - wget
 - tcpdump

# Samplicator config and service
write_files:
- path: /opt/samplicator/etc/samplicator.conf
  owner: root:root
  permissions: '0644'
  encoding: b64
  content: |
    ${samplicator_conf_b64}
- path: /etc/systemd/system/samplicator.service
  owner: root:root
  permissions: '0644'
  encoding: b64
  content: |
    ${samplicator_service_b64}